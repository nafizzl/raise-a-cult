--!strict
-- TutorialController.local.luau
-- Client-side onboarding tutorial: center-bottom floating instruction banner,
-- flat-ground repeating chevron guidance Beam (Work at a Pizza Place style, Steps 1 through 5),
-- and cashflow/upgrade milestone tracking.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockStageEvent = RemoteEvents:WaitForChild("UnlockStage") :: RemoteEvent
local MoneyUpdatedEvent = RemoteEvents:WaitForChild("MoneyUpdated") :: RemoteEvent
local UpgradeEvent = RemoteEvents:WaitForChild("UpgradeEvent") :: RemoteEvent
local TutorialInitFunc = RemoteEvents:WaitForChild("TutorialInit") :: RemoteFunction

-- Tutorial Step Enumeration
local STEP_1_BUY_BUILDING = 1
local STEP_2_START_CLICKING = 2
local STEP_3_UPGRADE_CASHFLOW = 3
local STEP_4_SPEED_UPGRADE = 4
local STEP_5_BUY_MANAGER = 5
local STEP_6_CONGRATULATIONS = 6
local STEP_COMPLETED = 7

local currentStep = STEP_1_BUY_BUILDING
local currentCash = 0
local isTutorialActive = false

-- UI Instances
local screenGui: ScreenGui? = nil
local bannerContainer: Frame? = nil
local instructionLabel: TextLabel? = nil
local uiScale: UIScale? = nil

-- Chevron Guide Beam Instances
local guideFolder: Folder? = nil
local playerAnchorPart: Part? = nil
local targetAnchorPart: Part? = nil
local playerAttachment: Attachment? = nil
local targetAttachment: Attachment? = nil
local guideBeam: Beam? = nil
local activeTargetPart: BasePart? = nil
local beamUpdateConnection: RBXScriptConnection? = nil

--------------------------------------------------------------------------------
-- 1. Repeating Chevron Ground Guidance Beam System (Steps 1 through 5)
--------------------------------------------------------------------------------

local function clearBeamSystem()
	if beamUpdateConnection then
		beamUpdateConnection:Disconnect()
		beamUpdateConnection = nil
	end

	activeTargetPart = nil

	if guideBeam then
		guideBeam.Enabled = false
	end

	if guideFolder and guideFolder.Parent then
		guideFolder:Destroy()
		guideFolder = nil
	end

	playerAnchorPart = nil
	targetAnchorPart = nil
	playerAttachment = nil
	targetAttachment = nil
	guideBeam = nil
end

