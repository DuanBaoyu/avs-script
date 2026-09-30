--==================================================
-- ASESINOS VS SHERIFS - 反检测完整版
--==================================================

-- 【反检测 1】延迟初始化，躲避入场扫描
task.wait(3)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer

-- 【反检测 2】清理执行器环境标识（如果存在）
pcall(function()
    if getgenv then
        local env = getgenv()
        if type(env) == "table" then
            pcall(function() env.syn = nil end)
            pcall(function() env.secure_call = nil end)
            pcall(function() env.getgenv = nil end)
            pcall(function() env.identifyexecutor = nil end)
        end
    end
end)

-- 【反检测 3】随机生成 UI 名称，每次加载都不一样
local function randStr(len)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local s = ""
    for i = 1, (len or 8) do
        local idx = math.random(1, #chars)
        s = s .. chars:sub(idx, idx)
    end
    return s
end

local GUI_NAME = "Stats_" .. randStr(6)

local PlayerGui = LP:WaitForChild("PlayerGui")
local old = PlayerGui:FindFirstChild("AsesinosVsSherifsHub")
if old then old:Destroy() end
old = PlayerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

--// 配置
local CFG = {
    AIM_FOV          = 110,
    MAX_AIM_DISTANCE = 350,
    AIM_SMOOTHNESS   = 0.92,
    LOCK_RADIUS      = 25,
    AUTO_FIRE_MIN    = 0.18,
    AUTO_FIRE_MAX    = 0.38,
    RETURN_DELAY     = 2.5,
    TELEPORT_CD      = 0.8,
}

local S = { esp = false, aim = false, autoFire = false }

local function safeClick()
    if mouse1click then
        pcall(mouse1click)
    else
        pcall(function()
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
end

--==================================================
-- GUI
--==================================================
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(400, 300)
main.Position = UDim2.new(0.5, -200, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
main.BorderSizePixel = 0
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = Color3.fromRGB(27, 27, 32)
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.fromOffset(280, 25)
title.Position = UDim2.fromOffset(15, 15)
title.BackgroundTransparency = 1
title.Text = "Asesinos vs Sherifs"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", header)
close.Size = UDim2.fromOffset(32, 32)
close.Position = UDim2.new(1, -42, 0, 13)
close.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.AutoButtonColor = false
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -24, 1, -72)
content.Position = UDim2.fromOffset(12, 66)
content.BackgroundTransparency = 1

local sidebar = Instance.new("Frame", content)
sidebar.Size = UDim2.fromOffset(105, 222)
sidebar.BackgroundColor3 = Color3.fromRGB(26, 26, 31)
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local function makeSideBtn(text, y)
    local b = Instance.new("TextButton", sidebar)
    b.Size = UDim2.new(1, -12, 0, 38)
    b.Position = UDim2.fromOffset(6, y)
    b.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(220, 220, 225)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local mainTab = makeSideBtn("Main", 10)
local playersTab = makeSideBtn("Players", 55)

local pages = Instance.new("Frame", content)
pages.Size = UDim2.new(1, -117, 1, 0)
pages.Position = UDim2.fromOffset(117, 0)
pages.BackgroundTransparency = 1

local mainPage = Instance.new("Frame", pages)
mainPage.Size = UDim2.new(1, 0, 1, 0)
mainPage.BackgroundTransparency = 1

local playersPage = Instance.new("Frame", pages)
playersPage.Size = UDim2.new(1, 0, 1, 0)
playersPage.BackgroundTransparency = 1
playersPage.Visible = false

local fovCircle = Instance.new("Frame", gui)
fovCircle.Size = UDim2.fromOffset(CFG.AIM_FOV * 2, CFG.AIM_FOV * 2)
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.ZIndex = 999
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = Color3.fromRGB(0, 255, 0)
fovStroke.Thickness = 3
fovStroke.Transparency = 0.2

local lockDot = Instance.new("Frame", gui)
lockDot.Size = UDim2.fromOffset(8, 8)
lockDot.AnchorPoint = Vector2.new(0.5, 0.5)
lockDot.Position = UDim2.new(0.5, 0, 0.5, 0)
lockDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
lockDot.BackgroundTransparency = 0.5
lockDot.BorderSizePixel = 0
lockDot.Visible = false
lockDot.ZIndex = 999
Instance.new("UICorner", lockDot).CornerRadius = UDim.new(1, 0)

--==================================================
-- ESP
--==================================================
local espObjects = {}

local function buildESP(player)
    if espObjects[player] then return end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.ZIndex = 10
    box.Visible = false
    box.Parent = gui
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = Color3.fromRGB(0, 255, 0)
    stroke.Thickness = 2
    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.ZIndex = 10
    nameLabel.Visible = false
    nameLabel.Parent = gui
    espObjects[player] = { box = box, nameLabel = nameLabel }
end

local function destroyESP(player)
    local d = espObjects[player]
    if not d then return end
    if d.box then d.box:Destroy() end
    if d.nameLabel then d.nameLabel:Destroy() end
    espObjects[player] = nil
end

local function rebuildESP()
    for p in pairs(espObjects) do destroyESP(p) end
    if S.esp then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then buildESP(p) end
        end
    end
end

--==================================================
-- 按钮
--==================================================
local function createButton(parent, text, y)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -10, 0, 44)
    b.Position = UDim2.fromOffset(5, y)
    b.BackgroundColor3 = Color3.fromRGB(34, 34, 41)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = false
    b.Active = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    return b
end

local function makeToggle(label, y, key, onChange)
    local btn = createButton(mainPage, label .. " - OFF", y)
    btn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        if S[key] then
            btn.Text = label .. " - ON"
            btn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
        else
            btn.Text = label .. " - OFF"
            btn.BackgroundColor3 = Color3.fromRGB(34, 34, 41)
        end
        if onChange then onChange(S[key]) end
    end)
    return btn
