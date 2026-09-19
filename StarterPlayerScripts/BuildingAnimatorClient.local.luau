--!strict
-- BuildingAnimatorClient.luau
-- Handles dynamic slide-in pop animations using PivotTo for newly spawned models and props.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockStageEvent = RemoteEvents:WaitForChild("UnlockStage") :: RemoteEvent

local STAGE_FOLDER_MAP: { [string]: string } = {
	-- Building 1 (Street Corner Preacher)
	["FloorChalkStage"]    = "FloorChalk",
	["FlyersStage"]        = "Flyers",
	["MorePreachersStage"] = "MorePreachers",
	["CanopyTentsStage"]   = "CanopyTents",
	["MegaphonesStage"]    = "Megaphones",
	["OutreachBoothStage"] = "OutreachBooth",
	["BookletsStage"]      = "Booklets",
	["SpeakersStage"]      = "Speakers",
	["StreetSignStage"]    = "StreetSign",
	["PlayerPodiumStage"]  = "PlayerPodium",
	["ManagerStage"]       = "Manager",

	-- Building 2 (Storage Unit Temple)
	["CarpetingStage"]         = "Carpeting",
	["FoldingChairsStage"]     = "Folding Chairs",
	["MicrophoneStage"]        = "Microphone",
	["BoomboxStage"]           = "Boombox",
	["Building2_ManagerStage"] = "Manager",
	["AltarStage"]             = "Altar",
	["DonationMachineStage"]   = "Donation Machine",
	["PosePostersStage"]       = "PosePosters",
	["ShutterDoorStage"]       = "Shutter Door",
	["HVACStage"]              = "HVAC",
	["CamerasStage"]           = "Cameras",
	["MoneySafesStage"]        = "Money Safes",

	-- Building 3 (Suburban Compound)
	["FoundationFramingStage"]        = "01_Foundation_and_Framing",
	["ExteriorWallsStage"]            = "02_Exterior_Walls_and_Windows",
	["RoofChimneyStage"]              = "03_Roof_and_Chimney",
	["CommunalKitchenStage"]          = "Communal Kitchen",
	["FrontPorchStage"]               = "04_Front_Porch",
	["DrivewayGardenStage"]           = "05_Driveway_and_Garden",
	["StaircaseHallwaysStage"]        = "06_Staircase_and_Hallways",
	["LivingRoomLoungeStage"]         = "07_LivingRoom_Lounge",
	["BunkBedroomStage"]              = "Bunk Bedroom",
	["LivingRoomEntertainmentStage"]  = "08_LivingRoom_Entertainment",
	["Building3_ManagerStage"]        = "Manager",
	["DiningRoomStage"]               = "09_Dining_Room",
	["AntennaTowerStage"]             = "Antenna Tower",
	["BathroomStage"]                 = "13_Bathroom",
	["GuestBedroomsStage"]            = "12_Guest_Bedrooms",
	["GarageCarStage"]                = "14_Garage_and_Car",
	["VegetableFarmsStage"]           = "Vegetable Farms",
	["SolarPanelsStage"]              = "Solar Panels",
	["WatchtowerStage"]               = "Watchtower",
	["BunkerHatchStage"]              = "Bunker Hatch",
	["GatesStage"]                    = "Gates",
}

