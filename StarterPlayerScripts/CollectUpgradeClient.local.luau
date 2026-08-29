--!strict
-- CollectUpgradeClient.local.luau
-- Robust PlayerGui Adornee Architecture with Proximity Hysteresis, Live Countdown Timer & Fast-Bar Animation.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyFolder = ReplicatedStorage:WaitForChild("Economy")
local EconomyMath = require(ReplicatedStorage.Economy.EconomyMath)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Distance Hysteresis thresholds to eliminate boundary jitter/collapsing
local COLLECT_IN_DIST = 14  -- Studs to pop in
local COLLECT_OUT_DIST = 18 -- Studs to pop out
local BUTTON_IN_DIST = 16   -- Studs to pop in
local BUTTON_OUT_DIST = 20  -- Studs to pop out

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectEvent = RemoteEvents:WaitForChild("CollectEvent") :: RemoteEvent
local UpgradeEvent = RemoteEvents:WaitForChild("UpgradeEvent") :: RemoteEvent

local activePlayerGuis: { [BasePart]: BillboardGui } = {}
local isGuiVisible: { [BillboardGui]: boolean } = {}
local activeTweens: { [BillboardGui]: Tween } = {}

local isCurrentlyCycling = false
local currentCycleTime = 1.0
local isFastBarActive = false

local function playBounceAnimation(guiObject: Instance?)
    if not guiObject or not guiObject:IsA("GuiObject") then return end
    local originalSize = guiObject.Size
    local bounceSize = UDim2.new(
        originalSize.X.Scale, originalSize.X.Offset + 6,
        originalSize.Y.Scale, originalSize.Y.Offset + 4
    )

    local tweenUp = TweenService:Create(guiObject, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = bounceSize
    })
    tweenUp:Play()
    tweenUp.Completed:Connect(function()
        local tweenDown = TweenService:Create(guiObject, TweenInfo.new(0.12, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
            Size = originalSize
        })
        tweenDown:Play()
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
        clonedBb.AlwaysOnTop = true
        clonedBb.Active = true
        clonedBb.Enabled = false
        clonedBb.StudsOffset = Vector3.new(0, 2.5, 0)
        clonedBb.Parent = playerGui

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
            local fill = track and track:FindFirstChild("ProgressFill")
            local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?
            local moneyLabel = container:FindFirstChild("MoneyAmount") :: TextLabel?
            local priceLabel = container:FindFirstChild("PriceText") :: TextLabel?

            -- Initialize default display values from Building 1 config ($1 yield, $4 upgrade cost)
            if timerLabel and not isCurrentlyCycling then timerLabel.Text = "READY" end
            if fill and not isCurrentlyCycling and fill:IsA("GuiObject") then fill.Size = UDim2.new(0, 0, 1, 0) end
            if moneyLabel then moneyLabel.Text = "$1" end
            if priceLabel then priceLabel.Text = "$4" end

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
                        if not isCurrentlyCycling and not isFastBarActive then
                            playBounceAnimation(track)
                            CollectEvent:FireServer(1)
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
                        UpgradeEvent:FireServer(1, 1) -- Building 1, Amount 1
                    end)
                end
            end
        end

        activePlayerGuis[workspacePart] = clonedBb
    end

    return activePlayerGuis[workspacePart]
end

