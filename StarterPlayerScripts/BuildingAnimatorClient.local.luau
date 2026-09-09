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
}

local function animateInstanceSlide(instanceObj: Instance?, worldOffset: Vector3, duration: number?, easingStyle: Enum.EasingStyle?)
    if not instanceObj then return end
    duration = duration or 0.6
    easingStyle = easingStyle or Enum.EasingStyle.Back

    if instanceObj:IsA("Model") then
        local targetCFrame = instanceObj:GetPivot()
        local startCFrame = CFrame.new(worldOffset) * targetCFrame

        instanceObj:PivotTo(startCFrame)

        local cfVal = Instance.new("CFrameValue")
        cfVal.Value = startCFrame
        cfVal.Changed:Connect(function(newCF)
            if instanceObj and instanceObj:IsA("Model") then
                instanceObj:PivotTo(newCF)
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

    -- Universal Button Pop-In Animation for Building 1 Buttons
    local btnTarget = unlockName:match("^ButtonReveal_(.+)")
    if btnTarget then
        local b1 = cultTycoon:FindFirstChild("Building1") or cultTycoon:WaitForChild("Building1", 2)
        local preacherFolder = b1 and (b1:FindFirstChild("StreetPreacherBuilding") or b1:WaitForChild("StreetPreacherBuilding", 2))
        if preacherFolder then
            local targetFolder = preacherFolder:FindFirstChild(btnTarget) or preacherFolder:WaitForChild(btnTarget, 2)
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
            -- Ceiling pops down from above
            animateInstanceSlide(storageUnit:FindFirstChild("Ceiling"), Vector3.new(0, 10, 0), 1.1)
            -- Floor pops up from below
            animateInstanceSlide(storageUnit:FindFirstChild("Floor"), Vector3.new(0, -6, 0), 1.1)
            -- LeftWall pops rightwards (starts at -X)
            animateInstanceSlide(storageUnit:FindFirstChild("LeftWall"), Vector3.new(-8, 0, 0), 1.1)
            -- RightWall pops leftwards (starts at +X)
            animateInstanceSlide(storageUnit:FindFirstChild("RightWall"), Vector3.new(8, 0, 0), 1.1)
            -- FrontWall pops backwards into place (starts at +Z)
            animateInstanceSlide(storageUnit:FindFirstChild("FrontWall"), Vector3.new(0, 0, 8), 1.1)
            -- BackWall pops forwards into place (starts at -Z)
            animateInstanceSlide(storageUnit:FindFirstChild("BackWall"), Vector3.new(0, 0, -8), 1.1)
            -- Light drops down from ceiling with slight bounce
            animateInstanceSlide(storageUnit:FindFirstChild("Light"), Vector3.new(0, 6, 0), 1.3)
        end

        -- Staggered interior props pop-up after the structure lands (0.70s delay, 1.2s duration)
        task.delay(0.70, function()
            local podium = temple:FindFirstChild("Podium") or temple:WaitForChild("Podium", 2)
            local cultMember = temple:FindFirstChild("Cult Member") or temple:WaitForChild("Cult Member", 2)
            local collectGui = temple:FindFirstChild("CollectUpgradeGui") or temple:WaitForChild("CollectUpgradeGui", 2)

            animateInstanceSlide(podium, Vector3.new(0, -4, 0), 1.2)
            animateInstanceSlide(cultMember, Vector3.new(0, -4, 0), 1.2)
            animateInstanceSlide(collectGui, Vector3.new(0, -4, 0), 1.2)
        end)
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

    -- Building 1 Upgrades and Base (1.2s duration - twice as slow)
    local b1 = cultTycoon:FindFirstChild("Building1") or cultTycoon:WaitForChild("Building1", 2)
    if not b1 then return end

    local preacherFolder = b1:FindFirstChild("StreetPreacherBuilding") or b1:WaitForChild("StreetPreacherBuilding", 2)
    if not preacherFolder then return end

    if unlockName == "BaseStage" then
        animateModelSlideIn(preacherFolder:FindFirstChild("Table") or preacherFolder:WaitForChild("Table", 2))
        animateModelSlideIn(preacherFolder:FindFirstChild("Cult Member") or preacherFolder:WaitForChild("Cult Member", 2))
        animateModelSlideIn(preacherFolder:FindFirstChild("CollectUpgradeGui") or preacherFolder:WaitForChild("CollectUpgradeGui", 2))
    else
        local targetFolderName = STAGE_FOLDER_MAP[unlockName]
        if targetFolderName then
            local stageFolder = preacherFolder:FindFirstChild(targetFolderName) or preacherFolder:WaitForChild(targetFolderName, 2)
            if stageFolder then
                for _, child in ipairs(stageFolder:GetChildren()) do
                    if child.Name ~= "UpgradeButton" and child.Name ~= "CosmeticButton" and child.Name ~= "ManagerButton" then
                        animateModelSlideIn(child)
                    end
                end
            end
        end
    end
end)

print("[BuildingAnimatorClient] Universal and directional slide-in pop animation initialized.")
