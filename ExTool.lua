--[[
  CLogger v2.1 - Mobile Safe Edition
  created by: SofiAkira
  Changes: removed __namecall hook, lighter animations, full crash protection
]]

-- [01] SERVICES
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local LogService       = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")
local LP               = Players.LocalPlayer

-- [02] EXECUTOR DETECTION
local isExec = false
pcall(function() isExec = type(getgenv) == "function" end)

-- [03] RESPONSIVE SIZING
local vp    = workspace.CurrentCamera.ViewportSize
local PW    = math.clamp(math.floor(vp.X * 0.92), 280, 540)
local PH    = math.clamp(math.floor(vp.Y * 0.85), 320, 500)
local FSM   = math.clamp(math.floor(PW / 48), 9, 13)
local FLG   = math.clamp(math.floor(PW / 28), 14, 20)
local TAB_W = math.floor((PW - 28) / 4) - 3

-- [04] CLEANUP OLD INSTANCE
pcall(function()
    local cg = game:GetService("CoreGui"):FindFirstChild("CLogger")
    if cg then cg:Destroy() end
end)
pcall(function()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local cg = pg:FindFirstChild("CLogger")
        if cg then cg:Destroy() end
    end
end)

-- [05] ROOT GUI
local Root = Instance.new("ScreenGui")
Root.Name            = "CLogger"
Root.ResetOnSpawn    = false
Root.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
Root.IgnoreGuiInset  = true
Root.DisplayOrder    = 999

local guiOk = false
if isExec then
    guiOk = pcall(function()
        Root.Parent = game:GetService("CoreGui")
    end)
end
if not guiOk then
    Root.Parent = LP:WaitForChild("PlayerGui", 10)
end

-- [06] HELPERS
local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0, 7)
end

local function mkStroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color     = col or Color3.fromRGB(40, 120, 220)
    s.Thickness = th or 1.5
    return s
end

local function mkPad(p, l, r, t, b)
    local u = Instance.new("UIPadding", p)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
end

local function mkList(p, dir, sp)
    local lay = Instance.new("UIListLayout", p)
    lay.FillDirection = dir or Enum.FillDirection.Vertical
    lay.SortOrder     = Enum.SortOrder.LayoutOrder
    lay.Padding       = UDim.new(0, sp or 4)
end

local function mkLabel(p, props)
    local lab = Instance.new("TextLabel", p)
    lab.BackgroundTransparency = 1
    lab.TextWrapped = true
    lab.RichText    = false
    for k, v in pairs(props or {}) do lab[k] = v end
    return lab
end

local function mkBtn(p, props)
    local b = Instance.new("TextButton", p)
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    for k, v in pairs(props or {}) do b[k] = v end
    return b
end

local function mkScroll(parent)
    local s = Instance.new("ScrollingFrame", parent)
    s.Size                 = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel      = 0
    s.ScrollBarThickness   = 3
    s.ScrollBarImageColor3 = Color3.fromRGB(46, 132, 215)
    s.CanvasSize           = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    s.Visible              = false
    s.ZIndex               = 11
    mkPad(s, 5, 5, 4, 4)
    mkList(s, Enum.FillDirection.Vertical, 4)
    return s
end

local function argStr(v)
    local t = typeof(v)
    if v == nil then return "nil"
    elseif t == "string" then
        local s = v:sub(1, 40)
        return '"' .. (#v > 40 and s .. "..." or s) .. '"'
    elseif t == "number" then
        return tostring(math.floor(v * 100 + 0.5) / 100)
    elseif t == "boolean" then return tostring(v)
    elseif t == "Instance" then return v.ClassName .. ':' .. v.Name
    elseif t == "table" then
        local n = 0
        for _ in pairs(v) do n = n + 1 end
        return "{" .. n .. " keys}"
    elseif t == "Vector3" then
        return ("V3(%.1f,%.1f,%.1f)"):format(v.X, v.Y, v.Z)
    else return t end
end

local function argsStr(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = argStr(select(i, ...))
    end
    return "(" .. table.concat(parts, ", ") .. ")"
end

-- [07] TOGGLE BUTTON
local Toggle = mkBtn(Root, {
    Size             = UDim2.new(0, 42, 0, 42),
    Position         = UDim2.new(0, 10, 0.5, -21),
    BackgroundColor3 = Color3.fromRGB(12, 48, 115),
    Text             = "CL",
    TextColor3       = Color3.fromRGB(105, 192, 255),
    TextSize         = 14,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 200,
    Visible          = false,
})
mkCorner(Toggle, UDim.new(1, 0))
mkStroke(Toggle, Color3.fromRGB(55, 148, 255), 2)

-- [08] MAIN WINDOW
local Main = Instance.new("Frame", Root)
Main.Name                   = "Main"
Main.Size                   = UDim2.new(0, PW, 0, PH)
Main.Position               = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
Main.BackgroundColor3       = Color3.fromRGB(6, 18, 52)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel        = 0
Main.ClipsDescendants       = true
mkCorner(Main, UDim.new(0, 12))
mkStroke(Main, Color3.fromRGB(32, 118, 255), 1.5)

-- Simple gradient (no animated waves to save memory)
local grad = Instance.new("UIGradient", Main)
grad.Rotation = 90
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(10, 30, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6, 18, 52)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(4, 12, 40)),
})

