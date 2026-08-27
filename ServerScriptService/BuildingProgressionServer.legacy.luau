-- BuildingProgressionServer.luau
-- Corrected tree mapping, table welding, and ClickDetector manual tapping

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MoneyManager = require(ServerScriptService:WaitForChild("MoneyManager"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockStageEvent = RemoteEvents:WaitForChild("UnlockStage")

local templatesFolder = ReplicatedStorage:FindFirstChild("BuildingTemplates")
if not templatesFolder then
    templatesFolder = Instance.new("Folder")
    templatesFolder.Name = "BuildingTemplates"
    templatesFolder.Parent = ReplicatedStorage
end

local b1Templates = templatesFolder:FindFirstChild("Building1")
if not b1Templates then
    b1Templates = Instance.new("Folder")
    b1Templates.Name = "Building1"
    b1Templates.Parent = templatesFolder
end

local b1Folder = workspace.CultTycoon.Building1
local newBuildingBtnFolder = b1Folder:FindFirstChild("NewBuildingButton")
local preacherFolder = b1Folder:FindFirstChild("StreetPreacherBuilding")

local tableModel = preacherFolder and preacherFolder:FindFirstChild("Table")
local cultMemberModel = preacherFolder and (preacherFolder:FindFirstChild("Cult Member") or preacherFolder:FindFirstChild("PlayerModel"))
local collectGuiPart = preacherFolder and preacherFolder:FindFirstChild("CollectUpgradeGui")

local flyersFolder = preacherFolder and preacherFolder:FindFirstChild("Flyers")
local flyersBtnFolder = flyersFolder and flyersFolder:FindFirstChild("UpgradeButton")

local preachersFolder = preacherFolder and preacherFolder:FindFirstChild("MorePreachers")
local preachersBtnFolder = preachersFolder and preachersFolder:FindFirstChild("UpgradeButton")

local managerBtnFolder = preacherFolder and preacherFolder:FindFirstChild("ManagerButton")

if tableModel then tableModel.Parent = b1Templates end
if cultMemberModel then cultMemberModel.Parent = b1Templates end
if collectGuiPart then collectGuiPart.Parent = b1Templates end

if flyersFolder then flyersFolder.Parent = b1Templates end
if flyersBtnFolder then flyersBtnFolder.Parent = b1Templates end

if preachersFolder then preachersFolder.Parent = b1Templates end
if preachersBtnFolder then preachersBtnFolder.Parent = b1Templates end

if managerBtnFolder then managerBtnFolder.Parent = b1Templates end

if newBuildingBtnFolder then newBuildingBtnFolder.Parent = b1Folder end

if collectGuiPart then
    local detector = collectGuiPart:FindFirstChildWhichIsA("ClickDetector")
    if not detector then
        detector = Instance.new("ClickDetector")
        detector.MaxActivationDistance = 16
        detector.Parent = collectGuiPart
    end

    detector.MouseClick:Connect(function(player)
        local CollectEvent = RemoteEvents:FindFirstChild("CollectEvent")
        if CollectEvent and _G.ProductionEngine then
            local data = _G.ProductionEngine.GetPlayerData(player)
            if not data.IsCycling and not data.HasManager then
                data.IsCycling = true
                local cycleTime = _G.ProductionEngine.CalculateCycleTime(data)
                CollectEvent:FireClient(player, "StartCycle", cycleTime)

                task.delay(cycleTime, function()
                    data.IsCycling = false
                    local yieldAmount = _G.ProductionEngine.CalculateYield(data)
                    MoneyManager.AddMoney(player, yieldAmount)
                    CollectEvent:FireClient(player, "CycleComplete")
                end)
            end
        end
    end)
end

local FLYERS_COST = 150
local PREACHERS_COST = 500
local MANAGER_COST = 10000

local function setupTouchButton(buttonFolder, cost, unlockName, callback)
    if not buttonFolder then return end

    local btnPart = buttonFolder:FindFirstChild("Button")
    if btnPart and btnPart:IsA("Model") then
        btnPart = btnPart:FindFirstChild("Button") or btnPart
    end
    if not btnPart then return end

    local debounce = false
    btnPart.Touched:Connect(function(hit)
        if debounce then return end
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        debounce = true

        if cost == 0 or MoneyManager.DeductMoney(player, cost) then
            print("[BuildingProgression] " .. player.Name .. " unlocked: " .. unlockName)

            buttonFolder.Parent = b1Templates

            if callback then
                callback(player)
            end

            UnlockStageEvent:FireClient(player, unlockName)
        else
            task.wait(0.5)
        end

        debounce = false
    end)
end

setupTouchButton(newBuildingBtnFolder, 0, "BaseStage", function(player)
    if tableModel then tableModel.Parent = preacherFolder end
    if cultMemberModel then cultMemberModel.Parent = preacherFolder end
    if collectGuiPart then collectGuiPart.Parent = preacherFolder end

    if flyersBtnFolder then flyersBtnFolder.Parent = preacherFolder end
end)

setupTouchButton(flyersBtnFolder, FLYERS_COST, "FlyersStage", function(player)
    if _G.ProductionEngine then
        local data = _G.ProductionEngine.GetPlayerData(player)
        data.FlyersUnlocked = true
    end

    if flyersFolder then flyersFolder.Parent = preacherFolder end

    if preachersBtnFolder then preachersBtnFolder.Parent = preacherFolder end
end)

setupTouchButton(preachersBtnFolder, PREACHERS_COST, "MorePreachersStage", function(player)
    if _G.ProductionEngine then
        local data = _G.ProductionEngine.GetPlayerData(player)
        data.MorePreachersUnlocked = true
    end

    if preachersFolder then preachersFolder.Parent = preacherFolder end

    if managerBtnFolder then managerBtnFolder.Parent = preacherFolder end
end)

setupTouchButton(managerBtnFolder, MANAGER_COST, "ManagerStage", function(player)
    if _G.ProductionEngine then
        local data = _G.ProductionEngine.GetPlayerData(player)
        data.HasManager = true
        print("[BuildingProgression] Manager hired for " .. player.Name .. "! Auto-collection active.")
    end
end)

print("[BuildingProgressionServer] Final fixed progression and ClickDetector server handler.")
