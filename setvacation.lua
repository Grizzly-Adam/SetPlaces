
setvacation = {}

local vacations_file = minetest.get_worldpath() .. "/vacations"
local vacationpos = {}

local function loadvacations()
	local input = io.open(vacations_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		vacationpos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadvacations()

setvacation.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	player:set_attribute("setvacation:vacation", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	local data = {}
	local output = io.open(vacations_file, "w")
	if output then
		vacationpos[name] = nil
		for i, v in pairs(vacationpos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

setvacation.get = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = minetest.string_to_pos(player:get_attribute("setvacation:vacation"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = vacationpos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

setvacation.go = function(name)
	local pos = setvacation.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("vacation", {
	description = "Can use /setvacation and /vacation",
	give_to_singleplayer = false
})

minetest.register_chatcommand("vacation", {
	description = "Teleport you to your vacation point",
	privs = {vacation = true},
	func = function(name)
		if setvacation.go(name) then
			return true, "Teleported to vacation!"
		end
		return false, "Set a vacation using /setvacation"
	end,
})

minetest.register_chatcommand("setvacation", {
	description = "Set your vacation point",
	privs = {vacation = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and setvacation.set(name, player:getpos()) then
			return true, "vacation set!"
		end
		return false, "Player not found!"
	end,
})
