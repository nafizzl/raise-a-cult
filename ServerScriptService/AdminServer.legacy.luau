--!strict
-- AdminServer.legacy.luau
-- Authoritative, secure developer console and chat command processor for testing & live operations.
-- Server-side verified permissions with whitelist protection, suffix parsing, and Tycoon management.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MoneyManager = require(ServerScriptService:WaitForChild("MoneyManager") :: any)
local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyConfig") :: any)
local EconomyMath = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyMath") :: any)

-- Ensure RemoteFunction exists in ReplicatedStorage.RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local AdminFunction = RemoteEvents:FindFirstChild("AdminFunction") :: RemoteFunction?
if not AdminFunction then
    AdminFunction = Instance.new("RemoteFunction")
    AdminFunction.Name = "AdminFunction"
    AdminFunction.Parent = RemoteEvents
end

-- Whitelist Configuration (Place Owner + Approved UserIds)
local ALLOWED_USER_IDS: { [number]: boolean } = {
    [51437187] = true, -- Place Owner
}

local function isPlayerAuthorized(player: Player): boolean
    if RunService:IsStudio() then
        return true -- Always allow in Studio local playtest
    end
    if player.UserId == game.CreatorId or ALLOWED_USER_IDS[player.UserId] == true then
        return true
    end
    return false
end

-- Parse numerical inputs with short-scale suffixes (e.g. 10k -> 10,000, 5M -> 5,000,000, 2.5B -> 2.5e9)
local function parseAmount(arg: string): number?
    if not arg then return nil end
    local clean = arg:gsub("[$,]", ""):lower()

    local suffixes: { [string]: number } = {
        ["k"] = 1e3,
        ["m"] = 1e6,
        ["b"] = 1e9,
        ["t"] = 1e12,
        ["qa"] = 1e15,
        ["qi"] = 1e18,
        ["sx"] = 1e21,
        ["sp"] = 1e24,
        ["oc"] = 1e27,
        ["no"] = 1e30,
        ["dc"] = 1e33,
        ["vg"] = 1e63,
        ["tg"] = 1e93,
        ["qd"] = 1e123,
        ["sg"] = 1e183,
        ["ns"] = 1e210,
        ["ce"] = 1e303,
    }

    for suffix, multiplier in pairs(suffixes) do
        if clean:sub(-#suffix) == suffix then
            local numPart = tonumber(clean:sub(1, -#suffix - 1))
            if numPart then
                return numPart * multiplier
            end
        end
    end

    return tonumber(clean)
end

-- Core Authoritative Command Processor
local function processAdminCommand(player: Player, rawCommand: string): (boolean, string)
    if not isPlayerAuthorized(player) then
        warn(string.format("[SECURITY ALERT] Unauthorized admin attempt by %s (UserId: %d)", player.Name, player.UserId))
        return false, "Permission Denied: You are not authorized to use developer commands."
    end

    local trimmed = rawCommand:gsub("^%s*(.-)%s*$", "%1")
    if trimmed:sub(1, 1) == ":" or trimmed:sub(1, 1) == "/" then
        trimmed = trimmed:sub(2)
    end

    local tokens = {}
    for word in trimmed:gmatch("%S+") do
        table.insert(tokens, word)
    end

    local cmd = (tokens[1] or ""):lower()
    local arg1 = tokens[2]

    if cmd == "give" or cmd == "givemoney" or cmd == "addmoney" or cmd == "cash" then
        local amount = parseAmount(arg1) or 1000000
        MoneyManager.AddMoney(player, amount)
        return true, string.format("Added %s. New Balance: %s", EconomyMath.FormatCurrency(amount), EconomyMath.FormatCurrency(MoneyManager.GetMoney(player)))

    elseif cmd == "set" or cmd == "setmoney" then
        local amount = parseAmount(arg1) or 0
        local current = MoneyManager.GetMoney(player)
        if amount > current then
            MoneyManager.AddMoney(player, amount - current)
        elseif amount < current then
            MoneyManager.DeductMoney(player, current - amount)
        end
        return true, string.format("Set balance to %s", EconomyMath.FormatCurrency(amount))

    elseif cmd == "reset" or cmd == "resetmoney" or cmd == "clearmoney" then
        local current = MoneyManager.GetMoney(player)
        MoneyManager.DeductMoney(player, current)
        return true, "Balance reset to $0."

    elseif cmd == "unlockmanager" or cmd == "givemanager" then
        local bId = tonumber(arg1) or 1
        MoneyManager.SetManagerOwned(player, bId, true)
        return true, string.format("Manager unlocked for Building %d.", bId)

    elseif cmd == "unlockall" then
        MoneyManager.AddMoney(player, 1e12)
        MoneyManager.UnlockFloorUpgrade(player, 1, 1)
        MoneyManager.UnlockFloorUpgrade(player, 1, 2)
        MoneyManager.SetManagerOwned(player, 1, true)
        return true, "Unlocked all early upgrades and granted $1 Trillion."

    elseif cmd == "help" or cmd == "cmds" then
        return true, "Commands: :give <amount>, :set <amount>, :reset, :unlockmanager <id>, :unlockall"

    else
        return false, string.format("Unknown command '%s'. Type :help for commands list.", cmd)
    end
end

-- Wire RemoteFunction for UI Dev Console
AdminFunction.OnServerInvoke = function(player: Player, rawCommand: any)
    if typeof(rawCommand) ~= "string" then
        return false, "Invalid command format."
    end
    return processAdminCommand(player, rawCommand)
end

-- Wire In-Game Chat Listener (:give 1M or /give 1M in chat)
Players.PlayerAdded:Connect(function(player: Player)
    player.Chatted:Connect(function(message: string)
        if message:sub(1, 1) == ":" or message:sub(1, 6) == "/give " or message:sub(1, 5) == "/set " or message:sub(1, 7) == "/reset" then
            local success, reply = processAdminCommand(player, message)
            if isPlayerAuthorized(player) then
                print(string.format("[Admin] %s: %s", player.Name, reply))
            end
        end
    end)
end)

print("[AdminServer] Secure developer command processor active.")