local function animateInstanceSlide(instanceObj: Instance?, worldOffset: Vector3, duration: number?, easingStyle: Enum.EasingStyle?)
	if not instanceObj then return end
	duration = duration or 0.6
	easingStyle = easingStyle or Enum.EasingStyle.Back

	if instanceObj:IsA("Model") or instanceObj:IsA("Tool") then
		local pvObj = instanceObj :: any
		local targetCFrame = pvObj:GetPivot()
		local startCFrame = CFrame.new(worldOffset) * targetCFrame

		pvObj:PivotTo(startCFrame)

		local cfVal = Instance.new("CFrameValue")
		cfVal.Value = startCFrame
		cfVal.Changed:Connect(function(newCF)
			if pvObj and pvObj.Parent then
				pvObj:PivotTo(newCF)
			end
		end)

		local tweenInfo = TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out)
		local tween = TweenService:Create(cfVal, tweenInfo, {
			Value = targetCFrame
		})
		tween:Play()
		tween.Completed:Connect(function()
			cfVal:Destroy()
		end)

	elseif instanceObj:IsA("BasePart") then
		local targetCFrame = instanceObj.CFrame
		local startCFrame = CFrame.new(worldOffset) * targetCFrame

		instanceObj.CFrame = startCFrame

		local tweenInfo = TweenInfo.new(duration, easingStyle, Enum.EasingDirection.Out)
		local tween = TweenService:Create(instanceObj, tweenInfo, {
			CFrame = targetCFrame
		})
		tween:Play()
	end
end

local function animateModelSlideIn(instanceObj: Instance?)
	animateInstanceSlide(instanceObj, Vector3.new(0, -4, 0), 1.2, Enum.EasingStyle.Back)
end

local function animateButtonPopIn(buttonFolder: Instance?)
	if not buttonFolder then return end
	local btn = buttonFolder:FindFirstChild("Button")
	local pTag = buttonFolder:FindFirstChild("PricingTag")
	animateInstanceSlide(btn, Vector3.new(0, -3, 0), 1.0, Enum.EasingStyle.Back)
	animateInstanceSlide(pTag, Vector3.new(0, -3, 0), 1.0, Enum.EasingStyle.Back)
end

