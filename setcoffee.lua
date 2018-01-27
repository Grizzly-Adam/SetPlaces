
setcoffee = {}

local coffees_file = minetest.get_worldpath() .. "/coffees"
local coffeepos = {}

local function loadcoffees()
	local input = io.open(coffees_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		coffeepos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadcoffees()

setcoffee.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	player:set_attribute("setcoffee:coffee", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	local data = {}
	local output = io.open(coffees_file, "w")
	if output then
		coffeepos[name] = nil
		for i, v in pairs(coffeepos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

setcoffee.get = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = minetest.string_to_pos(player:get_attribute("setcoffee:coffee"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = coffeepos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

setcoffee.go = function(name)
	local pos = setcoffee.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("coffee", {
	description = "Can use /setcoffee and /coffee",
	give_to_singleplayer = false
})

minetest.register_chatcommand("coffee", {
	description = "Teleport you to your coffee point",
	privs = {coffee = true},
	func = function(name)
		if setcoffee.go(name) then
			return true, "Teleported to coffee!"
		end
		return false, "Set a coffee using /setcoffee"
	end,
})

minetest.register_chatcommand("setcoffee", {
	description = "Set your coffee point",
	privs = {coffee = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and setcoffee.set(name, player:getpos()) then
			return true, "coffee set!"
		end
		return false, "Player not found!"
	end,
})
