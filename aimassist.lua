-- Aim Assist Toggle GUI Script for Roblox
-- by Colin (Survival Script)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Проверяем, что исполнитель загрузил библиотеку Drawing
if not drawing then
    LocalPlayer:Kick("Your exploit does not support Drawing API. Use Synapse X or equivalent.")
    return
end

-- Настройки аима
local AimSettings = {
    Enabled = false,
    TeamCheck = true, -- Не целить в своих
    WallCheck = true, -- Не целить сквозь стены
    Smoothness = 0.2, -- Плавность (меньше = резче)
    FOV = 100, -- Радиус прицеливания (пиксели)
    KeyToggle = Enum.KeyCode.V -- Кнопка для переключения (V)
}

-- Создаём интерфейс
local ScreenGui = drawing.new("Square")
ScreenGui.Visible = true
ScreenGui.Size = Vector2.new(200, 40)
ScreenGui.Position = Vector2.new(20, 20)
ScreenGui.Color = Color3.fromRGB(40, 40, 40)
ScreenGui.Transparency = 0.7
ScreenGui.Filled = true

-- Кнопка
local ToggleButton = drawing.new("Circle")
ToggleButton.Visible = true
ToggleButton.Radius = 10
ToggleButton.Position = Vector2.new(30, 40)
ToggleButton.Color = Color3.fromRGB(255, 50, 50)
ToggleButton.Filled = true
ToggleButton.Transparency = 0.5

-- Текст статуса
local StatusText = drawing.new("Text")
StatusText.Visible = true
StatusText.Text = "AIM: OFF"
StatusText.Position = Vector2.new(50, 32)
StatusText.Color = Color3.fromRGB(255, 255, 255)
StatusText.Size = 16
StatusText.Center = false

-- Текст FOV круга
local FOVText = drawing.new("Text")
FOVText.Visible = false
FOVText.Text = "FOV: " .. AimSettings.FOV
FOVText.Position = Vector2.new(20, 60)
FOVText.Color = Color3.fromRGB(200, 200, 200)
FOVText.Size = 14
FOVText.Center = false

-- Круг FOV (визуализация)
local FOVCircle = drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = AimSettings.FOV
FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
FOVCircle.Color = Color3.fromRGB(0, 255, 0)
FOVCircle.Filled = false
FOVCircle.Thickness = 1

-- Функция для перетаскивания GUI
local Dragging, DragOffset = false, nil
ToggleButton.MouseButton1Down:Connect(function()
    Dragging = true
    DragOffset = Vector2.new(Mouse.X - ScreenGui.Position.X, Mouse.Y - ScreenGui.Position.Y)
end)

UIS.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

-- Функция поиска цели
function GetClosestPlayer()
    local ClosestPlayer = nil
    local ShortestDistance = AimSettings.FOV
    
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Character = Player.Character
            local Humanoid = Character:FindFirstChild("Humanoid")
            local Head = Character:FindFirstChild("Head")
            
            if Humanoid and Humanoid.Health > 0 and Head then
                -- Проверка команды
                if AimSettings.TeamCheck then
                    if Player.Team and LocalPlayer.Team and Player.Team == LocalPlayer.Team then
                        continue
                    end
                end
                
                -- Проверка на стену
                if AimSettings.WallCheck then
                    local Raycast = workspace:Raycast(
                        LocalPlayer.Character.Head.Position,
                        (Head.Position - LocalPlayer.Character.Head.Position),
                        {LocalPlayer.Character, Character}
                    )
                    if Raycast and Raycast.Instance then
                        continue
                    end
                end
                
                -- Проверка угла и расстояния
                local ScreenPoint, OnScreen = workspace.CurrentCamera:WorldToScreenPoint(Head.Position)
                if OnScreen then
                    local Distance = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                    if Distance < ShortestDistance then
                        ShortestDistance = Distance
                        ClosestPlayer = Player
                    end
                end
            end
        end
    end
    
    return ClosestPlayer
