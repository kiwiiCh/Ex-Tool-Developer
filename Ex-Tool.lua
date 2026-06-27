--[[
  CLogger v2.0 - Developer Console & Real-Time Monitor
  created by: SofiAkira
  Fixed for Delta executor compatibility (standard Lua syntax)
]]

-- [01] SERVICES
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local LogService       = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LP               = Players.LocalPlayer

-- [02] EXECUTOR DETECTION
local isExec = false
pcall(function() isExec = type(getgenv) == "function" end)

-- [03] RESPONSIVE SIZING
local vp   = workspace.CurrentCamera.ViewportSize
local PW   = math.clamp(math.floor(vp.X * 0.94), 300, 570)
local PH   = math.clamp(math.floor(vp.Y * 0.87), 340, 530)
local FONT_SM = math.clamp(math.floor(PW / 48), 9, 13)
local FONT_MD = math.clamp(math.floor(PW / 36), 11, 15)
local FONT_LG = math.clamp(math.floor(PW / 28), 14, 20)
local TAB_W   = math.floor((PW - 28) / 4) - 3

-- [04] CLEANUP OLD INSTANCE
for _, loc in ipairs({
    (function() local ok,r = pcall(function() return game:GetService("CoreGui") end); return ok and r end)(),
    LP:FindFirstChild("PlayerGui"),
}) do
    if loc then pcall(function()
        local o = loc:FindFirstChild("CLogger"); if o then o:Destroy() end
    end) end
end

-- [05] ROOT GUI
local Root = Instance.new("ScreenGui")
Root.Name            = "CLogger"
Root.ResetOnSpawn    = false
Root.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
Root.IgnoreGuiInset  = true
Root.DisplayOrder    = 999

local rootOk = false
if isExec then rootOk = pcall(function() Root.Parent = game:GetService("CoreGui") end) end
if not rootOk then Root.Parent = LP:WaitForChild("PlayerGui") end

-- [06] HELPERS
local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0, 8)
    return c
end

local function uistroke(p, col, t, tr)
    local s = Instance.new("UIStroke", p)
    s.Color       = col or Color3.fromRGB(40, 120, 220)
    s.Thickness   = t or 1.5
    s.Transparency= tr or 0
    return s
end

local function ipad(p, all, l, r, t, b)
    local u = Instance.new("UIPadding", p)
    local v = UDim.new(0, all or 0)
    u.PaddingLeft   = l and UDim.new(0, l) or v
    u.PaddingRight  = r and UDim.new(0, r) or v
    u.PaddingTop    = t and UDim.new(0, t) or v
    u.PaddingBottom = b and UDim.new(0, b) or v
end

local function ll(p, dir, sp)
    local lay = Instance.new("UIListLayout", p)
    lay.FillDirection = dir or Enum.FillDirection.Vertical
    lay.SortOrder     = Enum.SortOrder.LayoutOrder
    lay.Padding       = UDim.new(0, sp or 4)
    return lay
end

local function lbl(p, props)
    local lab = Instance.new("TextLabel", p)
    lab.BackgroundTransparency = 1
    lab.TextWrapped = true
    lab.RichText    = false
    for k, v in pairs(props or {}) do lab[k] = v end
    return lab
end

local function mkbtn(p, props)
    local b = Instance.new("TextButton", p)
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    for k, v in pairs(props or {}) do b[k] = v end
    local nc = b.BackgroundColor3
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.new(
            math.min(nc.R + 0.06, 1), math.min(nc.G + 0.06, 1), math.min(nc.B + 0.08, 1)
        )}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = nc}):Play()
    end)
    return b
end

-- Argument serializer for rSpy
local function argStr(v)
    local t = typeof(v)
    if v == nil then
        return "nil"
    elseif t == "string" then
        local s = v:sub(1, 55)
        return '"' .. (#v > 55 and s .. "..." or s) .. '"'
    elseif t == "number" then
        return tostring(math.floor(v * 1000 + 0.5) / 1000)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "Instance" then
        return v.ClassName .. ' "' .. v.Name .. '"'
    elseif t == "table" then
        local n = 0
        for _ in pairs(v) do n = n + 1 end
        return "{" .. n .. " keys}"
    elseif t == "Vector3" then
        return ("V3(%.1f,%.1f,%.1f)"):format(v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        local pos = v.Position
        return ("CF(%.1f,%.1f,%.1f)"):format(pos.X, pos.Y, pos.Z)
    elseif t == "Color3" then
        return ("C3(%d,%d,%d)"):format(v.R * 255, v.G * 255, v.B * 255)
    elseif t == "Vector2" then
        return ("V2(%.1f,%.1f)"):format(v.X, v.Y)
    else
        return t
    end
end

local function argsStr(...)
    local t = {}
    for i = 1, select("#", ...) do
        t[i] = argStr(select(i, ...))
    end
    return "(" .. table.concat(t, ", ") .. ")"
end

-- [07] TOGGLE BUTTON
local Toggle = Instance.new("TextButton", Root)
Toggle.Size             = UDim2.new(0, 44, 0, 44)
Toggle.Position         = UDim2.new(0, 14, 0.5, -22)
Toggle.BackgroundColor3 = Color3.fromRGB(12, 48, 115)
Toggle.Text             = "CL"
Toggle.TextColor3       = Color3.fromRGB(105, 192, 255)
Toggle.TextSize         = 15
Toggle.Font             = Enum.Font.GothamBold
Toggle.BorderSizePixel  = 0
Toggle.ZIndex           = 200
Toggle.Visible          = false
corner(Toggle, UDim.new(1, 0))
local tStr = uistroke(Toggle, Color3.fromRGB(55, 148, 255), 2.5)
task.spawn(function()
    while Toggle.Parent do
        TweenService:Create(tStr, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.72}):Play()
        task.wait(1.1)
        TweenService:Create(tStr, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0}):Play()
        task.wait(1.1)
    end
end)

-- [08] MAIN WINDOW
local Main = Instance.new("Frame", Root)
Main.Name                  = "Main"
Main.Size                  = UDim2.new(0, PW, 0, PH)
Main.Position              = UDim2.new(0.5, -PW / 2, 0.5, -PH / 2)
Main.BackgroundColor3      = Color3.fromRGB(6, 18, 52)
Main.BackgroundTransparency= 0.28
Main.BorderSizePixel       = 0
Main.ClipsDescendants      = true
corner(Main, UDim.new(0, 14))

local Glass = Instance.new("Frame", Main)
Glass.Size                   = UDim2.new(1, 0, 1, 0)
Glass.BackgroundColor3       = Color3.fromRGB(55, 125, 225)
Glass.BackgroundTransparency = 0.91
Glass.BorderSizePixel        = 0
Glass.ZIndex                 = 1
corner(Glass, UDim.new(0, 14))

local BG = uistroke(Main, Color3.fromRGB(32, 118, 255), 2, 0.18)
task.spawn(function()
    while Main.Parent do
        TweenService:Create(BG, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Color = Color3.fromRGB(58, 160, 255), Transparency = 0.60}):Play()
        task.wait(2)
        TweenService:Create(BG, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Color = Color3.fromRGB(18, 88, 218), Transparency = 0.08}):Play()
        task.wait(2)
    end
end)

-- [09] INTERNAL FLOWING WATER BACKGROUND
local IW = Instance.new("Frame", Main)
IW.Size                  = UDim2.new(1, 0, 1, 0)
IW.BackgroundTransparency= 1
IW.BorderSizePixel       = 0
IW.ZIndex                = 2

