--!strict
-- BuildingProgressionServer.legacy.luau
-- Authoritative, sequence-chained building progression, template stashing, pop-up triggers, and data persistence.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyConfig = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyConfig") :: any)
local EconomyMath = require(ReplicatedStorage:WaitForChild("Economy"):WaitForChild("EconomyMath") :: any)
local MoneyManager = require(ServerScriptService:WaitForChild("MoneyManager") :: any)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockStageEvent = RemoteEvents:WaitForChild("UnlockStage") :: RemoteEvent

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

local cultTycoon = workspace:WaitForChild("CultTycoon", 10) or workspace
local b1Folder = cultTycoon:FindFirstChild("Building1")
local preacherFolder = b1Folder and b1Folder:FindFirstChild("StreetPreacherBuilding")
local newBuildingBtnFolder = b1Folder and b1Folder:FindFirstChild("NewBuildingButton")

-- Starter Base Props
local starterTable = preacherFolder and preacherFolder:FindFirstChild("Table")
local starterMember = preacherFolder and (preacherFolder:FindFirstChild("Cult Member") or preacherFolder:FindFirstChild("PlayerModel"))
local collectGuiPart = preacherFolder and preacherFolder:FindFirstChild("CollectUpgradeGui")

-- Sequential Upgrade Chain Definition for Building 1
type ChainStep = {
    Step: number,
    FolderName: string,
    ButtonName: string,
    Cost: number,
    SpeedTier: number?,
    UnlockId: string
}

local B1_CHAIN: { ChainStep } = {
    { Step = 1,  FolderName = "Flyers",        ButtonName = "UpgradeButton",  Cost = 30,                  SpeedTier = 1,   UnlockId = "FlyersStage" },
    { Step = 2,  FolderName = "MorePreachers", ButtonName = "UpgradeButton",  Cost = 375,                 SpeedTier = 2,   UnlockId = "MorePreachersStage" },
    { Step = 3,  FolderName = "CanopyTents",   ButtonName = "CosmeticButton", Cost = 1500,                SpeedTier = nil, UnlockId = "CanopyTentsStage" },
    { Step = 4,  FolderName = "Megaphones",    ButtonName = "UpgradeButton",  Cost = 4500,                SpeedTier = 3,   UnlockId = "MegaphonesStage" },
    { Step = 5,  FolderName = "FloorChalk",    ButtonName = "CosmeticButton", Cost = 10000,               SpeedTier = nil, UnlockId = "FloorChalkStage" },
    { Step = 6,  FolderName = "OutreachBooth", ButtonName = "UpgradeButton",  Cost = 525000,              SpeedTier = 4,   UnlockId = "OutreachBoothStage" },
    { Step = 7,  FolderName = "Booklets",      ButtonName = "UpgradeButton",  Cost = 6000000,             SpeedTier = 5,   UnlockId = "BookletsStage" },
    { Step = 8,  FolderName = "Speakers",      ButtonName = "UpgradeButton",  Cost = 375000000,           SpeedTier = 6,   UnlockId = "SpeakersStage" },
    { Step = 9,  FolderName = "StreetSign",    ButtonName = "UpgradeButton",  Cost = 112500000000,        SpeedTier = 7,   UnlockId = "StreetSignStage" },
    { Step = 10, FolderName = "PlayerPodium",  ButtonName = "UpgradeButton",  Cost = 2250000000000000,    SpeedTier = 8,   UnlockId = "PlayerPodiumStage" },
}

-- Stash starter props on server start
if starterTable and starterTable.Parent ~= b1Templates then starterTable.Parent = b1Templates end
if starterMember and starterMember.Parent ~= b1Templates then starterMember.Parent = b1Templates end
if collectGuiPart and collectGuiPart.Parent ~= b1Templates then collectGuiPart.Parent = b1Templates end

-- Stash Manager Props
local managerFolder = preacherFolder and preacherFolder:FindFirstChild("Manager")
local managerTemplateFolder = b1Templates:FindFirstChild("Manager") or Instance.new("Folder")
managerTemplateFolder.Name = "Manager"
managerTemplateFolder.Parent = b1Templates

local managerBtnFolder = managerFolder and managerFolder:FindFirstChild("ManagerButton")
if managerFolder then
    for _, child in ipairs(managerFolder:GetChildren()) do
        if child.Name == "ManagerButton" then
            child.Parent = managerTemplateFolder
            managerBtnFolder = child
        else
            child.Parent = managerTemplateFolder
        end
    end
