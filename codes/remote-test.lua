function netBootReset()
    print("Net-Boot Restart Cleanup!")
end

local counter = 0
while true do
    event.pull(1)
    counter = counter + 1
    print("Counter:", counter)
    if counter > 10 then
        error("moop")
    end
end