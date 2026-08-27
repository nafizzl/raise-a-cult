-- CollectUpgradeClient.local.luau
-- PlayerGui Adornee Architecture with UIScale Pop-In/Pop-Out Animations and Live Countdown Timer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local COLLECT_GUI_DISTANCE = 12 -- Studs
local BUTTON_GUI_DISTANCE = 16  -- Studs

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CollectEvent = RemoteEvents:WaitForChild("CollectEvent")
local UpgradeEvent = RemoteEvents:WaitForChild("UpgradeEvent")

local activePlayerGuis = {}
local isTargetVisible = {}
local activeTweens = {}

local isCurrentlyCycling = false
local currentCycleTime = 1.0

local function playBounceAnimation(guiObject)
    if not guiObject then return end
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

local function setGuiState(pGui, targetVisible)
    if isTargetVisible[pGui] == targetVisible then return end
    isTargetVisible[pGui] = targetVisible

    local container = pGui:FindFirstChild("Container") or pGui:FindFirstChild("Frame")
    local uiScale = container and container:FindFirstChild("UIScale")

    if not uiScale then
        pGui.Enabled = targetVisible
        return
    end

    if activeTweens[pGui] then
        activeTweens[pGui]:Cancel()
        activeTweens[pGui] = nil
    end

    if targetVisible then
        pGui.Enabled = true
        uiScale.Scale = 0
        local tween = TweenService:Create(uiScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Scale = 1
        })
        activeTweens[pGui] = tween
        tween:Play()
        tween.Completed:Connect(function()
            if activeTweens[pGui] == tween then activeTweens[pGui] = nil end
        end)
    else
        local tween = TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Scale = 0
        })
        activeTweens[pGui] = tween
        tween:Play()
        tween.Completed:Connect(function()
            if activeTweens[pGui] == tween then
                activeTweens[pGui] = nil
                if not isTargetVisible[pGui] then
                    pGui.Enabled = false
                end
            end
        end)
    end
end

local function setupPlayerGuiForPart(workspacePart)
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
            local uiScale = container:FindFirstChild("UIScale")
            if uiScale then uiScale.Scale = 0 end

            local track = container:FindFirstChild("ProgressBarTrack")
            local upgradeBtn = container:FindFirstChild("UpgradeButton")
            local fill = track and track:FindFirstChild("ProgressFill")
            local timerLabel = track and track:FindFirstChild("TimerLabel")
            local moneyLabel = container:FindFirstChild("MoneyAmount")
            local priceLabel = container:FindFirstChild("PriceText")

            if timerLabel and not isCurrentlyCycling then timerLabel.Text = "READY" end
            if fill and not isCurrentlyCycling then fill.Size = UDim2.new(0, 0, 1, 0) end
            if moneyLabel and (moneyLabel.Text == "$51.315" or moneyLabel.Text == "Label") then moneyLabel.Text = "$1" end
            if priceLabel and (priceLabel.Text == "$13.886" or priceLabel.Text == "Label") then priceLabel.Text = "$10" end

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

                btn.Activated:Connect(function()
                    if not isCurrentlyCycling then
                        playBounceAnimation(track)
                        CollectEvent:FireServer()
                    end
                end)
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

                btn.Activated:Connect(function()
                    playBounceAnimation(upgradeBtn)
                    UpgradeEvent:FireServer()
                end)
            end
        end

        activePlayerGuis[workspacePart] = clonedBb
    end

    return activePlayerGuis[workspacePart]
end

RunService.Heartbeat:Connect(function()
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    for part, gui in pairs(activePlayerGuis) do
        if not part or not part:IsDescendantOf(workspace) then
            isTargetVisible[gui] = nil
            activeTweens[gui] = nil
            gui:Destroy()
            activePlayerGuis[part] = nil
        end
    end

    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == "CollectUpgradeGui" or part.Name == "PricingTag") then
            local pGui = setupPlayerGuiForPart(part)
            if pGui then
                local maxDist = (part.Name == "CollectUpgradeGui") and COLLECT_GUI_DISTANCE or BUTTON_GUI_DISTANCE
                if hrp then
                    local distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(part.Position.X, 0, part.Position.Z)).Magnitude
                    setGuiState(pGui, distance <= maxDist)
                else
                    setGuiState(pGui, false)
                end
            end
        end
    end
