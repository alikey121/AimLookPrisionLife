-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService") -- Añadido para el movimiento

-- VARIABLES PRINCIPALES
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local targetPlayer = nil
local isLocking = false
local aimConnection = nil

-- Estado para el Spy Players
local spyPlayersActive = false
local espConnection = nil

-- 1. INTERFAZ GRÁFICA (Tu código original)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 190, 0, 100)
menuFrame.Position = UDim2.new(0.7, 0, 0.5, 0)
menuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
menuFrame.Active = true
menuFrame.Draggable = true 
menuFrame.Parent = screenGui

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(255, 0, 0)
menuStroke.Thickness = 2.5
menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
menuStroke.Parent = menuFrame

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menuFrame

local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Name = "WatermarkLabel"
watermarkLabel.Size = UDim2.new(0, 100, 0, 15)
watermarkLabel.Position = UDim2.new(0, 8, 0, 4)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.Text = "Js Like Beta"
watermarkLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
watermarkLabel.Font = Enum.Font.SourceSansBold
watermarkLabel.TextSize = 11 
watermarkLabel.TextXAlignment = Enum.TextXAlignment.Left 
watermarkLabel.Parent = menuFrame

local aimButton = Instance.new("TextButton")
aimButton.Name = "AimButton"
aimButton.Size = UDim2.new(0, 75, 0, 55)
aimButton.Position = UDim2.new(0, 12, 0, 28) 
aimButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
aimButton.Text = "LOCK"
aimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimButton.Font = Enum.Font.SourceSansBold
aimButton.TextSize = 16
aimButton.Parent = menuFrame

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 8)
corner1.Parent = aimButton

local spyButton = Instance.new("TextButton")
spyButton.Name = "SpyButton"
spyButton.Size = UDim2.new(0, 75, 0, 55)
spyButton.Position = UDim2.new(0, 103, 0, 28) 
spyButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
spyButton.Text = "Spy\nPlayers"
spyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spyButton.Font = Enum.Font.SourceSansBold
spyButton.TextSize = 14
spyButton.Parent = menuFrame

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 8)
corner2.Parent = spyButton

-- NUEVA FUNCIÓN: WALL CHECK
local function isVisible(targetCharacter)
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return false end
    local origin = Camera.CFrame.Position
    local destination = targetCharacter.HumanoidRootPart.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, destination - origin, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

-- 2. LÓGICA DE AUTO-APUNTADO (Actualizada para ser dinámica)
local function getClosestStrictEnemy()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myTeam = LocalPlayer.Team
    if not myTeam then return nil end
    
    local enemyTeams = {}
    if myTeam.Name == "Guards" then enemyTeams["Criminals"] = true; enemyTeams["Inmates"] = true
    elseif myTeam.Name == "Inmates" then enemyTeams["Guards"] = true; enemyTeams["Criminals"] = true
    elseif myTeam.Name == "Criminals" then enemyTeams["Guards"] = true; enemyTeams["Inmates"] = true
    else return nil end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            if player.Team and enemyTeams[player.Team.Name] and isVisible(player.Character) then
                local screenPosition, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                if onScreen then
                    local mouseLocation = Camera.ViewportSize / 2
                    local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mouseLocation).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function lockOnTarget()
    if aimConnection then aimConnection:Disconnect() end
    aimConnection = RunService.RenderStepped:Connect(function()
        if not isLocking then return end
        
        -- Si el objetivo no es válido o está tras una pared, busca uno nuevo
        if not (targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChildOfClass("Humanoid").Health > 0 and isVisible(targetPlayer.Character)) then
            targetPlayer = getClosestStrictEnemy()
        end
        
        if targetPlayer then
            local targetPart = targetPlayer.Character.HumanoidRootPart
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        end
    end)
end

aimButton.MouseButton1Click:Connect(function()
    isLocking = not isLocking
    aimButton.BackgroundColor3 = isLocking and Color3.fromRGB(50, 220, 50) or Color3.fromRGB(220, 50, 50)
    aimButton.Text = isLocking and "UNLOCK" or "LOCK"
    if isLocking then lockOnTarget() else if aimConnection then aimConnection:Disconnect() end end
end)

-- 3. SISTEMA DE ESP (Tu código original intacto)
local function createEspTag(player, color)
    if player.Character and player.Character:FindFirstChild("Head") then
        local head = player.Character.Head
        local tag = head:FindFirstChild("EspTag")
        if tag then
            local label = tag:FindFirstChildOfClass("TextLabel")
            if label then label.TextColor3 = color end
        else
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "EspTag"
            billboard.Size = UDim2.new(0, 150, 0, 30)
            billboard.AlwaysOnTop = true
            billboard.ExtentsOffset = Vector3.new(0, 2, 0)
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = player.Name
            textLabel.TextColor3 = color
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = 15
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.Parent = billboard
            billboard.Parent = head
        end
    end
end

local function removeAllEspTags()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local tag = player.Character.Head:FindFirstChild("EspTag")
            if tag then tag:Destroy() end
        end
    end
end

local function updateEspSystem()
    if espConnection then espConnection:Disconnect() end
    espConnection = RunService.Heartbeat:Connect(function()
        if not spyPlayersActive then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Team and player.Character and player.Character:FindFirstChild("Head") then
                if player.Team.Name == "Guards" then createEspTag(player, Color3.fromRGB(0, 150, 255))
                elseif player.Team.Name == "Inmates" then createEspTag(player, Color3.fromRGB(255, 130, 0))
                elseif player.Team.Name == "Criminals" then createEspTag(player, Color3.fromRGB(160, 160, 160))
                end
            end
        end
    end)
end

spyButton.MouseButton1Click:Connect(function()
    spyPlayersActive = not spyPlayersActive
    if spyPlayersActive then
        spyButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
        updateEspSystem()
    else
        spyButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        if espConnection then espConnection:Disconnect() end
        removeAllEspTags()
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if spyPlayersActive then task.wait(1); updateEspSystem() end
    end)
end)

