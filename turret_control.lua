local comp = require("component")
local term = require("term")
local serial = require("serialization")
local event = require("event")
local trusted = nil

local function loadTrusted()
    local file = io.open("/trusted.lua", "r")
    local output = ""
    while(true) do
        local out = file:read(1)
        if out then
            output = output .. out
        else
            break
        end
    end
    trusted = serial.unserialize(output)
end

local function saveTrusted()
    local file = io.open("/trusted.lua", "w")
	file:write(serial.serialize(trusted))
	file:close(file)

    loadTrusted()
end

local function printOptions()
    term.write("Options:\n")
    term.write("+: Add a Player\n")
    term.write("-: Remove a Player\n")
end

local function printTrusted()
    term.write("Trusted Players:\n")
    for _, player in pairs(trusted) do
        term.write("  " .. player .. "\n")
    end
end

local function addToTurrets(player)
    for address, _ in pairs(comp.list("Turret")) do
        local turret = comp.proxy(address)
        if not(turret.getOwner() == player) then
            turret.addTrustedPlayer(player)
        end
    end
end

local function removeFromTurrets(player)
    for address, _ in pairs(comp.list("Turret")) do
        comp.proxy(address).removeTrustedPlayer(player)
    end
end

local function handleAddition()
    term.clear()
    term.write("Player to Add: ")
    local player = string.gsub(term.read(), "\n", "")

    local alreadyTrusted = false
    for _, p in pairs(trusted) do
        if p == player then
            alreadyTrusted = true
            break
        end
    end

    if not(alreadyTrusted) then
        trusted[#trusted + 1] = player
    end

    addToTurrets(player)

    saveTrusted()
end

local function handleRemoval()
    term.clear()
    term.write("Player to Remove: ")
    local player = string.gsub(term.read(), "\n", "")

    local new = {}
    for _, p in pairs(trusted) do
        if not(p == player) then
            new[#new + 1] = p
        end
    end
    trusted = new

    removeFromTurrets(player)

    saveTrusted()
end

local function filter(name, ...)
    local _, ascii, _ = ...
    return name == "key_down" and (ascii == 43 or ascii == 45)
end

local function main()
    if not(trusted) then
        loadTrusted()
    end

    for _, player in pairs(trusted) do
        addToTurrets(player)
    end

    term.clear()
    printTrusted()
    term.write("\n")
    printOptions()

    local e = {event.pullFiltered(nil, filter)}
    if e[3] == 43 then
        handleAddition(name)
    else
        handleRemoval(name)
    end

    main()
end

main()