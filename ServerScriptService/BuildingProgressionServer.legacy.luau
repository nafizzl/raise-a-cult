-- BuildingProgressionServer.luau
-- Robust per-player floor button unlocks, template management, and stage progression.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyConfig = require(ReplicatedStorage.Economy.EconomyConfig)
local EconomyMath = require(ReplicatedStorage.Economy.EconomyMath)
local MoneyManager = require(ServerScriptService.MoneyManager)

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
    RemoteEvents = Instance.new("Folder")
    RemoteEvents.Name = "RemoteEvents"
    RemoteEvents.Parent = ReplicatedStorage
end

local UnlockStageEventObj = RemoteEvents:FindFirstChild("UnlockStage")
if not UnlockStageEventObj then
    UnlockStageEventObj = Instance.new("RemoteEvent")
    UnlockStageEventObj.Name = "UnlockStage"
    UnlockStageEventObj.Parent = RemoteEvents
end
local UnlockStageEvent = UnlockStageEventObj :: RemoteEvent

local CollectEventObj = RemoteEvents:FindFirstChild("CollectEvent")
if not CollectEventObj then
    CollectEventObj = Instance.new("RemoteEvent")
    CollectEventObj.Name = "CollectEvent"
    CollectEventObj.Parent = RemoteEvents
end
local CollectEvent = CollectEventObj :: RemoteEvent

-- Ensure template folders exist
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

local tableModel = preacherFolder and preacherFolder:FindFirstChild("Table")
local cultMemberModel = preacherFolder and (preacherFolder:FindFirstChild("Cult Member") or preacherFolder:FindFirstChild("PlayerModel"))
local collectGuiPart = preacherFolder and preacherFolder:FindFirstChild("CollectUpgradeGui")
local flyersFolder = preacherFolder and preacherFolder:FindFirstChild("Flyers")
local flyersBtnFolder = flyersFolder and flyersFolder:FindFirstChild("UpgradeButton")
local preachersFolder = preacherFolder and preacherFolder:FindFirstChild("MorePreachers")
local preachersBtnFolder = preachersFolder and preachersFolder:FindFirstChild("UpgradeButton")
local managerBtnFolder = preacherFolder and preacherFolder:FindFirstChild("ManagerButton")

-- Move unbuilt elements to template storage on server start
if tableModel and tableModel.Parent ~= b1Templates then tableModel.Parent = b1Templates end
if cultMemberModel and cultMemberModel.Parent ~= b1Templates then cultMemberModel.Parent = b1Templates end
if collectGuiPart and collectGuiPart.Parent ~= b1Templates then collectGuiPart.Parent = b1Templates end
if flyersFolder and flyersFolder.Parent ~= b1Templates then flyersFolder.Parent = b1Templates end
if flyersBtnFolder and flyersBtnFolder.Parent ~= b1Templates then flyersBtnFolder.Parent = b1Templates end
if preachersFolder and preachersFolder.Parent ~= b1Templates then preachersFolder.Parent = b1Templates end
if preachersBtnFolder and preachersBtnFolder.Parent ~= b1Templates then preachersBtnFolder.Parent = b1Templates end
if managerBtnFolder and managerBtnFolder.Parent ~= b1Templates then managerBtnFolder.Parent = b1Templates end

if newBuildingBtnFolder and b1Folder then newBuildingBtnFolder.Parent = b1Folder end

-- Setup manual click detector for CollectUpgradeGui part (fallback for 3D clicks)
if collectGuiPart and collectGuiPart:IsA("BasePart") then
    local detector = collectGuiPart:FindFirstChildWhichIsA("ClickDetector")
    if not detector then
        detector = Instance.new("ClickDetector")
        detector.MaxActivationDistance = 16
        detector.Parent = collectGuiPart
    end

    detector.MouseClick:Connect(function(player: Player)
        local prodEngine = rawget(_G, "ProductionEngine")
        local stats = prodEngine and prodEngine.GetBuildingStats(player, 1)
        if not stats then return end

        local cycle = prodEngine.GetCycleState(player, 1)
        if not cycle.IsCycling and not stats.State.HasManager and stats.Owned > 0 then
            cycle.IsCycling = true
            cycle.CurrentCycleTime = stats.EffectiveCycleTime
            if player:IsDescendantOf(Players) then
                CollectEvent:FireClient(player, "StartCycle", 1, stats.EffectiveCycleTime)
            end

            task.delay(stats.EffectiveCycleTime, function()
                cycle.IsCycling = false
                if player:IsDescendantOf(Players) then
                    local updatedStats = prodEngine.GetBuildingStats(player, 1) or stats
                    MoneyManager.AddMoney(player, updatedStats.IncomePerCycle)
                    CollectEvent:FireClient(player, "CycleComplete", 1)
                end
            end)
        end
    end)
end

-- Costs for Building 1 Progression (from EconomyConfig)
local FLYERS_COST = math.floor(EconomyConfig.FloorUpgradeCostMultipliers[1] * EconomyConfig.Buildings[1].BaseCost) -- $14
local PREACHERS_COST = math.floor(EconomyConfig.FloorUpgradeCostMultipliers[2] * EconomyConfig.Buildings[1].BaseCost) -- $100
local MANAGER_COST = EconomyConfig.Buildings[1].ManagerCost -- $100

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

-- Setup Stage 0: Initial Building Spawn ($0)
setupTouchButton(newBuildingBtnFolder, 0, "BaseStage", function(player: Player)
    local bState = MoneyManager.GetBuildingState(player, 1)
    if bState.OwnedCount <= 0 then
        bState.OwnedCount = 1
    end

    -- Parent base models to workspace if not present
    if preacherFolder then
        if tableModel then tableModel.Parent = preacherFolder end
        if cultMemberModel then cultMemberModel.Parent = preacherFolder end
        if collectGuiPart then collectGuiPart.Parent = preacherFolder end
        if flyersBtnFolder then flyersBtnFolder.Parent = preacherFolder end
    end
end)

-- Setup Stage 1: Flyers / Floor Upgrade 1 ($14, 2x Speed)
setupTouchButton(flyersBtnFolder, FLYERS_COST, "FlyersStage", function(player: Player)
    MoneyManager.UnlockFloorUpgrade(player, 1, 1)

    if preacherFolder then
        if flyersFolder then flyersFolder.Parent = preacherFolder end
        if preachersBtnFolder then preachersBtnFolder.Parent = preacherFolder end
    end
end)

-- Setup Stage 2: More Preachers / Floor Upgrade 2 ($100, 2x Speed)
setupTouchButton(preachersBtnFolder, PREACHERS_COST, "MorePreachersStage", function(player: Player)
    MoneyManager.UnlockFloorUpgrade(player, 1, 2)

    if preacherFolder then
        if preachersFolder then preachersFolder.Parent = preacherFolder end
        if managerBtnFolder then managerBtnFolder.Parent = preacherFolder end
    end
end)

-- Setup Manager ($100, Automation)
setupTouchButton(managerBtnFolder, MANAGER_COST, "ManagerStage", function(player: Player)
    MoneyManager.SetManagerOwned(player, 1, true)
    print("[BuildingProgression] Manager hired for " .. player.Name .. "! Auto-collection active.")
end)

Players.PlayerRemoving:Connect(function(player: Player)
    playerDebounce[player] = nil
end)

print("[BuildingProgressionServer] Initialized with robust touch detection and economy pricing.")
