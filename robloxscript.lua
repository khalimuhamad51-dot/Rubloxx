-- Rivals Mobile Safe | Delta
-- Soft silent + ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
    SilentAim = true,
    AimPart = "Head",
    FOV = 95,
    TeamCheck = true,
    VisibleCheck = true,
    HitChance = 72,
    Smooth = 0.12,

    ESP = true,
    Box = true,
    Name = true,
    Health = true,
    MaxDistance = 650,
}

local function isAlive(plr)
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart")
end

local function sameTeam(plr)
    if not Config.TeamCheck then return false end
    return plr.Team and plr.Team == LocalPlayer.Team
end

local function isVisible(part)
    if not Config.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(origin, dir.Unit * dir.Magnitude, params)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function getClosest()
    local closest, best = nil, Config.FOV
    local mouse = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr \~= LocalPlayer and isAlive(plr) and not sameTeam(plr) then
            local part = plr.Character:FindFirstChild(Config.AimPart) or plr.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if d < best and isVisible(part) then
                        if math.random(100) <= Config.HitChance then
                            best = d
                            closest = part
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Config.SilentAim then return end
    local target = getClosest()
    if target then
        local cur = Camera.CFrame
        local goal = CFrame.lookAt(cur.Position, target.Position)
        Camera.CFrame = cur:Lerp(goal, Config.Smooth)
    end
end)

local DrawingLib = Drawing
local drawings = {}

local function createESP(plr)
    if drawings[plr] then return end
    local box = DrawingLib.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = Color3.fromRGB(255, 70, 70)
    box.Visible = false

    local name = DrawingLib.new("Text")
    name.Size = 13
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Visible = false

    local hp = DrawingLib.new("Line")
    hp.Thickness = 2
    hp.Visible = false

    drawings[plr] = {box = box, name = name, hp = hp}
end

local function removeESP(plr)
    if drawings[plr] then
        for _, v in pairs(drawings[plr]) do v:Remove() end
        drawings[plr] = nil
    end
end

local function updateESP()
    for plr, objs in pairs(drawings) do
        if not Config.ESP or not isAlive(plr) or sameTeam(plr) then
            objs.box.Visible = false
            objs.name.Visible = false
            objs.hp.Visible = false
            continue
        end

        local root = plr.Character.HumanoidRootPart
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        local pos, on = Camera:WorldToViewportPoint(root.Position)
        local dist = (root.Position - Camera.CFrame.Position).Magnitude

        if on and dist <= Config.MaxDistance then
            local s = math.clamp(2000 / dist, 9, 36)
            objs.box.Size = Vector2.new(s * 0.6, s * 1.3)
            objs.box.Position = Vector2.new(pos.X - s * 0.3, pos.Y - s * 0.65)
            objs.box.Visible = Config.Box

            objs.name.Text = plr.DisplayName
            objs.name.Position = Vector2.new(pos.X, pos.Y - s * 0.8)
            objs.name.Visible = Config.Name

            local r = hum.Health / hum.MaxHealth
            objs.hp.From = Vector2.new(pos.X - s * 0.35, pos.Y + s * 0.65)
            objs.hp.To = Vector2.new(pos.X - s * 0.35, pos.Y + s * 0.65 - s * 1.3 * r)
            objs.hp.Color = Color3.fromRGB(255*(1-r), 255*r, 30)
            objs.hp.Visible = Config.Health
        else
            objs.box.Visible = false
            objs.name.Visible = false
            objs.hp.Visible = false
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p \~= LocalPlayer then createESP(p) end
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)
RunService.RenderStepped:Connect(updateESP)

local gui = Instance.new("ScreenGui")
gui.Name = "RivalsSafe"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local function makeBtn(text, pos, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(115, 44)
    b.Position = pos
    b.BackgroundColor3 = col
    b.BackgroundTransparency = 0.25
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 15
    b.Font = Enum.Font.GothamBold
    b.Parent = gui
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    return b
end

local sBtn = makeBtn("Silent: ON", UDim2.new(0, 12, 0.73, 0), Color3.fromRGB(0, 170, 80))
local eBtn = makeBtn("ESP: ON", UDim2.new(0, 12, 0.73, 52), Color3.fromRGB(0, 120, 200))

sBtn.MouseButton1Click:Connect(function()
    Config.SilentAim = not Config.SilentAim
    sBtn.Text = Config.SilentAim and "Silent: ON" or "Silent: OFF"
    sBtn.BackgroundColor3 = Config.SilentAim and Color3.fromRGB(0,170,80) or Color3.fromRGB(180,40,40)
end)

eBtn.MouseButton1Click:Connect(function()
    Config.ESP = not Config.ESP
    eBtn.Text = Config.ESP and "ESP: ON" or "ESP: OFF"
    eBtn.BackgroundColor3 = Config.ESP and Color3.fromRGB(0,120,200) or Color3.fromRGB(180,40,40)
end)

print("[Rivals Safe] loaded")