local function initBeamSystem()
	if guideFolder and guideBeam then return end

	-- Clean any existing folder
	local existing = workspace:FindFirstChild("TutorialGuideBeam")
	if existing then existing:Destroy() end

	guideFolder = Instance.new("Folder")
	guideFolder.Name = "TutorialGuideBeam"
	guideFolder.Parent = workspace

	-- Anchor part under the player's feet
	playerAnchorPart = Instance.new("Part")
	playerAnchorPart.Name = "PlayerAnchor"
	playerAnchorPart.Size = Vector3.new(0.1, 0.1, 0.1)
	playerAnchorPart.Anchored = true
	playerAnchorPart.CanCollide = false
	playerAnchorPart.CanTouch = false
	playerAnchorPart.CanQuery = false
	playerAnchorPart.CastShadow = false
	playerAnchorPart.Transparency = 1
	playerAnchorPart.Position = Vector3.new(0, -500, 0)
	playerAnchorPart.Parent = guideFolder

	-- Anchor part at the destination target
	targetAnchorPart = Instance.new("Part")
	targetAnchorPart.Name = "TargetAnchor"
	targetAnchorPart.Size = Vector3.new(0.1, 0.1, 0.1)
	targetAnchorPart.Anchored = true
	targetAnchorPart.CanCollide = false
	targetAnchorPart.CanTouch = false
	targetAnchorPart.CanQuery = false
	targetAnchorPart.CastShadow = false
	targetAnchorPart.Transparency = 1
	targetAnchorPart.Position = Vector3.new(0, -500, 0)
	targetAnchorPart.Parent = guideFolder

	-- Attachments for the Beam
	playerAttachment = Instance.new("Attachment")
	playerAttachment.Name = "PlayerAtt"
	playerAttachment.Axis = Vector3.new(0, 1, 0) -- Flat ground orientation
	playerAttachment.SecondaryAxis = Vector3.new(0, 0, 1)
	playerAttachment.Parent = playerAnchorPart

	targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "TargetAtt"
	targetAttachment.Axis = Vector3.new(0, 1, 0) -- Flat ground orientation
	targetAttachment.SecondaryAxis = Vector3.new(0, 0, 1)
	targetAttachment.Parent = targetAnchorPart

	-- Roblox Beam with repeating chevrons (Work at a Pizza Place style)
	-- Attachment0 is at Target, Attachment1 is at Player
	-- FaceCamera = false keeps the beam 100% flat on the ground plane with zero rotational distortion
	guideBeam = Instance.new("Beam")
	guideBeam.Name = "ChevronBeam"
	guideBeam.Attachment0 = targetAttachment -- Destination / Objective
	guideBeam.Attachment1 = playerAttachment -- Player / Origin
	guideBeam.FaceCamera = false -- Flat on ground (no tilting/rotating to camera)
	guideBeam.Texture = "rbxassetid://705372919" -- Road Chevron White
	guideBeam.TextureMode = Enum.TextureMode.Wrap
	guideBeam.TextureLength = 2.6
	guideBeam.TextureSpeed = -3.0 -- Negative moves towards Attachment0 (Destination)
	guideBeam.Width0 = 2.8
	guideBeam.Width1 = 2.8
	guideBeam.LightEmission = 1.0
	guideBeam.LightInfluence = 0.0

	-- Vibrant cyan-green at player (Keypoint 1.0) fading to pure white at target (Keypoint 0.0)
	guideBeam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 255, 200)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 235, 140)),
	})

	-- Crisp at player (1.0) with subtle distance fade at target (0.0)
	guideBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.50),
		NumberSequenceKeypoint.new(0.3, 0.15),
		NumberSequenceKeypoint.new(1.0, 0.05),
	})

	guideBeam.Enabled = false
	guideBeam.Parent = playerAnchorPart
end

local function setBeamTarget(target: BasePart?)
	activeTargetPart = target

	-- Keep arrows active across all early progression steps (Steps 1 through 5)
	if currentStep >= STEP_6_CONGRATULATIONS or not target then
		if guideBeam then
			guideBeam.Enabled = false
		end
		return
	end

	if not guideBeam or not guideFolder or not guideFolder.Parent then
		initBeamSystem()
	end

	if not beamUpdateConnection then
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		beamUpdateConnection = RunService.RenderStepped:Connect(function()
			if not activeTargetPart or not activeTargetPart:IsDescendantOf(workspace) then
				if guideBeam then guideBeam.Enabled = false end
				return
			end

			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				if guideBeam then guideBeam.Enabled = false end
				return
			end

			if not playerAnchorPart or not targetAnchorPart or not guideBeam then
				return
			end

			local playerPos = hrp.Position
			local targetPos = activeTargetPart.Position
			local toTarget = Vector3.new(targetPos.X - playerPos.X, 0, targetPos.Z - playerPos.Z)
			local dist = toTarget.Magnitude

			-- Hide beam when player has arrived right at the button/stand
			if dist < 2.8 then
				guideBeam.Enabled = false
				return
			end

			-- Raycast filter ignores character and guide elements
			if guideFolder then
				rayParams.FilterDescendantsInstances = { char, guideFolder }
			else
				rayParams.FilterDescendantsInstances = { char }
			end

			-- Pin beam flush on ground (+0.08 studs to lie flat on floor without z-fighting)
			local playerRay = workspace:Raycast(playerPos + Vector3.new(0, 4, 0), Vector3.new(0, -18, 0), rayParams)
			local playerGroundY = playerRay and (playerRay.Position.Y + 0.08) or (playerPos.Y - 2.8)

			-- Pin target end of beam flush on ground
			local targetRay = workspace:Raycast(targetPos + Vector3.new(0, 4, 0), Vector3.new(0, -18, 0), rayParams)
			local targetGroundY = targetRay and (targetRay.Position.Y + 0.08) or (targetPos.Y - 0.4)

			playerAnchorPart.CFrame = CFrame.new(playerPos.X, playerGroundY, playerPos.Z)
			targetAnchorPart.CFrame = CFrame.new(targetPos.X, targetGroundY, targetPos.Z)

			-- Calculate perpendicular horizontal vector so the beam's surface normal is strictly UP (0, 1, 0)
			-- and its width is strictly horizontal, keeping it 100% flat with zero camera distortion or twisting
			local dir = toTarget.Unit
			local up = Vector3.new(0, 1, 0)
			local right = dir:Cross(up).Unit

			if playerAttachment then
				playerAttachment.Axis = up
				playerAttachment.SecondaryAxis = right
			end
			if targetAttachment then
				targetAttachment.Axis = up
				targetAttachment.SecondaryAxis = right
			end

			guideBeam.Enabled = true
		end)
	end