end)

local activeCountdownConn = nil
local function startCycleAnimation(cycleTime)
    isCurrentlyCycling = true
    local startTime = os.clock()

    if activeCountdownConn then
        activeCountdownConn:Disconnect()
        activeCountdownConn = nil
    end

    for _, pGui in pairs(activePlayerGuis) do
        local container = pGui:FindFirstChild("Container") or pGui:FindFirstChild("Frame")
        local track = container and container:FindFirstChild("ProgressBarTrack")
        local fill = track and track:FindFirstChild("ProgressFill")
        local timerLabel = track and track:FindFirstChild("TimerLabel")

        if fill and track then
            if cycleTime <= 0.1 then
                fill.Size = UDim2.new(1, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(80, 240, 90)
                if timerLabel then timerLabel.Text = "FAST" end
            else
                fill.Size = UDim2.new(0, 0, 1, 0)

                local fillTween = TweenService:Create(fill, TweenInfo.new(cycleTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 1, 0)
                })
                fillTween:Play()

                activeCountdownConn = RunService.RenderStepped:Connect(function()
                    local elapsed = os.clock() - startTime
                    local remaining = math.max(0, cycleTime - elapsed)
                    if timerLabel then
                        timerLabel.Text = string.format("%.1fs", remaining)
                    end
                    if elapsed >= cycleTime then
                        if activeCountdownConn then
                            activeCountdownConn:Disconnect()
                            activeCountdownConn = nil
                        end
                        if timerLabel then timerLabel.Text = "READY" end
                        fill.Size = UDim2.new(0, 0, 1, 0)
                        isCurrentlyCycling = false
                    end
                end)
            end
        end
    end
end

CollectEvent.OnClientEvent:Connect(function(action, cycleTime)
    if action == "StartCycle" then
        startCycleAnimation(cycleTime or currentCycleTime)
    elseif action == "CycleComplete" then
        isCurrentlyCycling = false
        if activeCountdownConn then
            activeCountdownConn:Disconnect()
            activeCountdownConn = nil
        end
        for _, pGui in pairs(activePlayerGuis) do
            local container = pGui:FindFirstChild("Container") or pGui:FindFirstChild("Frame")
            local track = container and container:FindFirstChild("ProgressBarTrack")
            local fill = track and track:FindFirstChild("ProgressFill")
            local timerLabel = track and track:FindFirstChild("TimerLabel")

            if timerLabel then timerLabel.Text = "READY" end
            if fill then fill.Size = UDim2.new(0, 0, 1, 0) end
        end
    end
end)

UpgradeEvent.OnClientEvent:Connect(function(action, newLevel, newCost, newYield, newCycleTime)
    if action == "UpgradeSuccess" then
        currentCycleTime = newCycleTime
        for _, pGui in pairs(activePlayerGuis) do
            local container = pGui:FindFirstChild("Container")
            if container then
                local moneyLabel = container:FindFirstChild("MoneyAmount")
                local priceLabel = container:FindFirstChild("PriceText")

                if moneyLabel then moneyLabel.Text = "$" .. tostring(newYield) end
                if priceLabel then priceLabel.Text = "$" .. tostring(newCost) end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        for part, pGui in pairs(activePlayerGuis) do
            if pGui and pGui.Enabled then
                local container = pGui:FindFirstChild("Container") or pGui:FindFirstChild("Frame")
                local upgradeBtn = container and container:FindFirstChild("UpgradeButton")
                if upgradeBtn then playBounceAnimation(upgradeBtn) end
                UpgradeEvent:FireServer()
            end
        end
    end
end)

print("[CollectUpgradeClient] Restored smooth UIScale Pop-In/Pop-Out animations!")
