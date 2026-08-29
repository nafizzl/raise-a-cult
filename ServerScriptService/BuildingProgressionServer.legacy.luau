--!strict
-- BuildingProgressionServer.luau
-- Dynamic per-player floor button unlocks, template management, manager models storage, and stage progression.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyConfig") :: any)
local EconomyMath = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyMath") :: any)
local MoneyManager = require(ServerScriptService:WaitForChild("MoneyManager") :: any)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockStageEvent = RemoteEvents:WaitForChild("UnlockStage") :: RemoteEvent
local CollectEvent = RemoteEvents:WaitForChild("CollectEvent") :: RemoteEvent

-- Ensure template folders exist in ReplicatedStorage
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

local managerTemplates = b1Templates:FindFirstChild("Manager")
if not managerTemplates then
    managerTemplates = Instance.new("Folder")
    managerTemplates.Name = "Manager"
    managerTemplates.Parent = b1Templates
end

local cultTycoon = workspace:WaitForChild("CultTycoon", 10) or workspace
local b1Folder = cultTycoon:FindFirstChild("Building1")
local preacherFolder = b1Folder and b1Folder:FindFirstChild("StreetPreacherBuilding")
local newBuildingBtnFolder = b1Folder and b1Folder:FindFirstChild("NewBuildingButton")

-- Locate Building 1 structural elements
local tableModel = preacherFolder and preacherFolder:FindFirstChild("Table")
local cultMemberModel = preacherFolder and (preacherFolder:FindFirstChild("Cult Member") or preacherFolder:FindFirstChild("PlayerModel"))
local collectGuiPart = preacherFolder and preacherFolder:FindFirstChild("CollectUpgradeGui")
local flyersFolder = preacherFolder and preacherFolder:FindFirstChild("Flyers")
local flyersBtnFolder = flyersFolder and flyersFolder:FindFirstChild("UpgradeButton")
local preachersFolder = preacherFolder and preacherFolder:FindFirstChild("MorePreachers")
local preachersBtnFolder = preachersFolder and preachersFolder:FindFirstChild("UpgradeButton")

local managerFolder = preacherFolder and preacherFolder:FindFirstChild("Manager")
local managerBtnFolder = (managerFolder and managerFolder:FindFirstChild("ManagerButton")) or (preacherFolder and preacherFolder:FindFirstChild("ManagerButton"))

-- Dynamically stash all Manager props (Table, Cult Member, MoneyonTable, etc.) into template storage
if managerFolder then
    for _, child in ipairs(managerFolder:GetChildren()) do
        if child.Name ~= "ManagerButton" then
            child.Parent = managerTemplates
        end
    end
end

-- Store other unbuilt elements in template storage on server start
if tableModel and tableModel.Parent ~= b1Templates then tableModel.Parent = b1Templates end
if cultMemberModel and cultMemberModel.Parent ~= b1Templates then cultMemberModel.Parent = b1Templates end
if collectGuiPart and collectGuiPart.Parent ~= b1Templates then collectGuiPart.Parent = b1Templates end
if flyersFolder and flyersFolder.Parent ~= b1Templates then flyersFolder.Parent = b1Templates end
if flyersBtnFolder and flyersBtnFolder.Parent ~= b1Templates then flyersBtnFolder.Parent = b1Templates end
if preachersFolder and preachersFolder.Parent ~= b1Templates then preachersFolder.Parent = b1Templates end
if preachersBtnFolder and preachersBtnFolder.Parent ~= b1Templates then preachersBtnFolder.Parent = b1Templates end

if managerBtnFolder and managerBtnFolder.Parent ~= b1Templates then managerBtnFolder.Parent = b1Templates end

if newBuildingBtnFolder and b1Folder then newBuildingBtnFolder.Parent = b1Folder end

