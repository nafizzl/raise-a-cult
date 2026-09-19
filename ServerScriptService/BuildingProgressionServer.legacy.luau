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

local b2Templates = templatesFolder:FindFirstChild("Building2")
if not b2Templates then
	b2Templates = Instance.new("Folder")
	b2Templates.Name = "Building2"
	b2Templates.Parent = templatesFolder
end

local b3Templates = templatesFolder:FindFirstChild("Building3")
if not b3Templates then
	b3Templates = Instance.new("Folder")
	b3Templates.Name = "Building3"
	b3Templates.Parent = templatesFolder
end

local cultTycoon = workspace:WaitForChild("CultTycoon", 10) or workspace
local b1Folder = cultTycoon:FindFirstChild("Building1")
local preacherFolder = b1Folder and b1Folder:FindFirstChild("StreetPreacherBuilding")
local newBuildingBtnFolder = b1Folder and b1Folder:FindFirstChild("NewBuildingButton")

-- Building 2 Instances
local b2Folder = cultTycoon:FindFirstChild("Building2")
local templeFolder = b2Folder and b2Folder:FindFirstChild("StorageUnitTempleBuilding")
local b2NewBuildingBtn = b2Folder and b2Folder:FindFirstChild("NewBuildingButton")

local b2StorageUnit = templeFolder and templeFolder:FindFirstChild("Storage Unit")
local b2Podium = templeFolder and templeFolder:FindFirstChild("Podium")
local b2Member = templeFolder and templeFolder:FindFirstChild("Cult Member")
local b2CollectGui = templeFolder and templeFolder:FindFirstChild("CollectUpgradeGui")

-- Building 3 Instances
local b3Folder = cultTycoon:FindFirstChild("Building3")
local compoundFolder = b3Folder and b3Folder:FindFirstChild("Suburban Compound Building")
local b3NewBuildingBtn = b3Folder and b3Folder:FindFirstChild("NewBuildingButton")
local b3CollectGui = compoundFolder and compoundFolder:FindFirstChild("CollectUpgradeGui")

-- Starter Base Props (Building 1)
local starterTable = preacherFolder and preacherFolder:FindFirstChild("Table")
local starterMember = preacherFolder and (preacherFolder:FindFirstChild("Cult Member") or preacherFolder:FindFirstChild("PlayerModel"))
local collectGuiPart = preacherFolder and preacherFolder:FindFirstChild("CollectUpgradeGui")

-- Sequential Upgrade Chain Definition
type ChainStep = {
	Step: number,
	FolderName: string,
	ButtonName: string,
	Cost: number,
	SpeedTier: number?,
	UnlockId: string,
}

local B1_CHAIN: { ChainStep } = {
	{ Step = 1,  FolderName = "Flyers",        ButtonName = "UpgradeButton",  Cost = 50,                  SpeedTier = 1,   UnlockId = "FlyersStage" },
	{ Step = 2,  FolderName = "MorePreachers", ButtonName = "UpgradeButton",  Cost = 500,                 SpeedTier = 2,   UnlockId = "MorePreachersStage" },
	{ Step = 3,  FolderName = "CanopyTents",   ButtonName = "CosmeticButton", Cost = 1500,                SpeedTier = nil, UnlockId = "CanopyTentsStage" },
	{ Step = 4,  FolderName = "Megaphones",    ButtonName = "UpgradeButton",  Cost = 8500,                SpeedTier = 3,   UnlockId = "MegaphonesStage" },
	{ Step = 5,  FolderName = "FloorChalk",    ButtonName = "CosmeticButton", Cost = 15000,               SpeedTier = nil, UnlockId = "FloorChalkStage" },
	{ Step = 6,  FolderName = "OutreachBooth", ButtonName = "UpgradeButton",  Cost = 525000,              SpeedTier = 4,   UnlockId = "OutreachBoothStage" },
	{ Step = 7,  FolderName = "Booklets",      ButtonName = "UpgradeButton",  Cost = 6000000,             SpeedTier = 5,   UnlockId = "BookletsStage" },
	{ Step = 8,  FolderName = "Speakers",      ButtonName = "UpgradeButton",  Cost = 375000000,           SpeedTier = 6,   UnlockId = "SpeakersStage" },
	{ Step = 9,  FolderName = "StreetSign",    ButtonName = "UpgradeButton",  Cost = 112500000000,        SpeedTier = 7,   UnlockId = "StreetSignStage" },
	{ Step = 10, FolderName = "PlayerPodium",  ButtonName = "UpgradeButton",  Cost = 2250000000000000,    SpeedTier = 8,   UnlockId = "PlayerPodiumStage" },
}

