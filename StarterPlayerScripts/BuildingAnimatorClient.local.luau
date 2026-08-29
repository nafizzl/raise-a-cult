--!strict
-- BuildingAnimatorClient.luau
-- Handles dynamic slide-in pop animations using PivotTo for newly spawned models and props.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockStageEvent = RemoteEvents:WaitForChild("UnlockStage") :: RemoteEvent

local function animateModelSlideIn(instanceObj: Instance?)
    if not instanceObj then return end

    if instanceObj:IsA("Model") then
        local targetCFrame = instanceObj:GetPivot()
        local startCFrame = targetCFrame * CFrame.new(0, -4, 0)

        instanceObj:PivotTo(startCFrame)

        local cfVal = Instance.new("CFrameValue")
        cfVal.Value = startCFrame
        cfVal.Changed:Connect(function(newCF)
            if instanceObj and instanceObj:IsA("Model") then
                instanceObj:PivotTo(newCF)
            end
        end)

        local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(cfVal, tweenInfo, {
            Value = targetCFrame
        })
        tween:Play()
        tween.Completed:Connect(function()
            cfVal:Destroy()
        end)

    elseif instanceObj:IsA("BasePart") then
        local targetCFrame = instanceObj.CFrame
        local startCFrame = targetCFrame * CFrame.new(0, -4, 0)

        instanceObj.CFrame = startCFrame

        local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local tween = TweenService:Create(instanceObj, tweenInfo, {
            CFrame = targetCFrame
        })
        tween:Play()
    end
end

UnlockStageEvent.OnClientEvent:Connect(function(unlockName: string)
    local cultTycoon = workspace:FindFirstChild("CultTycoon", true)
    if not cultTycoon then
        cultTycoon = workspace:WaitForChild("CultTycoon", 3)
    end
    if not cultTycoon then return end

    local b1 = cultTycoon:FindFirstChild("Building1") or cultTycoon:WaitForChild("Building1", 2)
    if not b1 then return end

    local preacherFolder = b1:FindFirstChild("StreetPreacherBuilding") or b1:WaitForChild("StreetPreacherBuilding", 2)
    if not preacherFolder then return end

    if unlockName == "BaseStage" then
        animateModelSlideIn(preacherFolder:FindFirstChild("Table") or preacherFolder:WaitForChild("Table", 2))
        animateModelSlideIn(preacherFolder:FindFirstChild("Cult Member") or preacherFolder:WaitForChild("Cult Member", 2))
        animateModelSlideIn(preacherFolder:FindFirstChild("CollectUpgradeGui") or preacherFolder:WaitForChild("CollectUpgradeGui", 2))
    elseif unlockName == "FlyersStage" then
        local flyersFolder = preacherFolder:FindFirstChild("Flyers") or preacherFolder:WaitForChild("Flyers", 2)
        if flyersFolder then
            for _, child in ipairs(flyersFolder:GetChildren()) do
                if child.Name == "WorshipFlyers" then
                    animateModelSlideIn(child)
                end
            end
        end
    elseif unlockName == "MorePreachersStage" then
        local preachersFolder = preacherFolder:FindFirstChild("MorePreachers") or preacherFolder:WaitForChild("MorePreachers", 2)
        if preachersFolder then
            for _, child in ipairs(preachersFolder:GetChildren()) do
                if child:IsA("Model") and child.Name ~= "UpgradeButton" then
                    animateModelSlideIn(child)
                end
            end
        end
    elseif unlockName == "ManagerStage" then
        local managerFolder = preacherFolder:FindFirstChild("Manager") or preacherFolder:WaitForChild("Manager", 2)
        if managerFolder then
            for _, child in ipairs(managerFolder:GetChildren()) do
                if child.Name ~= "ManagerButton" and (child:IsA("Model") or child:IsA("BasePart")) then
                    animateModelSlideIn(child)
                end
            end
        end
    end
end)

print("[BuildingAnimatorClient] Manager pop-in animation handler wired.")
