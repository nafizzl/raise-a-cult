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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Find or mount custom LoadingScreen in PlayerGui immediately
local loadingScreen = playerGui:FindFirstChild("LoadingScreen") :: ScreenGui?
if not loadingScreen then
	local rfGui = ReplicatedFirst:FindFirstChild("LoadingScreen") :: ScreenGui?
	if rfGui then
		loadingScreen = rfGui:Clone()
		loadingScreen.ResetOnSpawn = false
		loadingScreen.IgnoreGuiInset = true
		loadingScreen.DisplayOrder = 999999
		loadingScreen.Enabled = true
		loadingScreen.Parent = playerGui
	else
		loadingScreen = playerGui:WaitForChild("LoadingScreen", 5) :: ScreenGui?
	end
end

if not loadingScreen then
	warn("[LoadingScreen] LoadingScreen ScreenGui could not be located.")
	return
end

loadingScreen.ResetOnSpawn = false
loadingScreen.IgnoreGuiInset = true
loadingScreen.DisplayOrder = 999999
loadingScreen.Enabled = true

-- 2. NOW that custom screen is active, dismiss the default Roblox spinner
ReplicatedFirst:RemoveDefaultLoadingScreen()

local bg = loadingScreen:WaitForChild("Background") :: Frame
local logo = bg:WaitForChild("Logo") :: ImageLabel
local bar = bg:WaitForChild("LoadingBar") :: Frame
local fill = bar:WaitForChild("ProgressFill") :: Frame
local assetsLabel = bg:WaitForChild("AssetsLoaded") :: TextLabel
local skipBtn = bg:WaitForChild("SkipButton") :: TextButton

-- 3. Start background music exactly when the loading screen appears
task.spawn(function()
	local musicSound = SoundService:WaitForChild("BackgroundMusic", 5) :: Sound?
	if musicSound and not musicSound.IsPlaying then
		musicSound.Looped = true
		musicSound.Volume = 0
		musicSound:Play()
		TweenService:Create(musicSound, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Volume = 0.35
		}):Play()
	end
end)

-- 4. Gentle Logo Rocking Animation (-4.5 deg to +4.5 deg)
logo.Rotation = -4.5
local rockTween = TweenService:Create(
	logo,
	TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Rotation = 4.5 }
)
rockTween:Play()

-- 5. Initial Component States
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(245, 45, 60)

assetsLabel.Text = ""
assetsLabel.TextTransparency = 1
local labelStroke = assetsLabel:FindFirstChildWhichIsA("UIStroke")
if labelStroke then
	labelStroke.Transparency = 1
end

skipBtn.Visible = false
skipBtn.BackgroundColor3 = Color3.fromRGB(245, 45, 60)
skipBtn.BackgroundTransparency = 1
skipBtn.TextTransparency = 1
local skipStrokes: { UIStroke } = {}
for _, c in ipairs(skipBtn:GetChildren()) do
	if c:IsA("UIStroke") then
		c.Transparency = 1
		table.insert(skipStrokes, c)
	end
end

-- 6. Dismiss Transition Function (Slide up past the top of the screen)
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

-- 7. Delayed Skip Button Reveal (After 3 seconds)
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

-- 8. Dynamic Asset Discovery via PreloadManifest
local function collectAssets(): { string }
	local manifestMod = ReplicatedStorage:WaitForChild("PreloadManifest", 5) :: ModuleScript?
	if manifestMod then
		local success, result = pcall(require, manifestMod)
		if success and type(result) == "table" and #result > 0 then
			print(string.format("[LoadingScreen] Loaded %d assets from PreloadManifest.", #result))
			return result
		end
	end

	-- Fallback dynamic scan if manifest is unavailable
	local contentIds: { string } = {}
	local function addId(id: string?)
		if id and id ~= "" then
			table.insert(contentIds, id)
		end
	end

	local function scanContainer(container: Instance?)
		if not container then return end
		for _, inst in ipairs(container:GetDescendants()) do
			if inst:IsA("MeshPart") then
				addId(inst.MeshId)
				addId(inst.TextureID)
			elseif inst:IsA("SpecialMesh") then
				addId(inst.MeshId)
				addId(inst.TextureId)
			elseif inst:IsA("Decal") or inst:IsA("Texture") then
				addId(inst.Texture)
			elseif inst:IsA("Sound") then
				addId(inst.SoundId)
			elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
				addId(inst.Image)
			elseif inst:IsA("Animation") then
				addId(inst.AnimationId)
			end
		end
	end

	scanContainer(workspace)
	scanContainer(ReplicatedStorage)
	scanContainer(SoundService)
	scanContainer(playerGui)

	print(string.format("[LoadingScreen] Fallback scan found %d assets.", #contentIds))
	return contentIds
end

-- 9. Execution & Preload Loop
task.spawn(function()
	-- Preload label and font so FredokaOne renders immediately without fallback font flash
	ContentProvider:PreloadAsync({ assetsLabel })

	local assetList = collectAssets()
	local total = math.max(#assetList, 1)
	local loaded = 0

	-- Reveal formatted counter now that real total is known and font is ready
	assetsLabel.Text = string.format("0/%d", total)
	assetsLabel.TextTransparency = 0
	if labelStroke then
		labelStroke.Transparency = 0
	end

	local fillTweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Safety timeout: 8 seconds maximum ceiling
	local timeoutThread = task.delay(8.0, function()
		if not isDismissed then
			dismissLoadingScreen()
		end
	end)

	ContentProvider:PreloadAsync(assetList, function(_contentId: string, _status: Enum.AssetFetchStatus)
		if isDismissed then return end
		loaded = math.min(loaded + 1, total)
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
