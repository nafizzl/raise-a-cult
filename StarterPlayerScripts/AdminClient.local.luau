--!strict
-- AdminClient.local.luau
-- Sleek developer command console with floating toggle button and custom keybinds.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local AdminFunction = RemoteEvents and (RemoteEvents:FindFirstChild("AdminFunction") or RemoteEvents:WaitForChild("AdminFunction", 10)) :: RemoteFunction?

-- Create ScreenGui immediately
local adminScreenGui = Instance.new("ScreenGui")
adminScreenGui.Name = "AdminConsoleGui"
adminScreenGui.ResetOnSpawn = false
adminScreenGui.DisplayOrder = 999
adminScreenGui.Parent = playerGui

-- Floating Quick-Open Button (Top Right corner)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "DevToggleBtn"
toggleBtn.Size = UDim2.new(0, 80, 0, 32)
toggleBtn.Position = UDim2.new(1, -95, 0, 14)
toggleBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
toggleBtn.BackgroundTransparency = 0.15
toggleBtn.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
toggleBtn.Text = "⚙ DEV"
toggleBtn.TextSize = 14
toggleBtn.TextColor3 = Color3.fromRGB(255, 234, 0)
toggleBtn.Active = true
toggleBtn.Parent = adminScreenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Thickness = 2
toggleStroke.Color = Color3.fromRGB(110, 72, 191)
toggleStroke.Parent = toggleBtn

-- Top Container Frame
local consoleFrame = Instance.new("Frame")
consoleFrame.Name = "ConsoleFrame"
consoleFrame.AnchorPoint = Vector2.new(0.5, 0)
consoleFrame.Position = UDim2.new(0.5, 0, 0, -120) -- Hidden above screen
consoleFrame.Size = UDim2.new(0, 560, 0, 50)
consoleFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
consoleFrame.BackgroundTransparency = 0.1
consoleFrame.BorderSizePixel = 0
consoleFrame.Visible = false
consoleFrame.Parent = adminScreenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 10)
frameCorner.Parent = consoleFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(110, 72, 191)
frameStroke.Parent = consoleFrame

-- Command Prefix Icon
local prefixLabel = Instance.new("TextLabel")
prefixLabel.Name = "Prefix"
prefixLabel.Size = UDim2.new(0, 36, 1, 0)
prefixLabel.Position = UDim2.new(0, 8, 0, 0)
prefixLabel.BackgroundTransparency = 1
prefixLabel.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
prefixLabel.Text = ">"
prefixLabel.TextSize = 22
prefixLabel.TextColor3 = Color3.fromRGB(255, 234, 0)
prefixLabel.Parent = consoleFrame

-- Command Input TextBox
local commandInput = Instance.new("TextBox")
commandInput.Name = "CommandInput"
commandInput.Size = UDim2.new(1, -130, 1, -12)
commandInput.Position = UDim2.new(0, 42, 0, 6)
commandInput.BackgroundTransparency = 1
commandInput.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)
commandInput.PlaceholderText = "Type command (e.g. :give 1M, :set 50B, :unlockall, :help)..."
commandInput.PlaceholderColor3 = Color3.fromRGB(140, 140, 160)
commandInput.Text = ""
commandInput.TextSize = 16
commandInput.TextColor3 = Color3.fromRGB(255, 255, 255)
commandInput.TextXAlignment = Enum.TextXAlignment.Left
commandInput.ClearTextOnFocus = false
commandInput.Parent = consoleFrame

-- Run Button
local runBtn = Instance.new("TextButton")
runBtn.Name = "RunButton"
runBtn.Size = UDim2.new(0, 70, 0, 34)
runBtn.Position = UDim2.new(1, -80, 0, 8)
runBtn.BackgroundColor3 = Color3.fromRGB(110, 72, 191)
runBtn.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
runBtn.Text = "RUN"
runBtn.TextSize = 14
runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runBtn.Parent = consoleFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = runBtn

-- Feedback Banner
local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "FeedbackLabel"
feedbackLabel.AnchorPoint = Vector2.new(0.5, 0)
feedbackLabel.Position = UDim2.new(0.5, 0, 0, 58)
feedbackLabel.Size = UDim2.new(0, 560, 0, 28)
feedbackLabel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
feedbackLabel.BackgroundTransparency = 0.2
feedbackLabel.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)
feedbackLabel.Text = ""
feedbackLabel.TextSize = 13
feedbackLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
feedbackLabel.Visible = false
feedbackLabel.Parent = consoleFrame

local fbCorner = Instance.new("UICorner")
fbCorner.CornerRadius = UDim.new(0, 6)
fbCorner.Parent = feedbackLabel

local isConsoleOpen = false

local function toggleConsole(open: boolean?)
    if open == nil then
        isConsoleOpen = not isConsoleOpen
    else
        isConsoleOpen = open
    end

    if isConsoleOpen then
        consoleFrame.Visible = true
        consoleFrame.Position = UDim2.new(0.5, 0, 0, -120)
        local tween = TweenService:Create(consoleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 16)
        })
        tween:Play()
        task.delay(0.1, function()
            commandInput:CaptureFocus()
        end)
    else
        local tween = TweenService:Create(consoleFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -120)
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not isConsoleOpen then
                consoleFrame.Visible = false
                feedbackLabel.Visible = false
            end
        end)
    end
end

local function executeCommand()
    local text = commandInput.Text
    if #text == 0 then return end

    if not AdminFunction then
        AdminFunction = RemoteEvents and RemoteEvents:FindFirstChild("AdminFunction") :: RemoteFunction?
    end

    if not AdminFunction then
        feedbackLabel.Visible = true
        feedbackLabel.Text = "Error: AdminFunction not connected on server."
        feedbackLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end

    local success, response = AdminFunction:InvokeServer(text)

    feedbackLabel.Visible = true
    feedbackLabel.Text = tostring(response)
    if success then
        feedbackLabel.TextColor3 = Color3.fromRGB(80, 255, 120) -- Green
        commandInput.Text = ""
    else
        feedbackLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- Red
    end

    task.delay(4.0, function()
        if feedbackLabel.Text == tostring(response) then
            feedbackLabel.Visible = false
        end
    end)
end

toggleBtn.Activated:Connect(function()
    toggleConsole()
end)

runBtn.Activated:Connect(executeCommand)

commandInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        executeCommand()
    end
end)

-- Keybind Listeners (F4, Semicolon ';', or RightBracket ']')
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.F4 or input.KeyCode == Enum.KeyCode.Semicolon or input.KeyCode == Enum.KeyCode.RightBracket then
        if not gameProcessed or not commandInput:IsFocused() then
            toggleConsole()
        end
    elseif input.KeyCode == Enum.KeyCode.Escape and isConsoleOpen then
        toggleConsole(false)
    end
end)

print("[AdminClient] Developer console initialized with floating '⚙ DEV' button.")
