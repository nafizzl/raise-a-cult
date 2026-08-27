-- BuildingAnimatorClient.luau
-- Handles dynamic slide-in pop animations using PivotTo for models

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UnlockStageEvent = RemoteEvents:WaitForChild("UnlockStage")

local function animateModelSlideIn(instanceObj)
    if not instanceObj then return end

    if instanceObj:IsA("Model") then
        local targetCFrame = instanceObj:GetPivot()
        local startCFrame = targetCFrame * CFrame.new(0, -4, 0)

        instanceObj:PivotTo(startCFrame)

        local cfVal = Instance.new("CFrameValue")
        cfVal.Value = startCFrame
        cfVal.Changed:Connect(function(newCF)
            instanceObj:PivotTo(newCF)
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

UnlockStageEvent.OnClientEvent:Connect(function(unlockName)
    local b1Folder = workspace:FindFirstChild("CultTycoon", true)
    if b1Folder then
        local b1 = b1Folder:FindFirstChild("Building1")
        if b1 then
            local preacherFolder = b1:FindFirstChild("StreetPreacherBuilding")
            if preacherFolder then
                if unlockName == "BaseStage" then
                    animateModelSlideIn(preacherFolder:FindFirstChild("Table"))
                    animateModelSlideIn(preacherFolder:FindFirstChild("Cult Member"))
                    animateModelSlideIn(preacherFolder:FindFirstChild("CollectUpgradeGui"))
                elseif unlockName == "FlyersStage" then
                    local flyersFolder = preacherFolder:FindFirstChild("Flyers")
                    if flyersFolder then
                        for _, child in ipairs(flyersFolder:GetChildren()) do
                            if child.Name == "WorshipFlyers" then
                                animateModelSlideIn(child)
                            end
                        end
                    end
                elseif unlockName == "MorePreachersStage" then
                    local preachersFolder = preacherFolder:FindFirstChild("MorePreachers")
                    if preachersFolder then
                        for _, child in ipairs(preachersFolder:GetChildren()) do
                            if child:IsA("Model") and child.Name ~= "UpgradeButton" then
                                animateModelSlideIn(child)
                            end
                        end
                    end
                end
            end
        end
    end
end)

print("[BuildingAnimatorClient] Updated PivotTo model animation.")
