--!strict
-- CollectUpgradeClient.local.luau
-- Robust PlayerGui Adornee Architecture with Proximity Hysteresis, Live Dynamic Cycle Times, Multi-Building Support & Auto-Cycle Animation.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyFolder = ReplicatedStorage:WaitForChild("Economy")
local EconomyConfig = require(EconomyFolder:WaitForChild("EconomyConfig") :: any)
local EconomyMath = require(EconomyFolder:WaitForChild("EconomyMath") :: any)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Distance Hysteresis thresholds to eliminate boundary jitter/collapsing
local COLLECT_IN_DIST = 7   -- Studs to pop in (Halved for collect stand)
local COLLECT_OUT_DIST = 9  -- Studs to pop out
local BUTTON_IN_DIST = 16   -- Studs to pop in (Reverted for floor buttons)
local BUTTON_OUT_DIST = 20  -- Studs to pop out

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectEvent = RemoteEvents:WaitForChild("CollectEvent") :: RemoteEvent
local UpgradeEvent = RemoteEvents:WaitForChild("UpgradeEvent") :: RemoteEvent

local activePlayerGuis: { [BasePart]: BillboardGui } = {}
local guiBuildingIds: { [BillboardGui]: number } = {}
local isGuiVisible: { [BillboardGui]: boolean } = {}
local activeTweens: { [BillboardGui]: Tween } = {}

type BuildingAnimState = {
    IsCycling: boolean,
    StartTime: number,
    Duration: number,
    IsFastBar: boolean,
    IsAutoManager: boolean,
    ActiveTween: Tween?,
}

local buildingAnimStates: { [number]: BuildingAnimState } = {}

local function getBuildingAnimState(buildingId: number): BuildingAnimState
    if not buildingAnimStates[buildingId] then
        buildingAnimStates[buildingId] = {
            IsCycling = false,
            StartTime = 0,
            Duration = 1.0,
            IsFastBar = false,
            IsAutoManager = false,
            ActiveTween = nil,
        }
    end
    return buildingAnimStates[buildingId]
end

-- Helper to extract Building ID from Attribute or Ancestor hierarchy
local function getBuildingIdForPart(part: BasePart): number
    local attr = part:GetAttribute("BuildingId") or (part.Parent and part.Parent:GetAttribute("BuildingId"))
    if attr and tonumber(attr) then
        return tonumber(attr) :: number
    end

    local current: Instance? = part
    while current and current ~= workspace do
        local match = current.Name:match("Building(%d+)")
        if match and tonumber(match) then
            return tonumber(match) :: number
        end
        current = current.Parent
    end

    return 1
end

-- Fixed Base Sizing Protection for Bounce Animations
local BASE_SIZES: { [string]: UDim2 } = {
    ["UpgradeButton"] = UDim2.new(0, 280, 0, 44),
    ["ProgressBarTrack"] = UDim2.new(0, 360, 0, 34),
}
local activeBounceTweens: { [Instance]: Tween } = {}

local function playBounceAnimation(guiObject: Instance?)
    if not guiObject or not guiObject:IsA("GuiObject") then return end
    local baseSize = BASE_SIZES[guiObject.Name] or guiObject.Size

    if activeBounceTweens[guiObject] then
        activeBounceTweens[guiObject]:Cancel()
        activeBounceTweens[guiObject] = nil
    end
    guiObject.Size = baseSize

    local bounceSize = UDim2.new(
        baseSize.X.Scale, baseSize.X.Offset + 6,
        baseSize.Y.Scale, baseSize.Y.Offset + 4
    )

    local tweenUp = TweenService:Create(guiObject, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = bounceSize
    })
    activeBounceTweens[guiObject] = tweenUp
    tweenUp:Play()
    tweenUp.Completed:Connect(function()
        if activeBounceTweens[guiObject] == tweenUp then
            local tweenDown = TweenService:Create(guiObject, TweenInfo.new(0.08, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                Size = baseSize
            })
            activeBounceTweens[guiObject] = tweenDown
            tweenDown:Play()
            tweenDown.Completed:Connect(function()
                if activeBounceTweens[guiObject] == tweenDown then
                    guiObject.Size = baseSize
                    activeBounceTweens[guiObject] = nil
                end
            end)
        end
    end)
end

