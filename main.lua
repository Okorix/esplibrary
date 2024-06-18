local Players = game.Players
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera
local CurrentCamera = workspace.CurrentCamera
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint

local HeadOffset = Vector3.new(0, 0.5, 0)
local LegOffset = Vector3.new(0, 3, 0)

getgenv().ESPSettings = {
    Enabled = false,
    BoxVisible = false,
    BoxOutlineVisible = false,
    BoxOutlineColor = Color3.new(0, 0, 0),
    BoxColor = Color3.new(255, 255, 255),
    NameVisible = false,
    NameColor = Color3.new(255, 255, 255),
    NameSize = 12,
    HealthBarOutlineVisible = false,
    HealthBarVisible = false,
    HealthTextVisible = false,
    CurrentToolTextVisible = false,
}
local ESPSettings = getgenv().ESPSettings
local Cached = {}

local function CreateDrawing(Class, Properties)
    local Drawing = Drawing.new(Class)
    for Property, Value in pairs(Properties) do
        Drawing[Property] = Value
    end
    return Drawing
end

local function CreateESP(Player)
    local ESP = {
        BoxOutline = CreateDrawing("Square", {
            Visible = false,
            Color = ESPSettings.BoxOutlineColor,
            Thickness = 3,
            Transparency = 1,
            Filled = false,
            ZIndex = 1, -- Setting a higher ZIndex for BoxOutline
        }),
        Box = CreateDrawing("Square", {
            Visible = false,
            Color = ESPSettings.BoxColor,
            Thickness = 1,
            Transparency = 1,
            Filled = false,
            ZIndex = 2, -- Lower ZIndex for Box
        }),
        NameText = CreateDrawing("Text", {
            Visible = false,
            Color = ESPSettings.NameColor,
            Size = ESPSettings.NameSize,
            Outline = true,
            ZIndex = 2, -- Set ZIndex for NameText to match BoxOutline
        }),
        HealthBarOutline = CreateDrawing("Line", {
            Thickness = 3,
            Color = Color3.new(0, 0, 0),
            ZIndex = 1, -- Set ZIndex for HealthBarOutline to match BoxOutline
        }),
        HealthBar = CreateDrawing("Line", {
            Thickness = 1,
            ZIndex = 2, -- Set ZIndex for HealthBar to match Box
        }),
        HealthText = CreateDrawing("Text", {
            Color = Color3.new(255, 255, 255),
            Outline = true,
            Center = false,
            Size = 11,
            ZIndex = 1, -- Set ZIndex for HealthText to match BoxOutline
        }),
        CurrentToolText = CreateDrawing("Text", {
            Color = Color3.new(255, 255, 255),
            Outline = true,
            Center = false,
            Size = ESPSettings.NameSize - 1,
            ZIndex = 1, -- Set ZIndex for CurrentToolText to match BoxOutline
        }),
    }
    Cached[Player] = ESP
end

local function RemoveESP(Player)
    if not Cached[Player] then
        return
    end

    for _, DrawingObject in pairs(Cached[Player]) do
        if DrawingObject then
            pcall(function()
                DrawingObject:Remove()
            end)
        end
    end
end