end

--------------------------------------------------------------------------------
-- 2. Floating Instruction Banner UI (Center Bottom, Fredoka One, White, Stroke 4.5)
--------------------------------------------------------------------------------

local function buildTutorialUI()
	if screenGui then return end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true

	bannerContainer = Instance.new("Frame")
	bannerContainer.Name = "BannerContainer"
	bannerContainer.AnchorPoint = Vector2.new(0.5, 1)
	bannerContainer.Position = UDim2.new(0.5, 0, 1, -145) -- Scaled position cleanly above HUD inside target area
	bannerContainer.Size = UDim2.new(0.95, 0, 0, 110) -- Expanded container to fit 25% larger text
	bannerContainer.BackgroundTransparency = 1 -- Pure floating text (no background frame)
	bannerContainer.Parent = screenGui

	uiScale = Instance.new("UIScale")
	uiScale.Scale = 1.0
	uiScale.Parent = bannerContainer

	instructionLabel = Instance.new("TextLabel")
	instructionLabel.Name = "InstructionText"
	instructionLabel.Size = UDim2.new(1, 0, 1, 0)
	instructionLabel.BackgroundTransparency = 1
	instructionLabel.Font = Enum.Font.FredokaOne
	instructionLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White fill
	instructionLabel.TextScaled = true
	instructionLabel.TextStrokeTransparency = 1
	instructionLabel.Text = ""
	instructionLabel.Parent = bannerContainer

	local stroke = Instance.new("UIStroke")
	stroke.Name = "TextStroke"
	stroke.Color = Color3.fromRGB(0, 0, 0) -- Black stroke
	stroke.Thickness = 4.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = instructionLabel

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = 68 -- 25% bigger scaled (up from 54)
	constraint.MinTextSize = 28
	constraint.Parent = instructionLabel

	screenGui.Parent = playerGui
end

local function setInstructionText(newText: string, playPunchAnim: boolean?)
	if not instructionLabel then buildTutorialUI() end
	if not instructionLabel then return end

	instructionLabel.Text = newText

	if playPunchAnim and uiScale then
		uiScale.Scale = 0.88
		local punchTween = TweenService:Create(uiScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.0
		})
		punchTween:Play()
	end
end

local function completeAndDismissTutorial()
	clearBeamSystem()
	setInstructionText("Well done, keep earning more money and grow your cult!", true)

	task.delay(5.0, function()
		if instructionLabel then
			local fadeInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local stroke = instructionLabel:FindFirstChild("TextStroke") :: UIStroke?

			local textTween = TweenService:Create(instructionLabel, fadeInfo, { TextTransparency = 1 })
			textTween:Play()

			if stroke then
				local strokeTween = TweenService:Create(stroke, fadeInfo, { Transparency = 1 })
				strokeTween:Play()
			end

			textTween.Completed:Connect(function()
				if screenGui then
					screenGui:Destroy()
					screenGui = nil
				end
			end)
		end
		currentStep = STEP_COMPLETED
	end)
