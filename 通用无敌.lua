-- LocalScript in StarterPlayer â†’ StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GodModeToggle"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 50)
frame.Position = UDim2.new(0.5, -100, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
frame.BackgroundTransparency = 0.5
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame)

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, 0, 1, 0)
button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
button.BackgroundTransparency = 0.5
button.Text = "esp无敌: OFF"
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Parent = frame
Instance.new("UICorner", button)

-- State
local godMode = false
local humanoid
local renderConnection

-- Update humanoid protection
local function updateGodMode()
	if not humanoid then return end

	if godMode then
		humanoid.BreakJointsOnDeath = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid.Health = 100

		if not renderConnection then
			renderConnection = RunService.RenderStepped:Connect(function()
				if humanoid and humanoid.Parent and humanoid.Health < 100 then
					humanoid.Health = 100
				end
			end)
		end
	else
		humanoid.BreakJointsOnDeath = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)

		if renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
	end
end

-- Setup character
local function setupCharacter(character)
	humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Reapply settings on character respawn
	updateGodMode()

	humanoid.Died:Connect(function()
		if godMode then
			local hrp = humanoid.Parent:FindFirstChild("HumanoidRootPart")
			local newHumanoid = Instance.new("Humanoid")
			newHumanoid.Parent = humanoid.Parent
			humanoid:Destroy()
			humanoid = newHumanoid
			setupCharacter(newHumanoid.Parent)

			if hrp then
				humanoid.Parent:MoveTo(hrp.Position)
			end
		end
	end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end

-- Toggle button
button.MouseButton1Click:Connect(function()
	godMode = not godMode
	button.Text = "esp无敌: " .. (godMode and "ON" or "OFF")
	updateGodMode()
end)