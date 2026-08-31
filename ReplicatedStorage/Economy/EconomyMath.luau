--!strict
-- EconomyMath.luau
-- Mathematical calculation engine and currency formatting for Raise a Cult.

local EconomyConfig = require(script.Parent.EconomyConfig :: any)

local EconomyMath = {}

-- 100-Tier Continuous Short-Scale Suffixes (10^3 to 10^303 - Centillion)
local SUFFIXES = {
    "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", -- 10^3 .. 10^33
    "UnDc", "DuDc", "TrDc", "QaDc", "QiDc", "SxDc", "SpDc", "OcDc", "NoDc", "Vg", -- 10^36 .. 10^63
    "UnVg", "DuVg", "TrVg", "QaVg", "QiVg", "SxVg", "SpVg", "OcVg", "NoVg", "Tg", -- 10^66 .. 10^93
    "UnTg", "DuTg", "TrTg", "QaTg", "QiTg", "SxTg", "SpTg", "OcTg", "NoTg", "Qd", -- 10^96 .. 10^123
    "UnQd", "DuQd", "TrQd", "QaQd", "QiQd", "SxQd", "SpQd", "OcQd", "NoQd", "Qn", -- 10^126 .. 10^153
    "UnQn", "DuQn", "TrQn", "QaQn", "QiQn", "SxQn", "SpQn", "OcQn", "NoQn", "SxG", -- 10^156 .. 10^183
    "UnSxG", "DuSxG", "TrSxG", "QaSxG", "QiSxG", "SxSxG", "SpSxG", "OcSxG", "NoSxG", "SpG", -- 10^186 .. 10^213
    "UnSpG", "DuSpG", "TrSpG", "QaSpG", "QiSpG", "SxSpG", "SpSpG", "OcSpG", "NoSpG", "Og", -- 10^216 .. 10^243
    "UnOg", "DuOg", "TrOg", "QaOg", "QiOg", "SxOg", "SpOg", "OcOg", "NoOg", "Nn", -- 10^246 .. 10^273
    "UnNn", "DuNn", "TrNn", "QaNn", "QiNn", "SxNn", "SpNn", "OcNn", "NoNn", "Ce"  -- 10^276 .. 10^303
}

-- Calculate cost of a single unit at currentLevel (1-indexed owned units)
-- Cost(n) = BaseCost * (GrowthRate ^ (level - 1))
function EconomyMath.GetSingleCost(baseCost: number, r: number, currentLevel: number): number
    if currentLevel <= 1 then
        return baseCost
    end
    return math.floor(baseCost * (r ^ (currentLevel - 1)))
end

-- Calculate exact geometric series batch cost for buying 'amount' units starting from 'currentLevel'
-- BatchCost = BaseCost * r^(currentLevel-1) * (r^amount - 1) / (r - 1)
function EconomyMath.GetBatchCost(baseCost: number, r: number, currentLevel: number, amount: number): number
    if amount <= 0 then return 0 end
    if amount == 1 then return EconomyMath.GetSingleCost(baseCost, r, currentLevel) end

    local n = math.max(0, currentLevel - 1)
    local rOwned = r ^ n
    local rAmount = r ^ amount
    local cost = baseCost * rOwned * ((rAmount - 1) / (r - 1))
    return math.floor(cost)
end

-- Calculate Buy Max: Maximum units affordable with current balance
-- m = floor( ln( 1 + (C * (r - 1)) / (BaseCost * r^n) ) / ln(r) )
function EconomyMath.CalculateMaxAffordable(baseCost: number, r: number, currentLevel: number, balance: number): (number, number)
    if balance < EconomyMath.GetSingleCost(baseCost, r, currentLevel) then
        return 0, 0
    end

    local n = math.max(0, currentLevel - 1)
    local rOwned = r ^ n
    local denom = baseCost * rOwned
    local inner = 1 + (balance * (r - 1)) / denom

    if inner <= 1 then return 0, 0 end

    local maxCount = math.floor(math.log(inner) / math.log(r))
    if maxCount <= 0 then return 0, 0 end

    local exactCost = EconomyMath.GetBatchCost(baseCost, r, currentLevel, maxCount)
    -- Safety check in case of float rounding overspending
    while exactCost > balance and maxCount > 0 do
        maxCount = maxCount - 1
        exactCost = EconomyMath.GetBatchCost(baseCost, r, currentLevel, maxCount)
    end

    return maxCount, exactCost
end