local B2_CHAIN: { ChainStep } = {
	{ Step = 1,  FolderName = "Carpeting",        ButtonName = "CosmeticButton", Cost = 45000,           SpeedTier = nil, UnlockId = "CarpetingStage" },
	{ Step = 2,  FolderName = "Folding Chairs",   ButtonName = "UpgradeButton",  Cost = 60000,           SpeedTier = 1,   UnlockId = "FoldingChairsStage" },
	{ Step = 3,  FolderName = "Microphone",       ButtonName = "CosmeticButton", Cost = 125000,          SpeedTier = nil, UnlockId = "MicrophoneStage" },
	{ Step = 4,  FolderName = "Boombox",          ButtonName = "UpgradeButton",  Cost = 250000,          SpeedTier = 2,   UnlockId = "BoomboxStage" },
	{ Step = 5,  FolderName = "Altar",            ButtonName = "CosmeticButton", Cost = 750000,          SpeedTier = nil, UnlockId = "AltarStage" },
	{ Step = 6,  FolderName = "Donation Machine", ButtonName = "UpgradeButton",  Cost = 5000000,         SpeedTier = 3,   UnlockId = "DonationMachineStage" },
	{ Step = 7,  FolderName = "PosePosters",      ButtonName = "UpgradeButton",  Cost = 75000000,        SpeedTier = 4,   UnlockId = "PosePostersStage" },
	{ Step = 8,  FolderName = "Shutter Door",     ButtonName = "UpgradeButton",  Cost = 500000000,       SpeedTier = 5,   UnlockId = "ShutterDoorStage" },
	{ Step = 9,  FolderName = "HVAC",             ButtonName = "UpgradeButton",  Cost = 2500000000,      SpeedTier = 6,   UnlockId = "HVACStage" },
	{ Step = 10, FolderName = "Cameras",          ButtonName = "UpgradeButton",  Cost = 7500000000,      SpeedTier = 7,   UnlockId = "CamerasStage" },
	{ Step = 11, FolderName = "Money Safes",      ButtonName = "UpgradeButton",  Cost = 250000000000,    SpeedTier = 8,   UnlockId = "MoneySafesStage" },
}

local B3_CHAIN: { ChainStep } = {
	{ Step = 1,  FolderName = "01_Foundation_and_Framing",    ButtonName = "CosmeticButton", Cost = 20000000,        SpeedTier = nil, UnlockId = "FoundationFramingStage" },
	{ Step = 2,  FolderName = "02_Exterior_Walls_and_Windows", ButtonName = "CosmeticButton", Cost = 30000000,        SpeedTier = nil, UnlockId = "ExteriorWallsStage" },
	{ Step = 3,  FolderName = "03_Roof_and_Chimney",           ButtonName = "CosmeticButton", Cost = 45000000,        SpeedTier = nil, UnlockId = "RoofChimneyStage" },
	{ Step = 4,  FolderName = "Communal Kitchen",              ButtonName = "UpgradeButton",  Cost = 70000000,        SpeedTier = 1,   UnlockId = "CommunalKitchenStage" },
	{ Step = 5,  FolderName = "04_Front_Porch",                ButtonName = "CosmeticButton", Cost = 120000000,       SpeedTier = nil, UnlockId = "FrontPorchStage" },
	{ Step = 6,  FolderName = "05_Driveway_and_Garden",        ButtonName = "CosmeticButton", Cost = 200000000,       SpeedTier = nil, UnlockId = "DrivewayGardenStage" },
	{ Step = 7,  FolderName = "06_Staircase_and_Hallways",     ButtonName = "CosmeticButton", Cost = 350000000,       SpeedTier = nil, UnlockId = "StaircaseHallwaysStage" },
	{ Step = 8,  FolderName = "07_LivingRoom_Lounge",          ButtonName = "CosmeticButton", Cost = 600000000,       SpeedTier = nil, UnlockId = "LivingRoomLoungeStage" },
	{ Step = 9,  FolderName = "Bunk Bedroom",                  ButtonName = "UpgradeButton",  Cost = 1000000000,      SpeedTier = 2,   UnlockId = "BunkBedroomStage" },
	{ Step = 10, FolderName = "08_LivingRoom_Entertainment",   ButtonName = "CosmeticButton", Cost = 1800000000,      SpeedTier = nil, UnlockId = "LivingRoomEntertainmentStage" },
	{ Step = 11, FolderName = "09_Dining_Room",                ButtonName = "CosmeticButton", Cost = 3000000000,      SpeedTier = nil, UnlockId = "DiningRoomStage" },
	{ Step = 12, FolderName = "Antenna Tower",                 ButtonName = "UpgradeButton",  Cost = 5000000000,      SpeedTier = 3,   UnlockId = "AntennaTowerStage" },
	{ Step = 13, FolderName = "13_Bathroom",                   ButtonName = "CosmeticButton", Cost = 8000000000,      SpeedTier = nil, UnlockId = "BathroomStage" },
	{ Step = 14, FolderName = "12_Guest_Bedrooms",             ButtonName = "CosmeticButton", Cost = 15000000000,     SpeedTier = nil, UnlockId = "GuestBedroomsStage" },
	{ Step = 15, FolderName = "14_Garage_and_Car",             ButtonName = "CosmeticButton", Cost = 40000000000,     SpeedTier = nil, UnlockId = "GarageCarStage" },
	{ Step = 16, FolderName = "Vegetable Farms",               ButtonName = "UpgradeButton",  Cost = 75000000000,     SpeedTier = 4,   UnlockId = "VegetableFarmsStage" },
	{ Step = 17, FolderName = "Solar Panels",                  ButtonName = "UpgradeButton",  Cost = 250000000000,    SpeedTier = 5,   UnlockId = "SolarPanelsStage" },
	{ Step = 18, FolderName = "Watchtower",                    ButtonName = "UpgradeButton",  Cost = 1500000000000,   SpeedTier = 6,   UnlockId = "WatchtowerStage" },
	{ Step = 19, FolderName = "Bunker Hatch",                 ButtonName = "UpgradeButton",  Cost = 10000000000000,  SpeedTier = 7,   UnlockId = "BunkerHatchStage" },
	{ Step = 20, FolderName = "Gates",                         ButtonName = "UpgradeButton",  Cost = 100000000000000, SpeedTier = 8,   UnlockId = "GatesStage" },
}

