-- MoneyManager.luau (ModuleScript)
-- Persistent $ Money balance, DataStore save/load with Studio API fallback

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MoneyDataStore = nil
pcall(function()
    MoneyDataStore = DataStoreService:GetDataStore("CultMoneyStore_v1")
end)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MoneyUpdatedEvent = RemoteEvents:WaitForChild("MoneyUpdated")

local playerMoney = {}
local playerLastSavedTime = {}

local MoneyManager = {}

function MoneyManager.GetMoney(player)
    return playerMoney[player] or 0
end

function MoneyManager.SetMoney(player, amount)
    playerMoney[player] = math.max(0, amount)
    MoneyUpdatedEvent:FireClient(player, playerMoney[player])
end

function MoneyManager.AddMoney(player, amount)
    if amount <= 0 then return end
    playerMoney[player] = (playerMoney[player] or 0) + amount
    MoneyUpdatedEvent:FireClient(player, playerMoney[player])
end

function MoneyManager.DeductMoney(player, amount)
    if amount <= 0 then return true end
    local current = playerMoney[player] or 0
    if current >= amount then
        playerMoney[player] = current - amount
        MoneyUpdatedEvent:FireClient(player, playerMoney[player])
        return true
    end
    return false
end

local function savePlayerData(player)
    if not playerMoney[player] or not MoneyDataStore then return end
    local dataToSave = {
        Money = playerMoney[player],
        LastSavedTimestamp = os.time()
    }
    pcall(function()
        MoneyDataStore:SetAsync("Player_" .. player.UserId, dataToSave)
    end)
end

local function loadPlayerData(player)
    local startingMoney = 0
    local offlineEarnings = 0

    if MoneyDataStore then
        local success, data = pcall(function()
            return MoneyDataStore:GetAsync("Player_" .. player.UserId)
        end)

        if success and data and type(data) == "table" then
            startingMoney = data.Money or 0
            local lastSaved = data.LastSavedTimestamp or os.time()
            local timeElapsed = math.max(0, os.time() - lastSaved)

            if timeElapsed > 5 then
                offlineEarnings = math.floor(timeElapsed * 0.25 * 1.0)
            end
        end
    end

    playerMoney[player] = startingMoney + offlineEarnings
    playerLastSavedTime[player] = os.time()

    MoneyUpdatedEvent:FireClient(player, playerMoney[player])

    if offlineEarnings > 0 then
        print("[MoneyManager] Welcome back " .. player.Name .. "! You earned $" .. tostring(offlineEarnings) .. " while offline (0.25x rate).")
    end
end

Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerMoney[player] = nil
    playerLastSavedTime[player] = nil
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
end)

task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayerData(player)
        end
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function() loadPlayerData(player) end)
end

return MoneyManager