-- Cached Proximity Scanning
local scanCooldown = 0
RunService.Heartbeat:Connect(function(dt: number)
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

    -- Clean up destroyed or unparented adornees
    for part, gui in pairs(activePlayerGuis) do
        if not part or not part:IsDescendantOf(workspace) then
            isGuiVisible[gui] = nil
            if activeTweens[gui] then activeTweens[gui]:Cancel() end
            activeTweens[gui] = nil
            gui:Destroy()
            activePlayerGuis[part] = nil
        end
    end

    -- Discover new billboard adornee parts every 0.3s
    scanCooldown = scanCooldown + dt
    if scanCooldown >= 0.3 then
        scanCooldown = 0
        local cultTycoon = workspace:FindFirstChild("CultTycoon") or workspace
        for _, part in ipairs(cultTycoon:GetDescendants()) do
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

-- Progress Bar & Fast-Bar Animation
local activeCountdownConn: RBXScriptConnection? = nil
local fastBarAnimConn: RBXScriptConnection? = nil

local function setFastBarVisuals(active: boolean)
    isFastBarActive = active
    if active then
        isCurrentlyCycling = false
        if activeCountdownConn then
            activeCountdownConn:Disconnect()
            activeCountdownConn = nil
        end

        for _, pGui in pairs(activePlayerGuis) do
            local container = pGui:FindFirstChild("Container")
            local track = container and container:FindFirstChild("ProgressBarTrack")
            local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
            local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?

            if fill and track then
                fill.Size = UDim2.new(1, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(70, 245, 100)
                if timerLabel then timerLabel.Text = "FAST" end
            end
        end

        if not fastBarAnimConn then
            local pulseTime = 0
            fastBarAnimConn = RunService.RenderStepped:Connect(function(stepDt: number)
                pulseTime = pulseTime + (stepDt * 4)
                local pulse = 0.85 + (math.sin(pulseTime) * 0.15)
                for _, pGui in pairs(activePlayerGuis) do
                    local container = pGui:FindFirstChild("Container")
                    local track = container and container:FindFirstChild("ProgressBarTrack")
                    local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
                    if fill and isFastBarActive then
                        fill.BackgroundColor3 = Color3.fromRGB(math.floor(50 * pulse), math.floor(245 * pulse), math.floor(90 * pulse))
                    end
                end
            end)
        end
    else
        if fastBarAnimConn then
            fastBarAnimConn:Disconnect()
            fastBarAnimConn = nil
        end
        for _, pGui in pairs(activePlayerGuis) do
            local container = pGui:FindFirstChild("Container")
            local track = container and container:FindFirstChild("ProgressBarTrack")
            local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
            if fill then
                fill.BackgroundColor3 = Color3.fromRGB(60, 220, 80)
            end
        end
    end
end

local function startCycleAnimation(cycleTime: number)
    if cycleTime <= 0.1 then
        setFastBarVisuals(true)
        return
    else
        setFastBarVisuals(false)
    end

    isCurrentlyCycling = true
    local startTime = os.clock()

    if activeCountdownConn then
        activeCountdownConn:Disconnect()
        activeCountdownConn = nil
    end

    for _, pGui in pairs(activePlayerGuis) do
        local container = pGui:FindFirstChild("Container")
        local track = container and container:FindFirstChild("ProgressBarTrack")
        local fill = track and track:FindFirstChild("ProgressFill")

        if fill and track and fill:IsA("GuiObject") then
            fill.Size = UDim2.new(0, 0, 1, 0)
            local fillTween = TweenService:Create(fill, TweenInfo.new(cycleTime, Enum.EasingStyle.Linear), {
                Size = UDim2.new(1, 0, 1, 0)
            })
            fillTween:Play()
        end
    end

    activeCountdownConn = RunService.RenderStepped:Connect(function()
        local elapsed = os.clock() - startTime
        local remaining = math.max(0, cycleTime - elapsed)

        for _, pGui in pairs(activePlayerGuis) do
            local container = pGui:FindFirstChild("Container")
            local track = container and container:FindFirstChild("ProgressBarTrack")
            local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?
            if timerLabel then
                timerLabel.Text = string.format("%.1fs", remaining)
            end
        end

        if elapsed >= cycleTime then
            if activeCountdownConn then
                activeCountdownConn:Disconnect()
                activeCountdownConn = nil
            end
            for _, pGui in pairs(activePlayerGuis) do
                local container = pGui:FindFirstChild("Container")
                local track = container and container:FindFirstChild("ProgressBarTrack")
                local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
                local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?

                if timerLabel then timerLabel.Text = "READY" end
                if fill then fill.Size = UDim2.new(0, 0, 1, 0) end
            end
            isCurrentlyCycling = false
        end
    end)
end

CollectEvent.OnClientEvent:Connect(function(action: string, buildingId: any, cycleTime: any)
    if action == "StartCycle" then
        local cTime = tonumber(cycleTime) or currentCycleTime
        startCycleAnimation(cTime)
    elseif action == "CycleComplete" then
        if not isFastBarActive then
            isCurrentlyCycling = false
            if activeCountdownConn then
                activeCountdownConn:Disconnect()
                activeCountdownConn = nil
            end
            for _, pGui in pairs(activePlayerGuis) do
                local container = pGui:FindFirstChild("Container")
                local track = container and container:FindFirstChild("ProgressBarTrack")
                local fill = track and track:FindFirstChild("ProgressFill") :: Frame?
                local timerLabel = track and track:FindFirstChild("TimerLabel") :: TextLabel?

                if timerLabel then timerLabel.Text = "READY" end
                if fill then fill.Size = UDim2.new(0, 0, 1, 0) end
            end
        end
    end
end)

UpgradeEvent.OnClientEvent:Connect(function(action: string, buildingId: any, newLevel: any, newCost: any, newYield: any, newCycleTime: any)
    if action == "UpgradeSuccess" then
        currentCycleTime = tonumber(newCycleTime) or currentCycleTime
        if currentCycleTime <= 0.1 then
            setFastBarVisuals(true)
        else
            setFastBarVisuals(false)
        end

        for _, pGui in pairs(activePlayerGuis) do
            local container = pGui:FindFirstChild("Container")
            if container then
                local moneyLabel = container:FindFirstChild("MoneyAmount") :: TextLabel?
                local priceLabel = container:FindFirstChild("PriceText") :: TextLabel?

                if moneyLabel and newYield ~= nil then
                    moneyLabel.Text = EconomyMath.FormatCurrency(tonumber(newYield) or 0)
                end
                if priceLabel and newCost ~= nil then
                    priceLabel.Text = EconomyMath.FormatCurrency(tonumber(newCost) or 0)
                end
            end
        end
    end
end)

-- Keyboard [E] shortcut for upgrading
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        for part, pGui in pairs(activePlayerGuis) do
            if pGui and pGui.Enabled and part.Name == "CollectUpgradeGui" then
                local container = pGui:FindFirstChild("Container")
                local upgradeBtn = container and container:FindFirstChild("UpgradeButton")
                if upgradeBtn then playBounceAnimation(upgradeBtn) end
                UpgradeEvent:FireServer(1, 1)
            end
        end
    end
end)

print("[CollectUpgradeClient] Initialized with distance hysteresis, fast-bar visuals, and economy formatting.")
