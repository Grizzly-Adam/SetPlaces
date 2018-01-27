
setjobsite = {}

local jobsites_file = minetest.get_worldpath() .. "/jobsites"
local jobsitepos = {}

local function loadjobsites()
	local input = io.open(jobsites_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		jobsitepos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadjobsites()

setjobsite.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	player:set_attribute("setjobsite:jobsite", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	local data = {}
	local output = io.open(jobsites_file, "w")
	if output then
		jobsitepos[name] = nil
		for i, v in pairs(jobsitepos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

setjobsite.get = function(name)
	local player = minetest.get_player_by_name(name)
	local pos = minetest.string_to_pos(player:get_attribute("setjobsite:jobsite"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = jobsitepos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

setjobsite.go = function(name)
	local pos = setjobsite.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("jobsite", {
	description = "Can use /setjobsite and /jobsite",
	give_to_singleplayer = false
})

minetest.register_chatcommand("jobsite", {
	description = "Teleport you to your jobsite point",
	privs = {jobsite = true},
	func = function(name)
		if setjobsite.go(name) then
			return true, "Teleported to jobsite!"
		end
		return false, "Set a jobsite using /setjobsite"
	end,
})

minetest.register_chatcommand("setjobsite", {
	description = "Set your jobsite point",
	privs = {jobsite = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and setjobsite.set(name, player:getpos()) then
			return true, "jobsite set!"
		end
		return false, "Player not found!"
	end,
})
