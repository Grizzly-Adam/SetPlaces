
setmine = {}

local mines_file = minetest.get_worldpath() .. "/mines"
local minepos = {}

local function loadmines()
	local input = io.open(mines_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		minepos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadmines()

setmine.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	player:set_attribute("setmine:mine", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	local data = {}
	local output = io.open(mines_file, "w")
	if output then
		minepos[name] = nil
		for i, v in pairs(minepos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

setmine.get = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = minetest.string_to_pos(player:get_attribute("setmine:mine"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = minepos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

setmine.go = function(name)
	local pos = setmine.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("mine", {
	description = "Can use /setmine and /mine",
	give_to_singleplayer = false
})

minetest.register_chatcommand("mine", {
	description = "Teleport you to your mine point",
	privs = {mine = true},
	func = function(name)
		if setmine.go(name) then
			return true, "Teleported to mine!"
		end
		return false, "Set a mine using /setmine"
	end,
})

minetest.register_chatcommand("setmine", {
	description = "Set your mine point",
	privs = {mine = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and setmine.set(name, player:getpos()) then
			return true, "mine set!"
		end
		return false, "Player not found!"
	end,
})