-- Stash starter props on server start
if starterTable and starterTable.Parent ~= b1Templates then starterTable.Parent = b1Templates end
if starterMember and starterMember.Parent ~= b1Templates then starterMember.Parent = b1Templates end
if collectGuiPart and collectGuiPart.Parent ~= b1Templates then collectGuiPart.Parent = b1Templates end

local function getB2Addons(): { Model }
	local result: { Model } = {}
	for _, parent in ipairs({templeFolder, b2Templates}) do
		if parent then
			for _, c in ipairs(parent:GetChildren()) do
				if c.Name:find("addon") and c:IsA("Model") and not table.find(result, c) then
					table.insert(result, c :: Model)
				end
			end
		end
	end
	return result
end

-- Stash Building 2 base props on server start
if b2StorageUnit and b2StorageUnit.Parent ~= b2Templates then b2StorageUnit.Parent = b2Templates end
for _, addon in ipairs(getB2Addons()) do
	if addon.Parent ~= b2Templates then addon.Parent = b2Templates end
end
if b2Podium and b2Podium.Parent ~= b2Templates then b2Podium.Parent = b2Templates end
if b2Member and b2Member.Parent ~= b2Templates then b2Member.Parent = b2Templates end
if b2CollectGui and b2CollectGui.Parent ~= b2Templates then b2CollectGui.Parent = b2Templates end
if b2NewBuildingBtn and b2NewBuildingBtn.Parent ~= b2Templates then b2NewBuildingBtn.Parent = b2Templates end

-- Stash Building 1 Manager Props
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

-- Stash Building 2 Manager Props (Available from the beginning)
local b2ManagerFolder = templeFolder and templeFolder:FindFirstChild("Manager")
local b2ManagerTemplateFolder = b2Templates:FindFirstChild("Manager") or Instance.new("Folder")
b2ManagerTemplateFolder.Name = "Manager"
b2ManagerTemplateFolder.Parent = b2Templates

local b2ManagerBtnFolder = b2ManagerFolder and b2ManagerFolder:FindFirstChild("ManagerButton")
if b2ManagerFolder then
	for _, child in ipairs(b2ManagerFolder:GetChildren()) do
		if child.Name == "ManagerButton" then
			child.Parent = b2ManagerTemplateFolder
			b2ManagerBtnFolder = child
		else
			child.Parent = b2ManagerTemplateFolder
		end
	end
end

-- Stash Building 3 base props on server start
if b3CollectGui and b3CollectGui.Parent ~= b3Templates then b3CollectGui.Parent = b3Templates end
if b3NewBuildingBtn and b3NewBuildingBtn.Parent ~= b3Templates then b3NewBuildingBtn.Parent = b3Templates end

-- Stash Building 3 Manager Props (Available from the beginning)
local b3ManagerFolder = compoundFolder and compoundFolder:FindFirstChild("Manager")
local b3ManagerTemplateFolder = b3Templates:FindFirstChild("Manager") or Instance.new("Folder")
b3ManagerTemplateFolder.Name = "Manager"
b3ManagerTemplateFolder.Parent = b3Templates

local b3ManagerBtnFolder = b3ManagerFolder and b3ManagerFolder:FindFirstChild("ManagerButton")
if b3ManagerFolder then
	for _, child in ipairs(b3ManagerFolder:GetChildren()) do
		if child.Name == "ManagerButton" then
			child.Parent = b3ManagerTemplateFolder
			b3ManagerBtnFolder = child
		else
			child.Parent = b3ManagerTemplateFolder
		end
	end
end

-- Stash all Building 1 sequential chain models & buttons into template storage
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

-- Stash all Building 2 sequential chain models & buttons into template storage
local b2StepTemplates: { [string]: Folder } = {}
local b2StepButtons: { [string]: Instance } = {}

