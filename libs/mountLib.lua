function mountOS(uuid, label)
	local fs = filesystem

	if fs.initFileSystem("/dev") == false then
    	computer.panic("Cannot initialize /dev")
	end

	print("Mounting OS")
	if fs.mount("/dev" .. uuid, "/") == false then
		error("Couldn't mount root fs")
	end
	local file = fs.open("/_type_", "w")
	file:write("OS")
	file:close()
	local file = fs.open("/_label_", "w")
	file:write(label)
	file:close()

	fs.createDir("/mnt")
end

function formatAndMount(type, label, mountpoint)
	local fs = filesystem
	local identified = ""
	local duplicate = false
	print("Searching for drive '" .. type .. " : " .. label .. "'")
	for _, drive in ipairs(fs.children("/dev")) do
    	print("--- Checking drive : " .. drive)
   		local dtype = ""
   		local dlabel = ""
   		fs.createDir("/mnt/" .. drive)
		fs.mount("/dev/" .. drive, "/mnt/" .. drive)
		if fs.isFile("/mnt/" .. drive .. "/_type_") then
			local file = fs.open("/mnt/" .. drive .. "/_type_", "r")
			dtype = file:read(65535)
			file:close()
		end
		if fs.isFile("/mnt/" .. drive .. "/_label_") then
			local file = fs.open("/mnt/" .. drive .. "/_label_", "r")
			dlabel = file:read(65535)
			file:close()
		end
		fs.unmount("/mnt/" .. drive)
		fs.remove("/mnt/" .. drive)
		if dtype == type and dlabel == label then
			if identified == "" then
				identified = drive
			else
				print("Error: Too many drives of type '" .. type .. "' and label '" .. label .. "' found")
				duplicate = true
			end
		end
	end
	if duplicate then
		error("See error(s) above")
	end
	if identified == "" then
		print("Drive not found, searching for spare")
		for _, drive in ipairs(fs.children("/dev")) do
   			print("--- Checking drive : " .. drive)
   			fs.createDir("/mnt/" .. drive)
			fs.mount("/dev/" .. drive, "/mnt/" .. drive)
			if fs.isFile("/mnt/" .. drive .. "/_type_") == false and fs.isFile("/mnt/" .. drive .. "/_label_") == false then
				identified = drive
			end
			fs.unmount("/mnt/" .. drive)
			fs.remove("/mnt/" .. drive)
			if identified ~= "" then
				break
			end
		end
	end
	if identified == "" then
		error("Failed to identify a suitable drive")
	else
		print("Compatible drive identified: " .. identified)
	end
	fs.createDir(mountpoint, true)
	if fs.mount("/dev/" .. identified, mountpoint) == false then
		error("Couldn't mount drive")
	end
	local file = fs.open(mountpoint .. "/_type_", "w")
	file:write(type)
	file:close()
	local file = fs.open(mountpoint .. "/_label_", "w")
	file:write(label)
	file:close()
end