-- Dynamic Costs for Building 1 Progression from EconomyConfig
local FLYERS_COST = math.floor(EconomyConfig.FloorUpgradeCostMultipliers[1] * EconomyConfig.Buildings[1].BaseCost) -- $30
local PREACHERS_COST = math.floor(EconomyConfig.FloorUpgradeCostMultipliers[2] * EconomyConfig.Buildings[1].BaseCost) -- $375
local MANAGER_COST = EconomyConfig.Buildings[1].ManagerCost -- $250

-- Robust Touch Button Handler with accessory support and per-player debounce
local playerDebounce: { [Player]: { [string]: boolean } } = {}

local function setupTouchButton(buttonFolder: Instance?, cost: number, unlockName: string, callback: ((Player) -> ())?)
    if not buttonFolder then return end

    local btnPart: Instance? = buttonFolder:FindFirstChild("Button", true)
    if btnPart and btnPart:IsA("Model") then
        btnPart = btnPart:FindFirstChild("Button") or btnPart:FindFirstChildWhichIsA("BasePart")
    end
    if not btnPart or not btnPart:IsA("BasePart") then return end

    btnPart.Touched:Connect(function(hit: BasePart)
        local character = hit:FindFirstAncestorWhichIsA("Model")
        if not character then return end

        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        if not playerDebounce[player] then playerDebounce[player] = {} end
        if playerDebounce[player][unlockName] then return end

        playerDebounce[player][unlockName] = true

        if cost == 0 or MoneyManager.DeductMoney(player, cost) then
            print(string.format("[BuildingProgression] %s unlocked %s (Cost: %s)",
                player.Name, unlockName, EconomyMath.FormatCurrency(cost)))

            -- Remove bought button from Workspace immediately so it de-renders and cannot be touched again
            buttonFolder.Parent = b1Templates

            if callback then
                callback(player)
            end

            if player:IsDescendantOf(Players) then
                UnlockStageEvent:FireClient(player, unlockName)
            end
        else
            task.wait(0.4)
        end

        task.delay(0.5, function()
            if playerDebounce[player] then
                playerDebounce[player][unlockName] = nil
            end
        end)
    end)
end

-- Helper to safely mount manager button into workspace
local function showManagerButton()
    if not managerBtnFolder then return end
    if not managerFolder or not managerFolder:IsDescendantOf(workspace) then
        if preacherFolder then
            managerFolder = preacherFolder:FindFirstChild("Manager") or Instance.new("Folder")
            managerFolder.Name = "Manager"
            managerFolder.Parent = preacherFolder
        end
    end
    if managerFolder and managerFolder:IsDescendantOf(workspace) then
        managerBtnFolder.Parent = managerFolder
    elseif preacherFolder then
        managerBtnFolder.Parent = preacherFolder
    end
end

-- Helper to safely spawn all manager models when purchased
local function spawnManagerModels()
    if preacherFolder then
        if not managerFolder or not managerFolder:IsDescendantOf(workspace) then
            managerFolder = preacherFolder:FindFirstChild("Manager") or Instance.new("Folder")
            managerFolder.Name = "Manager"
            managerFolder.Parent = preacherFolder
        end
        if managerTemplates then
            for _, child in ipairs(managerTemplates:GetChildren()) do
                child.Parent = managerFolder
            end
        end
    end
end

-- Setup Stage 0: Initial Building Spawn ($0)
setupTouchButton(newBuildingBtnFolder, 0, "BaseStage", function(player: Player)
    local bState = MoneyManager.GetBuildingState(player, 1)
    if bState.OwnedCount <= 0 then
        bState.OwnedCount = 1
    end

    -- Parent base models, first upgrade button, and Manager button to workspace
    if preacherFolder then
        if tableModel then tableModel.Parent = preacherFolder end
        if cultMemberModel then cultMemberModel.Parent = preacherFolder end
        if collectGuiPart then collectGuiPart.Parent = preacherFolder end
        if flyersBtnFolder and not bState.FloorUpgrades[1] then
            flyersBtnFolder.Parent = preacherFolder
        end
        if not bState.HasManager then
            showManagerButton()
        end
    end
end)

