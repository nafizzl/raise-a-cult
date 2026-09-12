--!strict
-- PosePosterClient.local.luau
-- Robust PlayerGui Adornee Architecture for 3D R15 Pose Posters.
-- Parents SurfaceGuis to localPlayer.PlayerGui with Adornee set to the wall poster parts.
-- This ensures ViewportFrame 3D models render properly on client GPUs with zero words and museum-quality presentation.

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local activeGuis: { [BasePart]: SurfaceGui } = {}

local function setupPoster(posterPart: BasePart)
	if activeGuis[posterPart] and activeGuis[posterPart].Parent then
		return -- Already mounted and rendering
	end

	local poseIndex = tonumber(posterPart.Name:match("%d+")) or 1

	-- Hide any physical SurfaceGui on the workspace part to prevent z-fighting
	local physicalSg = posterPart:FindFirstChild("PosePosterSurfaceGui") :: SurfaceGui?
	if physicalSg then
		physicalSg.Enabled = false
	end

	-- Create client-side SurfaceGui in PlayerGui adorning the poster part
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "PosePoster_" .. poseIndex .. "_Gui"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.CanvasSize = Vector2.new(600, 800)
	surfaceGui.LightInfluence = 0
	surfaceGui.Brightness = 1.0
	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surfaceGui.Adornee = posterPart
	surfaceGui.Parent = playerGui

	activeGuis[posterPart] = surfaceGui

	-- Dark whitish museum placard background
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(222, 224, 228)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = surfaceGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(48, 50, 58)
	stroke.Thickness = 5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = mainFrame

	-- ViewportFrame with generous side and edge padding
	local vpFrame = Instance.new("ViewportFrame")
	vpFrame.Name = "PoseViewport"
	vpFrame.Size = UDim2.new(1, -48, 1, -48)
	vpFrame.Position = UDim2.new(0, 24, 0, 24)
	vpFrame.BackgroundColor3 = Color3.fromRGB(222, 224, 228)
	vpFrame.BorderSizePixel = 0
	vpFrame.LightColor = Color3.fromRGB(255, 255, 255)
	vpFrame.Ambient = Color3.fromRGB(190, 192, 198)
	vpFrame.LightDirection = Vector3.new(-1, -1.5, -2)
	vpFrame.Parent = mainFrame

	local vpCorner = Instance.new("UICorner")
	vpCorner.CornerRadius = UDim.new(0, 10)
	vpCorner.Parent = vpFrame

	-- Local Camera rotated +90 deg so avatar stands upright with elegant side padding
	local camera = Instance.new("Camera")
	camera.Name = "Camera"
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 46
	local baseCF = CFrame.lookAt(Vector3.new(0, 0.2, 10.5), Vector3.new(0, 0.2, 0))
	camera.CFrame = baseCF * CFrame.Angles(0, 0, math.rad(90))
	camera.Parent = vpFrame
	vpFrame.CurrentCamera = camera

	-- Clone the pre-posed dummy from the workspace template if available
	local templateDummy: Model? = nil
	if physicalSg then
		local mf = physicalSg:FindFirstChild("MainFrame")
		local vp = mf and mf:FindFirstChild("PoseViewport")
		templateDummy = vp and vp:FindFirstChild("PosedLeader") :: Model?
	end

	if templateDummy then
		local dummy = templateDummy:Clone()
		dummy.Name = "PosedLeader"
		dummy.Parent = vpFrame
	else
		-- Fallback: Fetch avatar via UserId
		task.spawn(function()
			local targetUserId = 51437187 -- IsaccNewton123
			if localPlayer.UserId > 0 then
				targetUserId = localPlayer.UserId
			end
			local s, dummy = pcall(function()
				return Players:CreateHumanoidModelFromUserId(targetUserId)
			end)
			if s and dummy then
				dummy.Name = "PosedLeader"
				dummy.Parent = workspace
				task.wait(0.08)
				for _, p in ipairs(dummy:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Anchored = true
						p.CanCollide = false
					end
				end
				if dummy.PrimaryPart then
					dummy:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, 0))
				end
				dummy.Parent = vpFrame
			end
		end)
	end
end

local function scanPosters()
	local postersFolder = workspace:FindFirstChild("CultTycoon")
		and workspace.CultTycoon:FindFirstChild("Building2")
		and workspace.CultTycoon.Building2:FindFirstChild("StorageUnitTempleBuilding")
		and workspace.CultTycoon.Building2.StorageUnitTempleBuilding:FindFirstChild("PosePosters")

	if postersFolder then
		for _, child in ipairs(postersFolder:GetChildren()) do
			if child:IsA("BasePart") and child.Name:find("PlayerPosePoster_") then
				setupPoster(child)
			end
		end
	end
end

-- Initialize scanning
task.spawn(function()
	scanPosters()
	task.wait(0.5)
	scanPosters()
	task.wait(1.5)
	scanPosters()
end)

-- Continuously listen for posters entering workspace
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("BasePart") and desc.Name:find("PlayerPosePoster_") then
		task.wait(0.2)
		setupPoster(desc)
	end
end)