-- [09] HEADER
local HH = math.clamp(math.floor(PH * 0.10), 40, 52)
local Header = Instance.new("Frame", Main)
Header.Size                   = UDim2.new(1, 0, 0, HH)
Header.BackgroundColor3       = Color3.fromRGB(8, 24, 72)
Header.BackgroundTransparency = 0.05
Header.BorderSizePixel        = 0
Header.ZIndex                 = 60
mkCorner(Header, UDim.new(0, 12))

mkLabel(Header, {
    Size             = UDim2.new(0, 85, 1, 0),
    Position         = UDim2.new(0, 10, 0, 0),
    Text             = "CLogger",
    TextColor3       = Color3.fromRGB(115, 202, 255),
    TextSize         = FLG,
    Font             = Enum.Font.GothamBold,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 61,
})
mkLabel(Header, {
    Size             = UDim2.new(0, 180, 1, 0),
    Position         = UDim2.new(0, 100, 0, 0),
    Text             = "by SofiAkira  v2.1",
    TextColor3       = Color3.fromRGB(55, 135, 210),
    TextSize         = FSM,
    Font             = Enum.Font.Gotham,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 61,
})

local CloseBtn = mkBtn(Header, {
    Size             = UDim2.new(0, 26, 0, 26),
    Position         = UDim2.new(1, -34, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(172, 36, 36),
    Text             = "X",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = FSM,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 62,
})
mkCorner(CloseBtn, UDim.new(0, 5))

-- [10] TAB BAR
local TABH = 32
local TabBar = Instance.new("Frame", Main)
TabBar.Size                   = UDim2.new(1, -14, 0, TABH)
TabBar.Position               = UDim2.new(0, 7, 0, HH + 2)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel        = 0
TabBar.ZIndex                 = 60
mkList(TabBar, Enum.FillDirection.Horizontal, 3)

local CTOP = HH + TABH + 6
local ContentArea = Instance.new("Frame", Main)
ContentArea.Size                   = UDim2.new(1, -12, 1, -CTOP - 4)
ContentArea.Position               = UDim2.new(0, 6, 0, CTOP)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel        = 0
ContentArea.ZIndex                 = 10
ContentArea.ClipsDescendants       = true

-- [11] TAB SYSTEM
local tabPanels = {}
local tabBtns   = {}
local activeTab = nil
local C_OFF     = Color3.fromRGB(10, 35, 90)
local C_ON      = Color3.fromRGB(22, 95, 210)
local CT_OFF    = Color3.fromRGB(90, 155, 225)
local CT_ON     = Color3.fromRGB(220, 240, 255)

local function switchTab(name)
    for k, p in pairs(tabPanels) do
        p.Visible = false
        local b = tabBtns[k]
        if b then
            b.BackgroundColor3       = C_OFF
            b.BackgroundTransparency = 0.30
            b.TextColor3             = CT_OFF
        end
    end
    if tabPanels[name] then
        tabPanels[name].Visible = true
        local b = tabBtns[name]
        if b then
            b.BackgroundColor3       = C_ON
            b.BackgroundTransparency = 0
            b.TextColor3             = CT_ON
        end
        activeTab = name
    end
end

local function makeTab(name, order)
    local b = mkBtn(TabBar, {
        Size                   = UDim2.new(0, TAB_W, 0, TABH - 2),
        BackgroundColor3       = C_OFF,
        BackgroundTransparency = 0.30,
        Text                   = name,
        TextColor3             = CT_OFF,
        TextSize               = FSM,
        Font                   = Enum.Font.GothamSemibold,
        LayoutOrder            = order,
        ZIndex                 = 61,
        TextTruncate           = Enum.TextTruncate.AtEnd,
    })
    mkCorner(b, UDim.new(0, 6))
    local panel = mkScroll(ContentArea)
    tabPanels[name] = panel
    tabBtns[name]   = b
    b.MouseButton1Click:Connect(function() switchTab(name) end)
    return panel
end

-- [12] CONSOLE TAB
local consolePanel = makeTab("Console", 1)
local logSeq = 0

local CMETA = {
    [Enum.MessageType.MessageOutput]  = {tag = "OUT",  bg = Color3.fromRGB(20,60,140),  tc = Color3.fromRGB(148,212,255)},
    [Enum.MessageType.MessageWarning] = {tag = "WARN", bg = Color3.fromRGB(120,80,0),   tc = Color3.fromRGB(255,208,58)},
    [Enum.MessageType.MessageError]   = {tag = "ERR",  bg = Color3.fromRGB(120,20,20),  tc = Color3.fromRGB(255,100,100)},
    [Enum.MessageType.MessageInfo]    = {tag = "INFO", bg = Color3.fromRGB(10,100,140), tc = Color3.fromRGB(128,222,255)},
}

local function addLog(msg, msgType)
    pcall(function()
        if not msg or msg:match("^%s*$") then return end
        logSeq = logSeq + 1
        local meta = CMETA[msgType] or CMETA[Enum.MessageType.MessageOutput]

        local row = Instance.new("Frame", consolePanel)
        row.Size                   = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize          = Enum.AutomaticSize.Y
        row.BackgroundColor3       = meta.bg
        row.BackgroundTransparency = 0.55
        row.BorderSizePixel        = 0
        row.LayoutOrder            = logSeq
        row.ZIndex                 = 12
        mkCorner(row, UDim.new(0, 5))
        mkPad(row, 8, 6, 4, 4)
        mkList(row, Enum.FillDirection.Vertical, 2)

        local hdr = Instance.new("Frame", row)
        hdr.Size                   = UDim2.new(1, 0, 0, 14)
        hdr.BackgroundTransparency = 1
        hdr.LayoutOrder            = 1
        hdr.ZIndex                 = 13

        mkLabel(hdr, {
            Size           = UDim2.new(0, 36, 1, 0),
            Text           = meta.tag,
            TextColor3     = meta.tc,
            TextSize       = FSM - 1,
            Font           = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex         = 14,
        })
        mkLabel(hdr, {
            Size           = UDim2.new(1, -40, 1, 0),
            Position       = UDim2.new(0, 40, 0, 0),
            Text           = os.date("%H:%M:%S"),
            TextColor3     = Color3.fromRGB(80, 128, 190),
            TextSize       = FSM - 2,
            Font           = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex         = 14,
        })

        mkLabel(row, {
            Size           = UDim2.new(1, 0, 0, 0),
            AutomaticSize  = Enum.AutomaticSize.Y,
            Text           = msg,
            TextColor3     = meta.tc,
            TextSize       = FSM,
            Font           = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder    = 2,
            ZIndex         = 13,
        })
    end)
end

local clearBtn = mkBtn(consolePanel, {
    Size             = UDim2.new(1, 0, 0, 24),
    LayoutOrder      = 0,
    BackgroundColor3 = Color3.fromRGB(18, 50, 108),
    Text             = "Clear Console",
    TextColor3       = Color3.fromRGB(125, 192, 255),
    TextSize         = FSM,
    Font             = Enum.Font.GothamSemibold,
    ZIndex           = 12,
})
mkCorner(clearBtn, UDim.new(0, 5))
clearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(consolePanel:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    logSeq = 0
end)

LogService.MessageOut:Connect(addLog)

task.spawn(function()
    pcall(function()
        local hist = LogService:GetLogHistory()
        if #hist > 0 then
            addLog("-- " .. #hist .. " earlier log(s) --", Enum.MessageType.MessageInfo)
            for _, e in ipairs(hist) do addLog(e.message, e.messageType) end
        end
    end)
end)

-- [13] SCRIPTS TAB
local scriptPanel  = makeTab("Scripts", 2)
local sSeq         = 0
local knownScripts = {}

local typeColors = {
    Script       = Color3.fromRGB(255, 158, 45),
    LocalScript  = Color3.fromRGB(50, 205, 98),
    ModuleScript = Color3.fromRGB(162, 95, 255),
}

local function addScriptEntry(s)
    if knownScripts[s] then return end
    knownScripts[s] = true
    sSeq = sSeq + 1
    local tc = typeColors[s.ClassName] or Color3.fromRGB(175, 175, 195)

    local row = Instance.new("Frame", scriptPanel)
    row.Size                   = UDim2.new(1, 0, 0, 50)
    row.BackgroundColor3       = Color3.fromRGB(8, 24, 65)
    row.BackgroundTransparency = 0.20
    row.BorderSizePixel        = 0
    row.LayoutOrder            = sSeq
    row.ZIndex                 = 12
    mkCorner(row, UDim.new(0, 6))
    mkPad(row, 8, 8, 5, 5)

    mkLabel(row, {
        Size           = UDim2.new(1, 0, 0, 15),
        Text           = "[" .. s.ClassName .. "]",
        TextColor3     = tc,
        TextSize       = FSM - 1,
        Font           = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })
    mkLabel(row, {
        Size           = UDim2.new(1, 0, 0, 15),
        Position       = UDim2.new(0, 0, 0, 16),
        Text           = s.Name,
        TextColor3     = Color3.fromRGB(195, 228, 255),
        TextSize       = FSM,
        Font           = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        ZIndex         = 13,
    })
    mkLabel(row, {
        Size           = UDim2.new(1, 0, 0, 12),
        Position       = UDim2.new(0, 0, 0, 33),
        Text           = s:GetFullName(),
        TextColor3     = Color3.fromRGB(80, 140, 200),
        TextSize       = FSM - 2,
        Font           = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        ZIndex         = 13,
    })
end

local scanInfo = mkLabel(scriptPanel, {
    Size           = UDim2.new(1, 0, 0, 14),
    LayoutOrder    = 1,
    Text           = "Tap Scan to find all scripts.",
    TextColor3     = Color3.fromRGB(86, 150, 208),
    TextSize       = FSM - 1,
    Font           = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex         = 12,
})

local scanBtn = mkBtn(scriptPanel, {
    Size             = UDim2.new(1, 0, 0, 26),
    LayoutOrder      = 0,
    BackgroundColor3 = Color3.fromRGB(14, 86, 44),
    Text             = "Scan for Scripts",
    TextColor3       = Color3.fromRGB(122, 255, 165),
    TextSize         = FSM,
    Font             = Enum.Font.GothamBold,
    ZIndex           = 12,
})
mkCorner(scanBtn, UDim.new(0, 6))

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "Scanning..."
    for _, c in ipairs(scriptPanel:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    sSeq = 0
    knownScripts = {}
    task.spawn(function()
        pcall(function()
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    addScriptEntry(obj)
                end
            end
        end)
        pcall(function()
            if isExec and type(getscripts) == "function" then
                for _, s in ipairs(getscripts()) do addScriptEntry(s) end
            end
        end)
        local count = 0
        for _ in pairs(knownScripts) do count = count + 1 end
        scanInfo.Text = count .. " script(s) found."
        scanBtn.Text  = "Rescan (" .. count .. ")"
    end)
end)

-- [14] PLAYERS TAB
local playerPanel = makeTab("Players", 3)
local pCards      = {}
local pSeq        = 0

local function makeCard(player)
    if pCards[player] then return end
    pSeq = pSeq + 1

    local card = Instance.new("Frame", playerPanel)
    card.Size                   = UDim2.new(1, 0, 0, 62)
    card.BackgroundColor3       = Color3.fromRGB(8, 22, 64)
    card.BackgroundTransparency = 0.18
    card.BorderSizePixel        = 0
    card.LayoutOrder            = pSeq
    card.ZIndex                 = 12
    mkCorner(card, UDim.new(0, 7))
    mkPad(card, 8, 8, 6, 6)

    mkLabel(card, {
        Size           = UDim2.new(1, 0, 0, 18),
        Text           = player.DisplayName,
        TextColor3     = Color3.fromRGB(192, 232, 255),
        TextSize       = FSM,
        Font           = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })
    mkLabel(card, {
        Size           = UDim2.new(1, 0, 0, 13),
        Position       = UDim2.new(0, 0, 0, 19),
        Text           = "@" .. player.Name,
        TextColor3     = Color3.fromRGB(78, 132, 196),
        TextSize       = FSM - 2,
        Font           = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })

    local statusL = mkLabel(card, {
        Size           = UDim2.new(1, 0, 0, 13),
        Position       = UDim2.new(0, 0, 0, 34),
        Text           = "Alive",
        TextColor3     = Color3.fromRGB(68, 218, 108),
        TextSize       = FSM - 1,
        Font           = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })

    local hpBg = Instance.new("Frame", card)
    hpBg.Size             = UDim2.new(1, 0, 0, 5)
    hpBg.Position         = UDim2.new(0, 0, 1, -7)
    hpBg.BackgroundColor3 = Color3.fromRGB(22, 25, 54)
    hpBg.BorderSizePixel  = 0
    hpBg.ZIndex           = 13
    mkCorner(hpBg, UDim.new(1, 0))

    local hpBar = Instance.new("Frame", hpBg)
    hpBar.Size             = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(52, 210, 85)
    hpBar.BorderSizePixel  = 0
    hpBar.ZIndex           = 14
    mkCorner(hpBar, UDim.new(1, 0))

    pCards[player] = {card = card, status = statusL, hpBar = hpBar}
end

local function removeCard(player)
    if pCards[player] then
        pcall(function() pCards[player].card:Destroy() end)
        pCards[player] = nil
    end
end

-- Light heartbeat: runs at 5fps, only on Players tab
local hbAcc = 0
RunService.Heartbeat:Connect(function(dt)
    hbAcc = hbAcc + dt
    if hbAcc < 0.20 then return end
    hbAcc = 0
    if activeTab ~= "Players" then return end
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                if not pCards[player] then makeCard(player) end
                local card = pCards[player]
                if card then
                    local char = player.Character
                    local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Health > 0 then
                        local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        card.hpBar.Size = UDim2.new(r, 0, 1, 0)
                        card.hpBar.BackgroundColor3 = Color3.new(
                            math.clamp((1-r)*2, 0, 1),
                            math.clamp(r*1.4,   0, 1),
                            0.04
                        )
                        card.status.Text       = ("HP: %d/%d"):format(
                            math.floor(hum.Health), math.floor(hum.MaxHealth))
                        card.status.TextColor3 = Color3.fromRGB(68, 218, 108)
                    else
                        card.status.Text       = "Not spawned"
                        card.status.TextColor3 = Color3.fromRGB(148, 148, 160)
                    end
                end
            end
        end
        for player in pairs(pCards) do
            if not player.Parent then removeCard(player) end
        end
    end)
end)

Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    makeCard(p)
end)
Players.PlayerRemoving:Connect(removeCard)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then makeCard(p) end
end

