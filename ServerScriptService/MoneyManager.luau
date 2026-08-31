--!strict
-- MoneyManager.luau (ModuleScript)
-- Persistent player Cash and Tycoon progression DataStore saving with Studio fallback & offline earnings.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyFolder = ReplicatedStorage:WaitForChild("Economy")
local EconomyConfig = require(ReplicatedStorage.Economy.EconomyConfig)
local EconomyMath = require(ReplicatedStorage.Economy.EconomyMath)

local MoneyDataStore: any = nil
pcall(function()
    MoneyDataStore = DataStoreService:GetDataStore("CultTycoonStore_v2")
end)

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
    RemoteEvents = Instance.new("Folder")
    RemoteEvents.Name = "RemoteEvents"
    RemoteEvents.Parent = ReplicatedStorage
end

local MoneyUpdatedEvent = RemoteEvents:FindFirstChild("MoneyUpdated")
if not MoneyUpdatedEvent then
    MoneyUpdatedEvent = Instance.new("RemoteEvent")
    MoneyUpdatedEvent.Name = "MoneyUpdated"
    MoneyUpdatedEvent.Parent = RemoteEvents
end
local moneyUpdatedRemote = MoneyUpdatedEvent :: RemoteEvent

local function fireMoneyUpdated(player: Player, amount: number)
    if player and player:IsDescendantOf(Players) then
        moneyUpdatedRemote:FireClient(player, amount)
    end
end

export type BuildingState = {
    OwnedCount: number,
    FloorUpgrades: { [number]: boolean },
    PurchasedUpgrades: { [string]: boolean },
    HasManager: boolean,
}

export type PlayerTycoonData = {
    Cash: number,
    LastSavedTimestamp: number,
    Buildings: { [number]: BuildingState }
}

local playerData: { [Player]: PlayerTycoonData } = {}

local MoneyManager = {}

local function getDefaultBuildingState(buildingId: number): BuildingState
    return {
        OwnedCount = 0,
        FloorUpgrades = {},
        PurchasedUpgrades = {},
        HasManager = false,
    }
end

local function getDefaultPlayerData(): PlayerTycoonData
    local buildings: { [number]: BuildingState } = {}
    for id = 1, 10 do
        buildings[id] = getDefaultBuildingState(id)
    end
    return {
        Cash = 0,
        LastSavedTimestamp = os.time(),
        Buildings = buildings
    }
end

function MoneyManager.GetPlayerData(player: Player): PlayerTycoonData
    if not playerData[player] then
        playerData[player] = getDefaultPlayerData()
    end
    return playerData[player]
end

function MoneyManager.GetMoney(player: Player): number
    local data = MoneyManager.GetPlayerData(player)
    return data.Cash or 0
end

function MoneyManager.SetMoney(player: Player, amount: number)
    local data = MoneyManager.GetPlayerData(player)
    data.Cash = math.max(0, amount)
    fireMoneyUpdated(player, data.Cash)
end

function MoneyManager.AddMoney(player: Player, amount: number)
    if amount <= 0 then return end
    local data = MoneyManager.GetPlayerData(player)
    data.Cash = (data.Cash or 0) + amount
    fireMoneyUpdated(player, data.Cash)
end

function MoneyManager.DeductMoney(player: Player, amount: number): boolean
    if amount <= 0 then return true end
    local data = MoneyManager.GetPlayerData(player)
    local current = data.Cash or 0
    if current >= amount then
        data.Cash = current - amount
        fireMoneyUpdated(player, data.Cash)
        return true
    end
    return false
end

function MoneyManager.GetBuildingState(player: Player, buildingId: number): BuildingState
    local pData = MoneyManager.GetPlayerData(player)
    if not pData.Buildings[buildingId] then
        pData.Buildings[buildingId] = getDefaultBuildingState(buildingId)
    end
    return pData.Buildings[buildingId]
end

function MoneyManager.UnlockFloorUpgrade(player: Player, buildingId: number, tier: number)
    local bState = MoneyManager.GetBuildingState(player, buildingId)
    bState.FloorUpgrades[tier] = true
end

