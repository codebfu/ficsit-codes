function mountOS(uuid, type)
    print("Mounting OS")
    fs.mount("/dev" .. uuid, "/")
    fs.createDir("/type")
    local file = fs.open("/type/os", "w")
    file:write(type)
    file:close()
end