-- [15] RSPY TAB (S->C only, no __namecall hook)
local rspyPanel = makeTab("rSpy", 4)
local rspySeq   = 0
local rspyOn    = true
local rspyConns = {}

local rspyRow = Instance.new("Frame", rspyPanel)
rspyRow.Size                   = UDim2.new(1, 0, 0, 26)
rspyRow.BackgroundTransparency = 1
rspyRow.BorderSizePixel        = 0
rspyRow.LayoutOrder            = 0
rspyRow.ZIndex                 = 12
mkList(rspyRow, Enum.FillDirection.Horizontal, 4)

local rspyToggle = mkBtn(rspyRow, {
    Size             = UDim2.new(0, TAB_W + 20, 0, 26),
    BackgroundColor3 = Color3.fromRGB(18, 100, 42),
    Text             = "Spy: ON",
    TextColor3       = Color3.fromRGB(130, 255, 165),
    TextSize         = FSM,
    Font             = Enum.Font.GothamSemibold,
    LayoutOrder      = 0,
    ZIndex           = 12,
})
mkCorner(rspyToggle, UDim.new(0, 6))

local rspyClear = mkBtn(rspyRow, {
    Size             = UDim2.new(0, TAB_W, 0, 26),
    BackgroundColor3 = Color3.fromRGB(18, 50, 108),
    Text             = "Clear",
    TextColor3       = Color3.fromRGB(125, 192, 255),
    TextSize         = FSM,
    Font             = Enum.Font.GothamSemibold,
    LayoutOrder      = 1,
    ZIndex           = 12,
})
mkCorner(rspyClear, UDim.new(0, 6))