end

--------------------------------------------------------------------------------
-- 3. Dynamic Target Resolvers for Steps 1 through 5
--------------------------------------------------------------------------------

local function getStepTarget(step: number): BasePart?
	local cultTycoon = workspace:FindFirstChild("CultTycoon", true)
	local b1 = cultTycoon and cultTycoon:FindFirstChild("Building1")
	if not b1 then return nil end

	if step == STEP_1_BUY_BUILDING then
		local nbb = b1:FindFirstChild("NewBuildingButton")
		if nbb then
			local btnModel = nbb:FindFirstChild("Button")
			if btnModel then
				local btnPart = btnModel:FindFirstChild("Button")
				if btnPart and btnPart:IsA("BasePart") then return btnPart end
				if btnModel:IsA("BasePart") then return btnModel end
			end
			local p = nbb:FindFirstChildWhichIsA("BasePart", true)
			if p then return p end
		end

	elseif step == STEP_2_START_CLICKING or step == STEP_3_UPGRADE_CASHFLOW then
		local sp = b1:FindFirstChild("StreetPreacherBuilding")
		if sp then
			local cgui = sp:FindFirstChild("CollectUpgradeGui")
			if cgui and cgui:IsA("BasePart") then return cgui end
			local tableProp = sp:FindFirstChild("Table")
			if tableProp then
				if tableProp:IsA("BasePart") then return tableProp end
				if tableProp:IsA("Model") then
					return tableProp.PrimaryPart or tableProp:FindFirstChildWhichIsA("BasePart", true)
				end
			end
		end

	elseif step == STEP_4_SPEED_UPGRADE then
		local sp = b1:FindFirstChild("StreetPreacherBuilding")
		local flyers = sp and sp:FindFirstChild("Flyers")
		local ub = flyers and flyers:FindFirstChild("UpgradeButton")
		if ub then
			local btnModel = ub:FindFirstChild("Button")
			if btnModel then
				local btnPart = btnModel:FindFirstChild("Button")
				if btnPart and btnPart:IsA("BasePart") then return btnPart end
				if btnModel:IsA("BasePart") then return btnModel end
			end
			local p = ub:FindFirstChildWhichIsA("BasePart", true)
			if p then return p end
		end

	elseif step == STEP_5_BUY_MANAGER then
		local sp = b1:FindFirstChild("StreetPreacherBuilding")
		local mgr = sp and sp:FindFirstChild("Manager")
		local mb = mgr and mgr:FindFirstChild("ManagerButton")
		if mb then
			local btnModel = mb:FindFirstChild("Button")
			if btnModel then
				local btnPart = btnModel:FindFirstChild("Button")
				if btnPart and btnPart:IsA("BasePart") then return btnPart end
				if btnModel:IsA("BasePart") then return btnModel end
			end
			local p = mb:FindFirstChildWhichIsA("BasePart", true)
			if p then return p end
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- 4. Step Transition Engine
--------------------------------------------------------------------------------

local function enterStep(step: number)
	if step >= STEP_COMPLETED then return end
	currentStep = step

	if step == STEP_1_BUY_BUILDING then
		setInstructionText("Buy your first building for your cult!", true)
	elseif step == STEP_2_START_CLICKING then
		setInstructionText("Get closer and start clicking to earn money!", true)
	elseif step == STEP_3_UPGRADE_CASHFLOW then
		setInstructionText("Upgrade your cash flow!", true)
	elseif step == STEP_4_SPEED_UPGRADE then
		setInstructionText("Keep getting money and buy your first speed upgrade!", true)
	elseif step == STEP_5_BUY_MANAGER then
		setInstructionText("Earn money and buy your first manager!", true)
	elseif step == STEP_6_CONGRATULATIONS then
		completeAndDismissTutorial()
		return
	end

	-- Resolve target and activate guidance beam for Steps 1 through 5
	task.spawn(function()
		local target: BasePart? = nil
		for _ = 1, 30 do
			if currentStep ~= step then return end
			target = getStepTarget(step)
			if target then break end
			task.wait(0.2)
		end

		print(string.format("[TutorialController] Step %d Target resolved: %s (Pos: %s)",
			step,
			target and target:GetFullName() or "NIL",
			target and tostring(target.Position) or "NIL"))

		if currentStep == step and target then
			setBeamTarget(target)
		end
	end)