local function setGuiState(pGui: BillboardGui, shouldBeVisible: boolean)
    local currentlyVisible = isGuiVisible[pGui] or false
    if currentlyVisible == shouldBeVisible then return end
    isGuiVisible[pGui] = shouldBeVisible

    local container = pGui:FindFirstChild("Container") or pGui:FindFirstChild("Frame")
    local uiScale = container and container:FindFirstChildWhichIsA("UIScale")

    if not uiScale then
        pGui.Enabled = shouldBeVisible
        return
    end

    if activeTweens[pGui] then
        activeTweens[pGui]:Cancel()
        activeTweens[pGui] = nil
    end

    if shouldBeVisible then
        pGui.Enabled = true
        local currentScale = math.max(0, uiScale.Scale)
        uiScale.Scale = (currentScale < 0.1) and 0.1 or currentScale

        local tween = TweenService:Create(uiScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        })
        activeTweens[pGui] = tween
        tween:Play()
        tween.Completed:Connect(function()
            if activeTweens[pGui] == tween then
                uiScale.Scale = 1
                activeTweens[pGui] = nil
            end
        end)
    else
        local tween = TweenService:Create(uiScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Scale = 0
        })
        activeTweens[pGui] = tween
        tween:Play()
        tween.Completed:Connect(function()
            if activeTweens[pGui] == tween then
                uiScale.Scale = 0
                activeTweens[pGui] = nil
                if not (isGuiVisible[pGui] or false) then
                    pGui.Enabled = false
                end
            end
        end)
    end
end

local function setupPlayerGuiForPart(workspacePart: BasePart): BillboardGui?
    if not workspacePart then return nil end

    local sourceBb = workspacePart:FindFirstChildWhichIsA("BillboardGui")
    if not sourceBb and not activePlayerGuis[workspacePart] then return nil end

    if not activePlayerGuis[workspacePart] and sourceBb then
        sourceBb.Enabled = false

        local clonedBb = sourceBb:Clone()
        clonedBb.Name = "PlayerGui_" .. workspacePart.Name
        clonedBb.Adornee = workspacePart
        clonedBb.Size = sourceBb.Size
        clonedBb.StudsOffset = sourceBb.StudsOffset
        clonedBb.AlwaysOnTop = true
        clonedBb.Active = true
        clonedBb.Enabled = false
        clonedBb.Parent = playerGui

        local bId = getBuildingIdForPart(workspacePart)
        guiBuildingIds[clonedBb] = bId

        local container = clonedBb:FindFirstChild("Container") or clonedBb:FindFirstChild("Frame")
        if container then
            container.Active = true
            local uiScale = container:FindFirstChildWhichIsA("UIScale")
            if not uiScale then
                uiScale = Instance.new("UIScale")
                uiScale.Scale = 0
                uiScale.Parent = container
            else
                uiScale.Scale = 0
            end

            local track = container:FindFirstChild("ProgressBarTrack")
            local upgradeBtn = container:FindFirstChild("UpgradeButton")
            local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
            local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?
            local moneyLabel = container:FindFirstChild("MoneyAmount") :: TextLabel?
            local priceLabel = container:FindFirstChild("PriceText") :: TextLabel?
            local levelLabel = container:FindFirstChild("LevelLabel") :: TextLabel?

            -- Reset UpgradeButton and Track to exact base sizes
            if upgradeBtn and upgradeBtn:IsA("GuiObject") then
                upgradeBtn.Size = BASE_SIZES["UpgradeButton"]
            end
            if track and track:IsA("GuiObject") then
                track.Size = BASE_SIZES["ProgressBarTrack"]
            end

            -- Initialize default display values from Building config (starting at Level x1 -> next upgrade is Level 2)
            local bDef = EconomyConfig.Buildings[bId] or EconomyConfig.Buildings[1]
            local nextUpgradeCost = EconomyMath.GetSingleCost(bDef.BaseCost, bDef.GrowthRate, 2)
            if timerLabel then timerLabel.Text = "READY" end
            if fill then fill.Size = UDim2.new(0, 0, 1, 0) end
            if moneyLabel then moneyLabel.Text = EconomyMath.FormatCurrency(bDef.BaseProd) end
            if priceLabel then priceLabel.Text = EconomyMath.FormatCurrency(nextUpgradeCost) end
            if levelLabel then levelLabel.Text = "x1" end

            if track then
                track.Active = true
                local btn = track:IsA("GuiButton") and track or track:FindFirstChildWhichIsA("GuiButton")
                if not btn then
                    btn = Instance.new("TextButton")
                    btn.Name = "ClickBtn"
                    btn.Size = UDim2.new(1, 0, 1, 0)
                    btn.BackgroundTransparency = 1
                    btn.Text = ""
                    btn.ZIndex = 100
                    btn.Active = true
                    btn.Parent = track
                end

                if btn and btn:IsA("GuiButton") then
                    btn.Activated:Connect(function()
                        local animState = getBuildingAnimState(bId)
                        if not animState.IsCycling and not animState.IsFastBar then
                            playBounceAnimation(track)
                            CollectEvent:FireServer(bId)
                        end
                    end)
                end
            end

            if upgradeBtn then
                upgradeBtn.Active = true
                local btn = upgradeBtn:IsA("GuiButton") and upgradeBtn or upgradeBtn:FindFirstChildWhichIsA("GuiButton")
                if not btn then
                    btn = Instance.new("TextButton")
                    btn.Name = "ClickBtn"
                    btn.Size = UDim2.new(1, 0, 1, 0)
                    btn.BackgroundTransparency = 1
                    btn.Text = ""
                    btn.ZIndex = 100
                    btn.Active = true
                    btn.Parent = upgradeBtn
                end

                if btn and btn:IsA("GuiButton") then
                    btn.Activated:Connect(function()
                        playBounceAnimation(upgradeBtn)
                        UpgradeEvent:FireServer(bId, 1)
                    end)
                end
            end
        end

        activePlayerGuis[workspacePart] = clonedBb
    end

    return activePlayerGuis[workspacePart]
