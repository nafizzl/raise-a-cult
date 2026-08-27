-- HUDController.luau
-- Formats currency balance cleanly ($0, $100, $1.5K, $2.4M) and syncs to StarterGui.HUD.MoneyLabel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("HUD")
local moneyLabel = hud:WaitForChild("MoneyLabel")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MoneyUpdatedEvent = RemoteEvents:WaitForChild("MoneyUpdated")

local function formatMoney(amount)
    if amount < 1000 then
        return "$" .. string.format("%d", amount)
    elseif amount < 1000000 then
        return string.format("$%.1fK", amount / 1000)
    elseif amount < 1000000000 then
        return string.format("$%.2fM", amount / 1000000)
    elseif amount < 1000000000000 then
        return string.format("$%.2fB", amount / 1000000000)
    else
        return string.format("$%.2fT", amount / 1000000000000)
    end
end

MoneyUpdatedEvent.OnClientEvent:Connect(function(newBalance)
    moneyLabel.Text = formatMoney(newBalance)
end)

print("[HUDController] Initialized $ money display sync.")