mkLabel(rspyPanel, {
    Size           = UDim2.new(1, 0, 0, 13),
    LayoutOrder    = 1,
    Text           = "Capturing S->C RemoteEvent fires.",
    TextColor3     = Color3.fromRGB(80, 148, 210),
    TextSize       = FSM - 2,
    Font           = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex         = 12,
})

local function addRSpyEntry(name, path, ...)
    if not rspyOn then return end
    pcall(function()
        rspySeq = rspySeq + 1
        local args = argsStr(...)

        local row = Instance.new("Frame", rspyPanel)
        row.Size                   = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize          = Enum.AutomaticSize.Y
        row.BackgroundColor3       = Color3.fromRGB(7, 20, 55)
        row.BackgroundTransparency = 0.25
        row.BorderSizePixel        = 0
        row.LayoutOrder            = rspySeq + 10
        row.ZIndex                 = 12
        mkCorner(row, UDim.new(0, 5))
        mkPad(row, 8, 6, 4, 4)
        mkList(row, Enum.FillDirection.Vertical, 2)

        mkLabel(row, {
            Size           = UDim2.new(1, 0, 0, 14),
            Text           = "[S->C]  " .. name .. "  " .. os.date("%H:%M:%S"),
            TextColor3     = Color3.fromRGB(60, 200, 255),
            TextSize       = FSM - 1,
            Font           = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder    = 1,
            ZIndex         = 13,
        })
        mkLabel(row, {
            Size           = UDim2.new(1, 0, 0, 11),
            Text           = path,
            TextColor3     = Color3.fromRGB(80, 130, 195),
            TextSize       = FSM - 2,
            Font           = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate   = Enum.TextTruncate.AtEnd,
            LayoutOrder    = 2,
            ZIndex         = 13,
        })
        mkLabel(row, {
            Size           = UDim2.new(1, 0, 0, 0),
            AutomaticSize  = Enum.AutomaticSize.Y,
            Text           = "Args: " .. args,
            TextColor3     = Color3.fromRGB(168, 215, 255),
            TextSize       = FSM - 1,
            Font           = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped    = true,
            LayoutOrder    = 3,
            ZIndex         = 13,
        })
    end)