end

local espBtn      = makeToggle("ESP",        10,  "esp",      function() rebuildESP() end)
local aimBtn      = makeToggle("Aim Assist", 64,  "aim",      function(on)
    fovCircle.Visible = on
    lockDot.Visible = on
end)
local autoFireBtn = makeToggle("Auto Fire",  118, "autoFire")

--==================================================
-- 玩家列表
--==================================================
local scroll = Instance.new("ScrollingFrame", playersPage)
scroll.Size = UDim2.new(1, -10, 1, -10)
scroll.Position = UDim2.fromOffset(5, 5)
scroll.BackgroundColor3 = Color3.fromRGB(26, 26, 31)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 10)
local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 6)

local selectedButton, selectedPlayer = nil, nil
local returnToken = 0
local lastTeleport = 0
local teleporting = false

local function clearSelection()
    if selectedButton then
        selectedButton.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    end
    selectedButton, selectedPlayer = nil, nil
end

-- 【反检测 4】传送加入随机步数和随机延迟，避免机械的固定轨迹
local function smoothMove(root, fromCF, toCF)
    local steps = math.random(3, 5)
    local stepTime = 0.008 + math.random() * 0.008
    for i = 1, steps do
        if not root or not root.Parent then return false end
        root.CFrame = fromCF:Lerp(toCF, i / steps)
        task.wait(stepTime)
    end
    return true
end

local function teleportTo(target)
    if teleporting then return end
    if os.clock() - lastTeleport < CFG.TELEPORT_CD then return end
    if not target then return end

    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local tChar = target.Character
    local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not (myRoot and tRoot) then return end

    lastTeleport = os.clock()
    teleporting = true

    local savedPos = myRoot.CFrame
    local dest = tRoot.CFrame * CFrame.new(0, 0.5, 1.5)

    smoothMove(myRoot, savedPos, dest)

    if S.autoFire then
        task.wait(0.06 + math.random() * 0.06)
        safeClick()
    end

    returnToken = returnToken + 1
    local myToken = returnToken
    task.delay(CFG.RETURN_DELAY, function()
        if returnToken ~= myToken then
            teleporting = false
            return
        end
        local c = LP.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then
            smoothMove(r, r.CFrame, savedPos + Vector3.new(0, 3, 0))
        end
        teleporting = false
    end)
end

local function refreshPlayers()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    clearSelection()

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= LP then
            local b = Instance.new("TextButton", scroll)
            b.Size = UDim2.new(1, -10, 0, 40)
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
            b.Text = "  " .. target.Name
            b.TextColor3 = Color3.new(1, 1, 1)
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.Font = Enum.Font.Gotham
            b.TextSize = 13
            b.AutoButtonColor = false
            b.Active = true
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)

            b.MouseButton1Click:Connect(function()
                if selectedButton == b then
                    clearSelection()
                else
                    if selectedButton then
                        selectedButton.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
                    end
                    selectedButton, selectedPlayer = b, target
                    b.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                end
            end)
        end
    end
end

refreshPlayers()

Players.PlayerAdded:Connect(function(p)
    if S.esp and p ~= LP then buildESP(p) end
    refreshPlayers()
end)

