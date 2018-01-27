
setbowl = {}

local bowls_file = minetest.get_worldpath() .. "/bowls"
local bowlpos = {}

local function loadbowls()
	local input = io.open(bowls_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		bowlpos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadbowls()

setbowl.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	player:set_attribute("setbowl:bowl", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	local data = {}
	local output = io.open(bowls_file, "w")
	if output then
		bowlpos[name] = nil
		for i, v in pairs(bowlpos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

setbowl.get = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = minetest.string_to_pos(player:get_attribute("setbowl:bowl"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = bowlpos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

setbowl.go = function(name)
	local pos = setbowl.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("bowl", {
	description = "Can use /setbowl and /bowl",
	give_to_singleplayer = false
})

minetest.register_chatcommand("bowl", {
	description = "Teleport you to your bowl point",
	privs = {bowl = true},
	func = function(name)
		if setbowl.go(name) then
			return true, "Teleported to bowl!"
		end
		return false, "Set a bowl using /setbowl"
	end,
})

minetest.register_chatcommand("setbowl", {
	description = "Set your bowl point",
	privs = {bowl = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and setbowl.set(name, player:getpos()) then
			return true, "bowl set!"
		end
		return false, "Player not found!"
	end,
})
