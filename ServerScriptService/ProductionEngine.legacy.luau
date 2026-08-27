-- ProductionEngine.luau
-- Manages Building 1 production loop, yield calculations, milestone multipliers, and payout

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MoneyManager = require(ServerScriptService:WaitForChild("MoneyManager"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectEvent = RemoteEvents:WaitForChild("CollectEvent")
local UpgradeEvent = RemoteEvents:WaitForChild("UpgradeEvent")
local BuyManagerEvent = RemoteEvents:WaitForChild("BuyManagerEvent")
local MoneyUpdatedEvent = RemoteEvents:WaitForChild("MoneyUpdated")

local buildingData = {}

local BASE_COST = 10
local GROWTH_RATE = 1.07
local BASE_YIELD = 1
local BASE_CYCLE_TIME = 1.0

local function getPlayerData(player)
    if not buildingData[player] then
        buildingData[player] = {
            Level = 1,
            OwnedCount = 1,
            FlyersUnlocked = false,
            MorePreachersUnlocked = false,
            HasManager = false,
            IsCycling = false,
            LastCycleStart = 0
        }
    end
    return buildingData[player]
end

local function calculateCycleTime(data)
    local speedMult = 1

    if data.FlyersUnlocked then speedMult = speedMult * 2 end
    if data.MorePreachersUnlocked then speedMult = speedMult * 2 end

    local level = data.Level
    if level >= 25 then speedMult = speedMult * 2 end
    if level >= 50 then speedMult = speedMult * 2 end
    if level >= 100 then speedMult = speedMult * 2 end
    if level >= 200 then speedMult = speedMult * 2 end
    if level >= 500 then speedMult = speedMult * 2 end

    return math.max(0.05, BASE_CYCLE_TIME / speedMult)
end

local function calculateYield(data)
    local level = data.Level
    local yieldMult = 1

    if level >= 1000 then yieldMult = yieldMult * 2 end
    if level >= 2000 then yieldMult = yieldMult * 2 end
    if level >= 3000 then yieldMult = yieldMult * 2 end
    if level >= 5000 then yieldMult = yieldMult * 4 end
    if level >= 7500 then yieldMult = yieldMult * 4 end
    if level >= 10000 then yieldMult = yieldMult * 10 end

    return level * BASE_YIELD * yieldMult
end

local function calculateNextCost(level)
    return math.floor(BASE_COST * (GROWTH_RATE ^ (level - 1)))
end

CollectEvent.OnServerEvent:Connect(function(player)
    local data = getPlayerData(player)
    if data.HasManager or data.IsCycling then return end

    local cycleTime = calculateCycleTime(data)
    data.IsCycling = true
    data.LastCycleStart = os.clock()

    CollectEvent:FireClient(player, "StartCycle", cycleTime)

    task.delay(cycleTime, function()
        data.IsCycling = false
        local yieldAmount = calculateYield(data)
        MoneyManager.AddMoney(player, yieldAmount)
        CollectEvent:FireClient(player, "CycleComplete")
    end)
end)

UpgradeEvent.OnServerEvent:Connect(function(player)
    local data = getPlayerData(player)
    local cost = calculateNextCost(data.Level)

    if MoneyManager.DeductMoney(player, cost) then
        data.Level = data.Level + 1
        data.OwnedCount = data.Level

        local nextCost = calculateNextCost(data.Level)
        local yield = calculateYield(data)
        local cycleTime = calculateCycleTime(data)

        UpgradeEvent:FireClient(player, "UpgradeSuccess", data.Level, nextCost, yield, cycleTime)
        print("[ProductionEngine] " .. player.Name .. " upgraded Building 1 to Level " .. tostring(data.Level))
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        for _, player in ipairs(Players:GetPlayers()) do
            local data = getPlayerData(player)
            if data.HasManager and not data.IsCycling then
                data.IsCycling = true
                local cycleTime = calculateCycleTime(data)

                task.spawn(function()
                    task.wait(cycleTime)
                    data.IsCycling = false
                    local yieldAmount = calculateYield(data)
                    MoneyManager.AddMoney(player, yieldAmount)
                end)
            end
        end
    end
end)

_G.ProductionEngine = {
    GetPlayerData = getPlayerData,
    CalculateCycleTime = calculateCycleTime,
    CalculateYield = calculateYield,
    CalculateNextCost = calculateNextCost
}