for _, item in ipairs(B2_CHAIN) do
	local f = templeFolder and templeFolder:FindFirstChild(item.FolderName)
	local tFolder = b2Templates:FindFirstChild(item.FolderName) or Instance.new("Folder")
	tFolder.Name = item.FolderName
	tFolder.Parent = b2Templates
	b2StepTemplates[item.FolderName] = tFolder

	if f then
		for _, child in ipairs(f:GetChildren()) do
			if child.Name == item.ButtonName or child.Name == "UpgradeButton" or child.Name == "CosmeticButton" or child.Name == "ManagerButton" then
				child.Parent = tFolder
				b2StepButtons[item.FolderName] = child
			else
				child.Parent = tFolder
			end
		end
	end
end

-- Stash all Building 3 sequential chain models & buttons into template storage
local b3StepTemplates: { [string]: Folder } = {}
local b3StepButtons: { [string]: Instance } = {}

for _, item in ipairs(B3_CHAIN) do
	local f = compoundFolder and compoundFolder:FindFirstChild(item.FolderName)
	local tFolder = b3Templates:FindFirstChild(item.FolderName) or Instance.new("Folder")
	tFolder.Name = item.FolderName
	tFolder.Parent = b3Templates
	b3StepTemplates[item.FolderName] = tFolder

	if f then
		for _, child in ipairs(f:GetChildren()) do
			if child.Name == item.ButtonName or child.Name == "UpgradeButton" or child.Name == "CosmeticButton" or child.Name == "ManagerButton" then
				child.Parent = tFolder
				b3StepButtons[item.FolderName] = child
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
			local targetTemplate = b1Templates
			if buttonFolder and (
				buttonFolder == b3NewBuildingBtn
				or (buttonFolder.Parent and buttonFolder.Parent.Name == "Building3")
				or (compoundFolder and buttonFolder:IsDescendantOf(compoundFolder))
				or buttonFolder:IsDescendantOf(b3Templates)
			) then
				targetTemplate = b3Templates
			elseif buttonFolder and (
				buttonFolder == b2NewBuildingBtn
				or (buttonFolder.Parent and buttonFolder.Parent.Name == "Building2")
				or (templeFolder and buttonFolder:IsDescendantOf(templeFolder))
				or buttonFolder:IsDescendantOf(b2Templates)
			) then
				targetTemplate = b2Templates
			end

			local parentFolder = buttonFolder.Parent
			if parentFolder and parentFolder:IsDescendantOf(templatesFolder) then
				-- Already in templates
			elseif parentFolder and targetTemplate:FindFirstChild(parentFolder.Name) then
				buttonFolder.Parent = targetTemplate:FindFirstChild(parentFolder.Name)
			else
				buttonFolder.Parent = targetTemplate
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

-- Spawn / Restore functions for Building 1
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

local function showButtonForStep(folderName: string, player: Player?)
	if not preacherFolder then return end
	local targetFolder = preacherFolder:FindFirstChild(folderName)
	if not targetFolder then
		targetFolder = Instance.new("Folder")
		targetFolder.Name = folderName
		targetFolder.Parent = preacherFolder
	end

	local btn = stepButtons[folderName] or (b1Templates:FindFirstChild(folderName) and (
		b1Templates[folderName]:FindFirstChild("UpgradeButton")
		or b1Templates[folderName]:FindFirstChild("CosmeticButton")
	))
	if btn then
		btn.Parent = targetFolder
		if player and player:IsDescendantOf(Players) then
			UnlockStageEvent:FireClient(player, "ButtonReveal_" .. folderName)
		end
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

local function showManagerButton(player: Player?)
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
		if player and player:IsDescendantOf(Players) then
			UnlockStageEvent:FireClient(player, "ButtonReveal_Manager")
		end
	end
end

-- Spawn / Restore functions for Building 2
local function spawnModelsForB2Step(folderName: string)
	if not templeFolder then return end
	local targetFolder = templeFolder:FindFirstChild(folderName)
	if not targetFolder then
		targetFolder = Instance.new("Folder")
		targetFolder.Name = folderName
		targetFolder.Parent = templeFolder
	end

	local tFolder = b2Templates:FindFirstChild(folderName)
	if tFolder then
		for _, child in ipairs(tFolder:GetChildren()) do
			if child.Name ~= "UpgradeButton" and child.Name ~= "CosmeticButton" and child.Name ~= "ManagerButton" then
				child.Parent = targetFolder
			end
		end
	end
end

local function showButtonForB2Step(folderName: string, player: Player?)
	if not templeFolder then return end
	local targetFolder = templeFolder:FindFirstChild(folderName)
	if not targetFolder then
		targetFolder = Instance.new("Folder")
		targetFolder.Name = folderName
		targetFolder.Parent = templeFolder
	end

	local btn = b2StepButtons[folderName] or (b2Templates:FindFirstChild(folderName) and (
		b2Templates[folderName]:FindFirstChild("UpgradeButton")
		or b2Templates[folderName]:FindFirstChild("CosmeticButton")
	))
	if btn then
		btn.Parent = targetFolder
		if player and player:IsDescendantOf(Players) then
			UnlockStageEvent:FireClient(player, "ButtonReveal_" .. folderName)
		end
	end
