
setwork = {}

local works_file = minetest.get_worldpath() .. "/works"
local workpos = {}

local function loadworks()
	local input = io.open(works_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		workpos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadworks()

setwork.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	player:set_attribute("setwork:work", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	local data = {}
	local output = io.open(works_file, "w")
	if output then
		workpos[name] = nil
		for i, v in pairs(workpos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

setwork.get = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = minetest.string_to_pos(player:get_attribute("setwork:work"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = workpos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

setwork.go = function(name)
	local pos = setwork.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("work", {
	description = "Can use /setwork and /work",
	give_to_singleplayer = false
})

minetest.register_chatcommand("work", {
	description = "Teleport you to your work point",
	privs = {work = true},
	func = function(name)
		if setwork.go(name) then
			return true, "Teleported to work!"
		end
		return false, "Set a work using /setwork"
	end,
})

minetest.register_chatcommand("setwork", {
	description = "Set your work point",
	privs = {work = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and setwork.set(name, player:getpos()) then
			return true, "work set!"
		end
		return false, "Player not found!"
	end,
})