-- Get milestone output multiplier and speed divisor for a given owned count
function EconomyMath.GetMilestoneMultipliers(ownedCount: number): (number, number)
    local outputMult = 1
    local speedDivisor = 1

    local milestones = EconomyConfig.Milestones or {}
    for _, milestone in ipairs(milestones) do
        if ownedCount >= milestone.Threshold then
            outputMult = outputMult * milestone.OutputMult
            speedDivisor = speedDivisor * milestone.SpeedMult
        else
            break
        end
    end

    -- Algorithmic extension beyond defined table (> 1,000,000)
    if ownedCount > 1000000 then
        local extraMillionSteps = math.floor((ownedCount - 1000000) / 1000000)
        if extraMillionSteps > 0 then
            outputMult = outputMult * (2 ^ (extraMillionSteps * 2))
        end
    end

    return outputMult, speedDivisor
end

-- Get cumulative speed multiplier from purchased floor upgrades (Tiers 1..8)
-- Tiers 1-7: 2x speed each; Tier 8: 3x speed. Total: 384x speed divisor.
function EconomyMath.GetFloorSpeedMultiplier(buildingId: number, unlockedFloorUpgrades: { [number]: boolean }?): number
    if not unlockedFloorUpgrades then return 1 end

    local speedDivisor = 1
    local speedMap = EconomyConfig.FloorUpgradeSpeedMultipliers or {}
    for tier = 1, 8 do
        if unlockedFloorUpgrades[tier] then
            local tierMult = speedMap[tier] or 2
            speedDivisor = speedDivisor * tierMult
        end
    end
    return speedDivisor
end

-- Calculate effective cycle time
-- EffectiveCycleTime = BaseCycleTime / (FloorSpeedDivisor * MilestoneSpeedDivisor * GlobalSpeedMult)
function EconomyMath.CalculateEffectiveCycleTime(baseCycleTime: number, floorSpeedDiv: number, milestoneSpeedDiv: number, globalSpeedMult: number?): number
    local totalSpeedDiv = (floorSpeedDiv or 1) * (milestoneSpeedDiv or 1) * (globalSpeedMult or 1)
    if totalSpeedDiv <= 0 then totalSpeedDiv = 1 end
    return math.max(0.001, baseCycleTime / totalSpeedDiv)
end

-- Calculate income per completed cycle
-- Income = Owned * BaseProd * MilestoneOutputMult * PrestigeMult
function EconomyMath.CalculateIncomePerCycle(owned: number, baseProd: number, milestoneOutputMult: number, prestigeMult: number?): number
    local pMult = prestigeMult or 1
    local mMult = milestoneOutputMult or 1
    return math.floor(owned * baseProd * mMult * pMult)
end

-- Format numbers into readable currency strings (e.g. $0, $14, $1.5K, $2.4M, $3.8B ... Centillion / Scientific)
function EconomyMath.FormatCurrency(amount: number): string
    if amount == nil or amount <= 0 then
        return "$0"
    end

    if amount < 1000 then
        if amount == math.floor(amount) then
            return "$" .. tostring(math.floor(amount))
        else
            return string.format("$%.2f", amount)
        end
    end

    local log10Val = math.log10(amount)
    local tier = math.floor(log10Val / 3)

    if tier <= #SUFFIXES then
        local suffix = SUFFIXES[tier]
        local divisor = 10 ^ (tier * 3)
        local value = amount / divisor
        if value >= 100 then
            return string.format("$%.1f%s", value, suffix)
        else
            return string.format("$%.2f%s", value, suffix)
        end
    else
        -- Scientific notation past Centillion (10^303)
        local exp = math.floor(log10Val)
        local mantissa = amount / (10 ^ exp)
        return string.format("$%.2fe%d", mantissa, exp)
    end
end

-- Format cycle times into readable strings (e.g. every 1.5s, every 0.25s, every 3ms, every 500μs, every 250ns)
function EconomyMath.FormatTime(seconds: number): string
    if seconds == nil or seconds <= 0 then
        return "instant"
    end

    if seconds >= 60 then
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("every %dm %ds", mins, math.floor(secs))
    elseif seconds >= 1 then
        if seconds == math.floor(seconds) then
            return string.format("every %ds", math.floor(seconds))
        else
            return string.format("every %.1fs", seconds)
        end
    elseif seconds >= 0.1 then
        return string.format("every %.2fs", seconds)
    elseif seconds >= 0.001 then
        -- Milliseconds (1ms .. 99ms)
        local ms = seconds * 1000
        if ms >= 10 or ms == math.floor(ms) then
            return string.format("every %dms", math.floor(ms + 0.5))
        else
            return string.format("every %.1fms", ms)
        end
    elseif seconds >= 1e-6 then
        -- Microseconds (1μs .. 999μs)
        local us = seconds * 1e6
        if us >= 10 or us == math.floor(us) then
            return string.format("every %dμs", math.floor(us + 0.5))
        else
            return string.format("every %.1fμs", us)
        end
    else
        -- Nanoseconds (ns)
        local ns = seconds * 1e9
        return string.format("every %dns", math.floor(ns + 0.5))
    end
end

return EconomyMath