Players.PlayerRemoving:Connect(function(p)
    destroyESP(p)
    if selectedPlayer == p then clearSelection() end
    refreshPlayers()
end)

mainTab.MouseButton1Click:Connect(function()
    mainPage.Visible, playersPage.Visible = true, false
end)
playersTab.MouseButton1Click:Connect(function()
    mainPage.Visible, playersPage.Visible = false, true
    refreshPlayers()
end)

-- R 键传送
UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.R then
        if selectedPlayer and selectedPlayer.Parent then
            teleportTo(selectedPlayer)
        end
    end
end)

--==================================================
-- 主循环
--==================================================
local aimTarget = nil
local nextShotTime = 0
local frame = 0
local isLocked = false
local aimJitterX, aimJitterY = 0, 0
local jitterTick = 0

local function isVisible(targetPart)
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local dir = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character }
    local result = workspace:Raycast(origin, dir, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function findTarget(cam)
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local best, bestDist = nil, math.huge
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= LP then
            local char = target.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and char:FindFirstChild("Head")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and head and root and hum.Health > 0 then
                local d3 = (root.Position - cam.CFrame.Position).Magnitude
                if d3 <= CFG.MAX_AIM_DISTANCE then
                    local pos, onScreen = cam:WorldToViewportPoint(head.Position)
                    if onScreen and pos.Z > 0 then
                        local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if d < CFG.AIM_FOV and d < bestDist and isVisible(head) then
                            bestDist, best = d, target
                        end
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    frame = frame + 1
    local cam = workspace.CurrentCamera
    if not cam then return end

    -- ESP
    if S.esp and frame % 2 == 0 then
        for player, data in pairs(espObjects) do
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            if root and head then
                local headScreen, headOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local footScreen, footOn = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                if headOn and footOn and headScreen.Z > 0 then
                    local height = math.abs(footScreen.Y - headScreen.Y)
                    local width  = height * 0.55
                    data.box.Size = UDim2.fromOffset(width, height)
                    data.box.Position = UDim2.fromOffset(headScreen.X - width / 2, headScreen.Y)
                    data.box.Visible = true
                    data.nameLabel.Size = UDim2.fromOffset(160, 18)
                    data.nameLabel.Position = UDim2.fromOffset(headScreen.X - 80, headScreen.Y - 20)
                    data.nameLabel.Visible = true
                else
                    data.box.Visible = false
                    data.nameLabel.Visible = false
                end
            else
                data.box.Visible = false
                data.nameLabel.Visible = false
            end
        end
    end

    -- 自瞄 + 开火联动
    if S.aim then
        aimTarget = findTarget(cam)
        isLocked = false

        if aimTarget then
            local char = aimTarget.Character
            local head = char and char:FindFirstChild("Head")
            if head then
                -- 【反检测 5】自瞄加入轻微抖动，让轨迹不完全笔直
                jitterTick = jitterTick + 1
                if jitterTick % 6 == 0 then
                    aimJitterX = (math.random() - 0.5) * 0.008
                    aimJitterY = (math.random() - 0.5) * 0.008
                end
                local jitteredHeadPos = head.Position + Vector3.new(aimJitterX, aimJitterY, 0)

                local targetCF = CFrame.lookAt(cam.CFrame.Position, jitteredHeadPos)
                local smooth = CFG.AIM_SMOOTHNESS + (math.random() - 0.5) * 0.02
                cam.CFrame = cam.CFrame:Lerp(targetCF, smooth)

                -- 锁定判定
                local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen and screenPos.Z > 0 then
                    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                    local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if screenDist <= CFG.LOCK_RADIUS then
                        isLocked = true
                    end
                end
            end
        end

        -- 【反检测 6】开火加入随机抖动窗口，节奏不固定
        if isLocked and S.autoFire then
            if os.clock() >= nextShotTime then
                -- 有一定概率跳过这一次开火，避免完美的稳定节奏
                if math.random() > 0.08 then
                    safeClick()
                end
                nextShotTime = os.clock() + CFG.AUTO_FIRE_MIN
                    + math.random() * (CFG.AUTO_FIRE_MAX - CFG.AUTO_FIRE_MIN)
            end
        end
    else
        aimTarget = nil
        isLocked = false
    end

    -- 锁定指示点
    if lockDot.Visible then
        if isLocked then
            lockDot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            lockDot.BackgroundTransparency = 0.2
        else
            lockDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            lockDot.BackgroundTransparency = 0.5
        end
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if S.esp then rebuildESP() end
end)

--==================================================
-- 拖拽 & 关闭
--==================================================
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

print("[AVS Hub] 反检测版加载完成")