-- Setup Stage 1: Flyers / Floor Upgrade 1 ($30, 2x Speed)
setupTouchButton(flyersBtnFolder, FLYERS_COST, "FlyersStage", function(player: Player)
    MoneyManager.UnlockFloorUpgrade(player, 1, 1)

    if preacherFolder then
        if flyersFolder then flyersFolder.Parent = preacherFolder end
        if preachersBtnFolder then preachersBtnFolder.Parent = preacherFolder end
    end
end)

-- Setup Stage 2: More Preachers / Floor Upgrade 2 ($375, 2x Speed)
setupTouchButton(preachersBtnFolder, PREACHERS_COST, "MorePreachersStage", function(player: Player)
    MoneyManager.UnlockFloorUpgrade(player, 1, 2)

    if preacherFolder then
        if preachersFolder then preachersFolder.Parent = preacherFolder end
    end
end)

-- Setup Manager ($250, Automation)
setupTouchButton(managerBtnFolder, MANAGER_COST, "ManagerStage", function(player: Player)
    MoneyManager.SetManagerOwned(player, 1, true)
    spawnManagerModels()
    print("[BuildingProgression] Manager hired for " .. player.Name .. "! Auto-collection active.")
end)

-- Restore existing unlocked progression on player join
local function restorePlayerProgression(player: Player)
    local bState = MoneyManager.GetBuildingState(player, 1)

    if bState.OwnedCount <= 0 then
        -- New player: Show only the NewBuildingButton, hide all building structures & subsequent buttons
        if newBuildingBtnFolder and b1Folder then newBuildingBtnFolder.Parent = b1Folder end
        if tableModel then tableModel.Parent = b1Templates end
        if cultMemberModel then cultMemberModel.Parent = b1Templates end
        if collectGuiPart then collectGuiPart.Parent = b1Templates end
        if flyersBtnFolder then flyersBtnFolder.Parent = b1Templates end
        if flyersFolder then flyersFolder.Parent = b1Templates end
        if preachersBtnFolder then preachersBtnFolder.Parent = b1Templates end
        if preachersFolder then preachersFolder.Parent = b1Templates end
        if managerBtnFolder then managerBtnFolder.Parent = b1Templates end
        if managerTemplates and managerFolder then
            for _, child in ipairs(managerFolder:GetChildren()) do
                if child.Name ~= "ManagerButton" then
                    child.Parent = managerTemplates
                end
            end
        end
        return
    end

    -- Returning player who already purchased Building 1:
    if newBuildingBtnFolder then newBuildingBtnFolder.Parent = b1Templates end
    if preacherFolder then
        if tableModel then tableModel.Parent = preacherFolder end
        if cultMemberModel then cultMemberModel.Parent = preacherFolder end
        if collectGuiPart then collectGuiPart.Parent = preacherFolder end
        if flyersBtnFolder and not bState.FloorUpgrades[1] then
            flyersBtnFolder.Parent = preacherFolder
        end
        if not bState.HasManager then
            showManagerButton()
        end
    end

    if bState.FloorUpgrades[1] then
        if flyersBtnFolder then flyersBtnFolder.Parent = b1Templates end
        if preacherFolder then
            if flyersFolder then flyersFolder.Parent = preacherFolder end
            if preachersBtnFolder and not bState.FloorUpgrades[2] then
                preachersBtnFolder.Parent = preacherFolder
            end
        end
    end

    if bState.FloorUpgrades[2] then
        if preachersBtnFolder then preachersBtnFolder.Parent = b1Templates end
        if preacherFolder then
            if preachersFolder then preachersFolder.Parent = preacherFolder end
        end
    end

    if bState.HasManager then
        if managerBtnFolder then managerBtnFolder.Parent = b1Templates end
        spawnManagerModels()
    end
end

Players.PlayerAdded:Connect(function(player: Player)
    task.delay(0.5, function()
        if player:IsDescendantOf(Players) then
            restorePlayerProgression(player)
        end
    end)
end)

print("[BuildingProgressionServer] Hierarchy-aware building & manager progression initialized.")