end

-- Основной цикл аима
RunService.RenderStepped:Connect(function()
    -- Перетаскивание GUI
    if Dragging then
        local NewPos = Vector2.new(Mouse.X - DragOffset.X, Mouse.Y - DragOffset.Y)
        ScreenGui.Position = NewPos
        ToggleButton.Position = Vector2.new(NewPos.X + 10, NewPos.Y + 20)
        StatusText.Position = Vector2.new(NewPos.X + 40, NewPos.Y + 12)
        FOVText.Position = Vector2.new(NewPos.X, NewPos.Y + 40)
    end
    
    -- Обновление FOV круга
    FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
    
    -- Аим
    if AimSettings.Enabled then
        local Target = GetClosestPlayer()
        if Target and Target.Character and Target.Character:FindFirstChild("Head") then
            local Head = Target.Character.Head
            local Camera = workspace.CurrentCamera
            
            -- Плавное движение мыши
            local TargetPosition = Camera:WorldToScreenPoint(Head.Position)
            local CurrentPosition = Vector2.new(Mouse.X, Mouse.Y)
            local NewPosition = CurrentPosition + (Vector2.new(TargetPosition.X, TargetPosition.Y) - CurrentPosition) * AimSettings.Smoothness
            
            mousemoverel(NewPosition.X - CurrentPosition.X, NewPosition.Y - CurrentPosition.Y)
        end
    end
end)

-- Переключение кнопкой мыши
ToggleButton.MouseButton1Click:Connect(function()
    AimSettings.Enabled = not AimSettings.Enabled
    ToggleButton.Color = AimSettings.Enabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    StatusText.Text = "AIM: " .. (AimSettings.Enabled and "ON" or "OFF")
    FOVCircle.Visible = AimSettings.Enabled
    FOVText.Visible = AimSettings.Enabled
end)

-- Переключение горячей клавишей
UIS.InputBegan:Connect(function(Input)
    if Input.KeyCode == AimSettings.KeyToggle then
        AimSettings.Enabled = not AimSettings.Enabled
        ToggleButton.Color = AimSettings.Enabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
        StatusText.Text = "AIM: " .. (AimSettings.Enabled and "ON" or "OFF")
        FOVCircle.Visible = AimSettings.Enabled
        FOVText.Visible = AimSettings.Enabled
    end
end)

-- Закрытие GUI при нажатии на крестик (круг)
local CloseButton = drawing.new("Circle")
CloseButton.Visible = true
CloseButton.Radius = 6
CloseButton.Position = Vector2.new(ScreenGui.Position.X + ScreenGui.Size.X - 15, ScreenGui.Position.Y + 15)
CloseButton.Color = Color3.fromRGB(255, 100, 100)
CloseButton.Filled = true

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Remove()
    ToggleButton:Remove()
    StatusText:Remove()
    FOVCircle:Remove()
    FOVText:Remove()
    CloseButton:Remove()
end)

-- Обновление позиции крестика при перетаскивании
RunService.RenderStepped:Connect(function()
    CloseButton.Position = Vector2.new(ScreenGui.Position.X + ScreenGui.Size.X - 15, ScreenGui.Position.Y + 15)
end)

-- Скрытие/показ GUI при нажатии на кнопку H
UIS.InputBegan:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.H then
        local Visible = not ScreenGui.Visible
        ScreenGui.Visible = Visible
        ToggleButton.Visible = Visible
        StatusText.Visible = Visible
        CloseButton.Visible = Visible
        if AimSettings.Enabled then
            FOVCircle.Visible = Visible
            FOVText.Visible = Visible
        end
    end
end)

print("Aim Assist GUI loaded!")
print("Controls:")
print("- Click button to toggle aim")
print("- Drag GUI to move")
print("- Press V to toggle aim")
print("- Press H to hide/show GUI")
print("- Click red X to close")