local WAVE_DEF = {
    {yB = 0.00, alpha = 0.89, h = 0.600, sp = 0.26, amp = 0.055, xSp = 0.18},
    {yB = 0.22, alpha = 0.87, h = 0.615, sp = 0.20, amp = 0.065, xSp = 0.14},
    {yB = 0.46, alpha = 0.85, h = 0.605, sp = 0.30, amp = 0.048, xSp = 0.22},
    {yB = 0.68, alpha = 0.90, h = 0.590, sp = 0.17, amp = 0.072, xSp = 0.12},
}
local iWaves = {}
for i, wd in ipairs(WAVE_DEF) do
    local wf = Instance.new("Frame", IW)
    wf.Size                  = UDim2.new(1.5, 0, 0.40, 0)
    wf.BackgroundColor3      = Color3.fromHSV(wd.h, 0.78, 0.44)
    wf.BackgroundTransparency= wd.alpha
    wf.BorderSizePixel       = 0
    wf.ZIndex                = 2
    local g = Instance.new("UIGradient", wf)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(4, 25, 90)),
        ColorSequenceKeypoint.new(0.40, Color3.fromHSV(wd.h, 0.82, 0.58)),
        ColorSequenceKeypoint.new(0.60, Color3.fromHSV(wd.h, 0.72, 0.50)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(4, 25, 90)),
    })
    g.Rotation = 90
    table.insert(iWaves, {f = wf, ph = i * math.pi / 2, wd = wd})
end
task.spawn(function()
    local t = 0
    while IW.Parent do
        t = t + 0.033
        for _, w in ipairs(iWaves) do
            local wd = w.wd
            local y  = wd.yB + math.sin(t * wd.sp  + w.ph) * wd.amp
            local x  = -0.25 + math.cos(t * wd.xSp + w.ph) * 0.09
            w.f.Position = UDim2.new(x, 0, y, 0)
        end
        task.wait(0.033)
    end
end)

-- [10] BORDER WATER DROPLETS
local WL = Instance.new("Frame", Main)
WL.Size                  = UDim2.new(1, 0, 1, 0)
WL.BackgroundTransparency= 1
WL.BorderSizePixel       = 0
WL.ZIndex                = 3

local DHUES = {200, 205, 210, 215, 220, 225}
local function spawnDroplet(side)
    local d   = Instance.new("Frame", WL)
    d.BorderSizePixel = 0
    d.ZIndex  = 4
    local dw  = math.random(4, 9)
    local dh  = math.random(10, 22)
    local spd = math.random(14, 36) / 10
    local col = Color3.fromHSV(DHUES[math.random(#DHUES)] / 360, math.random(58, 92) / 100, math.random(70, 100) / 100)
    local alp = math.random(28, 58) / 100
    d.BackgroundColor3       = col
    d.BackgroundTransparency = alp
    corner(d, UDim.new(0, 3))
    local g = Instance.new("UIGradient", d)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(205, 242, 255)),
        ColorSequenceKeypoint.new(0.42, col),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(6, 42, 140)),
    })
    local sp, ep
    if side == "L" then
        g.Rotation = 90; d.Size = UDim2.new(0, dw, 0, dh)
        sp = UDim2.new(0, 0, 0, math.random(-dh, 10)); ep = UDim2.new(0, 0, 1, dh + 6)
    elseif side == "R" then
        g.Rotation = 90; d.Size = UDim2.new(0, dw, 0, dh)
        sp = UDim2.new(1, -dw, 0, math.random(-dh, 10)); ep = UDim2.new(1, -dw, 1, dh + 6)
    elseif side == "T" then
        g.Rotation = 0; d.Size = UDim2.new(0, dh, 0, dw); spd = spd * 0.4
        local sx = math.random(0, PW - dh)
        sp = UDim2.new(0, sx, 0, 0); ep = UDim2.new(0, sx + math.random(8, 30), 0, dw + 1)
    elseif side == "B" then
        g.Rotation = 0; d.Size = UDim2.new(0, dh, 0, dw); spd = spd * 0.4
        local sx = math.random(0, PW - dh)
        sp = UDim2.new(0, sx, 1, -dw); ep = UDim2.new(0, sx + math.random(8, 30), 1, -1)
    end
    d.Position = sp
    local tw = TweenService:Create(d, TweenInfo.new(spd, Enum.EasingStyle.Linear),
        {Position = ep, BackgroundTransparency = math.min(alp + 0.38, 0.96)})
    tw:Play()
    tw.Completed:Connect(function() d:Destroy() end)
end
local SIDES = {"L", "R", "T", "B"}
task.spawn(function()
    while Root.Parent do
        if Main.Visible then
            for _ = 1, math.random(2, 4) do spawnDroplet(SIDES[math.random(4)]) end
        end
        task.wait(0.06 + math.random() * 0.07)
    end
end)

-- [11] HEADER
local HH = math.clamp(math.floor(PH * 0.10), 42, 54)
local Header = Instance.new("Frame", Main)
Header.Size                  = UDim2.new(1, 0, 0, HH)
Header.BackgroundColor3      = Color3.fromRGB(6, 22, 70)
Header.BackgroundTransparency= 0.10
Header.BorderSizePixel       = 0
Header.ZIndex                = 60
corner(Header, UDim.new(0, 14))
do
    local g = Instance.new("UIGradient", Header)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 42, 108)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 16, 56)),
    })
end

local Logo = Instance.new("Frame", Header)
Logo.Size                  = UDim2.new(0, HH - 14, 0, HH - 14)
Logo.Position              = UDim2.new(0, 10, 0.5, -(HH - 14) / 2)
Logo.BackgroundColor3      = Color3.fromRGB(22, 90, 195)
Logo.BackgroundTransparency= 0.28
Logo.BorderSizePixel       = 0
Logo.ZIndex                = 61
corner(Logo, UDim.new(0, 8))
lbl(Logo, {Size = UDim2.new(1, 0, 1, 0), Text = "CL", TextColor3 = Color3.fromRGB(135, 215, 255),
    TextSize = FONT_MD, Font = Enum.Font.GothamBold, ZIndex = 62})

lbl(Header, {Size = UDim2.new(0, 120, 0, HH * 0.50), Position = UDim2.new(0, HH + 4, 0, 4),
    Text = "CLogger", TextColor3 = Color3.fromRGB(115, 202, 255), TextSize = FONT_LG,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61})
lbl(Header, {Size = UDim2.new(0, 200, 0, HH * 0.38), Position = UDim2.new(0, HH + 4, 0, HH * 0.52),
    Text = "created by: SofiAkira", TextColor3 = Color3.fromRGB(55, 135, 210),
    TextSize = FONT_SM, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61})

local CloseBtn = mkbtn(Header, {
    Size            = UDim2.new(0, 28, 0, 28),
    Position        = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3= Color3.fromRGB(172, 36, 36),
    BackgroundTransparency = 0.12,
    Text            = "X",
    TextColor3      = Color3.fromRGB(255, 255, 255),
    TextSize        = FONT_SM,
    Font            = Enum.Font.GothamBold,
    ZIndex          = 62,
})
corner(CloseBtn, UDim.new(0, 6))

-- [12] TAB BAR
local TABH = 34
local TabBar = Instance.new("Frame", Main)
TabBar.Size                  = UDim2.new(1, -16, 0, TABH)
TabBar.Position              = UDim2.new(0, 8, 0, HH + 2)
TabBar.BackgroundTransparency= 1
TabBar.BorderSizePixel       = 0
TabBar.ZIndex                = 60
ll(TabBar, Enum.FillDirection.Horizontal, 4)

local Div = Instance.new("Frame", Main)
Div.Size                  = UDim2.new(1, -16, 0, 1)
Div.Position              = UDim2.new(0, 8, 0, HH + TABH + 4)
Div.BackgroundColor3      = Color3.fromRGB(28, 86, 195)
Div.BackgroundTransparency= 0.44
Div.BorderSizePixel       = 0
Div.ZIndex                = 60

local CTOP = HH + TABH + 8
local ContentArea = Instance.new("Frame", Main)
ContentArea.Size                  = UDim2.new(1, -14, 1, -CTOP - 4)
ContentArea.Position              = UDim2.new(0, 7, 0, CTOP)
ContentArea.BackgroundTransparency= 1
ContentArea.BorderSizePixel       = 0
ContentArea.ZIndex                = 10
ContentArea.ClipsDescendants      = true

