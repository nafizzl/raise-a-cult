--!strict
-- TutorialServer.legacy.luau
-- Server-side tutorial controller: Welcome Badge awarding and initial progress synchronization.

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MoneyManager = require(ServerScriptService:WaitForChild("MoneyManager") :: any)

local WELCOME_BADGE_ID = 1830127030429571

-- Ensure RemoteEvents folder and TutorialInit RemoteFunction exist
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local TutorialInitFunc = RemoteEvents:FindFirstChild("TutorialInit")
if not TutorialInitFunc then
	TutorialInitFunc = Instance.new("RemoteFunction")
	TutorialInitFunc.Name = "TutorialInit"
	TutorialInitFunc.Parent = RemoteEvents
end
local tutorialInitRemote = TutorialInitFunc :: RemoteFunction

local function awardWelcomeBadge(player: Player)
	task.spawn(function()
		if WELCOME_BADGE_ID <= 0 then return end
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, WELCOME_BADGE_ID)
		end)

		if success and not hasBadge then
			local awardSuccess, err = pcall(function()
				BadgeService:AwardBadge(player.UserId, WELCOME_BADGE_ID)
			end)
			if awardSuccess then
				print(string.format("[TutorialServer] Welcome badge (%d) awarded to %s!", WELCOME_BADGE_ID, player.Name))
			else
				warn(string.format("[TutorialServer] Failed to award Welcome badge to %s: %s", player.Name, tostring(err)))
			end
		end
	end)
end

-- Helper to check if player has zero progress or is in early tutorial
local function getTutorialStatus(player: Player): { IsTutorialActive: boolean, InitialStep: number }
	local b1State = MoneyManager.GetBuildingState(player, 1)
	local cash = MoneyManager.GetMoney(player)

	-- If player already hired Building 1 Manager, tutorial is fully completed
	if b1State.HasManager then
		return { IsTutorialActive = false, InitialStep = 0 }
	end

	-- Check if player has higher buildings owned
	for bId = 2, 10 do
		local bState = MoneyManager.GetBuildingState(player, bId)
		if bState.OwnedCount > 0 then
			return { IsTutorialActive = false, InitialStep = 0 }
		end
	end

	-- Determine resume step
	local step = 1
	if b1State.OwnedCount <= 0 then
		step = 1 -- "Buy your first building for your cult!"
	elseif b1State.OwnedCount == 1 and cash < 16 then
		step = 2 -- "Get closer and start clicking to earn money!"
	elseif b1State.OwnedCount == 1 and cash >= 16 then
		step = 3 -- "Upgrade your cash flow!"
	elseif b1State.OwnedCount >= 2 and not MoneyManager.IsUpgradePurchased(player, 1, "FlyersStage") then
		step = 4 -- "Keep getting money and buy your first speed upgrade!"
	elseif MoneyManager.IsUpgradePurchased(player, 1, "FlyersStage") and not b1State.HasManager then
		step = 5 -- "Earn money and buy your first manager!"
	end

	return { IsTutorialActive = true, InitialStep = step }
end

-- Handle client query for tutorial status
tutorialInitRemote.OnServerInvoke = function(player: Player)
	return getTutorialStatus(player)
end

-- Player join handling: Welcome badge award
Players.PlayerAdded:Connect(function(player: Player)
	awardWelcomeBadge(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	awardWelcomeBadge(player)
end

print(string.format("[TutorialServer] Initialized with Welcome Badge ID: %d", WELCOME_BADGE_ID))
