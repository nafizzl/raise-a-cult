-- ProductionEngine.luau
-- Universal production loop, cycle management, batch upgrades, and manager automation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyConfig") :: any)
local EconomyMath = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyMath") :: any)
local MoneyManager = require(ServerScriptService:WaitForChild("MoneyManager") :: any)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectEvent = RemoteEvents:WaitForChild("CollectEvent") :: RemoteEvent
local UpgradeEvent = RemoteEvents:WaitForChild("UpgradeEvent") :: RemoteEvent

type ActiveCycleState = {
    IsCycling: boolean,
    CycleStartTime: number,
    CurrentCycleTime: number,
    LastFastPayout: number,
}

local playerCycles: { [Player]: { [number]: ActiveCycleState } } = {}

local function getCycleState(player: Player, buildingId: number): ActiveCycleState
    if not playerCycles[player] then
        playerCycles[player] = {}
    end
    if not playerCycles[player][buildingId] then
        playerCycles[player][buildingId] = {
            IsCycling = false,
            CycleStartTime = 0,
            CurrentCycleTime = 1.0,
            LastFastPayout = 0,
        }
    end
    return playerCycles[player][buildingId]
end

local function getBuildingStats(player: Player, buildingId: number)
    local bDef = EconomyConfig.Buildings[buildingId]
    if not bDef then return nil end

    local bState = MoneyManager.GetBuildingState(player, buildingId)
    local owned = bState.OwnedCount or 0
    local mOutput, mSpeed = EconomyMath.GetMilestoneMultipliers(owned)
    local floorSpeed = EconomyMath.GetFloorSpeedMultiplier(buildingId, bState.FloorUpgrades)
    local effectiveCycleTime = EconomyMath.CalculateEffectiveCycleTime(bDef.BaseCycleTime, floorSpeed, mSpeed)
    local incomePerCycle = EconomyMath.CalculateIncomePerCycle(owned, bDef.BaseProd, mOutput)
    local nextCost = EconomyMath.GetSingleCost(bDef.BaseCost, bDef.GrowthRate, owned + 1)

    return {
        Def = bDef,
        State = bState,
        Owned = owned,
        EffectiveCycleTime = effectiveCycleTime,
        IncomePerCycle = incomePerCycle,
        NextCost = nextCost,
    }
end

-- Handle Manual Player Tap/Collect Event
CollectEvent.OnServerEvent:Connect(function(player: Player, buildingIdArg: any)
    local buildingId = tonumber(buildingIdArg) or 1
    local stats = getBuildingStats(player, buildingId)
    if not stats or stats.Owned <= 0 then return end

    local cycle = getCycleState(player, buildingId)
    if stats.State.HasManager or cycle.IsCycling then return end

    cycle.IsCycling = true
    cycle.CycleStartTime = os.clock()
    cycle.CurrentCycleTime = stats.EffectiveCycleTime

    if player:IsDescendantOf(Players) then
        CollectEvent:FireClient(player, "StartCycle", buildingId, stats.EffectiveCycleTime)
    end

    task.delay(stats.EffectiveCycleTime, function()
        cycle.IsCycling = false
        if player:IsDescendantOf(Players) then
            local updatedStats = getBuildingStats(player, buildingId)
            if updatedStats and updatedStats.Owned > 0 then
                MoneyManager.AddMoney(player, updatedStats.IncomePerCycle)
                CollectEvent:FireClient(player, "CycleComplete", buildingId)
            end
        end
    end)
end)

-- Handle Player Upgrade Purchase Event (Buy 1 or Batch)
UpgradeEvent.OnServerEvent:Connect(function(player: Player, buildingIdArg: any, amountArg: any)
    local buildingId = tonumber(buildingIdArg) or 1
    local amount = tonumber(amountArg) or 1
    if amount <= 0 then amount = 1 end

    local stats = getBuildingStats(player, buildingId)
    if not stats then return end

    local bDef = stats.Def
    local currentLevel = stats.Owned
    local batchCost = EconomyMath.GetBatchCost(bDef.BaseCost, bDef.GrowthRate, currentLevel + 1, amount)

    if MoneyManager.DeductMoney(player, batchCost) then
        stats.State.OwnedCount = currentLevel + amount

        local updatedStats = getBuildingStats(player, buildingId)
        if updatedStats and player:IsDescendantOf(Players) then
            UpgradeEvent:FireClient(
                player,
                "UpgradeSuccess",
                buildingId,
                updatedStats.Owned,
                updatedStats.NextCost,
                updatedStats.IncomePerCycle,
                updatedStats.EffectiveCycleTime
            )
            print(string.format("[ProductionEngine] %s upgraded Building %d to Level %d (Cost: %s)",
                player.Name, buildingId, updatedStats.Owned, EconomyMath.FormatCurrency(batchCost)))
        end
    end
end)

-- Server loop handling manager automation & fast-bar payouts
task.spawn(function()
    while true do
        task.wait(0.05) -- 20 Hz tick
        local now = os.clock()

        for _, player in ipairs(Players:GetPlayers()) do
            local pData = MoneyManager.GetPlayerData(player)
            if pData and pData.Buildings then
                for buildingId, bDef in pairs(EconomyConfig.Buildings) do
                    local bState = pData.Buildings[buildingId]
                    if bState and bState.HasManager and bState.OwnedCount > 0 then
                        local mOutput, mSpeed = EconomyMath.GetMilestoneMultipliers(bState.OwnedCount)
                        local floorSpeed = EconomyMath.GetFloorSpeedMultiplier(buildingId, bState.FloorUpgrades)
                        local effectiveCycle = EconomyMath.CalculateEffectiveCycleTime(bDef.BaseCycleTime, floorSpeed, mSpeed)
                        local incomePerCycle = EconomyMath.CalculateIncomePerCycle(bState.OwnedCount, bDef.BaseProd, mOutput)
                        local cycle = getCycleState(player, buildingId)

                        if effectiveCycle <= 0.1 then
                            -- Fast-bar streaming: stream smooth income per second continuously
                            if cycle.LastFastPayout == 0 then
                                cycle.LastFastPayout = now
                            else
                                local dt = now - cycle.LastFastPayout
                                if dt >= 0.05 then
                                    cycle.LastFastPayout = now
                                    local streamIncome = (incomePerCycle / effectiveCycle) * dt
                                    if streamIncome >= 1 then
                                        MoneyManager.AddMoney(player, math.floor(streamIncome))
                                    end
                                end
                            end
                            if player:IsDescendantOf(Players) then
                                CollectEvent:FireClient(player, "FastBarActive", buildingId, effectiveCycle)
                            end
                        else
                            -- Standard cycle loop with continuous manager countdown
                            cycle.LastFastPayout = 0
                            if not cycle.IsCycling then
                                cycle.IsCycling = true
                                cycle.CycleStartTime = now
                                cycle.CurrentCycleTime = effectiveCycle

                                if player:IsDescendantOf(Players) then
                                    CollectEvent:FireClient(player, "StartCycle", buildingId, effectiveCycle, true)
                                end

                                task.spawn(function()
                                    task.wait(effectiveCycle)
                                    cycle.IsCycling = false
                                    if player:IsDescendantOf(Players) then
                                        MoneyManager.AddMoney(player, incomePerCycle)
                                        CollectEvent:FireClient(player, "CycleComplete", buildingId, true)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    playerCycles[player] = nil
end)

local engineExport = {
    GetBuildingStats = getBuildingStats,
    GetCycleState = getCycleState,
}

rawset(_G, "ProductionEngine", engineExport)

return engineExport
