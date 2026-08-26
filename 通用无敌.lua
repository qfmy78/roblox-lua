```lua
-- LocalScript in StarterPlayer → StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- 通知函数 (融合您的通知代码)
local function sendNotification(title, text, duration)
	duration = duration or 5
	StarterGui:SetCore("SendNotification", {
		Title = title or "GodMode",
		Text = text or "Status Changed",
		Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150",
		Duration = duration
	})
end

-- 创建粉色UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GodModeToggle"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")


local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 50)
frame.Position = UDim2.new(0.5, -100, 0.8, 0)
frame.BackgroundColor3 = Color3.fromRGB(255, 105, 180) -- 粉色
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame)

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, 0, 1, 0)
button.BackgroundColor3 = Color3.fromRGB(255, 20, 147) -- 深粉色
button.Text = "God Mode: OFF"
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Parent = frame
Instance.new("UICorner", button)

-- 状态变量
local godMode = false
local humanoid = nil
local renderConnection = nil

-- 核心无敌逻辑 (提取的核心代码)
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
		-- 发送开启通知
		sendNotification("GodMode", "无敌已开启", 3)
	else
		humanoid.BreakJointsOnDeath = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)

		if renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
		-- 发送关闭通知
		sendNotification("GodMode", "无敌已关闭", 3)
	end
end
-- 角色设置 (提取的核心代码)
local function setupCharacter(character)
	humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

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

-- 按钮点击事件 (切换无敌状态)
button.MouseButton1Click:Connect(function()
	godMode = not godMode
	button.Text = "God Mode: " .. (godMode and "ON" or "OFF")
	updateGodMode()
end)
```
