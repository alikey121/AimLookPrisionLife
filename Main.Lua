-- SERVICIOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- VARIABLES PRINCIPALES
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local targetPlayer = nil
local isLocking = false
local aimConnection = nil

-- Estado para el Spy Players
local spyPlayersActive = false
local espConnection = nil

-- 1. INTERFAZ GRÁFICA (Cuadro Contenedor Negro con Borde Rojo)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- El cuadro principal movible
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 190, 0, 100)
menuFrame.Position = UDim2.new(0.7, 0, 0.5, 0)
menuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Fondo Negro oscuro
menuFrame.Active = true
menuFrame.Draggable = true 
menuFrame.Parent = screenGui

-- Borde Rojo para el cuadro
local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(255, 0, 0) -- Borde Rojo
menuStroke.Thickness = 2.5
menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
menuStroke.Parent = menuFrame

-- Esquinas redondeadas para el cuadro principal
local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menuFrame

-- Texto "Js Like Beta" en la esquina superior izquierda
local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Name = "WatermarkLabel"
watermarkLabel.Size = UDim2.new(0, 100, 0, 15)
watermarkLabel.Position = UDim2.new(0, 8, 0, 4)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.Text = "Js Like Beta"
watermarkLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Color Rojo
watermarkLabel.Font = Enum.Font.SourceSansBold
watermarkLabel.TextSize = 11 
watermarkLabel.TextXAlignment = Enum.TextXAlignment.Left 
watermarkLabel.Parent = menuFrame

-- Botón 1: LOCK
local aimButton = Instance.new("TextButton")
aimButton.Name = "AimButton"
aimButton.Size = UDim2.new(0, 75, 0, 55)
aimButton.Position = UDim2.new(0, 12, 0, 28) 
aimButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- Rojo (Desactivado)
aimButton.Text = "LOCK"
aimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimButton.Font = Enum.Font.SourceSansBold
aimButton.TextSize = 16
aimButton.Parent = menuFrame

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 8)
corner1.Parent = aimButton

-- Botón 2: Spy Players
local spyButton = Instance.new("TextButton")
spyButton.Name = "SpyButton"
spyButton.Size = UDim2.new(0, 75, 0, 55)
spyButton.Position = UDim2.new(0, 103, 0, 28) 
spyButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- Rojo (Desactivado)
spyButton.Text = "Spy\nPlayers"
spyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spyButton.Font = Enum.Font.SourceSansBold
spyButton.TextSize = 14
spyButton.Parent = menuFrame

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 8)
corner2.Parent = spyButton


-- 2. LÓGICA DE AUTO-APUNTADO RESPECTO A LA MIRA (AL CENTRO DE LA PANTALLA)
local function getClosestStrictEnemy()
	local closestPlayer = nil
	local shortestDistance = math.huge
	
	local myTeam = LocalPlayer.Team
	if not myTeam then return nil end
	
	-- Configuración estricta de contrincantes (Corregida y completa)
	local enemyTeams = {}
	if myTeam.Name == "Guards" then
		enemyTeams["Criminals"] = true
		enemyTeams["Inmates"] = true
	elseif myTeam.Name == "Inmates" then
		enemyTeams["Guards"] = true
		enemyTeams["Criminals"] = true
	elseif myTeam.Name == "Criminals" then
		enemyTeams["Guards"] = true
		enemyTeams["Inmates"] = true
	else
		return nil
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
			if player.Team and enemyTeams[player.Team.Name] then
				
				-- Regresamos al cálculo basándonos en la posición dentro de la pantalla (Mira / Mouse)
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
		local myTeam = LocalPlayer.Team
		if not myTeam then return end
		
		local enemyTeams = {}
		if myTeam.Name == "Guards" then
			enemyTeams["Criminals"] = true
			enemyTeams["Inmates"] = true
		elseif myTeam.Name == "Inmates" then
			enemyTeams["Guards"] = true
			enemyTeams["Criminals"] = true
		elseif myTeam.Name == "Criminals" then
			enemyTeams["Guards"] = true
			enemyTeams["Inmates"] = true
		end
		
		if isLocking and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChildOfClass("Humanoid").Health > 0 and targetPlayer.Team and enemyTeams[targetPlayer.Team.Name] then
			
			local targetPart = targetPlayer.Character.HumanoidRootPart
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
		else
			if isLocking then
				isLocking = false
				aimButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50) 
				aimButton.Text = "LOCK"
				if aimConnection then aimConnection:Disconnect() end
			end
		end
	end)
end

aimButton.MouseButton1Click:Connect(function()
	if not isLocking then
		targetPlayer = getClosestStrictEnemy()
		if targetPlayer then
			isLocking = true
			aimButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50) 
			aimButton.Text = "UNLOCK"
			lockOnTarget()
		end
	else
		isLocking = false
		aimButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50) 
		aimButton.Text = "LOCK"
		if aimConnection then aimConnection:Disconnect() end
	end
end)


-- 3. SISTEMA DE ESP (SPY PLAYERS)
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
				if player.Team.Name == "Guards" then
					createEspTag(player, Color3.fromRGB(0, 150, 255)) 
				elseif player.Team.Name == "Inmates" then
					createEspTag(player, Color3.fromRGB(255, 130, 0)) 
				elseif player.Team.Name == "Criminals" then
					createEspTag(player, Color3.fromRGB(160, 160, 160)) 
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
		if spyPlayersActive then
			task.wait(1)
			updateEspSystem()
		end
	end)
end)