end

-- Stash all sequential chain models & buttons into template storage
local stepTemplates: { [string]: Folder } = {}
local stepButtons: { [string]: Instance } = {}

for _, item in ipairs(B1_CHAIN) do
    local f = preacherFolder and preacherFolder:FindFirstChild(item.FolderName)
    local tFolder = b1Templates:FindFirstChild(item.FolderName) or Instance.new("Folder")
    tFolder.Name = item.FolderName
    tFolder.Parent = b1Templates
    stepTemplates[item.FolderName] = tFolder

    if f then
        for _, child in ipairs(f:GetChildren()) do
            if child.Name == item.ButtonName or child.Name == "UpgradeButton" or child.Name == "CosmeticButton" then
                child.Parent = tFolder
                stepButtons[item.FolderName] = child
            else
                child.Parent = tFolder
            end
        end
    end
end

if newBuildingBtnFolder and b1Folder then newBuildingBtnFolder.Parent = b1Folder end

-- Robust Touch Button Handler
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

            -- De-render button by moving to templates
            local parentFolder = buttonFolder.Parent
            if parentFolder and parentFolder:IsDescendantOf(b1Templates) then
                -- Already in templates
            elseif parentFolder and b1Templates:FindFirstChild(parentFolder.Name) then
                buttonFolder.Parent = b1Templates:FindFirstChild(parentFolder.Name)
            else
                buttonFolder.Parent = b1Templates
            end

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

-- Spawn / Restore functions
local function spawnModelsForStep(folderName: string)
    if not preacherFolder then return end
    local targetFolder = preacherFolder:FindFirstChild(folderName)
    if not targetFolder then
        targetFolder = Instance.new("Folder")
        targetFolder.Name = folderName
        targetFolder.Parent = preacherFolder
    end

    local tFolder = b1Templates:FindFirstChild(folderName)
    if tFolder then
        for _, child in ipairs(tFolder:GetChildren()) do
            if child.Name ~= "UpgradeButton" and child.Name ~= "CosmeticButton" and child.Name ~= "ManagerButton" then
                child.Parent = targetFolder
            end
        end
    end
end

local function showButtonForStep(folderName: string)
    if not preacherFolder then return end
    local targetFolder = preacherFolder:FindFirstChild(folderName)
    if not targetFolder then
        targetFolder = Instance.new("Folder")
        targetFolder.Name = folderName
        targetFolder.Parent = preacherFolder
    end

    local btn = stepButtons[folderName] or (b1Templates:FindFirstChild(folderName) and (b1Templates[folderName]:FindFirstChild("UpgradeButton") or b1Templates[folderName]:FindFirstChild("CosmeticButton")))
    if btn then
        btn.Parent = targetFolder
    end
end

local function spawnManagerModels()
    if not preacherFolder then return end
    local mFolder = preacherFolder:FindFirstChild("Manager")
    if not mFolder then
        mFolder = Instance.new("Folder")
        mFolder.Name = "Manager"
        mFolder.Parent = preacherFolder
    end

    local mTemplate = b1Templates:FindFirstChild("Manager")
    if mTemplate then
        for _, child in ipairs(mTemplate:GetChildren()) do
            if child.Name ~= "ManagerButton" then
                child.Parent = mFolder
            end
        end
    end
end

local function showManagerButton()
    if not preacherFolder then return end
    local mFolder = preacherFolder:FindFirstChild("Manager")
    if not mFolder then
        mFolder = Instance.new("Folder")
        mFolder.Name = "Manager"
        mFolder.Parent = preacherFolder
    end

    local mBtn = managerBtnFolder or (b1Templates:FindFirstChild("Manager") and b1Templates.Manager:FindFirstChild("ManagerButton"))
    if mBtn then
        mBtn.Parent = mFolder
    end
end

-- Wire Manager Button Touch Handler ($250)
setupTouchButton(managerBtnFolder, 250, "ManagerStage", function(player: Player)
    MoneyManager.SetManagerOwned(player, 1, true)
    spawnManagerModels()
    print("[BuildingProgression] Manager hired for " .. player.Name .. "! Auto-collection active.")
end)