UnlockStageEvent.OnClientEvent:Connect(function(unlockName: string)
	local cultTycoon = workspace:FindFirstChild("CultTycoon", true)
	if not cultTycoon then
		cultTycoon = workspace:WaitForChild("CultTycoon", 3)
	end
	if not cultTycoon then return end

	-- Universal Button Pop-In Animation for Buildings 1, 2 & 3
	local btnTarget = unlockName:match("^ButtonReveal_(.+)")
	if btnTarget then
		local b1 = cultTycoon:FindFirstChild("Building1") or cultTycoon:WaitForChild("Building1", 2)
		local preacherFolder = b1 and (b1:FindFirstChild("StreetPreacherBuilding") or b1:WaitForChild("StreetPreacherBuilding", 2))
		local b2 = cultTycoon:FindFirstChild("Building2") or cultTycoon:WaitForChild("Building2", 2)
		local temple = b2 and (b2:FindFirstChild("StorageUnitTempleBuilding") or b2:WaitForChild("StorageUnitTempleBuilding", 2))
		local b3 = cultTycoon:FindFirstChild("Building3") or cultTycoon:WaitForChild("Building3", 2)
		local compound = b3 and (b3:FindFirstChild("Suburban Compound Building") or b3:WaitForChild("Suburban Compound Building", 2))

		local targetFolder: Instance? = nil
		if btnTarget == "B2_Manager" then
			targetFolder = temple and temple:FindFirstChild("Manager")
		elseif btnTarget == "B3_Manager" then
			targetFolder = compound and compound:FindFirstChild("Manager")
		elseif compound and compound:FindFirstChild(btnTarget) then
			targetFolder = compound:FindFirstChild(btnTarget)
		elseif temple and temple:FindFirstChild(btnTarget) then
			targetFolder = temple:FindFirstChild(btnTarget)
		elseif preacherFolder and preacherFolder:FindFirstChild(btnTarget) then
			targetFolder = preacherFolder:FindFirstChild(btnTarget)
		end

		if targetFolder then
			local btnObj = targetFolder:FindFirstChild("UpgradeButton")
				or targetFolder:FindFirstChild("CosmeticButton")
				or targetFolder:FindFirstChild("ManagerButton")
				or targetFolder:FindFirstChild("NewBuildingButton")
			if btnObj then
				animateButtonPopIn(btnObj)
			else
				animateButtonPopIn(targetFolder)
			end
		end
		return
	end

	-- Building 3: Suburban Compound Base Stage
	if unlockName == "Building3_BaseStage" then
		local b3 = cultTycoon:FindFirstChild("Building3") or cultTycoon:WaitForChild("Building3", 3)
		local compound = b3 and (b3:FindFirstChild("Suburban Compound Building") or b3:WaitForChild("Suburban Compound Building", 3))
		if not compound then return end

		local collectGui = compound:FindFirstChild("CollectUpgradeGui") or compound:WaitForChild("CollectUpgradeGui", 2)
		if collectGui then
			animateInstanceSlide(collectGui, Vector3.new(0, -4, 0), 1.2)
		end
		return
	end

	-- Building 3: Button Reveal when Donation Machine is purchased in Building 2
	if unlockName == "Building3_ButtonReveal" then
		local b3 = cultTycoon:FindFirstChild("Building3") or cultTycoon:WaitForChild("Building3", 2)
		local btnFolder = b3 and (b3:FindFirstChild("NewBuildingButton") or b3:WaitForChild("NewBuildingButton", 2))
		if btnFolder then
			animateButtonPopIn(btnFolder)
		end
		return
	end

	-- Building 2: Storage Unit Temple Base Stage (Multi-directional assembly, 2x slower)
	if unlockName == "Building2_BaseStage" then
		local b2 = cultTycoon:FindFirstChild("Building2") or cultTycoon:WaitForChild("Building2", 3)
		local temple = b2 and (b2:FindFirstChild("StorageUnitTempleBuilding") or b2:WaitForChild("StorageUnitTempleBuilding", 3))
		if not temple then return end

		local storageUnit = temple:FindFirstChild("Storage Unit") or temple:WaitForChild("Storage Unit", 2)
		if storageUnit then
			-- Directional animations for storage unit shell (1.1s - twice as slow)
			animateInstanceSlide(storageUnit:FindFirstChild("Ceiling"), Vector3.new(0, 10, 0), 1.1)
			animateInstanceSlide(storageUnit:FindFirstChild("Floor"), Vector3.new(0, -6, 0), 1.1)
			animateInstanceSlide(storageUnit:FindFirstChild("LeftWall"), Vector3.new(-8, 0, 0), 1.1)
			animateInstanceSlide(storageUnit:FindFirstChild("RightWall"), Vector3.new(8, 0, 0), 1.1)
			animateInstanceSlide(storageUnit:FindFirstChild("FrontWall"), Vector3.new(0, 0, 8), 1.1)
			animateInstanceSlide(storageUnit:FindFirstChild("BackWall"), Vector3.new(0, 0, -8), 1.1)
		end

		-- Side Addon Storage Units (pop-up from Y - 6 studs over 1.2s)
		for _, child in ipairs(temple:GetChildren()) do
			if child.Name:find("addon") and child:IsA("Model") then
				animateInstanceSlide(child, Vector3.new(0, -6, 0), 1.2)
			end
		end

		-- Interior props pop-up (starts simultaneously with the building structure, 1.2s duration)
		local podium = temple:FindFirstChild("Podium") or temple:WaitForChild("Podium", 2)
		local cultMember = temple:FindFirstChild("Cult Member") or temple:WaitForChild("Cult Member", 2)
		local collectGui = temple:FindFirstChild("CollectUpgradeGui") or temple:WaitForChild("CollectUpgradeGui", 2)

		animateInstanceSlide(podium, Vector3.new(0, -4, 0), 1.2)
		animateInstanceSlide(cultMember, Vector3.new(0, -4, 0), 1.2)
		animateInstanceSlide(collectGui, Vector3.new(0, -4, 0), 1.2)
		return
	end

	-- Building 2: Button Reveal when FloorChalk is purchased in Building 1
	if unlockName == "Building2_ButtonReveal" then
		local b2 = cultTycoon:FindFirstChild("Building2") or cultTycoon:WaitForChild("Building2", 2)
		local btnFolder = b2 and (b2:FindFirstChild("NewBuildingButton") or b2:WaitForChild("NewBuildingButton", 2))
		if btnFolder then
			animateButtonPopIn(btnFolder)
		end
		return
	end

	-- Building 1 Starter Base
	if unlockName == "BaseStage" then
		local b1 = cultTycoon:FindFirstChild("Building1") or cultTycoon:WaitForChild("Building1", 2)
		local preacherFolder = b1 and (b1:FindFirstChild("StreetPreacherBuilding") or b1:WaitForChild("StreetPreacherBuilding", 2))
		if preacherFolder then
			animateModelSlideIn(preacherFolder:FindFirstChild("Table") or preacherFolder:WaitForChild("Table", 2))
			animateModelSlideIn(preacherFolder:FindFirstChild("Cult Member") or preacherFolder:WaitForChild("Cult Member", 2))
			animateModelSlideIn(preacherFolder:FindFirstChild("CollectUpgradeGui") or preacherFolder:WaitForChild("CollectUpgradeGui", 2))
		end
		return
	end

	-- Universal Sequential Stage Handling (Buildings 1, 2 & 3)
	local targetFolderName = STAGE_FOLDER_MAP[unlockName]
	if targetFolderName then
		local stageFolder: Instance? = nil
		local isB2 = (unlockName:find("^Building2") ~= nil)
			or unlockName == "CarpetingStage"
			or unlockName == "FoldingChairsStage"
			or unlockName == "MicrophoneStage"
			or unlockName == "BoomboxStage"
			or unlockName == "AltarStage"
			or unlockName == "DonationMachineStage"
			or unlockName == "PosePostersStage"
			or unlockName == "ShutterDoorStage"
			or unlockName == "HVACStage"
			or unlockName == "CamerasStage"
			or unlockName == "MoneySafesStage"

		local b3 = cultTycoon:FindFirstChild("Building3") or cultTycoon:WaitForChild("Building3", 2)
		local compound = b3 and (b3:FindFirstChild("Suburban Compound Building") or b3:WaitForChild("Suburban Compound Building", 2))

		local b2 = cultTycoon:FindFirstChild("Building2") or cultTycoon:WaitForChild("Building2", 2)
		local temple = b2 and (b2:FindFirstChild("StorageUnitTempleBuilding") or b2:WaitForChild("StorageUnitTempleBuilding", 2))

		local b1 = cultTycoon:FindFirstChild("Building1") or cultTycoon:WaitForChild("Building1", 2)
		local preacherFolder = b1 and (b1:FindFirstChild("StreetPreacherBuilding") or b1:WaitForChild("StreetPreacherBuilding", 2))

		if compound and compound:FindFirstChild(targetFolderName) then
			stageFolder = compound:FindFirstChild(targetFolderName)
		elseif isB2 and temple then
			stageFolder = temple:FindFirstChild(targetFolderName) or temple:WaitForChild(targetFolderName, 2)
		elseif preacherFolder then
			stageFolder = preacherFolder:FindFirstChild(targetFolderName) or preacherFolder:WaitForChild(targetFolderName, 2)
		end

		-- Fallback check: if stageFolder is not in the expected building, check other buildings
		if not stageFolder then
			if compound and compound:FindFirstChild(targetFolderName) then
				stageFolder = compound:FindFirstChild(targetFolderName)
			elseif isB2 and preacherFolder then
				stageFolder = preacherFolder:FindFirstChild(targetFolderName)
			elseif temple then
				stageFolder = temple:FindFirstChild(targetFolderName)
			end
		end

		if stageFolder then
			for _, child in ipairs(stageFolder:GetChildren()) do
				if child.Name ~= "UpgradeButton" and child.Name ~= "CosmeticButton" and child.Name ~= "ManagerButton" then
					animateModelSlideIn(child)
				end
			end
		end
	end
end)

print("[BuildingAnimatorClient] Universal Buildings 1, 2 & 3 slide-in pop animations initialized.")