-- [13] TAB SYSTEM
local tabPanels, tabBtns = {}, {}
local activeTab = nil
local C_OFF  = Color3.fromRGB(10, 38, 94);  local C_ON  = Color3.fromRGB(22, 100, 215)
local CT_OFF = Color3.fromRGB(90, 155, 230); local CT_ON = Color3.fromRGB(222, 242, 255)

local function switchTab(name)
    for k, p in pairs(tabPanels) do
        p.Visible = false
        local b = tabBtns[k]
        if b then
            b.BackgroundColor3      = C_OFF
            b.BackgroundTransparency= 0.36
            b.TextColor3            = CT_OFF
        end
    end
    if tabPanels[name] then
        tabPanels[name].Visible = true
        local b = tabBtns[name]
        if b then
            b.BackgroundColor3      = C_ON
            b.BackgroundTransparency= 0
            b.TextColor3            = CT_ON
        end
        activeTab = name
    end
end

local function makeTab(name, icon, order)
    local b = mkbtn(TabBar, {
        Size                  = UDim2.new(0, TAB_W, 0, TABH - 4),
        BackgroundColor3      = C_OFF,
        BackgroundTransparency= 0.36,
        Text                  = icon .. " " .. name,
        TextColor3            = CT_OFF,
        TextSize              = FONT_SM,
        Font                  = Enum.Font.GothamSemibold,
        LayoutOrder           = order,
        ZIndex                = 61,
        TextScaled            = false,
        TextTruncate          = Enum.TextTruncate.AtEnd,
    })
    corner(b, UDim.new(0, 7))

    local panel = Instance.new("ScrollingFrame", ContentArea)
    panel.Size                  = UDim2.new(1, 0, 1, 0)
    panel.BackgroundTransparency= 1
    panel.BorderSizePixel       = 0
    panel.ScrollBarThickness    = 3
    panel.ScrollBarImageColor3  = Color3.fromRGB(46, 132, 215)
    panel.CanvasSize            = UDim2.new(0, 0, 0, 0)
    panel.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    panel.Visible               = false
    panel.ZIndex                = 11
    ipad(panel, 6)
    ll(panel, Enum.FillDirection.Vertical, 5)

    tabPanels[name] = panel
    tabBtns[name]   = b
    b.MouseButton1Click:Connect(function() switchTab(name) end)
    return panel
end

-- [14] CONSOLE TAB
local consolePanel = makeTab("Console", "[]", 1)
local logSeq = 0

local function aiAnalyze(raw)
    local m   = raw:lower()
    local out = {"AI Analysis", ""}
    local function add(s) table.insert(out, s) end
    local function sep() table.insert(out, "") end

    if m:match("attempt to index a? ?nil") then
        local v = raw:match("%((.-)%)") or "a variable"
        add("  TYPE    Nil Index Error")
        add("  CAUSE   '" .. v .. "' is nil -- path wrong or object missing.")
        sep(); add("  FIX 1   Use WaitForChild with timeout:")
        add('             local x = parent:WaitForChild("Name", 5)')
        sep(); add("  FIX 2   Guard before indexing:")
        add("             if obj then obj.Property = val end")
    elseif m:match("attempt to call a? ?nil") then
        local v = raw:match("%((.-)%)") or "function"
        add("  TYPE    Nil Function Call")
        add("  CAUSE   '" .. v .. "' is nil -- not a function here.")
        sep(); add("  FIX     Check spelling and require(). Wrap in pcall.")
    elseif m:match("stack overflow") then
        add("  TYPE    Stack Overflow (infinite recursion)")
        sep(); add("  FIX     Add exit condition: if depth >= MAX then return end")
    elseif m:match("infinite yield possible") then
        local nm = raw:match('WaitForChild%("(.-)"%)')
            or raw:match("WaitForChild%('(.-)'%)") or "child"
        add("  TYPE    WaitForChild Timeout")
        add("  CAUSE   '" .. nm .. "' may not exist or is misspelled.")
        sep(); add('  FIX     Add timeout: :WaitForChild("' .. nm .. '", 10)')
    elseif m:match("bad argument") or m:match("invalid argument") then
        local n = raw:match("#(%d+)") or "?"
        add("  TYPE    Wrong Argument Type (arg #" .. n .. ")")
        sep(); add("  FIX     print(type(myVal)) to debug the value.")
    elseif m:match("is not a valid member") then
        local prop = raw:match("'(.-)' is not") or "?"
        local cls  = raw:match("of '(.-)'") or "?"
        add("  TYPE    Invalid Member '" .. prop .. "' on '" .. cls .. "'")
        sep(); add("  FIX     Check spelling; confirm with print(obj.ClassName)")
    elseif m:match("attempt to perform arithmetic") then
        add("  TYPE    Arithmetic on Non-Number")
        sep(); add("  FIX     tonumber(str) or 0  /  someVal or 0")
    elseif m:match("attempt to compare") then
        add("  TYPE    Comparison Mismatch")
        sep(); add("  FIX     if val ~= nil and val > 0 then ... end")
    elseif m:match("exceeded memory") or m:match("out of memory") then
        add("  TYPE    Memory Limit Exceeded")
        sep(); add("  FIX 1   Disconnect unused events.")
        add("  FIX 2   Nil out large tables when done.")
    else
        add("  No pattern matched. General steps:")
        sep(); add("  1. Check line numbers in the error above.")
        add("  2. print() before the suspect line.")
        add("  3. Wrap block in pcall() to isolate.")
        add("  4. Search the error on the Roblox DevForum.")
    end
    return table.concat(out, "\n")
end

local CMETA = {
    [Enum.MessageType.MessageOutput]  = {tag="LOG",  tc=Color3.fromRGB(50,132,215),  textc=Color3.fromRGB(148,212,255), sc=Color3.fromRGB(36,118,210)},
    [Enum.MessageType.MessageWarning] = {tag="WARN", tc=Color3.fromRGB(205,162,0),   textc=Color3.fromRGB(255,208,58),  sc=Color3.fromRGB(220,172,0)},
    [Enum.MessageType.MessageError]   = {tag="ERR",  tc=Color3.fromRGB(195,38,38),   textc=Color3.fromRGB(255,102,102), sc=Color3.fromRGB(205,44,44)},
    [Enum.MessageType.MessageInfo]    = {tag="INFO", tc=Color3.fromRGB(28,165,212),  textc=Color3.fromRGB(128,222,255), sc=Color3.fromRGB(22,160,210)},
}

