--!strict
-- HUDController.local.luau
-- Formats currency balance cleanly ($0, $100, $1.5K, $2.4M ... Centillion) and syncs to StarterGui.HUD.MoneyLabel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyFolder = ReplicatedStorage:WaitForChild("Economy")
local EconomyMath = require(ReplicatedStorage.Economy.EconomyMath)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MoneyUpdatedEvent = RemoteEvents:WaitForChild("MoneyUpdated") :: RemoteEvent

local lastKnownBalance = 0

local function getMoneyLabel(): TextLabel?
    local hud = playerGui:FindFirstChild("HUD")
    if not hud then
        hud = playerGui:WaitForChild("HUD", 3)
    end
    if hud then
        local label = hud:FindFirstChild("MoneyLabel", true)
        if label and label:IsA("TextLabel") then
            return label
        end
    end
    return nil
end

local function updateDisplay(balance: number)
    lastKnownBalance = balance
    local label = getMoneyLabel()
    if label then
        label.Text = EconomyMath.FormatCurrency(balance)
    end
end

MoneyUpdatedEvent.OnClientEvent:Connect(function(newBalance: any)
    updateDisplay(tonumber(newBalance) or 0)
end)

-- Re-sync when character respawns (PlayerGui reloads if ResetOnSpawn is true)
localPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    updateDisplay(lastKnownBalance)
end)

print("[HUDController] Initialized continuous short-scale currency display sync.")
