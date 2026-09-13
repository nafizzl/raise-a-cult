--!strict
-- MusicController.local.luau
-- Maintains ambient background music looping and restart protection.
-- Playback is initially kicked off when the LoadingScreen displays in ReplicatedFirst.

local SoundService = game:GetService("SoundService")

local DEFAULT_TRACK_ID = "rbxassetid://1840684529"
local TARGET_VOLUME = 0.35

local musicSound = SoundService:WaitForChild("BackgroundMusic", 10) :: Sound?
if musicSound then
	musicSound.Looped = true

	-- Safety monitor: restart playback if interrupted or stopped
	musicSound.Ended:Connect(function()
		if musicSound and not musicSound.IsPlaying then
			musicSound:Play()
		end
	end)
end

print("[MusicController] Background music supervisor ready.")