local function UpdateESP()
    for Player, ESP in pairs(Cached) do
        local Box = ESP.Box
        local BoxOutline = ESP.BoxOutline
        local NameText = ESP.NameText
        local HealthBarOutline = ESP.HealthBarOutline
        local HealthBar = ESP.HealthBar
        local HealthText = ESP.HealthText
        local CurrentToolText = ESP.CurrentToolText

        BoxOutline.Color = ESPSettings.BoxOutlineColor
        Box.Color = ESPSettings.BoxColor

        local Character = Player.Character

        if Character and Character:FindFirstChild("Humanoid") and Character:FindFirstChild("HumanoidRootPart") and Player ~= LocalPlayer and Character.Humanoid.Health > 0 and ESPSettings.Enabled then
            local Vector, OnScreen = Camera:WorldToViewportPoint(Character.HumanoidRootPart.Position)

            local RootPart = Character.HumanoidRootPart
            local Head = Character.Head
            local RootPosition, RootVis = WorldToViewportPoint(CurrentCamera, RootPart.Position)
            local HeadPosition = WorldToViewportPoint(CurrentCamera, Head.Position + HeadOffset)
            local LegPosition = WorldToViewportPoint(CurrentCamera, RootPart.Position - LegOffset)

            if OnScreen then
                local FOVFactor = Camera.FieldOfView / 70 -- Normalize based on default FOV

                local BoxHeight = HeadPosition.Y - LegPosition.Y
                local BoxWidth = 2500 / RootPosition.Z / FOVFactor

                Box.Size = Vector2.new(BoxWidth, BoxHeight)
                Box.Position = Vector2.new(RootPosition.X - Box.Size.X / 2, RootPosition.Y - Box.Size.Y / 2)
                Box.Visible = ESPSettings.BoxVisible

                BoxOutline.Size = Vector2.new(BoxWidth, BoxHeight)
                BoxOutline.Position = Vector2.new(RootPosition.X - BoxOutline.Size.X / 2, RootPosition.Y - BoxOutline.Size.Y / 2)
                BoxOutline.Visible = ESPSettings.BoxOutlineVisible

                NameText.Position = Vector2.new(RootPosition.X - NameText.TextBounds.X / 2, RootPosition.Y - Box.Size.Y / 2)
                NameText.Color = ESPSettings.NameColor
                NameText.Size = ESPSettings.NameSize
                NameText.Visible = ESPSettings.NameVisible
                NameText.Text = Player.Name

                local HealthPercentage = Character.Humanoid.Health / Character.Humanoid.MaxHealth
                HealthBarOutline.From = Vector2.new(Box.Position.X - 6, Box.Position.Y + Box.Size.Y)
                HealthBarOutline.To = Vector2.new(HealthBarOutline.From.X, HealthBarOutline.From.Y - Box.Size.Y)
                HealthBar.From = Vector2.new((Box.Position.X - 5), Box.Position.Y + Box.Size.Y)
                HealthBar.To = Vector2.new(HealthBar.From.X, HealthBar.From.Y - HealthPercentage * Box.Size.Y)
                HealthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), HealthPercentage)

                local RoundedNumber = math.floor(Character.Humanoid.Health * 100) / 100
                HealthText.Position = Vector2.new(Box.Position.X - 28, Box.Position.Y + Box.Size.Y)
                HealthText.Color = HealthBar.Color
                HealthText.Text = tostring(math.max(RoundedNumber, 0))

                HealthText.Visible = ESPSettings.HealthTextVisible
                HealthBar.Visible = ESPSettings.HealthBarVisible
                HealthBarOutline.Visible = ESPSettings.HealthBarOutlineVisible

                CurrentToolText.Size = ESPSettings.NameSize - 1
                CurrentToolText.Position = Vector2.new(RootPosition.X - CurrentToolText.TextBounds.X / 2, RootPosition.Y - Box.Size.Y / 1.25)
                CurrentToolText.Visible = ESPSettings.CurrentToolTextVisible
                if Character:FindFirstChildWhichIsA("Tool") then
                    CurrentToolText.Visible = ESPSettings.CurrentToolTextVisible
                    CurrentToolText.Text = tostring(Character:FindFirstChildWhichIsA("Tool").Name)
                else
                    CurrentToolText.Visible = false
                    CurrentToolText.Text = "Nothing"
                end
            else
                BoxOutline.Visible = false
                Box.Visible = false
                NameText.Visible = false
                HealthBarOutline.Visible = false
                HealthBar.Visible = false
                HealthText.Visible = false
                CurrentToolText.Visible = false
            end
        else
            BoxOutline.Visible = false
            Box.Visible = false
            NameText.Visible = false
            HealthBarOutline.Visible = false
            HealthBar.Visible = false
            HealthText.Visible = false
            CurrentToolText.Visible = false
        end
    end
end

for _, Player in pairs(Players:GetChildren()) do
    CreateESP(Player)
end

Players.PlayerAdded:Connect(function(Player)
    CreateESP(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    RemoveESP(Player)
end)

RunService.RenderStepped:Connect(UpdateESP)

return ESPSettings