end

--------------------------------------------------------------------------------
-- 5. Event Listeners for Game Progression
--------------------------------------------------------------------------------

-- Milestone / Stage Unlocks via BuildingProgressionServer
UnlockStageEvent.OnClientEvent:Connect(function(unlockName: string)
	if not isTutorialActive or currentStep >= STEP_COMPLETED then return end

	-- Step 1 -> Step 2: Player bought NewBuildingButton ($0 free starter)
	if unlockName == "BaseStage" and currentStep == STEP_1_BUY_BUILDING then
		enterStep(STEP_2_START_CLICKING)
		return
	end

	-- Step 4 -> Step 5: Player bought first speed upgrade (Flyers, $50)
	if unlockName == "FlyersStage" and currentStep == STEP_4_SPEED_UPGRADE then
		enterStep(STEP_5_BUY_MANAGER)
		return
	end

	-- Step 5 -> Step 6: Player hired Building 1 Manager ($250)
	if unlockName == "ManagerStage" and currentStep == STEP_5_BUY_MANAGER then
		enterStep(STEP_6_CONGRATULATIONS)
		return
	end
end)

-- Real-time Cash Tracking
MoneyUpdatedEvent.OnClientEvent:Connect(function(newBalance: any)
	currentCash = tonumber(newBalance) or 0
	if not isTutorialActive or currentStep >= STEP_COMPLETED then return end

	-- Step 2 -> Step 3: Player accumulated $16 for the first GUI cash flow upgrade
	if currentStep == STEP_2_START_CLICKING and currentCash >= 16 then
		enterStep(STEP_3_UPGRADE_CASHFLOW)
	end
end)

-- GUI Cash Flow Upgrade Success via ProductionEngine
UpgradeEvent.OnClientEvent:Connect(function(action: string, buildingIdArg: any, newLevel: any)
	if not isTutorialActive or currentStep >= STEP_COMPLETED then return end

	local bId = tonumber(buildingIdArg) or 1
	local lvl = tonumber(newLevel) or 1

	-- Step 3 -> Step 4: Player upgraded Building 1 from Level 1 to Level 2+
	if action == "UpgradeSuccess" and bId == 1 and currentStep == STEP_3_UPGRADE_CASHFLOW and lvl >= 2 then
		enterStep(STEP_4_SPEED_UPGRADE)
	end
end)

-- Keep beam attached upon character respawn
localPlayer.CharacterAdded:Connect(function()
	if isTutorialActive and currentStep < STEP_6_CONGRATULATIONS then
		task.wait(0.3)
		local target = getStepTarget(currentStep)
		if target then
			setBeamTarget(target)
		end
	end
end)

--------------------------------------------------------------------------------
-- 6. Initialization
--------------------------------------------------------------------------------

local function initTutorial()
	buildTutorialUI()

	local status: any = nil
	local success = pcall(function()
		status = TutorialInitFunc:InvokeServer()
	end)

	if success and status and type(status) == "table" then
		isTutorialActive = (status.IsTutorialActive == true)
		if isTutorialActive then
			enterStep(status.InitialStep or STEP_1_BUY_BUILDING)
			print(string.format("[TutorialController] Tutorial active. Resumed at Step %d.", currentStep))
		else
			if screenGui then screenGui:Destroy() end
			print("[TutorialController] Player already completed tutorial or has advanced progression. Standby.")
		end
	else
		-- Fallback check if server invoke fails
		isTutorialActive = true
		enterStep(STEP_1_BUY_BUILDING)
	end
end

task.delay(0.5, initTutorial)