end

local function hookRemote(remote)
    if rspyConns[remote] then return end
    if not remote:IsA("RemoteEvent") then return end
    pcall(function()
        local conn = remote.OnClientEvent:Connect(function(...)
            addRSpyEntry(remote.Name, remote:GetFullName(), ...)
        end)
        rspyConns[remote] = conn
    end)
end

pcall(function()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") then hookRemote(obj) end
    end
end)

game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then
        task.wait(0.1)
        hookRemote(obj)
    end
end)

rspyToggle.MouseButton1Click:Connect(function()
    rspyOn = not rspyOn
    rspyToggle.Text             = rspyOn and "Spy: ON" or "Spy: OFF"
    rspyToggle.BackgroundColor3 = rspyOn
        and Color3.fromRGB(18, 100, 42)
        or  Color3.fromRGB(85, 22, 22)
    rspyToggle.TextColor3       = rspyOn
        and Color3.fromRGB(130, 255, 165)
        or  Color3.fromRGB(255, 140, 140)
end)

rspyClear.MouseButton1Click:Connect(function()
    for _, c in ipairs(rspyPanel:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    rspySeq = 0
end)

-- [16] DRAG
local drag = {on = false, ms = nil, sp = nil}
Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        drag.on = true
        drag.ms = i.Position
        drag.sp = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not drag.on then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - drag.ms
        Main.Position = UDim2.new(
            drag.sp.X.Scale, drag.sp.X.Offset + d.X,
            drag.sp.Y.Scale, drag.sp.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        drag.on = false
    end
end)

-- [17] OPEN / CLOSE
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible   = false
    Toggle.Visible = true
end)
Toggle.MouseButton1Click:Connect(function()
    Main.Visible   = true
    Toggle.Visible = false
end)

-- [18] STARTUP
switchTab("Console")
print("[CLogger v2.1] Loaded " .. PW .. "x" .. PH .. " -- by SofiAkira")
