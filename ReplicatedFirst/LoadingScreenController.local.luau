--!strict
-- LoadingScreenController.client.luau
-- Manages custom ReplicatedFirst loading screen, dynamic asset preloading, progress bar,
-- 3-second delayed skip button, gentle logo rocking animation, and smooth slide-up exit.

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Instantly remove default Roblox loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 2. Find or mount LoadingScreen in PlayerGui
local loadingScreen = playerGui:FindFirstChild("LoadingScreen") :: ScreenGui?
if not loadingScreen then
	local rfGui = ReplicatedFirst:FindFirstChild("LoadingScreen") :: ScreenGui?
	if rfGui then
		loadingScreen = rfGui:Clone()
		loadingScreen.Parent = playerGui
	else
		local sgGui = game:GetService("StarterGui"):FindFirstChild("LoadingScreen") :: ScreenGui?
		if sgGui then
			loadingScreen = sgGui:Clone()
			loadingScreen.Parent = playerGui
		end
	end
end

if not loadingScreen then
	warn("[LoadingScreen] LoadingScreen ScreenGui could not be located.")
	return
end

loadingScreen.IgnoreGuiInset = true
loadingScreen.DisplayOrder = 999999
loadingScreen.Enabled = true

local bg = loadingScreen:WaitForChild("Background") :: Frame
local logo = bg:WaitForChild("Logo") :: ImageLabel
local bar = bg:WaitForChild("LoadingBar") :: Frame
local fill = bar:WaitForChild("ProgressFill") :: Frame
local assetsLabel = bg:WaitForChild("AssetsLoaded") :: TextLabel
local skipBtn = bg:WaitForChild("SkipButton") :: TextButton

-- 3. Gentle Logo Rocking Animation (-4.5 deg to +4.5 deg)
logo.Rotation = -4.5
local rockTween = TweenService:Create(
	logo,
	TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Rotation = 4.5 }
)
rockTween:Play()

-- 4. Initial Component States
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(245, 45, 60)
assetsLabel.Text = "0/0"

skipBtn.Visible = false
skipBtn.BackgroundTransparency = 1
skipBtn.TextTransparency = 1
local skipStrokes: { UIStroke } = {}
for _, c in ipairs(skipBtn:GetChildren()) do
	if c:IsA("UIStroke") then
		c.Transparency = 1
		table.insert(skipStrokes, c)
	end
end

-- 5. Dismiss Transition Function (Slide up past the top of the screen)
local isDismissed = false

local function dismissLoadingScreen()
	if isDismissed then return end
	isDismissed = true

	rockTween:Cancel()

	local slideUpTween = TweenService:Create(
		bg,
		TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, -0.65, 0) }
	)

	slideUpTween:Play()
	slideUpTween.Completed:Connect(function()
		loadingScreen:Destroy()
	end)
end

-- 6. Delayed Skip Button Reveal (After 3 seconds)
task.delay(3.0, function()
	if isDismissed then return end

	skipBtn.Visible = true
	local fadeInInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(skipBtn, fadeInInfo, {
		BackgroundTransparency = 0,
		TextTransparency = 0,
	}):Play()

	for _, stroke in ipairs(skipStrokes) do
		TweenService:Create(stroke, fadeInInfo, { Transparency = 0 }):Play()
	end

	skipBtn.Activated:Connect(function()
		dismissLoadingScreen()
	end)
end)

-- 7. Dynamic Asset Discovery
local function collectAssets(): { Instance }
	local assets: { Instance } = {}

	local function scanContainer(container: Instance?)
		if not container then return end
		for _, desc in ipairs(container:GetDescendants()) do
			if desc:IsA("MeshPart") or desc:IsA("SpecialMesh")
				or desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("SurfaceAppearance")
				or desc:IsA("Sound") or desc:IsA("ImageLabel") or desc:IsA("ImageButton")
				or desc:IsA("Animation") then
				table.insert(assets, desc)
			end
		end
	end

	scanContainer(workspace:FindFirstChild("CultTycoon"))
	scanContainer(ReplicatedStorage:FindFirstChild("BuildingTemplates"))
	scanContainer(SoundService)
	scanContainer(playerGui)

	return assets
end

-- 8. Execution & Preload Loop
task.spawn(function()
	-- Brief tick to let initial instances replicate
	task.wait(0.1)

	local assetList = collectAssets()
	local total = math.max(#assetList, 1)
	local loaded = 0

	assetsLabel.Text = string.format("0/%d", total)

	local fillTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Safety timeout: 8 seconds maximum ceiling
	local timeoutThread = task.delay(8.0, function()
		if not isDismissed then
			dismissLoadingScreen()
		end
	end)

	ContentProvider:PreloadAsync(assetList, function(_contentId: string, _status: Enum.AssetFetchStatus)
		if isDismissed then return end
		loaded += 1
		assetsLabel.Text = string.format("%d/%d", loaded, total)

		local fraction = math.clamp(loaded / total, 0, 1)
		TweenService:Create(fill, fillTweenInfo, {
			Size = UDim2.new(fraction, 0, 1, 0)
		}):Play()
	end)

	task.cancel(timeoutThread)

	if not isDismissed then
		-- Finalize to 100% and brief pause for visual polish
		assetsLabel.Text = string.format("%d/%d", total, total)
		TweenService:Create(fill, fillTweenInfo, { Size = UDim2.new(1, 0, 1, 0) }):Play()
		task.wait(0.35)
		dismissLoadingScreen()
	end
end)
