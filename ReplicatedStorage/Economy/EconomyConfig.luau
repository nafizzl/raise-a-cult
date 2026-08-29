--!strict
-- EconomyConfig.luau
-- Centralized configuration for all buildings, floor speed upgrades, and milestone thresholds.

local EconomyConfig = {}

export type BuildingDefinition = {
    Id: number,
    Name: string,
    BaseCost: number,
    GrowthRate: number,
    BaseProd: number,
    BaseCycleTime: number,
    ManagerCost: number,
}

-- 10-Tier Canonical Building Definitions (Table 2 in economy.md)
EconomyConfig.Buildings = {
    [1] = {
        Id = 1,
        Name = "Street Corner Preacher",
        BaseCost = 4,
        GrowthRate = 1.07,
        BaseProd = 1,
        BaseCycleTime = 1.0,
        ManagerCost = 100,
    },
    [2] = {
        Id = 2,
        Name = "Storage Unit Temple",
        BaseCost = 60,
        GrowthRate = 1.08,
        BaseProd = 12,
        BaseCycleTime = 3.0,
        ManagerCost = 1500,
    },
    [3] = {
        Id = 3,
        Name = "Suburban Compound",
        BaseCost = 1800,
        GrowthRate = 1.09,
        BaseProd = 80,
        BaseCycleTime = 6.0,
        ManagerCost = 45000,
    },
    [4] = {
        Id = 4,
        Name = "Community Hall",
        BaseCost = 90000,
        GrowthRate = 1.10,
        BaseProd = 720,
        BaseCycleTime = 12.0,
        ManagerCost = 2500000,
    },
    [5] = {
        Id = 5,
        Name = "Wellness Retreat Ranch",
        BaseCost = 9000000, -- 9M
        GrowthRate = 1.11,
        BaseProd = 12000,
        BaseCycleTime = 24.0,
        ManagerCost = 300000000, -- 300M
    },
    [6] = {
        Id = 6,
        Name = "Merch & Media Wing",
        BaseCost = 2500000000, -- 2.5B
        GrowthRate = 1.12,
        BaseProd = 350000,
        BaseCycleTime = 45.0,
        ManagerCost = 100000000000, -- 100B
    },
    [7] = {
        Id = 7,
        Name = "Pirate Radio/TV Broadcast",
        BaseCost = 1500000000000, -- 1.5T
        GrowthRate = 1.13,
        BaseProd = 12000000, -- 12M
        BaseCycleTime = 90.0,
        ManagerCost = 75000000000000, -- 75T
    },
    [8] = {
        Id = 8,
        Name = "Underground Bunker Complex",
        BaseCost = 2000000000000000, -- 2Qa
        GrowthRate = 1.14,
        BaseProd = 600000000, -- 600M
        BaseCycleTime = 180.0,
        ManagerCost = 120000000000000000, -- 120Qa
    },
    [9] = {
        Id = 9,
        Name = "Shell Corporation Network",
        BaseCost = 5000000000000000000, -- 5Qi
        GrowthRate = 1.15,
        BaseProd = 40000000000, -- 40B
        BaseCycleTime = 360.0,
        ManagerCost = 350000000000000000000, -- 350Qi
    },
    [10] = {
        Id = 10,
        Name = "Global Mega-Temple HQ",
        BaseCost = 2.5e22, -- 25Sx
        GrowthRate = 1.16,
        BaseProd = 3.5e12, -- 3.5T
        BaseCycleTime = 720.0,
        ManagerCost = 2e24, -- 2Sp
    },
}

-- 8-Tier Floor Speed Upgrades (Multipliers of BaseCost Bk, strictly cycle speed divisors)
-- Upgrades 1-7: 2x speed, Upgrade 8: 3x speed. Total = 384x Speed.
EconomyConfig.FloorUpgradeCostMultipliers = {
    [1] = 3.5,            -- Tier 1: 3.5 * Bk  (B1: $14)
    [2] = 25,             -- Tier 2: 25 * Bk   (B1: $100 - overlaps B2 base)
    [3] = 200,            -- Tier 3: 200 * Bk  (B1: $800)
    [4] = 3000,           -- Tier 4: 3,000 * Bk (B1: $12,000 - overlaps B3 base)
    [5] = 85000,          -- Tier 5: 85,000 * Bk (B1: $340,000 - overlaps B4 base)
    [6] = 4500000,        -- Tier 6: 4.5M * Bk (B1: $18M - overlaps B5 base)
    [7] = 350000000,      -- Tier 7: 350M * Bk (B1: $1.4B - overlaps B6 base)
    [8] = 60000000000,    -- Tier 8: 60B * Bk  (B1: $240B - endgame capstone)
}

-- Floor Upgrade speed multipliers per tier
EconomyConfig.FloorUpgradeSpeedMultipliers = {
    [1] = 2,
    [2] = 2,
    [3] = 2,
    [4] = 2,
    [5] = 2,
    [6] = 2,
    [7] = 2,
    [8] = 3,
}

-- Extended Milestone Thresholds (1 - 2.5 - 5 - 10 rhythm)
-- Output boosts scale up, with periodic speed doublings
EconomyConfig.Milestones = {
    { Threshold = 10,       OutputMult = 2,    SpeedMult = 1 },
    { Threshold = 25,       OutputMult = 2,    SpeedMult = 1 },
    { Threshold = 50,       OutputMult = 2,    SpeedMult = 2 },
    { Threshold = 100,      OutputMult = 2,    SpeedMult = 2 },
    { Threshold = 200,      OutputMult = 4,    SpeedMult = 1 },
    { Threshold = 500,      OutputMult = 8,    SpeedMult = 1 },
    { Threshold = 1000,     OutputMult = 16,   SpeedMult = 2 },
    { Threshold = 2000,     OutputMult = 32,   SpeedMult = 2 },
    { Threshold = 5000,     OutputMult = 64,   SpeedMult = 1 },
    { Threshold = 10000,    OutputMult = 128,  SpeedMult = 2 },
    { Threshold = 25000,    OutputMult = 256,  SpeedMult = 1 },
    { Threshold = 50000,    OutputMult = 512,  SpeedMult = 2 },
    { Threshold = 100000,   OutputMult = 1024, SpeedMult = 2 },
    { Threshold = 250000,   OutputMult = 2048, SpeedMult = 1 },
    { Threshold = 500000,   OutputMult = 4096, SpeedMult = 2 },
    { Threshold = 1000000,  OutputMult = 8192, SpeedMult = 2 },
}

return EconomyConfig