local function addLog(msg, msgType)
    if not msg or msg:match("^%s*$") then return end
    logSeq = logSeq + 1
    local meta  = CMETA[msgType] or CMETA[Enum.MessageType.MessageOutput]
    local isErr = msgType == Enum.MessageType.MessageError or msgType == Enum.MessageType.MessageWarning

    local e = Instance.new("Frame", consolePanel)
    e.Size                  = UDim2.new(1, 0, 0, 0)
    e.AutomaticSize         = Enum.AutomaticSize.Y
    e.BackgroundColor3      = Color3.fromRGB(7, 20, 55)
    e.BackgroundTransparency= 0.22
    e.BorderSizePixel       = 0
    e.LayoutOrder           = logSeq
    e.ZIndex                = 12
    corner(e, UDim.new(0, 6))
    ipad(e, nil, 14, 7, 5, 6)
    ll(e, Enum.FillDirection.Vertical, 3)

    local stripe = Instance.new("Frame", e)
    stripe.Size             = UDim2.new(0, 3, 1, 0)
    stripe.BackgroundColor3 = meta.sc
    stripe.BorderSizePixel  = 0
    stripe.ZIndex           = 13
    corner(stripe, UDim.new(0, 2))

    local tr = Instance.new("Frame", e)
    tr.Size                  = UDim2.new(1, 0, 0, 16)
    tr.BackgroundTransparency= 1
    tr.LayoutOrder           = 1
    tr.ZIndex                = 13

    local bdg = lbl(tr, {
        Size                  = UDim2.new(0, 40, 1, 0),
        BackgroundColor3      = meta.tc,
        BackgroundTransparency= 0.48,
        Text                  = meta.tag,
        TextColor3            = Color3.fromRGB(235, 240, 255),
        TextSize              = FONT_SM - 1,
        Font                  = Enum.Font.GothamBold,
        ZIndex                = 14,
    })
    bdg.BackgroundTransparency = 0.48
    corner(bdg, UDim.new(0, 3))

    lbl(tr, {
        Size             = UDim2.new(1, -46, 1, 0),
        Position         = UDim2.new(0, 46, 0, 0),
        Text             = os.date("%H:%M:%S"),
        TextColor3       = Color3.fromRGB(68, 115, 182),
        TextSize         = FONT_SM - 1,
        Font             = Enum.Font.Code,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 14,
    })

    lbl(e, {
        Size            = UDim2.new(1, 0, 0, 0),
        AutomaticSize   = Enum.AutomaticSize.Y,
        Text            = msg,
        TextColor3      = meta.textc,
        TextSize        = FONT_SM,
        Font            = Enum.Font.Code,
        TextXAlignment  = Enum.TextXAlignment.Left,
        LayoutOrder     = 2,
        ZIndex          = 13,
    })

    if isErr then
        local ab = mkbtn(e, {
            Size            = UDim2.new(0, 100, 0, 20),
            LayoutOrder     = 3,
            BackgroundColor3= Color3.fromRGB(24, 72, 162),
            Text            = "AI Assist",
            TextColor3      = Color3.fromRGB(145, 202, 255),
            TextSize        = FONT_SM - 1,
            Font            = Enum.Font.GothamSemibold,
            ZIndex          = 13,
        })
        corner(ab, UDim.new(0, 5))
        local aiBox = Instance.new("Frame", e)
        aiBox.Size                  = UDim2.new(1, 0, 0, 0)
        aiBox.AutomaticSize         = Enum.AutomaticSize.Y
        aiBox.BackgroundColor3      = Color3.fromRGB(8, 26, 70)
        aiBox.BackgroundTransparency= 0.06
        aiBox.BorderSizePixel       = 0
        aiBox.LayoutOrder           = 4
        aiBox.Visible               = false
        aiBox.ZIndex                = 13
        corner(aiBox, UDim.new(0, 6))
        ipad(aiBox, 7)
        local aitxt = lbl(aiBox, {
            Size           = UDim2.new(1, 0, 0, 0),
            AutomaticSize  = Enum.AutomaticSize.Y,
            TextColor3     = Color3.fromRGB(145, 208, 255),
            TextSize       = FONT_SM - 1,
            Font           = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex         = 14,
        })
        local aiOpen = false
        ab.MouseButton1Click:Connect(function()
            aiOpen = not aiOpen
            if aiOpen then
                aitxt.Text = aiAnalyze(msg)
                aiBox.Visible = true
                ab.Text = "Hide"
                ab.BackgroundColor3 = Color3.fromRGB(52, 26, 132)
            else
                aiBox.Visible = false
                ab.Text = "AI Assist"
                ab.BackgroundColor3 = Color3.fromRGB(24, 72, 162)
            end
        end)
    end
end