end

-- Cached Proximity Scanning across workspace
local scanCooldown = 0
RunService.Heartbeat:Connect(function(dt: number)
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

    -- Clean up destroyed or unparented adornees
    for part, gui in pairs(activePlayerGuis) do
        if not part or not part:IsDescendantOf(workspace) then
            isGuiVisible[gui] = nil
            guiBuildingIds[gui] = nil
            if activeTweens[gui] then activeTweens[gui]:Cancel() end
            activeTweens[gui] = nil
            gui:Destroy()
            activePlayerGuis[part] = nil
        end
    end

    -- Discover new billboard adornee parts every 0.3s across workspace
    scanCooldown = scanCooldown + dt
    if scanCooldown >= 0.3 then
        scanCooldown = 0
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name == "CollectUpgradeGui" or part.Name == "PricingTag") then
                setupPlayerGuiForPart(part)
            end
        end
    end

    -- Update Visibility Hysteresis for all active GUIs
    for part, pGui in pairs(activePlayerGuis) do
        local isCollect = (part.Name == "CollectUpgradeGui")
        local inDist = isCollect and COLLECT_IN_DIST or BUTTON_IN_DIST
        local outDist = isCollect and COLLECT_OUT_DIST or BUTTON_OUT_DIST

        if hrp and part:IsDescendantOf(workspace) then
            local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(part.Position.X, 0, part.Position.Z)).Magnitude
            local currentlyOn = isGuiVisible[pGui] or false

            if currentlyOn then
                if dist > outDist then
                    setGuiState(pGui, false)
                end
            else
                if dist <= inDist then
                    setGuiState(pGui, true)
                end
            end
        else
            setGuiState(pGui, false)
        end
    end
end)

-- Continuous Per-Building Progress Bar & Fast-Bar Animation
local fastBarPulseTime = 0
RunService.RenderStepped:Connect(function(stepDt: number)
    local now = os.clock()
    fastBarPulseTime = fastBarPulseTime + (stepDt * 4)
    local pulse = 0.85 + (math.sin(fastBarPulseTime) * 0.15)

    for part, pGui in pairs(activePlayerGuis) do
        if part.Name == "CollectUpgradeGui" and pGui.Enabled then
            local bId = guiBuildingIds[pGui] or 1
            local animState = getBuildingAnimState(bId)
            local container = pGui:FindFirstChild("Container")
            local track = container and container:FindFirstChild("ProgressBarTrack")
            local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
            local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?

            if animState.IsFastBar then
                if fill then
                    fill.Size = UDim2.new(1, 0, 1, 0)
                    fill.BackgroundColor3 = Color3.fromRGB(math.floor(50 * pulse), math.floor(245 * pulse), math.floor(90 * pulse))
                end
                if timerLabel then
                    timerLabel.Text = EconomyMath.FormatTime(animState.Duration)
                end
            elseif animState.IsCycling then
                local elapsed = now - animState.StartTime
                local remaining = math.max(0, animState.Duration - elapsed)
                if timerLabel then
                    timerLabel.Text = string.format("%.1fs", remaining)
                end
            else
                if not animState.IsAutoManager then
                    if timerLabel and timerLabel.Text ~= "READY" then
                        timerLabel.Text = "READY"
                    end
                    if fill and fill.Size.X.Scale > 0 then
                        fill.Size = UDim2.new(0, 0, 1, 0)
                    end
                end
            end
        end
    end
end)

