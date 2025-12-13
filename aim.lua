local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera

-- Variables
local aimEnabled = false
local toggleKey = Enum.KeyCode.E
local fov = 150
local targetLocked = nil
local guiVisible = true
local fovVisible = true -- 🔥 control del círculo FOV

-- GUI básico y moderno
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 180, 0, 110)
frame.Position = UDim2.new(0.8, -90, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Etiqueta
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 0.25, 0)
label.Text = "Tecla Aim: (...)"
label.TextColor3 = Color3.new(1,1,1)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.BackgroundTransparency = 1

-- Botón selección tecla
local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(1, 0, 0.25, 0)
button.Position = UDim2.new(0, 0, 0.25, 0)
button.Text = "..."
button.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
button.TextColor3 = Color3.new(1,1,1)
button.Font = Enum.Font.GothamBold
button.TextScaled = true
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

-- Slider FOV
local sliderFrame = Instance.new("Frame", frame)
sliderFrame.Size = UDim2.new(1, -20, 0.2, 0)
sliderFrame.Position = UDim2.new(0, 10, 0.55, 0)
sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sliderFrame.BorderSizePixel = 0
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 6)

local sliderBar = Instance.new("Frame", sliderFrame)
sliderBar.Size = UDim2.new(0.5, 0, 1, 0)
sliderBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
sliderBar.BorderSizePixel = 0
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 6)

local sliderLabel = Instance.new("TextLabel", frame)
sliderLabel.Size = UDim2.new(1, 0, 0.2, 0)
sliderLabel.Position = UDim2.new(0, 0, 0.75, 0)
sliderLabel.Text = "FOV: " .. fov
sliderLabel.TextColor3 = Color3.new(1,1,1)
sliderLabel.Font = Enum.Font.GothamBold
sliderLabel.TextScaled = true
sliderLabel.BackgroundTransparency = 1

-- Checkbox FOV
local fovButton = Instance.new("TextButton", frame)
fovButton.Size = UDim2.new(1, 0, 0.2, 0)
fovButton.Position = UDim2.new(0, 0, 0.9, 0)
fovButton.Text = "FOV: ON"
fovButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
fovButton.TextColor3 = Color3.new(1,1,1)
fovButton.Font = Enum.Font.GothamBold
fovButton.TextScaled = true
Instance.new("UICorner", fovButton).CornerRadius = UDim.new(0, 6)

-- FOV Circle
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Color = Color3.fromRGB(0, 170, 255)
FOVring.Thickness = 2
FOVring.NumSides = 64
FOVring.Radius = fov
FOVring.Filled = false
FOVring.Position = Cam.ViewportSize/2
FOVring.Transparency = 0.5

-- Selección de tecla
button.MouseButton1Click:Connect(function()
    label.Text = "Presiona una tecla..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if not gp then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                toggleKey = input.KeyCode
            else
                toggleKey = input.UserInputType
            end
            label.Text = "Tecla Aim: " .. tostring(toggleKey)
            conn:Disconnect()
        end
    end)
end)

-- Toggle Aim y GUI
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp then
        if input.KeyCode == toggleKey or input.UserInputType == toggleKey then
            aimEnabled = not aimEnabled
            if not aimEnabled then targetLocked = nil end
        end
        if input.KeyCode == Enum.KeyCode.F4 then
            guiVisible = not guiVisible
            screenGui.Enabled = guiVisible
        end
    end
end)

-- Slider interacción
local dragging = false
sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local relativeX = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        sliderBar.Size = UDim2.new(relativeX, 0, 1, 0)
        fov = math.floor(50 + relativeX * 250)
        sliderLabel.Text = "FOV: " .. fov
        FOVring.Radius = fov
    end
end)

-- Toggle FOV circle
fovButton.MouseButton1Click:Connect(function()
    fovVisible = not fovVisible
    FOVring.Visible = fovVisible
    fovButton.Text = fovVisible and "FOV: ON" or "FOV: OFF"
end)

-- Función mirar a la cabeza
local function lookAt(targetPart)
    Cam.CFrame = CFrame.lookAt(Cam.CFrame.Position, targetPart.Position)
end

-- Buscar jugador más cercano
local function getClosestPlayerInFOV(trg_part)
    local nearest = nil
    local last = math.huge
    local playerMousePos = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local part = player.Character and player.Character:FindFirstChild(trg_part)
            if part then
                local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(ePos.x, ePos.y) - playerMousePos).Magnitude
                if distance < last and isVisible and distance < fov then
                    last = distance
                    nearest = part
                end
            end
        end
    end
    return nearest
end

-- Loop principal
RunService.RenderStepped:Connect(function()
    FOVring.Position = Cam.ViewportSize/2

    if aimEnabled then
        if targetLocked and targetLocked.Parent then
            lookAt(targetLocked)
        else
            local head = getClosestPlayerInFOV("Head")
            if head then
                targetLocked = head
            end
        end
    end
end)