-- Wire Sequential Chain Step Handlers
for i, item in ipairs(B1_CHAIN) do
    local btn = stepButtons[item.FolderName]
    setupTouchButton(btn, item.Cost, item.UnlockId, function(player: Player)
        MoneyManager.SetUpgradePurchased(player, 1, item.UnlockId, true)
        if item.SpeedTier then
            MoneyManager.UnlockFloorUpgrade(player, 1, item.SpeedTier)
        end

        spawnModelsForStep(item.FolderName)

        -- Reveal next button in chain if available
        local nextItem = B1_CHAIN[i + 1]
        if nextItem then
            showButtonForStep(nextItem.FolderName)
        end
    end)
end

-- Stage 0: Initial Building Spawn ($0)
setupTouchButton(newBuildingBtnFolder, 0, "BaseStage", function(player: Player)
    local bState = MoneyManager.GetBuildingState(player, 1)
    if bState.OwnedCount <= 0 then
        bState.OwnedCount = 1
    end

    if preacherFolder then
        if starterTable then starterTable.Parent = preacherFolder end
        if starterMember then starterMember.Parent = preacherFolder end
        if collectGuiPart then collectGuiPart.Parent = preacherFolder end
        if not bState.HasManager then
            showManagerButton()
        end
        showButtonForStep(B1_CHAIN[1].FolderName) -- Show FloorChalk ($15)
    end
end)

-- Full Player Progression Restoration on Join
local function restorePlayerProgression(player: Player)
    local bState = MoneyManager.GetBuildingState(player, 1)

    if bState.OwnedCount <= 0 then
        -- Brand new player: Show only NewBuildingButton, hide everything else
        if newBuildingBtnFolder and b1Folder then newBuildingBtnFolder.Parent = b1Folder end
        if starterTable then starterTable.Parent = b1Templates end
        if starterMember then starterMember.Parent = b1Templates end
        if collectGuiPart then collectGuiPart.Parent = b1Templates end
        if managerBtnFolder then managerBtnFolder.Parent = b1Templates.Manager end

        for _, item in ipairs(B1_CHAIN) do
            local btn = stepButtons[item.FolderName]
            if btn then btn.Parent = b1Templates[item.FolderName] end
            local f = preacherFolder and preacherFolder:FindFirstChild(item.FolderName)
            if f then
                for _, child in ipairs(f:GetChildren()) do
                    child.Parent = b1Templates[item.FolderName]
                end
            end
        end
        return
    end

    -- Returning player who owns Building 1:
    if newBuildingBtnFolder then newBuildingBtnFolder.Parent = b1Templates end
    if preacherFolder then
        if starterTable then starterTable.Parent = preacherFolder end
        if starterMember then starterMember.Parent = preacherFolder end
        if collectGuiPart then collectGuiPart.Parent = preacherFolder end
    end

    -- Restore Manager State
    if bState.HasManager then
        if managerBtnFolder then managerBtnFolder.Parent = b1Templates.Manager end
        spawnManagerModels()
    else
        showManagerButton()
    end

    -- Restore Sequential Chain State
    local nextButtonToShow: string? = nil
    for _, item in ipairs(B1_CHAIN) do
        local isPurchased = MoneyManager.IsUpgradePurchased(player, 1, item.UnlockId)
        -- Backward compatibility check for floor speed tiers
        if not isPurchased and item.SpeedTier and bState.FloorUpgrades[item.SpeedTier] then
            isPurchased = true
            MoneyManager.SetUpgradePurchased(player, 1, item.UnlockId, true)
        end

        if isPurchased then
            spawnModelsForStep(item.FolderName)
            local btn = stepButtons[item.FolderName]
            if btn then btn.Parent = b1Templates[item.FolderName] end
        else
            if not nextButtonToShow then
                nextButtonToShow = item.FolderName
            else
                local btn = stepButtons[item.FolderName]
                if btn then btn.Parent = b1Templates[item.FolderName] end
            end
        end
    end

    if nextButtonToShow then
        showButtonForStep(nextButtonToShow)
    end
end

Players.PlayerAdded:Connect(function(player: Player)
    task.delay(0.5, function()
        if player:IsDescendantOf(Players) then
            restorePlayerProgression(player)
        end
    end)
end)

print("[BuildingProgressionServer] Full 11-step Building 1 upgrade chain & manager pipeline ready.")