function MoneyManager.SetUpgradePurchased(player: Player, buildingId: number, upgradeName: string, purchased: boolean)
    local bState = MoneyManager.GetBuildingState(player, buildingId)
    bState.PurchasedUpgrades[upgradeName] = (purchased ~= false)
end

function MoneyManager.IsUpgradePurchased(player: Player, buildingId: number, upgradeName: string): boolean
    local bState = MoneyManager.GetBuildingState(player, buildingId)
    return bState.PurchasedUpgrades[upgradeName] == true
end

function MoneyManager.SetManagerOwned(player: Player, buildingId: number, owned: boolean)
    local bState = MoneyManager.GetBuildingState(player, buildingId)
    bState.HasManager = owned
end

local function calculateAutomatedIncomePerSecond(pData: PlayerTycoonData): number
    local totalIncomePerSec = 0
    local buildings = EconomyConfig.Buildings or {}
    for id, bDef in pairs(buildings) do
        local bState = pData.Buildings[id]
        if bState and bState.HasManager and bState.OwnedCount > 0 then
            local mOutput, mSpeed = EconomyMath.GetMilestoneMultipliers(bState.OwnedCount)
            local floorSpeed = EconomyMath.GetFloorSpeedMultiplier(id, bState.FloorUpgrades)
            local effectiveCycle = EconomyMath.CalculateEffectiveCycleTime(bDef.BaseCycleTime, floorSpeed, mSpeed)
            local incomePerCycle = EconomyMath.CalculateIncomePerCycle(bState.OwnedCount, bDef.BaseProd, mOutput)
            totalIncomePerSec = totalIncomePerSec + (incomePerCycle / effectiveCycle)
        end
    end
    return totalIncomePerSec
end

local function savePlayerData(player: Player)
    local data = playerData[player]
    if not data or not MoneyDataStore then return end

    data.LastSavedTimestamp = os.time()
    pcall(function()
        MoneyDataStore:SetAsync("Player_" .. player.UserId, data)
    end)
end

local function loadPlayerData(player: Player)
    local loadedData: any = nil

    if MoneyDataStore then
        local success, raw = pcall(function()
            return MoneyDataStore:GetAsync("Player_" .. player.UserId)
        end)
        if success and raw and type(raw) == "table" then
            loadedData = raw
        end
    end

    local finalData = getDefaultPlayerData()
    if loadedData then
        finalData.Cash = tonumber(loadedData.Cash) or 0
        finalData.LastSavedTimestamp = tonumber(loadedData.LastSavedTimestamp) or os.time()
        if loadedData.Buildings and type(loadedData.Buildings) == "table" then
            for id, bState in pairs(loadedData.Buildings) do
                local numId = tonumber(id) or id
                if type(bState) == "table" then
                    finalData.Buildings[numId] = {
                        OwnedCount = tonumber(bState.OwnedCount) or 0,
                        FloorUpgrades = (type(bState.FloorUpgrades) == "table") and bState.FloorUpgrades or {},
                        PurchasedUpgrades = (type(bState.PurchasedUpgrades) == "table") and bState.PurchasedUpgrades or {},
                        HasManager = (bState.HasManager == true)
                    }
                end
            end
        end
    end

    -- Calculate offline earnings (0.25x rate from automated managers)
    local timeElapsed = math.max(0, os.time() - (finalData.LastSavedTimestamp or os.time()))
    local offlineEarnings = 0
    if timeElapsed > 5 then
        local incomePerSec = calculateAutomatedIncomePerSecond(finalData)
        if incomePerSec > 0 then
            offlineEarnings = math.floor(timeElapsed * 0.25 * incomePerSec)
            finalData.Cash = finalData.Cash + offlineEarnings
        end
    end

    finalData.LastSavedTimestamp = os.time()
    playerData[player] = finalData

    fireMoneyUpdated(player, finalData.Cash)

    if offlineEarnings > 0 then
        print(string.format("[MoneyManager] Welcome back %s! You earned %s while offline (0.25x rate over %ds).",
            player.Name, EconomyMath.FormatCurrency(offlineEarnings), timeElapsed))
    end
end

Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(function(player: Player)
    savePlayerData(player)
    playerData[player] = nil
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayerData(player)
    end
end)

-- Autosave loop every 60s
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
