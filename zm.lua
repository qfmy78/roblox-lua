```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================
-- 配置参数
-- ============================================
local Config = {
    Enabled = false,
    WallCheck = false,
    MaxDistance = 150,
    FOVRadius = 200,
    AimPart = "Head",      -- Head / Body / Leg
    Smoothness = 0.3,      -- 平滑度 0.1=瞬间 0.5=平滑
    MagnetStrength = 0.8,  -- 吸附强度 0.1~1.0，越高越粘
}
-- ============================================
-- 状态变量
-- ============================================
local isDragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil
local lastTarget = nil
local targetLostTimer = 0

-- ============================================
-- 创建 GUI
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleAimbot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
-- ============================================
-- 主悬浮窗
-- ============================================
local FloatingFrame = Instance.new("Frame")
FloatingFrame.Name = "FloatingFrame"
FloatingFrame.Size = UDim2.new(0, 210, 0, 330)
FloatingFrame.Position = UDim2.new(0.5, -105, 0.35, 0)
FloatingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FloatingFrame.BackgroundTransparency = 0.5
FloatingFrame.BorderSizePixel = 0
FloatingFrame.ClipsDescendants = true
FloatingFrame.Parent = ScreenGui

-- 圆角
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = FloatingFrame

-- 边框
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(200, 200, 200)
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.5
MainStroke.Parent = FloatingFrame

-- ============================================
-- 标题栏
-- ============================================
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.BackgroundTransparency = 0.6
TitleBar.BorderSizePixel = 0
TitleBar.Parent = FloatingFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "自瞄"
TitleLabel.TextColor3 = Color3.fromRGB(50, 50, 60)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- 关闭按钮
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 2)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(50, 50, 60)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ============================================
-- 内容区域
-- ============================================
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -44)
Content.Position = UDim2.new(0, 8, 0, 38)
Content.BackgroundTransparency = 1
Content.Parent = FloatingFrame

-- ============================================
-- 开关：启用自瞄
-- ============================================
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.BackgroundTransparency = 0.6
ToggleBtn.Text = "自瞄: 关闭"
ToggleBtn.TextColor3 = Color3.fromRGB(50, 50, 60)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = Content

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

-- ============================================
-- 开关：隔墙检测
-- ============================================
local WallBtn = Instance.new("TextButton")
WallBtn.Size = UDim2.new(1, 0, 0, 26)
WallBtn.Position = UDim2.new(0, 0, 0, 34)
WallBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WallBtn.BackgroundTransparency = 0.6
WallBtn.Text = "隔墙: 关闭"
WallBtn.TextColor3 = Color3.fromRGB(50, 50, 60)
WallBtn.Font = Enum.Font.Gotham
WallBtn.TextSize = 12
WallBtn.Parent = Content

local WallCorner = Instance.new("UICorner")
WallCorner.CornerRadius = UDim.new(0, 6)
WallCorner.Parent = WallBtn

-- ============================================
-- 部位切换按钮
-- ============================================
local PartBtn = Instance.new("TextButton")
PartBtn.Size = UDim2.new(1, 0, 0, 26)
PartBtn.Position = UDim2.new(0, 0, 0, 64)
PartBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PartBtn.BackgroundTransparency = 0.6
PartBtn.Text = "部位: 头部"
PartBtn.TextColor3 = Color3.fromRGB(50, 50, 60)
PartBtn.Font = Enum.Font.Gotham
PartBtn.TextSize = 12
PartBtn.Parent = Content

local PartCorner = Instance.new("UICorner")
PartCorner.CornerRadius = UDim.new(0, 6)
PartCorner.Parent = PartBtn
-- ============================================
-- FOV 大小控制
-- ============================================
local FovLabel = Instance.new("TextLabel")
FovLabel.Size = UDim2.new(0.5, 0, 0, 22)
FovLabel.Position = UDim2.new(0, 0, 0, 94)
FovLabel.BackgroundTransparency = 1
FovLabel.Text = "FOV: " .. Config.FOVRadius
FovLabel.TextColor3 = Color3.fromRGB(50, 50, 60)
FovLabel.Font = Enum.Font.Gotham
FovLabel.TextSize = 12
FovLabel.TextXAlignment = Enum.TextXAlignment.Left
FovLabel.Parent = Content

local FovMinus = Instance.new("TextButton")
FovMinus.Size = UDim2.new(0, 24, 0, 22)
FovMinus.Position = UDim2.new(0.7, 0, 0, 94)
FovMinus.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FovMinus.BackgroundTransparency = 0.6
FovMinus.Text = "−"
FovMinus.TextColor3 = Color3.fromRGB(50, 50, 60)
FovMinus.Font = Enum.Font.GothamBold
FovMinus.TextSize = 16
FovMinus.Parent = Content

local FovMinusCorner = Instance.new("UICorner")
FovMinusCorner.CornerRadius = UDim.new(0, 4)
FovMinusCorner.Parent = FovMinus

local FovPlus = Instance.new("TextButton")
FovPlus.Size = UDim2.new(0, 24, 0, 22)
FovPlus.Position = UDim2.new(0.85, 0, 0, 94)
FovPlus.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FovPlus.BackgroundTransparency = 0.6
FovPlus.Text = "+"
FovPlus.TextColor3 = Color3.fromRGB(50, 50, 60)
FovPlus.Font = Enum.Font.GothamBold
FovPlus.TextSize = 16
FovPlus.Parent = Content

local FovPlusCorner = Instance.new("UICorner")
FovPlusCorner.CornerRadius = UDim.new(0, 4)
FovPlusCorner.Parent = FovPlus

-- ============================================
-- 距离控制
-- ============================================
local DistLabel = Instance.new("TextLabel")
DistLabel.Size = UDim2.new(0.5, 0, 0, 22)
DistLabel.Position = UDim2.new(0, 0, 0, 120)
DistLabel.BackgroundTransparency = 1
DistLabel.Text = "距离: " .. Config.MaxDistance
DistLabel.TextColor3 = Color3.fromRGB(50, 50, 60)
DistLabel.Font = Enum.Font.Gotham
DistLabel.TextSize = 12
DistLabel.TextXAlignment = Enum.TextXAlignment.Left
DistLabel.Parent = Content

local DistMinus = Instance.new("TextButton")
DistMinus.Size = UDim2.new(0, 24, 0, 22)
DistMinus.Position = UDim2.new(0.7, 0, 0, 120)
DistMinus.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DistMinus.BackgroundTransparency = 0.6
DistMinus.Text = "−"
DistMinus.TextColor3 = Color3.fromRGB(50, 50, 60)
DistMinus.Font = Enum.Font.GothamBold
DistMinus.TextSize = 16
DistMinus.Parent = Content

local DistMinusCorner = Instance.new("UICorner")
DistMinusCorner.CornerRadius = UDim.new(0, 4)
DistMinusCorner.Parent = DistMinus

local DistPlus = Instance.new("TextButton")
DistPlus.Size = UDim2.new(0, 24, 0, 22)
DistPlus.Position = UDim2.new(0.85, 0, 0, 120)
DistPlus.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DistPlus.BackgroundTransparency = 0.6
DistPlus.Text = "+"
DistPlus.TextColor3 = Color3.fromRGB(50, 50, 60)
DistPlus.Font = Enum.Font.GothamBold
DistPlus.TextSize = 16
DistPlus.Parent = Content

local DistPlusCorner = Instance.new("UICorner")
DistPlusCorner.CornerRadius = UDim.new(0, 4)
DistPlusCorner.Parent = DistPlus

-- ============================================
-- 🧲 吸附强度控制 (新增)
-- ============================================
local MagnetLabel = Instance.new("TextLabel")
MagnetLabel.Size = UDim2.new(0.5, 0, 0, 22)
MagnetLabel.Position = UDim2.new(0, 0, 0, 146)
MagnetLabel.BackgroundTransparency = 1
MagnetLabel.Text = "吸附: " .. string.format("%.1f", Config.MagnetStrength)
MagnetLabel.TextColor3 = Color3.fromRGB(50, 50, 60)
MagnetLabel.Font = Enum.Font.Gotham
MagnetLabel.TextSize = 12
MagnetLabel.TextXAlignment = Enum.TextXAlignment.Left
MagnetLabel.Parent = Content

local MagnetMinus = Instance.new("TextButton")
MagnetMinus.Size = UDim2.new(0, 24, 0, 22)
MagnetMinus.Position = UDim2.new(0.7, 0, 0, 146)
MagnetMinus.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MagnetMinus.BackgroundTransparency = 0.6
MagnetMinus.Text = "−"
MagnetMinus.TextColor3 = Color3.fromRGB(50, 50, 60)
MagnetMinus.Font = Enum.Font.GothamBold
MagnetMinus.TextSize = 16
MagnetMinus.Parent = Content

local MagnetMinusCorner = Instance.new("UICorner")
MagnetMinusCorner.CornerRadius = UDim.new(0, 4)
MagnetMinusCorner.Parent = MagnetMinus

local MagnetPlus = Instance.new("TextButton")
MagnetPlus.Size = UDim2.new(0, 24, 0, 22)
MagnetPlus.Position = UDim2.new(0.85, 0, 0, 146)
MagnetPlus.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MagnetPlus.BackgroundTransparency = 0.6
MagnetPlus.Text = "+"
MagnetPlus.TextColor3 = Color3.fromRGB(50, 50, 60)
MagnetPlus.Font = Enum.Font.GothamBold
MagnetPlus.TextSize = 16
MagnetPlus.Parent = Content

local MagnetPlusCorner = Instance.new("UICorner")
MagnetPlusCorner.CornerRadius = UDim.new(0, 4)
MagnetPlusCorner.Parent = MagnetPlus

-- ============================================
-- 状态标签
-- ============================================
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 18)
StatusLabel.Position = UDim2.new(0, 0, 0, 174)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "目标: 无"
StatusLabel.TextColor3 = Color3.fromRGB(80, 80, 90)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = Content
-- ============================================
-- FOV 圆圈 (屏幕中心)
-- ============================================
local FovCircle = Instance.new("Frame")
FovCircle.Name = "FovCircle"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FovCircle.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
FovCircle.BackgroundTransparency = 1
FovCircle.Visible = false
FovCircle.Parent = ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FovCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Color = Color3.fromRGB(100, 200, 255)
CircleStroke.Thickness = 1.5
CircleStroke.Transparency = 0.5
CircleStroke.Parent = FovCircle

-- ============================================
-- 核心功能
-- ============================================
local function getTargetPart(character)
    local part = Config.AimPart
    if part == "Head" then
        return character:FindFirstChild("Head")
    elseif part == "Body" then
        return character:FindFirstChild("HumanoidRootPart") 
            or character:FindFirstChild("Torso") 
            or character:FindFirstChild("UpperTorso")
    elseif part == "Leg" then
        return character:FindFirstChild("LeftLeg") 
            or character:FindFirstChild("RightLeg") 
            or character:FindFirstChild("LeftFoot") 
            or character:FindFirstChild("RightFoot")
    end
    return character:FindFirstChild("Head")
end

local function getClosestTarget()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest = nil
    local closestDist = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local targetPart = getTargetPart(char)
        if not targetPart then continue end

        local distance = (hrp.Position - targetPart.Position).Magnitude
        if distance > Config.MaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        if Config.WallCheck then
            local ray = Ray.new(
                Camera.CFrame.Position,
                (targetPart.Position - Camera.CFrame.Position).Unit * distance
            )
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character}, false, true)
            if hit and hit.Parent ~= char then
                continue
            end
        end
        
        local distToCenter = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
        if distToCenter <= Config.FOVRadius and distToCenter < closestDist then
            closest = targetPart
            closestDist = distToCenter
        end
    end

    return closest
end

-- ============================================
-- 自瞄循环
-- ============================================
local aimConnection = nil

local function startAimbot()
    if aimConnection then return end
    Config.Enabled = true
    FovCircle.Visible = true
    lastTarget = nil
    
    aimConnection = RunService.RenderStepped:Connect(function()
        if not Config.Enabled then return end
        
        local target = getClosestTarget()
        
        -- 吸附强度逻辑：目标丢失时逐渐松开
        if target then
            lastTarget = target
            targetLostTimer = 0
        else
            targetLostTimer = targetLostTimer + 0.016
            if targetLostTimer > 0.5 then  -- 0.5秒没看到目标就彻底松开
                lastTarget = nil
            end
        end
        
        local aimTarget = target or lastTarget
        
        if aimTarget then
            -- 根据吸附强度决定平滑度
            -- MagnetStrength 越高，平滑度越高（越粘）
            local magnetFactor = 0.3 + (Config.MagnetStrength * 0.6)
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, aimTarget.Position)
            Camera.CFrame = currentCF:Lerp(targetCF, magnetFactor)
            
            if target then
                StatusLabel.Text = "目标: " .. aimTarget.Parent.Name
                StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            else
                StatusLabel.Text = "目标: 追踪中..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            end
        else
            StatusLabel.Text = "目标: 无"
            StatusLabel.TextColor3 = Color3.fromRGB(80, 80, 90)
        end
    end)
end

local function stopAimbot()
    Config.Enabled = false
    FovCircle.Visible = false
    lastTarget = nil
    targetLostTimer = 0
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
    StatusLabel.Text = "目标: 无"
    StatusLabel.TextColor3 = Color3.fromRGB(80, 80, 90)
end

local function toggleAimbot()
    if Config.Enabled then
        stopAimbot()
        ToggleBtn.Text = "自瞄: 关闭"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    else
        startAimbot()
        ToggleBtn.Text = "自瞄: 开启"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 120)
    end
end

-- ============================================
-- 按钮事件绑定
-- ============================================
ToggleBtn.MouseButton1Click:Connect(toggleAimbot)

WallBtn.MouseButton1Click:Connect(function()
    Config.WallCheck = not Config.WallCheck
    WallBtn.Text = Config.WallCheck and "隔墙: 开启" or "隔墙: 关闭"
    WallBtn.BackgroundColor3 = Config.WallCheck and Color3.fromRGB(60, 180, 220) or Color3.fromRGB(200, 200, 200)
end)

PartBtn.MouseButton1Click:Connect(function()
    local parts = {"Head", "Body", "Leg"}
    local index = table.find(parts, Config.AimPart) or 1
    index = index % 3 + 1
    Config.AimPart = parts[index]
    PartBtn.Text = "部位: " .. Config.AimPart
end)

FovMinus.MouseButton1Click:Connect(function()
    Config.FOVRadius = math.max(50, Config.FOVRadius - 10)
    FovLabel.Text = "FOV: " .. Config.FOVRadius
    FovCircle.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
end)

FovPlus.MouseButton1Click:Connect(function()
    Config.FOVRadius = math.min(400, Config.FOVRadius + 10)
    FovLabel.Text = "FOV: " .. Config.FOVRadius
    FovCircle.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
end)

DistMinus.MouseButton1Click:Connect(function()
    Config.MaxDistance = math.max(50, Config.MaxDistance - 10)
    DistLabel.Text = "距离: " .. Config.MaxDistance
end)

DistPlus.MouseButton1Click:Connect(function()
    Config.MaxDistance = math.min(500, Config.MaxDistance + 10)
    DistLabel.Text = "距离: " .. Config.MaxDistance
end)

-- 吸附强度控制
MagnetMinus.MouseButton1Click:Connect(function()
    Config.MagnetStrength = math.max(0.1, Config.MagnetStrength - 0.1)
    MagnetLabel.Text = "吸附: " .. string.format("%.1f", Config.MagnetStrength)
end)

MagnetPlus.MouseButton1Click:Connect(function()
    Config.MagnetStrength = math.min(1.0, Config.MagnetStrength + 0.1)
    MagnetLabel.Text = "吸附: " .. string.format("%.1f", Config.MagnetStrength)
end)

-- ============================================
-- 拖拽功能 (手机+PC通用)
-- ============================================
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = FloatingFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
        local delta = input.Position - dragStart
        FloatingFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================
-- 键盘快捷键 (PC)
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleAimbot()
    end
end)

-- ============================================
-- 初始化完成
-- ============================================
print("✅ 自瞄脚本 v2.0 已加载")
print("   💡 点击「自瞄」按钮切换")
print("   💡 按 F 键快速开关")
print("   💡 拖拽标题栏移动窗口")
print("   🧲 吸附强度越高越粘目标")
```