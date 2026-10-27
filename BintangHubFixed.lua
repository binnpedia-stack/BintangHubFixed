-- BINTANGHUB V5.0 | Violence District
-- Full Features + Auto Skillcheck (GUI Watcher)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- CONFIG
-- ==========================================
local Config = {
    SilentAim = false, AimLock = false, AutoParry = false,
    AutoSkill = false, AutoTrap = false, AutoCrouch = false,
    Fullbright = false, NoShadow = false, NoClip = false, CameraFOV = 70,
    ESP_Survivor = false, ESP_Killer = false, ESP_Gen = false, ESP_Trap = false,
    Color_Survivor = Color3.fromRGB(40, 255, 40),
    Color_Killer = Color3.fromRGB(255, 40, 40),
    Color_Gen = Color3.fromRGB(255, 165, 0),
    Color_Trap = Color3.fromRGB(200, 0, 0)
}

-- ==========================================
-- RAYFIELD UI
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "BINTANGHUB V5.0",
   LoadingTitle = "BINTANGHUB",
   LoadingSubtitle = "by Owner BintangHub",
   KeySystem = false, Theme = "Amethyst"
})

local TabMain = Window:CreateTab("Main", 4483362458)
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabSurvivor = Window:CreateTab("Survivor", 4483362458)
local TabESP = Window:CreateTab("ESP", 4483362458)

-- UI TOGGLES
TabMain:CreateSlider({Name = "Camera FOV", Range = {70, 120}, Increment = 1, CurrentValue = 70, Callback = function(v) Config.CameraFOV = v end})
TabMain:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Config.Fullbright = v end})
TabMain:CreateToggle({Name = "No Shadow", CurrentValue = false, Callback = function(v) Config.NoShadow = v end})
TabMain:CreateToggle({Name = "No Clip", CurrentValue = false, Callback = function(v) Config.NoClip = v end})

TabCombat:CreateToggle({Name = "Silent Aim", CurrentValue = false, Callback = function(v) Config.SilentAim = v end})
TabCombat:CreateToggle({Name = "Aim Lock", CurrentValue = false, Callback = function(v) Config.AimLock = v end})
TabCombat:CreateToggle({Name = "Auto Parry", CurrentValue = false, Callback = function(v) Config.AutoParry = v end})

TabSurvivor:CreateToggle({Name = "Auto Skillcheck (Gen)", CurrentValue = false, Callback = function(v) Config.AutoSkill = v end})
TabSurvivor:CreateToggle({Name = "Auto Trap Release", CurrentValue = false, Callback = function(v) Config.AutoTrap = v end})
TabSurvivor:CreateToggle({Name = "Auto Crouch", CurrentValue = false, Callback = function(v) Config.AutoCrouch = v end})

TabESP:CreateToggle({Name = "ESP Survivor", CurrentValue = false, Callback = function(v) Config.ESP_Survivor = v end})
TabESP:CreateToggle({Name = "ESP Killer", CurrentValue = false, Callback = function(v) Config.ESP_Killer = v end})
TabESP:CreateToggle({Name = "ESP Generator", CurrentValue = false, Callback = function(v) Config.ESP_Gen = v end})
TabESP:CreateToggle({Name = "ESP Trap", CurrentValue = false, Callback = function(v) Config.ESP_Trap = v end})

-- ==========================================
-- ESP LOGIC
-- ==========================================
local espCache = {}
local function CreateBillboard(parent, name, color)
    local b = Instance.new("BillboardGui")
    b.Name = "BH_ESP"
    b.Size = UDim2.new(0, 100, 0, 50)
    b.StudsOffset = Vector3.new(0, 3, 0)
    b.AlwaysOnTop = true
    b.Parent = parent
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = name
    t.TextColor3 = color
    t.TextStrokeTransparency = 0
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.Parent = b
    return b
end

local function UpdateESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local isKiller = plr.Character:FindFirstChildOfClass("Tool") ~= nil
                if (isKiller and Config.ESP_Killer) or (not isKiller and Config.ESP_Survivor) then
                    if not espCache[plr] then
                        espCache[plr] = CreateBillboard(hrp, plr.Name, isKiller and Config.Color_Killer or Config.Color_Survivor)
                    end
                    espCache[plr].Enabled = true
                else
                    if espCache[plr] then espCache[plr].Enabled = false end
                end
            end
        end
    end
    for _, obj in pairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (Config.ESP_Gen and n:find("generator")) or (Config.ESP_Trap and n:find("trap")) then
            if not espCache[obj] then
                espCache[obj] = CreateBillboard(obj, n:find("gen") and "GEN" or "TRAP", n:find("gen") and Config.Color_Gen or Config.Color_Trap)
            end
            espCache[obj].Enabled = true
        end
    end
end

-- ==========================================
-- AUTO SKILLCHECK (GUI WATCHER)
-- ==========================================
local vim = game:GetService("VirtualInputManager")
local isHitting = false

local function CheckForSkillcheck()
    if isHitting then return end
    local guis = game:GetService("CoreGui"):GetDescendants()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then for _, v in pairs(pg:GetDescendants()) do table.insert(guis, v) end end

    for _, gui in pairs(guis) do
        if gui:IsA("Frame") or gui:IsA("ImageLabel") then
            local name = gui.Name:lower()
            if name:find("skill") or name:find("check") or name:find("minigame") then
                if gui.Visible then
                    isHitting = true
                    vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    task.wait(0.5)
                    isHitting = false
                    break
                end
            end
        end
    end
end

-- ==========================================
-- AIM & COMBAT
-- ==========================================
local function GetClosestTarget()
    local closest, minDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local vec, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if onScreen and dist < minDist and dist < 200 then
                    minDist = dist; closest = hrp
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    UpdateESP()
    if Config.AutoSkill or Config.AutoTrap then CheckForSkillcheck() end
    if Camera.FieldOfView ~= Config.CameraFOV then Camera.FieldOfView = Config.CameraFOV end
    if Config.AimLock then
        local target = GetClosestTarget()
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), 0.2)
        end
    end
end)

-- ==========================================
-- CHARACTER LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                if Config.AutoCrouch then hum.CameraOffset = Vector3.new(0, -1, 0) else hum.CameraOffset = Vector3.new(0, 0, 0) end
                if Config.NoClip then for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
            end
        end
        if Config.Fullbright then Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
        else Lighting.Brightness = 1; Lighting.GlobalShadows = true end
        if Config.NoShadow then for _, v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.CastShadow = false end end end
    end
end)