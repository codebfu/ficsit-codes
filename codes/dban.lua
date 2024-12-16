fs = filesystem

if fs.initFileSystem("/dev") == false then
    computer.panic("Cannot initialize /dev")
end

fs.createDir("/mnt")
for _, drive in ipairs(fs.children("/dev")) do
    print("Mounting drive : " .. drive)
    fs.createDir("/mnt/" .. drive)
	fs.mount("/dev/" .. drive, "/mnt/" .. drive)
end

for _, drive in ipairs(fs.children("/dev")) do
    print("Erasing drive : " .. drive)
    for _, entry in ipairs(fs.children("/mnt/" .. drive)) do
        if fs.isFile("/mnt/" .. drive .. "/" .. entry) then
            fs.remove("/mnt/" .. drive .. "/" .. entry)
        end
        if fs.isDir("/mnt/" .. drive .. "/" .. entry) then
            fs.remove("/mnt/" .. drive .. "/" .. entry, true)
        end
    end
end
print("done")