end

local function spawnB2ManagerModels()
	if not templeFolder then return end
	local mFolder = templeFolder:FindFirstChild("Manager")
	if not mFolder then
		mFolder = Instance.new("Folder")
		mFolder.Name = "Manager"
		mFolder.Parent = templeFolder
	end

	local mTemplate = b2Templates:FindFirstChild("Manager")
	if mTemplate then
		for _, child in ipairs(mTemplate:GetChildren()) do
			if child.Name ~= "ManagerButton" then
				child.Parent = mFolder
			end
		end
	end
end

local function showB2ManagerButton(player: Player?)
	if not templeFolder then return end
	local mFolder = templeFolder:FindFirstChild("Manager")
	if not mFolder then
		mFolder = Instance.new("Folder")
		mFolder.Name = "Manager"
		mFolder.Parent = templeFolder
	end

	local mBtn = b2ManagerBtnFolder or (b2Templates:FindFirstChild("Manager") and b2Templates.Manager:FindFirstChild("ManagerButton"))
	if mBtn then
		mBtn.Parent = mFolder
		if player and player:IsDescendantOf(Players) then
			UnlockStageEvent:FireClient(player, "ButtonReveal_B2_Manager")
		end
	end
end

-- Spawn / Restore functions for Building 3
local function spawnModelsForB3Step(folderName: string)
	if not compoundFolder then return end
	local targetFolder = compoundFolder:FindFirstChild(folderName)
	if not targetFolder then
		targetFolder = Instance.new("Folder")
		targetFolder.Name = folderName
		targetFolder.Parent = compoundFolder
	end

	local tFolder = b3Templates:FindFirstChild(folderName)
	if tFolder then
		for _, child in ipairs(tFolder:GetChildren()) do
			if child.Name ~= "UpgradeButton" and child.Name ~= "CosmeticButton" and child.Name ~= "ManagerButton" then
				child.Parent = targetFolder
			end
		end
	end
end

local function showButtonForB3Step(folderName: string, player: Player?)
	if not compoundFolder then return end
	local targetFolder = compoundFolder:FindFirstChild(folderName)
	if not targetFolder then
		targetFolder = Instance.new("Folder")
		targetFolder.Name = folderName
		targetFolder.Parent = compoundFolder
	end

	local btn = b3StepButtons[folderName] or (b3Templates:FindFirstChild(folderName) and (
		b3Templates[folderName]:FindFirstChild("UpgradeButton")
		or b3Templates[folderName]:FindFirstChild("CosmeticButton")
	))
	if btn then
		btn.Parent = targetFolder
		if player and player:IsDescendantOf(Players) then
			UnlockStageEvent:FireClient(player, "ButtonReveal_" .. folderName)
		end
	end
end

local function spawnB3ManagerModels()
	if not compoundFolder then return end
	local mFolder = compoundFolder:FindFirstChild("Manager")
	if not mFolder then
		mFolder = Instance.new("Folder")
		mFolder.Name = "Manager"
		mFolder.Parent = compoundFolder
	end

	local mTemplate = b3Templates:FindFirstChild("Manager")
	if mTemplate then
		for _, child in ipairs(mTemplate:GetChildren()) do
			if child.Name ~= "ManagerButton" then
				child.Parent = mFolder
			end
		end
	end
end

local function showB3ManagerButton(player: Player?)
	if not compoundFolder then return end
	local mFolder = compoundFolder:FindFirstChild("Manager")
	if not mFolder then
		mFolder = Instance.new("Folder")
		mFolder.Name = "Manager"
		mFolder.Parent = compoundFolder
	end

	local mBtn = b3ManagerBtnFolder or (b3Templates:FindFirstChild("Manager") and b3Templates.Manager:FindFirstChild("ManagerButton"))
	if mBtn then
		mBtn.Parent = mFolder
		if player and player:IsDescendantOf(Players) then
			UnlockStageEvent:FireClient(player, "ButtonReveal_B3_Manager")
		end
	end
end

-- Wire Building 1 Manager Button Touch Handler ($250)
setupTouchButton(managerBtnFolder, 250, "ManagerStage", function(player: Player)
	MoneyManager.SetManagerOwned(player, 1, true)
	spawnManagerModels()
	print("[BuildingProgression] Manager hired for " .. player.Name .. "! Auto-collection active.")
end)

-- Wire Building 2 Manager (Caretaker) Touch Handler ($500,000 - Available from the beginning)
setupTouchButton(b2ManagerBtnFolder, 500000, "Building2_ManagerStage", function(player: Player)
	MoneyManager.SetManagerOwned(player, 2, true)
	spawnB2ManagerModels()
	print("[BuildingProgression] Caretaker hired for " .. player.Name .. "! Auto-collection active.")
end)

