
setspouse = {}

local spouses_file = minetest.get_worldpath() .. "/spouses"
local spousepos = {}

local function loadspouses()
	local input = io.open(spouses_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		spousepos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadspouses()

setspouse.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	player:set_attribute("setspouse:spouse", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	local data = {}
	local output = io.open(spouses_file, "w")
	if output then
		spousepos[name] = nil
		for i, v in pairs(spousepos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

setspouse.get = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = minetest.string_to_pos(player:get_attribute("setspouse:spouse"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = spousepos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

setspouse.go = function(name)
	local pos = setspouse.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("spouse", {
	description = "Can use /setspouse and /spouse",
	give_to_singleplayer = false
})

minetest.register_chatcommand("spouse", {
	description = "Teleport you to your spouse point",
	privs = {spouse = true},
	func = function(name)
		if setspouse.go(name) then
			return true, "Teleported to spouse!"
		end
		return false, "Set a spouse using /setspouse"
	end,
})

minetest.register_chatcommand("setspouse", {
	description = "Set your spouse point",
	privs = {spouse = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and setspouse.set(name, player:getpos()) then
			return true, "spouse set!"
		end
		return false, "Player not found!"
	end,
})