local consoleClear = mkbtn(consolePanel, {
    Size                  = UDim2.new(1, 0, 0, 26),
    LayoutOrder           = 0,
    BackgroundColor3      = Color3.fromRGB(18, 50, 108),
    BackgroundTransparency= 0.28,
    Text                  = "Clear Console",
    TextColor3            = Color3.fromRGB(125, 192, 255),
    TextSize              = FONT_SM,
    Font                  = Enum.Font.GothamSemibold,
    ZIndex                = 12,
})
corner(consoleClear, UDim.new(0, 6))
consoleClear.MouseButton1Click:Connect(function()
    for _, c in ipairs(consolePanel:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    logSeq = 0
end)

LogService.MessageOut:Connect(addLog)

task.spawn(function()
    pcall(function()
        local hist = LogService:GetLogHistory()
        if #hist == 0 then return end
        addLog(("-- %d log(s) before CLogger loaded --"):format(#hist), Enum.MessageType.MessageInfo)
        for _, entry in ipairs(hist) do addLog(entry.message, entry.messageType) end
    end)
end)

if isExec then
    pcall(function()
        local _P = getgenv().print
        local _W = getgenv().warn
        getgenv().print = function(...)
            local t = {}
            for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end
            addLog(table.concat(t, "    "), Enum.MessageType.MessageOutput)
            if _P then return _P(...) end
        end
        getgenv().warn = function(...)
            local t = {}
            for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end
            addLog(table.concat(t, "    "), Enum.MessageType.MessageWarning)
            if _W then return _W(...) end
        end
    end)
end

-- [15] SCRIPT LOGGER TAB
local scriptPanel  = makeTab("Scripts", "S", 2)
local sSeq         = 0
local knownScripts = {}

local PURP = {
    anim="Animation", walk="Movement",  move="Movement",
    gui="UI/HUD",     hud="HUD",        ui="Interface",
    chat="Chat",      camera="Camera",  cam="Camera",
    data="Data/Save", save="Save",      shop="Shop",
    store="Commerce", spawn="Spawning", admin="Admin",
    sound="Audio",    music="Music",    light="Lighting",
    tool="Tool/Gear", weapon="Weapon",  npc="NPC AI",
    enemy="Enemy",    mob="Mob AI",     round="Rounds",
    anti="Anti-cheat",remote="Remotes", loader="Loader",
    kill="Kill/Dmg",  leader="Leaderboard",door="Door",
    pet="Pets",       cash="Economy",   coin="Currency",
    tween="Tween",    touch="Touch",    module="Module",
}

local function guessPurpose(s)
    local n = s.Name:lower()
    for k, v in pairs(PURP) do if n:find(k) then return v end end
    if s.ClassName == "LocalScript"  then return "LocalScript (client)" end
    if s.ClassName == "ModuleScript" then return "ModuleScript" end
    return "Script (server)"
end

local function tryGetSource(s)
    local src = ""
    pcall(function() local r = s.Source; if r and r ~= "" then src = r end end)
    if src ~= "" then return src, "OK .Source" end
    if isExec then
        pcall(function()
            if type(getscriptsource) == "function" then
                local r = getscriptsource(s); if r and r ~= "" then src = r end
            end
        end)
        if src ~= "" then return src, "OK getscriptsource()" end
        pcall(function()
            if type(decompile) == "function" then
                local r = decompile(s); if r and r ~= "" then src = r end
            end
        end)
        if src ~= "" then return src, "WARN decompile() (reconstructed)" end
    end
    local lines = {}
    local function w(l) table.insert(lines, l) end
    w("--[[ Source protected by Roblox at runtime.")
    if isExec then
        w("  getscriptsource() and decompile() returned empty.")
        w("  Possible: server Script, obfuscated bytecode, or executor limitation.")
    else
        w("  Run CLogger via an executor to unlock source reading.")
    end
    w(""); w("  Name:     " .. s.Name); w("  Class:    " .. s.ClassName)
    w("  Path:     " .. s:GetFullName())
    local dis = "?"; pcall(function() dis = tostring(s.Disabled) end)
    w("  Disabled: " .. dis)
    w(""); w("  Parent Chain:")
    local chain, cur = {}, s.Parent
    for _ = 1, 14 do
        if not cur or cur == game then break end
        table.insert(chain, 1, "    " .. cur.ClassName .. ' "' .. cur.Name .. '"')
        cur = cur.Parent
    end
    for _, line in ipairs(chain) do w(line) end
    w('    -- ' .. s.ClassName .. ' "' .. s.Name .. '"')
    w(""); w("  Children:")
    local kids = s:GetChildren()
    if #kids == 0 then
        w("  (none)")
    else
        for _, c in ipairs(kids) do w("  - " .. c.ClassName .. ' "' .. c.Name .. '"') end
    end
    w("]]")
    return table.concat(lines, "\n"), "BLOCKED Metadata only"
end

local function openSourcePopup(s)
    local src, method = tryGetSource(s)
    local isMeta = src:sub(1, 4) == "--[["

    if isExec and not isMeta and #src > 3800 then
        local fname = s.Name:gsub("[^%w_%-]", "_") .. "_CLogger.lua"
        local ok2   = pcall(writefile, fname, src)
        local ng    = Instance.new("ScreenGui"); ng.DisplayOrder = 1100; ng.ResetOnSpawn = false
        pcall(function() ng.Parent = game:GetService("CoreGui") end)
        if not ng.Parent then ng.Parent = LP.PlayerGui end
        local nf = Instance.new("Frame", ng)
        nf.Size             = UDim2.new(0, math.min(PW - 10, 360), 0, 50)
        nf.Position         = UDim2.new(0.5, -170, 0, 22)
        nf.BackgroundColor3 = ok2 and Color3.fromRGB(12, 65, 25) or Color3.fromRGB(80, 20, 20)
        nf.BorderSizePixel  = 0
        corner(nf, UDim.new(0, 9))
        lbl(nf, {
            Size           = UDim2.new(1, -10, 1, 0),
            Position       = UDim2.new(0, 5, 0, 0),
            Text           = ok2 and ("Saved: " .. fname) or "writefile() failed",
            TextColor3     = ok2 and Color3.fromRGB(138, 255, 168) or Color3.fromRGB(255, 130, 130),
            TextSize       = FONT_SM,
            Font           = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        task.delay(4, function() pcall(function() ng:Destroy() end) end)
        return
    end

    local vp2 = workspace.CurrentCamera.ViewportSize
    local vfW = math.min(vp2.X - 12, 520)
    local vfH = math.min(vp2.Y - 36, 450)

    local vg = Instance.new("ScreenGui"); vg.Name = "CLogger_SrcView"
    vg.DisplayOrder = 1000; vg.ResetOnSpawn = false
    pcall(function() vg.Parent = game:GetService("CoreGui") end)
    if not vg.Parent then vg.Parent = LP.PlayerGui end

    local vf = Instance.new("Frame", vg)
    vf.Size             = UDim2.new(0, vfW, 0, vfH)
    vf.Position         = UDim2.new(0.5, -vfW / 2, 0.5, -vfH / 2)
    vf.BackgroundColor3 = Color3.fromRGB(5, 14, 42)
    vf.BorderSizePixel  = 0
    corner(vf, UDim.new(0, 11))
    uistroke(vf, Color3.fromRGB(28, 102, 205), 1.5)

    local VHDRH = 54
    local vh = Instance.new("Frame", vf)
    vh.Size             = UDim2.new(1, 0, 0, VHDRH)
    vh.BackgroundColor3 = Color3.fromRGB(10, 38, 98)
    vh.BorderSizePixel  = 0
    corner(vh, UDim.new(0, 11))

    lbl(vh, {
        Size           = UDim2.new(1, -42, 0, 22),
        Position       = UDim2.new(0, 10, 0, 6),
        Text           = "FILE: " .. s:GetFullName(),
        TextColor3     = Color3.fromRGB(155, 212, 255),
        TextSize       = FONT_SM,
        Font           = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
    })

    local mCol = Color3.fromRGB(90, 225, 125)
    if method:match("^WARN")    then mCol = Color3.fromRGB(255, 205, 70) end
    if method:match("^BLOCKED") then mCol = Color3.fromRGB(255, 105, 105) end
    lbl(vh, {
        Size           = UDim2.new(1, -42, 0, 16),
        Position       = UDim2.new(0, 10, 0, 32),
        Text           = "Source: " .. method,
        TextColor3     = mCol,
        TextSize       = FONT_SM - 1,
        Font           = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local vcl = mkbtn(vh, {
        Size            = UDim2.new(0, 26, 0, 26),
        Position        = UDim2.new(1, -32, 0.5, -13),
        BackgroundColor3= Color3.fromRGB(158, 32, 32),
        Text            = "X",
        TextColor3      = Color3.fromRGB(255, 255, 255),
        TextSize        = FONT_SM,
        Font            = Enum.Font.GothamBold,
        ZIndex          = 5,
    })
    corner(vcl, UDim.new(0, 5))
    vcl.MouseButton1Click:Connect(function() vg:Destroy() end)

    local vsf = Instance.new("ScrollingFrame", vf)
    vsf.Size                 = UDim2.new(1, -10, 1, -(VHDRH + 6))
    vsf.Position             = UDim2.new(0, 5, 0, VHDRH + 4)
    vsf.BackgroundColor3     = Color3.fromRGB(3, 9, 26)
    vsf.BorderSizePixel      = 0
    vsf.ScrollBarThickness   = 4
    vsf.ScrollBarImageColor3 = Color3.fromRGB(42, 125, 210)
    vsf.CanvasSize           = UDim2.new(0, 0, 0, 0)
    vsf.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    corner(vsf, UDim.new(0, 7))
    ipad(vsf, 6)
    lbl(vsf, {
        Size           = UDim2.new(1, 0, 0, 0),
        AutomaticSize  = Enum.AutomaticSize.Y,
        Text           = src,
        TextColor3     = Color3.fromRGB(160, 212, 255),
        TextSize       = FONT_SM,
        Font           = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local vd = {on = false, ms = nil, sp = nil}
    vh.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            vd.on = true; vd.ms = i.Position; vd.sp = vf.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if vd.on and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - vd.ms
            vf.Position = UDim2.new(vd.sp.X.Scale, vd.sp.X.Offset + delta.X, vd.sp.Y.Scale, vd.sp.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            vd.on = false
        end
    end)
end

local SCC = {
    Script      = Color3.fromRGB(255, 158, 45),
    LocalScript = Color3.fromRGB(50, 205, 98),
    ModuleScript= Color3.fromRGB(162, 95, 255),
}
local function addScriptEntry(s)
    if knownScripts[s] then return end
    knownScripts[s] = true
    sSeq = sSeq + 1
    local tc = SCC[s.ClassName] or Color3.fromRGB(175, 175, 195)
    local ef = Instance.new("Frame", scriptPanel)
    ef.Size                  = UDim2.new(1, 0, 0, 56)
    ef.BackgroundColor3      = Color3.fromRGB(8, 24, 65)
    ef.BackgroundTransparency= 0.14
    ef.BorderSizePixel       = 0
    ef.LayoutOrder           = sSeq + 10
    ef.ZIndex                = 12
    corner(ef, UDim.new(0, 7))
    ipad(ef, nil, 9, 8, 6, 6)
    local bdg = lbl(ef, {
        Size                  = UDim2.new(0, 90, 0, 15),
        BackgroundColor3      = tc,
        BackgroundTransparency= 0.50,
        Text                  = s.ClassName,
        TextColor3            = Color3.fromRGB(235, 242, 255),
        TextSize              = FONT_SM - 1,
        Font                  = Enum.Font.GothamBold,
        ZIndex                = 13,
    })
    bdg.BackgroundTransparency = 0.50
    corner(bdg, UDim.new(0, 4))
    lbl(ef, {
        Size           = UDim2.new(1, -76, 0, 18),
        Position       = UDim2.new(0, 0, 0, 18),
        Text           = s.Name,
        TextColor3     = Color3.fromRGB(195, 228, 255),
        TextSize       = FONT_SM,
        Font           = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        ZIndex         = 13,
    })
    lbl(ef, {
        Size           = UDim2.new(1, -76, 0, 13),
        Position       = UDim2.new(0, 0, 1, -14),
        Text           = "-> " .. guessPurpose(s),
        TextColor3     = Color3.fromRGB(80, 142, 208),
        TextSize       = FONT_SM - 1,
        Font           = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        ZIndex         = 13,
    })
    local ob = mkbtn(ef, {
        Size            = UDim2.new(0, 62, 0, 22),
        Position        = UDim2.new(1, -62, 0.5, -11),
        BackgroundColor3= Color3.fromRGB(24, 86, 172),
        Text            = "Open",
        TextColor3      = Color3.fromRGB(182, 222, 255),
        TextSize        = FONT_SM - 1,
        Font            = Enum.Font.GothamSemibold,
        ZIndex          = 13,
    })
    corner(ob, UDim.new(0, 5))
    ob.MouseButton1Click:Connect(function() openSourcePopup(s) end)
end

local scanInfo = lbl(scriptPanel, {
    Size           = UDim2.new(1, 0, 0, 14),
    LayoutOrder    = 1,
    Text           = "Press Scan -- auto-detects new scripts every 2s.",
    TextColor3     = Color3.fromRGB(86, 150, 208),
    TextSize       = FONT_SM - 1,
    Font           = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex         = 12,
})

local scanBtn = mkbtn(scriptPanel, {
    Size            = UDim2.new(1, 0, 0, 28),
    LayoutOrder     = 0,
    BackgroundColor3= Color3.fromRGB(14, 86, 44),
    Text            = "Scan for Scripts",
    TextColor3      = Color3.fromRGB(122, 255, 165),
    TextSize        = FONT_SM,
    Font            = Enum.Font.GothamBold,
    ZIndex          = 12,
})
corner(scanBtn, UDim.new(0, 7))

local function doScan()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            addScriptEntry(obj)
        end
    end
    if isExec then
        pcall(function()
            for _, s in ipairs(getscripts()) do addScriptEntry(s) end
        end)
    end
end

scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text            = "Scanning..."
    scanBtn.BackgroundColor3= Color3.fromRGB(35, 65, 16)
    for _, c in ipairs(scriptPanel:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    sSeq = 0; knownScripts = {}
    task.spawn(function()
        doScan()
        local count = 0
        for _ in pairs(knownScripts) do count = count + 1 end
        scanInfo.Text           = string.format("Found %d script(s). Auto-detecting...", count)
        scanBtn.Text            = string.format("Rescan (%d)", count)
        scanBtn.BackgroundColor3= Color3.fromRGB(14, 86, 44)
    end)
end)

task.spawn(function()
    while Root.Parent do
        if activeTab == "Scripts" then
            pcall(function()
                if isExec then
                    for _, s in ipairs(getscripts()) do addScriptEntry(s) end
                end
            end)
        end
        task.wait(2)
    end
end)

-- [16] PLAYER LOGGER TAB
local playerPanel = makeTab("Players", "P", 3)
local pData, pCards, pESP, pSeq = {}, {}, {}, 0
local espEnabled = true

local espToggleBtn = mkbtn(playerPanel, {
    Size            = UDim2.new(1, 0, 0, 28),
    LayoutOrder     = 0,
    BackgroundColor3= Color3.fromRGB(22, 88, 170),
    Text            = "ESP: ON",
    TextColor3      = Color3.fromRGB(180, 225, 255),
    TextSize        = FONT_SM,
    Font            = Enum.Font.GothamSemibold,
    ZIndex          = 12,
})
corner(espToggleBtn, UDim.new(0, 7))
espToggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        espToggleBtn.Text            = "ESP: ON"
        espToggleBtn.BackgroundColor3= Color3.fromRGB(22, 88, 170)
    else
        espToggleBtn.Text            = "ESP: OFF"
        espToggleBtn.BackgroundColor3= Color3.fromRGB(72, 22, 22)
        for player in pairs(pESP) do
            if pESP[player] then
                pESP[player].conn:Disconnect()
                pcall(function() pESP[player].folder:Destroy() end)
                pESP[player] = nil
            end
        end
        for _, card in pairs(pCards) do
            card.espDot.BackgroundColor3 = Color3.fromRGB(44, 44, 66)
        end
    end
end)

local function dCol(d)
    if d < 24  then return Color3.fromRGB(255, 65, 65)  end
    if d <= 88 then return Color3.fromRGB(68, 218, 105) end
    return Color3.fromRGB(60, 148, 255)
end

local function buildESP(player)
    if not espEnabled or pESP[player] then return end
    local char = player.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local folder = Instance.new("Folder")
    folder.Name   = "CLESP_" .. player.UserId
    folder.Parent = workspace
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            local sb = Instance.new("SelectionBox", folder)
            sb.Adornee            = p
            sb.Color3             = Color3.fromRGB(255, 52, 52)
            sb.LineThickness      = 0.055
            sb.SurfaceTransparency= 0.72
            sb.SurfaceColor3      = Color3.fromRGB(255, 68, 68)
        end
    end
    local bb = Instance.new("BillboardGui", folder)
    bb.Adornee      = hrp
    bb.Size         = UDim2.new(0, 150, 0, 72)
    bb.StudsOffset  = Vector3.new(0, 4.5, 0)
    bb.AlwaysOnTop  = true
    local bg = Instance.new("Frame", bb)
    bg.Size                  = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency= 0.40
    bg.BorderSizePixel       = 0
    corner(bg, UDim.new(0, 7))
    local infoL = lbl(bg, {
        Size           = UDim2.new(1, -8, 1, -6),
        Position       = UDim2.new(0, 4, 0, 3),
        TextColor3     = Color3.fromRGB(255, 192, 192),
        TextSize       = 12,
        Font           = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local conn = RunService.Heartbeat:Connect(function()
        if not pESP[player] or not char.Parent then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
        local tool = "None"
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") then tool = obj.Name; break end
        end
        infoL.Text = string.format("Player: %s\nHP: %d/%d\nTool: %s",
            player.DisplayName, math.floor(hum.Health), math.max(math.floor(hum.MaxHealth), 1), tool)
    end)
    pESP[player] = {folder = folder, conn = conn}
end

local function clearESP(player)
    if pESP[player] then
        pESP[player].conn:Disconnect()
        pcall(function() pESP[player].folder:Destroy() end)
        pESP[player] = nil
    end
end

local function makeCard(player)
    if pCards[player] then return end
    pSeq = pSeq + 1
    local card = Instance.new("Frame", playerPanel)
    card.Size                  = UDim2.new(1, 0, 0, 88)
    card.BackgroundColor3      = Color3.fromRGB(8, 22, 64)
    card.BackgroundTransparency= 0.13
    card.BorderSizePixel       = 0
    card.LayoutOrder           = pSeq
    card.ZIndex                = 12
    corner(card, UDim.new(0, 9))
    ipad(card, 9)
    lbl(card, {
        Size           = UDim2.new(0.6, 0, 0, 20),
        Text           = "[P] " .. player.DisplayName,
        TextColor3     = Color3.fromRGB(192, 232, 255),
        TextSize       = FONT_SM,
        Font           = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })
    lbl(card, {
        Size           = UDim2.new(0.6, 0, 0, 14),
        Position       = UDim2.new(0, 0, 0, 21),
        Text           = "@" .. player.Name,
        TextColor3     = Color3.fromRGB(78, 132, 196),
        TextSize       = FONT_SM - 2,
        Font           = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })
    local statusL = lbl(card, {
        Size           = UDim2.new(1, 0, 0, 16),
        Position       = UDim2.new(0, 0, 0, 37),
        Text           = "Normal",
        TextColor3     = Color3.fromRGB(68, 218, 108),
        TextSize       = FONT_SM - 1,
        Font           = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })
    local distL = lbl(card, {
        Size           = UDim2.new(0.6, 0, 0, 14),
        Position       = UDim2.new(0, 0, 0, 55),
        Text           = "Dist: --",
        TextColor3     = Color3.fromRGB(148, 195, 255),
        TextSize       = FONT_SM - 1,
        Font           = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 13,
    })
    local hpBg = Instance.new("Frame", card)
    hpBg.Size             = UDim2.new(1, 0, 0, 6)
    hpBg.Position         = UDim2.new(0, 0, 1, -8)
    hpBg.BackgroundColor3 = Color3.fromRGB(22, 25, 54)
    hpBg.BorderSizePixel  = 0
    hpBg.ZIndex           = 13
    corner(hpBg, UDim.new(1, 0))
    local hpBar = Instance.new("Frame", hpBg)
    hpBar.Size             = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(52, 210, 85)
    hpBar.BorderSizePixel  = 0
    hpBar.ZIndex           = 14
    corner(hpBar, UDim.new(1, 0))
    local espDot = Instance.new("Frame", card)
    espDot.Size             = UDim2.new(0, 9, 0, 9)
    espDot.Position         = UDim2.new(1, -9, 0, 0)
    espDot.BackgroundColor3 = Color3.fromRGB(48, 48, 68)
    espDot.BorderSizePixel  = 0
    espDot.ZIndex           = 13
    corner(espDot, UDim.new(1, 0))
    pCards[player] = {card = card, statusL = statusL, distL = distL, hpBar = hpBar, espDot = espDot}
end

local function removeCard(player)
    if pCards[player] then
        pcall(function() pCards[player].card:Destroy() end)
        pCards[player] = nil
    end
    pData[player] = nil
    clearESP(player)
end

local function initData(player)
    pData[player] = {afkTimer = 0, lastPos = nil, posHistory = {}}
end

local function onGround(hrp)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {hrp.Parent}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    return workspace:Raycast(hrp.Position, Vector3.new(0, -4.4, 0), rp) ~= nil
end

local function isNoclipping(char, hrp)
    local op = OverlapParams.new()
    op.FilterDescendantsInstances = {char}
    op.FilterType = Enum.RaycastFilterType.Exclude
    for _, p in ipairs(workspace:GetPartsInPart(hrp, op)) do
        if p:IsA("BasePart") and p.CanCollide then return true end
    end
    return false
end

local hbAcc = 0
RunService.Heartbeat:Connect(function(dt)
    hbAcc = hbAcc + dt
    if hbAcc < 0.10 then return end
    hbAcc = 0
    if activeTab ~= "Players" then return end
    local myChar = LP.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            if not pCards[player] then makeCard(player) end
            if not pData[player]  then initData(player) end
            local data = pData[player]
            local card = pCards[player]
            if card then
                local char = player.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
                if not hrp then
                    card.statusL.Text      = "Not spawned"
                    card.statusL.TextColor3= Color3.fromRGB(148, 148, 160)
                    card.distL.Text        = "N/A"
                    clearESP(player)
                else
                    local pos = hrp.Position
                    local now = os.clock()
                    if hum then
                        local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        card.hpBar.Size             = UDim2.new(r, 0, 1, 0)
                        card.hpBar.BackgroundColor3 = Color3.new(
                            math.clamp((1 - r) * 2, 0, 1),
                            math.clamp(r * 1.4, 0, 1),
                            0.04
                        )
                    end
                    local dist = myHRP and math.floor((myHRP.Position - pos).Magnitude + 0.5) or -1
                    if dist >= 0 then
                        card.distL.Text      = ("Dist: %d studs"):format(dist)
                        card.distL.TextColor3= dCol(dist)
                        if espEnabled and dist < 24 then
                            buildESP(player)
                            card.espDot.BackgroundColor3 = Color3.fromRGB(255, 52, 52)
                        elseif not espEnabled or dist >= 24 then
                            clearESP(player)
                            card.espDot.BackgroundColor3 = espEnabled
                                and Color3.fromRGB(44, 44, 66)
                                or  Color3.fromRGB(80, 22, 22)
                        end
                    end
                    if data.lastPos then
                        data.afkTimer = (pos - data.lastPos).Magnitude < 0.5
                            and data.afkTimer + 0.10 or 0
                    end
                    data.lastPos = pos
                    table.insert(data.posHistory, {p = pos, t = now})
                    while #data.posHistory > 20 do table.remove(data.posHistory, 1) end
                    local flags   = {}
                    local flagCol = Color3.fromRGB(68, 218, 108)
                    if data.afkTimer >= 300 then
                        table.insert(flags, "AFK 5min+"); flagCol = Color3.fromRGB(168, 168, 182)
                    elseif data.afkTimer >= 120 then
                        table.insert(flags, "AFK 2min+"); flagCol = Color3.fromRGB(178, 178, 190)
                    end
                    if hum then
                        local state = hum:GetState()
                        if not onGround(hrp)
                            and state ~= Enum.HumanoidStateType.Freefall
                            and state ~= Enum.HumanoidStateType.Jumping
                            and state ~= Enum.HumanoidStateType.FallingDown
                            and state ~= Enum.HumanoidStateType.Swimming
                            and state ~= Enum.HumanoidStateType.Climbing
                            and hrp.AssemblyLinearVelocity.Magnitude > 1.8 then
                            table.insert(flags, "Flying"); flagCol = Color3.fromRGB(88, 195, 255)
                        end
                    end
                    if #data.posHistory >= 2 then
                        local oldest = data.posHistory[1]
                        if (now - oldest.t) <= 0.35 and (pos - oldest.p).Magnitude > 55 then
                            table.insert(flags, "Teleporting"); flagCol = Color3.fromRGB(255, 206, 42)
                        end
                    end
                    if char and hrp and isNoclipping(char, hrp) then
                        table.insert(flags, "Noclipping"); flagCol = Color3.fromRGB(232, 92, 232)
                    end
                    if #flags == 0 then
                        card.statusL.Text      = "Normal"
                        card.statusL.TextColor3= Color3.fromRGB(68, 218, 108)
                    else
                        card.statusL.Text      = table.concat(flags, " | ")
                        card.statusL.TextColor3= flagCol
                    end
                end
            end
        end
    end
    for player in pairs(pCards) do
        if not player.Parent then removeCard(player) end
    end
end)

Players.PlayerAdded:Connect(function(p) task.wait(0.3); makeCard(p); initData(p) end)
Players.PlayerRemoving:Connect(removeCard)
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then makeCard(p); initData(p) end end

-- [17] rSPY TAB
local rspyPanel  = makeTab("rSpy", "R", 4)
local rspySeq    = 0
local rspyActive = true
local rspyConns  = {}

local rspyCtrlRow = Instance.new("Frame", rspyPanel)
rspyCtrlRow.Size                  = UDim2.new(1, 0, 0, 28)
rspyCtrlRow.BackgroundTransparency= 1
rspyCtrlRow.BorderSizePixel       = 0
rspyCtrlRow.LayoutOrder           = 0
rspyCtrlRow.ZIndex                = 12
ll(rspyCtrlRow, Enum.FillDirection.Horizontal, 5)

local rspyToggleBtn = mkbtn(rspyCtrlRow, {
    Size            = UDim2.new(0.55, 0, 1, 0),
    BackgroundColor3= Color3.fromRGB(18, 100, 42),
    Text            = "Monitoring: ON",
    TextColor3      = Color3.fromRGB(130, 255, 165),
    TextSize        = FONT_SM,
    Font            = Enum.Font.GothamSemibold,
    ZIndex          = 12,
})
corner(rspyToggleBtn, UDim.new(0, 7))

local rspyClearBtn = mkbtn(rspyCtrlRow, {
    Size            = UDim2.new(0.42, 0, 1, 0),
    BackgroundColor3= Color3.fromRGB(18, 50, 108),
    Text            = "Clear",
    TextColor3      = Color3.fromRGB(125, 192, 255),
    TextSize        = FONT_SM,
    Font            = Enum.Font.GothamSemibold,
    ZIndex          = 12,
})
corner(rspyClearBtn, UDim.new(0, 7))

local rspyInfoL = lbl(rspyPanel, {
    Size           = UDim2.new(1, 0, 0, 13),
    LayoutOrder    = 1,
    Text           = isExec
        and "Hooking FireServer+InvokeServer (C->S) and OnClientEvent (S->C)."
        or  "OnClientEvent (S->C) only. Run via executor for C->S capture.",
    TextColor3     = Color3.fromRGB(80, 148, 210),
    TextSize       = FONT_SM - 2,
    Font           = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex         = 12,
})

local DIR_COL = {
    ["C->S FireServer"]   = Color3.fromRGB(255, 168, 45),
    ["C->S InvokeServer"] = Color3.fromRGB(255, 120, 70),
    ["S->C Event"]        = Color3.fromRGB(60, 200, 255),
    ["S->C Invoke"]       = Color3.fromRGB(100, 225, 255),
}

local function addRSpyEntry(remoteName, remotePath, direction, ...)
    if not rspyActive then return end
    rspySeq = rspySeq + 1
    local dc      = DIR_COL[direction] or Color3.fromRGB(180, 180, 200)
    local argText = argsStr(...)

    local e = Instance.new("Frame", rspyPanel)
    e.Size                  = UDim2.new(1, 0, 0, 0)
    e.AutomaticSize         = Enum.AutomaticSize.Y
    e.BackgroundColor3      = Color3.fromRGB(7, 20, 55)
    e.BackgroundTransparency= 0.22
    e.BorderSizePixel       = 0
    e.LayoutOrder           = rspySeq + 10
    e.ZIndex                = 12
    corner(e, UDim.new(0, 6))
    ipad(e, nil, 12, 7, 5, 6)
    ll(e, Enum.FillDirection.Vertical, 2)

    local stripe = Instance.new("Frame", e)
    stripe.Size             = UDim2.new(0, 3, 1, 0)
    stripe.BackgroundColor3 = dc
    stripe.BorderSizePixel  = 0
    stripe.ZIndex           = 13
    corner(stripe, UDim.new(0, 2))

    local r1 = Instance.new("Frame", e)
    r1.Size                  = UDim2.new(1, 0, 0, 17)
    r1.BackgroundTransparency= 1
    r1.LayoutOrder           = 1
    r1.ZIndex                = 13

    local dirBdg = lbl(r1, {
        Size                  = UDim2.new(0, 110, 1, 0),
        BackgroundColor3      = dc,
        BackgroundTransparency= 0.50,
        Text                  = direction,
        TextColor3            = Color3.fromRGB(238, 245, 255),
        TextSize              = FONT_SM - 1,
        Font                  = Enum.Font.GothamBold,
        ZIndex                = 14,
    })
    dirBdg.BackgroundTransparency = 0.50
    corner(dirBdg, UDim.new(0, 3))

    lbl(r1, {
        Size           = UDim2.new(0, 52, 1, 0),
        Position       = UDim2.new(0, 116, 0, 0),
        Text           = os.date("%H:%M:%S"),
        TextColor3     = Color3.fromRGB(68, 115, 182),
        TextSize       = FONT_SM - 1,
        Font           = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 14,
    })
    lbl(r1, {
        Size           = UDim2.new(1, -174, 1, 0),
        Position       = UDim2.new(0, 172, 0, 0),
        Text           = remoteName,
        TextColor3     = dc,
        TextSize       = FONT_SM,
        Font           = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        ZIndex         = 14,
    })

    lbl(e, {
        Size           = UDim2.new(1, 0, 0, 13),
        Text           = "  " .. remotePath,
        TextColor3     = Color3.fromRGB(90, 138, 200),
        TextSize       = FONT_SM - 2,
        Font           = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder    = 2,
        TextTruncate   = Enum.TextTruncate.AtEnd,
        ZIndex         = 13,
    })

    local r3 = Instance.new("Frame", e)
    r3.Size                  = UDim2.new(1, 0, 0, 0)
    r3.AutomaticSize         = Enum.AutomaticSize.Y
    r3.BackgroundTransparency= 1
    r3.LayoutOrder           = 3
    r3.ZIndex                = 13

    lbl(r3, {
        Size           = UDim2.new(1, -60, 0, 0),
        AutomaticSize  = Enum.AutomaticSize.Y,
        Text           = "  Args: " .. argText,
        TextColor3     = Color3.fromRGB(168, 215, 255),
        TextSize       = FONT_SM - 1,
        Font           = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped    = true,
        ZIndex         = 14,
    })

    local cpBtn = mkbtn(r3, {
        Size            = UDim2.new(0, 54, 0, 18),
        Position        = UDim2.new(1, -54, 0, 1),
        BackgroundColor3= Color3.fromRGB(30, 70, 140),
        Text            = "Copy",
        TextColor3      = Color3.fromRGB(170, 210, 255),
        TextSize        = FONT_SM - 2,
        Font            = Enum.Font.GothamSemibold,
        ZIndex          = 14,
    })
    corner(cpBtn, UDim.new(0, 4))
    cpBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(remotePath) end
        end)
        cpBtn.Text = "Copied!"
        task.delay(1.5, function() cpBtn.Text = "Copy" end)
    end)
end

local function hookRemote(remote)
    if rspyConns[remote] then return end
    if remote:IsA("RemoteEvent") then
        local conn = remote.OnClientEvent:Connect(function(...)
            addRSpyEntry(remote.Name, remote:GetFullName(), "S->C Event", ...)
        end)
        rspyConns[remote] = conn
    elseif remote:IsA("RemoteFunction") then
        pcall(function()
            local original = remote.OnClientInvoke
            remote.OnClientInvoke = function(...)
                addRSpyEntry(remote.Name, remote:GetFullName(), "S->C Invoke", ...)
                if original then return original(...) end
            end
            rspyConns[remote] = "wrapped"
        end)
    end
end

for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then hookRemote(obj) end
end
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        task.wait(0.05); hookRemote(obj)
    end
end)

if isExec then
    pcall(function()
        assert(type(getrawmetatable) == "function", "no getrawmetatable")
        assert(type(setreadonly)     == "function", "no setreadonly")
        assert(type(getnamecallmethod) == "function", "no getnamecallmethod")

        local mt    = getrawmetatable(game)
        local origNC= mt.__namecall
        setreadonly(mt, false)

        local hookBody = function(self, ...)
            local method = getnamecallmethod()
            if rspyActive then
                pcall(function()
                    if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                        if method == "FireServer" then
                            addRSpyEntry(self.Name, self:GetFullName(), "C->S FireServer", ...)
                        elseif method == "InvokeServer" then
                            addRSpyEntry(self.Name, self:GetFullName(), "C->S InvokeServer", ...)
                        end
                    end
                end)
            end
            return origNC(self, ...)
        end

        mt.__namecall = type(newcclosure) == "function" and newcclosure(hookBody) or hookBody
        setreadonly(mt, true)
        rspyInfoL.Text = "C->S hook active (FireServer+InvokeServer) + S->C (OnClientEvent)"
    end)
end

rspyToggleBtn.MouseButton1Click:Connect(function()
    rspyActive = not rspyActive
    if rspyActive then
        rspyToggleBtn.Text            = "Monitoring: ON"
        rspyToggleBtn.BackgroundColor3= Color3.fromRGB(18, 100, 42)
        rspyToggleBtn.TextColor3      = Color3.fromRGB(130, 255, 165)
    else
        rspyToggleBtn.Text            = "Monitoring: OFF"
        rspyToggleBtn.BackgroundColor3= Color3.fromRGB(85, 22, 22)
        rspyToggleBtn.TextColor3      = Color3.fromRGB(255, 140, 140)
    end
end)
rspyClearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(rspyPanel:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    rspySeq = 0
end)

-- [18] DRAG
local drag = {on = false, ms = nil, sp = nil}
Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag.on = true; drag.ms = i.Position; drag.sp = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag.on and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - drag.ms
        Main.Position = UDim2.new(drag.sp.X.Scale, drag.sp.X.Offset + delta.X, drag.sp.Y.Scale, drag.sp.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag.on = false
    end
end)

-- [19] OPEN / CLOSE
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false; Toggle.Visible = true end)
Toggle.MouseButton1Click:Connect(function() Main.Visible = true; Toggle.Visible = false end)

-- [20] STARTUP
switchTab("Console")
print("[CLogger v2.0] Loaded " .. PW .. "x" .. PH .. " -- created by SofiAkira")