-- Wire Building 3 Manager (Compound Overseer) Touch Handler ($150,000,000 - Available from the beginning)
setupTouchButton(b3ManagerBtnFolder, 150000000, "Building3_ManagerStage", function(player: Player)
	MoneyManager.SetManagerOwned(player, 3, true)
	spawnB3ManagerModels()
	print("[BuildingProgression] Compound Overseer hired for " .. player.Name .. "! Auto-collection active.")
end)

-- Wire Sequential Chain Step Handlers for Building 1
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
			showButtonForStep(nextItem.FolderName, player)
		end

		-- Gate Check: Sidewalk Chalk Circle ($50K) unlocks Building 2's NewBuildingButton ($250K)
		if item.UnlockId == "FloorChalkStage" then
			local b2State = MoneyManager.GetBuildingState(player, 2)
			if b2State.OwnedCount <= 0 and b2NewBuildingBtn and b2Folder then
				b2NewBuildingBtn.Parent = b2Folder
				UnlockStageEvent:FireClient(player, "Building2_ButtonReveal")
			end
		end
	end)
end

-- Wire Sequential Chain Step Handlers for Building 2
for i, item in ipairs(B2_CHAIN) do
	local btn = b2StepButtons[item.FolderName]
	setupTouchButton(btn, item.Cost, item.UnlockId, function(player: Player)
		MoneyManager.SetUpgradePurchased(player, 2, item.UnlockId, true)
		if item.SpeedTier then
			MoneyManager.UnlockFloorUpgrade(player, 2, item.SpeedTier)
		end

		spawnModelsForB2Step(item.FolderName)

		-- Reveal next button in B2 chain if available
		local nextItem = B2_CHAIN[i + 1]
		if nextItem then
			showButtonForB2Step(nextItem.FolderName, player)
		end

		-- Gate Check: Donation Machine ($15M) in Building 2 unlocks Building 3's NewBuildingButton ($250M)
		if item.UnlockId == "DonationMachineStage" then
			local b3State = MoneyManager.GetBuildingState(player, 3)
			if b3State.OwnedCount <= 0 and b3NewBuildingBtn and b3Folder then
				b3NewBuildingBtn.Parent = b3Folder
				UnlockStageEvent:FireClient(player, "Building3_ButtonReveal")
			end
		end
	end)
end

-- Wire Sequential Chain Step Handlers for Building 3
for i, item in ipairs(B3_CHAIN) do
	local btn = b3StepButtons[item.FolderName]
	setupTouchButton(btn, item.Cost, item.UnlockId, function(player: Player)
		MoneyManager.SetUpgradePurchased(player, 3, item.UnlockId, true)
		if item.SpeedTier then
			MoneyManager.UnlockFloorUpgrade(player, 3, item.SpeedTier)
		end

		spawnModelsForB3Step(item.FolderName)

		-- Reveal next button in B3 chain if available
		local nextItem = B3_CHAIN[i + 1]
		if nextItem then
			showButtonForB3Step(nextItem.FolderName, player)
		end

		-- Gate Check: GarageCarStage ($350B) in Building 3 unlocks Building 4's NewBuildingButton ($500B) if present
		if item.UnlockId == "GarageCarStage" then
			local b4Folder = cultTycoon:FindFirstChild("Building4")
			local b4NewBuildingBtn = b4Folder and b4Folder:FindFirstChild("NewBuildingButton")
			local b4State = MoneyManager.GetBuildingState(player, 4)
			if b4State and b4State.OwnedCount <= 0 and b4NewBuildingBtn and b4Folder then
				b4NewBuildingBtn.Parent = b4Folder
				UnlockStageEvent:FireClient(player, "Building4_ButtonReveal")
			end
		end
	end)
end

-- Stage 0: Initial Building 1 Spawn ($0)
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
			showManagerButton(player)
		end
		showButtonForStep(B1_CHAIN[1].FolderName, player)
	end
end)

-- Building 2: Initial Building Spawn ($30,000)
local B2_UNLOCK_COST = 30000
setupTouchButton(b2NewBuildingBtn, B2_UNLOCK_COST, "Building2_BaseStage", function(player: Player)
	local b2State = MoneyManager.GetBuildingState(player, 2)
	if b2State.OwnedCount <= 0 then
		b2State.OwnedCount = 1
	end

	if templeFolder then
		if b2StorageUnit then b2StorageUnit.Parent = templeFolder end
		for _, addon in ipairs(getB2Addons()) do
			addon.Parent = templeFolder
		end
		if b2Podium then b2Podium.Parent = templeFolder end
		if b2Member then b2Member.Parent = templeFolder end
		if b2CollectGui then b2CollectGui.Parent = templeFolder end

		-- Show Caretaker (Manager) button from the beginning of Building 2 immediately
		if not b2State.HasManager then
			showB2ManagerButton(player)
		end

		-- Reveal Step 1 (Carpeting) button immediately alongside the base structure
		showButtonForB2Step(B2_CHAIN[1].FolderName, player)
	end
end)

