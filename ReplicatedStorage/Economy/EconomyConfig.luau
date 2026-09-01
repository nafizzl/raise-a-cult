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

-- 10-Tier Elevated Building Definitions (Compensated for Dual Milestone + Speed Multipliers)
EconomyConfig.Buildings = {
    [1] = {
        Id = 1,
        Name = "Street Corner Preacher",
        BaseCost = 15,
        GrowthRate = 1.12,
        BaseProd = 1,
        BaseCycleTime = 1.0,
        ManagerCost = 250,
    },
    [2] = {
        Id = 2,
        Name = "Storage Unit Temple",
        BaseCost = 250000, -- $250K
        GrowthRate = 1.13,
        BaseProd = 500,
        BaseCycleTime = 3.0,
        ManagerCost = 2500000, -- $2.5M
    },
    [3] = {
        Id = 3,
        Name = "Suburban Compound",
        BaseCost = 250000000, -- $250M
        GrowthRate = 1.14,
        BaseProd = 250000,
        BaseCycleTime = 6.0,
        ManagerCost = 5000000000, -- $5B
    },
    [4] = {
        Id = 4,
        Name = "Community Hall",
        BaseCost = 500000000000, -- $500B
        GrowthRate = 1.15,
        BaseProd = 200000000, -- 200M
        BaseCycleTime = 12.0,
        ManagerCost = 50000000000000, -- $50T
    },
    [5] = {
        Id = 5,
        Name = "Wellness Retreat Ranch",
        BaseCost = 1e14, -- $100T
        GrowthRate = 1.16,
        BaseProd = 350000000000, -- 350B
        BaseCycleTime = 24.0,
        ManagerCost = 2.5e17, -- $250Qa
    },
    [6] = {
        Id = 6,
        Name = "Merch & Media Wing",
        BaseCost = 5e20, -- $500Qi
        GrowthRate = 1.17,
        BaseProd = 2e15, -- 2Qa
        BaseCycleTime = 45.0,
        ManagerCost = 1e24, -- $1Sx
    },
    [7] = {
        Id = 7,
        Name = "Pirate Radio/TV Broadcast",
        BaseCost = 5e25, -- $50Sp
        GrowthRate = 1.18,
        BaseProd = 1.5e20, -- 150Qi
        BaseCycleTime = 90.0,
        ManagerCost = 2.5e29, -- $250Oc
    },
    [8] = {
        Id = 8,
        Name = "Underground Bunker Complex",
        BaseCost = 2.5e44, -- $250Td
        GrowthRate = 1.19,
        BaseProd = 1e25, -- 10Sp
        BaseCycleTime = 180.0,
        ManagerCost = 5e49, -- $50Qd
    },
    [9] = {
        Id = 9,
        Name = "Shell Corporation Network",
        BaseCost = 5e65, -- $500Vg
        GrowthRate = 1.20,
        BaseProd = 5e43, -- 50Td
        BaseCycleTime = 360.0,
        ManagerCost = 1e71, -- $100Tg
    },
    [10] = {
        Id = 10,
        Name = "Global Mega-Temple HQ",
        BaseCost = 5e185, -- $500Sg
        GrowthRate = 1.21,
        BaseProd = 5e63, -- 5Vg
        BaseCycleTime = 720.0,
        ManagerCost = 5e211, -- $50Ns
    },
}

-- 8-Tier Floor Speed Upgrades (Multipliers of BaseCost Bk, strictly cycle speed divisors)
-- Upgrades 1-7: 2x speed, Upgrade 8: 3x speed. Total = 384x Speed Divisor.
EconomyConfig.FloorUpgradeCostMultipliers = {
    [1] = 2.0,            -- Tier 1: 2.0 * Bk   (B1: $30)
    [2] = 25,             -- Tier 2: 25 * Bk    (B1: $375)
    [3] = 300,            -- Tier 3: 300 * Bk   (B1: $4,500)
    [4] = 35000,          -- Tier 4: 35,000 * Bk (B1: $525,000)
    [5] = 400000,         -- Tier 5: 400,000 * Bk (B1: $6.0M)
    [6] = 25000000,       -- Tier 6: 25M * Bk   (B1: $375M)
    [7] = 7500000000,     -- Tier 7: 7.5B * Bk  (B1: $112.5B)
    [8] = 150000000000000,-- Tier 8: 150T * Bk  (B1: $2.25Qa - Capstone: $50 Novemsexagintillion on B10)
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
-- Output multipliers strictly double/scale output without speed doublings (Floor Upgrades handle speed)
EconomyConfig.Milestones = {
    { Threshold = 10,       OutputMult = 2,    SpeedMult = 1 }, -- 2x
    { Threshold = 25,       OutputMult = 2,    SpeedMult = 1 }, -- 4x cumulative
    { Threshold = 50,       OutputMult = 2,    SpeedMult = 1 }, -- 8x cumulative
    { Threshold = 100,      OutputMult = 2,    SpeedMult = 1 }, -- 16x cumulative
    { Threshold = 200,      OutputMult = 4,    SpeedMult = 1 }, -- 64x cumulative
    { Threshold = 500,      OutputMult = 8,    SpeedMult = 1 }, -- 512x cumulative
    { Threshold = 1000,     OutputMult = 16,   SpeedMult = 1 }, -- 8,192x cumulative
    { Threshold = 2000,     OutputMult = 32,   SpeedMult = 1 },
    { Threshold = 5000,     OutputMult = 64,   SpeedMult = 1 },
    { Threshold = 10000,    OutputMult = 128,  SpeedMult = 1 },
    { Threshold = 25000,    OutputMult = 256,  SpeedMult = 1 },
    { Threshold = 50000,    OutputMult = 512,  SpeedMult = 1 },
    { Threshold = 100000,   OutputMult = 1024, SpeedMult = 1 },
    { Threshold = 250000,   OutputMult = 2048, SpeedMult = 1 },
    { Threshold = 500000,   OutputMult = 4096, SpeedMult = 1 },
    { Threshold = 1000000,  OutputMult = 8192, SpeedMult = 1 },
}

return EconomyConfig