local function startBuildingCycle(buildingId: number, cycleDuration: number, isAutoManager: boolean?)
    local animState = getBuildingAnimState(buildingId)
    animState.Duration = cycleDuration
    animState.IsAutoManager = (isAutoManager == true)

    if cycleDuration <= 0.1 then
        animState.IsFastBar = true
        animState.IsCycling = false
        return
    else
        animState.IsFastBar = false
    end

    animState.IsCycling = true
    animState.StartTime = os.clock()

    if animState.ActiveTween then
        animState.ActiveTween:Cancel()
        animState.ActiveTween = nil
    end

    for pGui, bId in pairs(guiBuildingIds) do
        if bId == buildingId then
            local container = pGui:FindFirstChild("Container")
            local track = container and container:FindFirstChild("ProgressBarTrack")
            local fill = track and track:FindFirstChild("ProgressFill") :: Frame?

            if fill then
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(60, 220, 80)
                local fillTween = TweenService:Create(fill, TweenInfo.new(cycleDuration, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 1, 0)
                })
                animState.ActiveTween = fillTween
                fillTween:Play()
            end
        end
    end
end

local function completeBuildingCycle(buildingId: number, isAutoManager: boolean?)
    local animState = getBuildingAnimState(buildingId)
    animState.IsAutoManager = (isAutoManager == true)

    if not animState.IsFastBar then
        animState.IsCycling = false
        if animState.ActiveTween then
            animState.ActiveTween:Cancel()
            animState.ActiveTween = nil
        end

        for pGui, bId in pairs(guiBuildingIds) do
            if bId == buildingId then
                local container = pGui:FindFirstChild("Container")
                local track = container and container:FindFirstChild("ProgressBarTrack")
                local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
                local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?

                if not animState.IsAutoManager then
                    if timerLabel then timerLabel.Text = "READY" end
                    if fill then fill.Size = UDim2.new(0, 0, 1, 0) end
                end
            end
        end
    end
end

CollectEvent.OnClientEvent:Connect(function(action: string, buildingIdArg: any, cycleTimeArg: any, isAutoManagerArg: any)
    local bId = tonumber(buildingIdArg) or 1
    if action == "StartCycle" then
        local cTime = tonumber(cycleTimeArg) or 1.0
        local isAuto = (isAutoManagerArg == true)
        startBuildingCycle(bId, cTime, isAuto)
    elseif action == "CycleComplete" then
        local isAuto = (cycleTimeArg == true or isAutoManagerArg == true)
        completeBuildingCycle(bId, isAuto)
    elseif action == "FastBarActive" then
        local cTime = tonumber(cycleTimeArg) or 0.05
        local animState = getBuildingAnimState(bId)
        animState.Duration = cTime
        animState.IsFastBar = true
        animState.IsCycling = false
    end
end)

UpgradeEvent.OnClientEvent:Connect(function(action: string, buildingIdArg: any, newLevel: any, newCost: any, newYield: any, newCycleTime: any)
    if action == "UpgradeSuccess" then
        local bId = tonumber(buildingIdArg) or 1
        local cTime = tonumber(newCycleTime) or 1.0
        local animState = getBuildingAnimState(bId)
        animState.Duration = cTime

        if cTime <= 0.1 then
            animState.IsFastBar = true
            animState.IsCycling = false
        else
            animState.IsFastBar = false
        end

        for pGui, guiBId in pairs(guiBuildingIds) do
            if guiBId == bId then
                local container = pGui:FindFirstChild("Container")
                if container then
                    local moneyLabel = container:FindFirstChild("MoneyAmount") :: TextLabel?
                    local priceLabel = container:FindFirstChild("PriceText") :: TextLabel?
                    local levelLabel = container:FindFirstChild("LevelLabel") :: TextLabel?

                    if levelLabel and newLevel ~= nil then
                        levelLabel.Text = "x" .. tostring(newLevel)
                    end
                    if moneyLabel and newYield ~= nil then
                        moneyLabel.Text = EconomyMath.FormatCurrency(tonumber(newYield) or 0)
                    end
                    if priceLabel and newCost ~= nil then
                        priceLabel.Text = EconomyMath.FormatCurrency(tonumber(newCost) or 0)
                    end
                end
            end
        end
    end
end)

-- Keyboard [E] shortcut for upgrading the nearest in-range building
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        for part, pGui in pairs(activePlayerGuis) do
            if pGui and pGui.Enabled and part.Name == "CollectUpgradeGui" then
                local bId = guiBuildingIds[pGui] or 1
                local container = pGui:FindFirstChild("Container")
                local upgradeBtn = container and container:FindFirstChild("UpgradeButton")
                if upgradeBtn then playBounceAnimation(upgradeBtn) end
                UpgradeEvent:FireServer(bId, 1)
            end
        end
    end
end)

print("[CollectUpgradeClient] Multi-building dynamic time formatting & bounce safety initialized.")