-- Building 3: Initial Building Spawn ($15,000,000)
local B3_UNLOCK_COST = 15000000
setupTouchButton(b3NewBuildingBtn, B3_UNLOCK_COST, "Building3_BaseStage", function(player: Player)
	local b3State = MoneyManager.GetBuildingState(player, 3)
	if b3State.OwnedCount <= 0 then
		b3State.OwnedCount = 1
	end

	if compoundFolder then
		if b3CollectGui then b3CollectGui.Parent = compoundFolder end

		-- Show Overseer (Manager) button from the beginning of Building 3 immediately
		if not b3State.HasManager then
			showB3ManagerButton(player)
		end

		-- Reveal Step 1 (01_Foundation_and_Framing) button immediately alongside the base structure
		showButtonForB3Step(B3_CHAIN[1].FolderName, player)
	end
end)

-- Full Player Progression Restoration on Join
local function restorePlayerProgression(player: Player)
	local bState = MoneyManager.GetBuildingState(player, 1)

	-- 1. Building 1 Progression Restoration
	if bState.OwnedCount <= 0 then
		-- Brand new player: Show only NewBuildingButton, hide everything else
		if newBuildingBtnFolder and b1Folder then newBuildingBtnFolder.Parent = b1Folder end
		if starterTable then starterTable.Parent = b1Templates end
		if starterMember then starterMember.Parent = b1Templates end
		if collectGuiPart then collectGuiPart.Parent = b1Templates end
		if managerBtnFolder then managerBtnFolder.Parent = b1Templates.Manager end

		for _, item in ipairs(B1_CHAIN) do
			local btn = stepButtons[item.FolderName]
			if btn and b1Templates:FindFirstChild(item.FolderName) then
				btn.Parent = b1Templates[item.FolderName]
			end
			local f = preacherFolder and preacherFolder:FindFirstChild(item.FolderName)
			if f and b1Templates:FindFirstChild(item.FolderName) then
				for _, child in ipairs(f:GetChildren()) do
					child.Parent = b1Templates[item.FolderName]
				end
			end
		end
	else
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
				if btn and b1Templates:FindFirstChild(item.FolderName) then
					btn.Parent = b1Templates[item.FolderName]
				end
			else
				if not nextButtonToShow then
					nextButtonToShow = item.FolderName
				else
					local btn = stepButtons[item.FolderName]
					if btn and b1Templates:FindFirstChild(item.FolderName) then
						btn.Parent = b1Templates[item.FolderName]
					end
				end
			end
		end

		if nextButtonToShow then
			showButtonForStep(nextButtonToShow)
		end
	end

	-- 2. Building 2 Progression Restoration
	local b2State = MoneyManager.GetBuildingState(player, 2)
	if b2State.OwnedCount <= 0 then
		-- Building 2 not purchased yet: only show NewBuildingButton if FloorChalk is owned!
		local hasChalk = MoneyManager.IsUpgradePurchased(player, 1, "FloorChalkStage")
		if hasChalk and b2NewBuildingBtn and b2Folder then
			b2NewBuildingBtn.Parent = b2Folder
		else
			if b2NewBuildingBtn then b2NewBuildingBtn.Parent = b2Templates end
		end
		if b2StorageUnit then b2StorageUnit.Parent = b2Templates end
		for _, addon in ipairs(getB2Addons()) do
			addon.Parent = b2Templates
		end
		if b2Podium then b2Podium.Parent = b2Templates end
		if b2Member then b2Member.Parent = b2Templates end
		if b2CollectGui then b2CollectGui.Parent = b2Templates end
		if b2ManagerBtnFolder then b2ManagerBtnFolder.Parent = b2Templates.Manager end

		for _, item in ipairs(B2_CHAIN) do
			local btn = b2StepButtons[item.FolderName]
			if btn and b2Templates:FindFirstChild(item.FolderName) then
				btn.Parent = b2Templates[item.FolderName]
			end
			local f = templeFolder and templeFolder:FindFirstChild(item.FolderName)
			if f and b2Templates:FindFirstChild(item.FolderName) then
				for _, child in ipairs(f:GetChildren()) do
					child.Parent = b2Templates[item.FolderName]
				end
			end
		end
	else
		-- Building 2 owned: hide NewBuildingButton, restore base props
		if b2NewBuildingBtn then b2NewBuildingBtn.Parent = b2Templates end
		if templeFolder then
			if b2StorageUnit then b2StorageUnit.Parent = templeFolder end
			for _, addon in ipairs(getB2Addons()) do
				addon.Parent = templeFolder
			end
			if b2Podium then b2Podium.Parent = templeFolder end
			if b2Member then b2Member.Parent = templeFolder end
			if b2CollectGui then b2CollectGui.Parent = templeFolder end
		end

		-- Restore Building 2 Caretaker (Manager) State (Available from the beginning)
		if b2State.HasManager then
			if b2ManagerBtnFolder then b2ManagerBtnFolder.Parent = b2Templates.Manager end
			spawnB2ManagerModels()
		else
			showB2ManagerButton()
		end

		-- Restore Sequential Chain State for Building 2
		local nextB2ButtonToShow: string? = nil
		for _, item in ipairs(B2_CHAIN) do
			local isPurchased = MoneyManager.IsUpgradePurchased(player, 2, item.UnlockId)
			-- Backward compatibility check for floor speed tiers
			if not isPurchased and item.SpeedTier and b2State.FloorUpgrades[item.SpeedTier] then
				isPurchased = true
				MoneyManager.SetUpgradePurchased(player, 2, item.UnlockId, true)
			end

			if isPurchased then
				spawnModelsForB2Step(item.FolderName)
				local btn = b2StepButtons[item.FolderName]
				if btn and b2Templates:FindFirstChild(item.FolderName) then
					btn.Parent = b2Templates[item.FolderName]
				end
			else
				if not nextB2ButtonToShow then
					nextB2ButtonToShow = item.FolderName
				else
					local btn = b2StepButtons[item.FolderName]
					if btn and b2Templates:FindFirstChild(item.FolderName) then
						btn.Parent = b2Templates[item.FolderName]
					end
				end
			end
		end

		if nextB2ButtonToShow then
			showButtonForB2Step(nextB2ButtonToShow)
		end
	end

	-- 3. Building 3 Progression Restoration
	local b3State = MoneyManager.GetBuildingState(player, 3)
	if b3State.OwnedCount <= 0 then
		-- Building 3 not purchased yet: only show NewBuildingButton if Donation Machine is owned in B2!
		local hasDonationMachine = MoneyManager.IsUpgradePurchased(player, 2, "DonationMachineStage")
		if hasDonationMachine and b3NewBuildingBtn and b3Folder then
			b3NewBuildingBtn.Parent = b3Folder
		else
			if b3NewBuildingBtn then b3NewBuildingBtn.Parent = b3Templates end
		end
		if b3CollectGui then b3CollectGui.Parent = b3Templates end
		if b3ManagerBtnFolder then b3ManagerBtnFolder.Parent = b3Templates.Manager end

		for _, item in ipairs(B3_CHAIN) do
			local btn = b3StepButtons[item.FolderName]
			if btn and b3Templates:FindFirstChild(item.FolderName) then
				btn.Parent = b3Templates[item.FolderName]
			end
			local f = compoundFolder and compoundFolder:FindFirstChild(item.FolderName)
			if f and b3Templates:FindFirstChild(item.FolderName) then
				for _, child in ipairs(f:GetChildren()) do
					child.Parent = b3Templates[item.FolderName]
				end
			end
		end
	else
		-- Building 3 owned: hide NewBuildingButton, restore base props
		if b3NewBuildingBtn then b3NewBuildingBtn.Parent = b3Templates end
		if compoundFolder then
			if b3CollectGui then b3CollectGui.Parent = compoundFolder end
		end

		-- Restore Building 3 Overseer (Manager) State (Available from the beginning)
		if b3State.HasManager then
			if b3ManagerBtnFolder then b3ManagerBtnFolder.Parent = b3Templates.Manager end
			spawnB3ManagerModels()
		else
			showB3ManagerButton()
		end

		-- Restore Sequential Chain State for Building 3
		local nextB3ButtonToShow: string? = nil
		for _, item in ipairs(B3_CHAIN) do
			local isPurchased = MoneyManager.IsUpgradePurchased(player, 3, item.UnlockId)
			-- Backward compatibility check for floor speed tiers
			if not isPurchased and item.SpeedTier and b3State.FloorUpgrades[item.SpeedTier] then
				isPurchased = true
				MoneyManager.SetUpgradePurchased(player, 3, item.UnlockId, true)
			end

			if isPurchased then
				spawnModelsForB3Step(item.FolderName)
				local btn = b3StepButtons[item.FolderName]
				if btn and b3Templates:FindFirstChild(item.FolderName) then
					btn.Parent = b3Templates[item.FolderName]
				end
			else
				if not nextB3ButtonToShow then
					nextB3ButtonToShow = item.FolderName
				else
					local btn = b3StepButtons[item.FolderName]
					if btn and b3Templates:FindFirstChild(item.FolderName) then
						btn.Parent = b3Templates[item.FolderName]
					end
				end
			end
		end

		if nextB3ButtonToShow then
			showButtonForB3Step(nextB3ButtonToShow)
		end
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	task.delay(0.5, function()
		if player:IsDescendantOf(Players) then
			restorePlayerProgression(player)
		end
	end)
end)

print("[BuildingProgressionServer] Full Building 1, 2 & 3 (immediate manager) pipelines ready.")
