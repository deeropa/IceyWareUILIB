--[[
    RogueLib - IceyWare Style UI Library
    Base color from Studio: RGB(81, 81, 81)
]]

local Library = {}
Library.__index = Library
Library._flags = {}
Library._configFolder = "RogueHub/configs"

local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")

-- Colors derived from the Studio base: RGB(81,81,81)
local C = {
    mainBg      = Color3.fromRGB(81, 81, 81),       -- exact from Studio
    contentBg   = Color3.fromRGB(81, 81, 81),        -- same as main frame
    tabFace     = Color3.fromRGB(75, 75, 75),         -- tab default
    tabActive   = Color3.fromRGB(90, 90, 90),         -- tab selected (lighter)
    tabBorder   = Color3.fromRGB(55, 55, 55),         -- tab border
    border      = Color3.fromRGB(50, 50, 50),         -- main frame border
    checkOn     = Color3.fromRGB(45, 85, 140),        -- blue checkbox ON
    checkOff    = Color3.fromRGB(200, 200, 200),      -- light checkbox OFF
    checkBorder = Color3.fromRGB(40, 40, 40),         -- checkbox border
    text        = Color3.fromRGB(0, 0, 0),            -- black text (IceyWare uses dark text)
    textLight   = Color3.fromRGB(220, 220, 220),      -- tab text
    white       = Color3.fromRGB(255, 255, 255),
    sliderFill  = Color3.fromRGB(45, 85, 140),
    sliderBg    = Color3.fromRGB(60, 60, 60),
    btnFace     = Color3.fromRGB(75, 75, 75),
}

local FONT = Font.fromEnum(Enum.Font.SourceSansBold)
local FONT_R = Font.fromEnum(Enum.Font.SourceSans)
local TS = 18
local CS = 20
local RH = 28
local TH = 24
local CORNER = UDim.new(0, 4)

-- ===== Helpers =====
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = r or CORNER; c.Parent = p
end

local function makeDraggable(fr, hd)
    local d, ds, sp
    hd.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            d = true; ds = i.Position; sp = fr.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and i.UserInputType == Enum.UserInputType.MouseMovement then
            local dt = i.Position - ds
            fr.Position = UDim2.new(sp.X.Scale, sp.X.Offset + dt.X, sp.Y.Scale, sp.Y.Offset + dt.Y)
        end
    end)
end

-- ===== Config System =====
function Library:_ef()
    if not isfolder(self._configFolder) then makefolder(self._configFolder) end
end

function Library:SaveConfig(n)
    self:_ef()
    local d = {}
    for f, i in pairs(self._flags) do d[f] = i.value end
    writefile(self._configFolder .. "/" .. n .. ".json", HS:JSONEncode(d))
end

function Library:LoadConfig(n)
    self:_ef()
    local p = self._configFolder .. "/" .. n .. ".json"
    if not isfile(p) then return end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(p)) end)
    if not ok then return end
    for f, v in pairs(d) do if self._flags[f] then self._flags[f].set(v) end end
end

function Library:DeleteConfig(n)
    self:_ef()
    local p = self._configFolder .. "/" .. n .. ".json"
    if isfile(p) then delfile(p) end
end

function Library:ListConfigs()
    self:_ef()
    local r = {}
    for _, f in pairs(listfiles(self._configFolder)) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(r, n) end
    end
    return r
end

function Library:SetAutoload(n)
    self:_ef()
    writefile(self._configFolder .. "/autoload.txt", n)
end

function Library:LoadAutoload()
    self:_ef()
    local p = self._configFolder .. "/autoload.txt"
    if isfile(p) then
        local n = readfile(p)
        if n ~= "" then self:LoadConfig(n) end
    end
end

-- ===== Window (from Studio base) =====
function Library:CreateWindow(title, toggleKey)
    local self = setmetatable({}, Library)
    self._flags = {}
    self._tabs = {}
    self._visible = true

    -- ScreenGui -> CoreGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "RogueLib"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
    self._screenGui = sg

    -- Wrapper frame (holds tabs + main together for dragging/visibility)
    local wrapper = Instance.new("Frame")
    wrapper.Name = "Wrapper"
    wrapper.Size = UDim2.new(0, 458, 0, 326 + TH + 4)
    wrapper.Position = UDim2.new(0.5, -229, 0.5, -163 - TH - 4)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = sg
    self._wrapper = wrapper

    -- Tab bar — OUTSIDE main frame, just above it
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, TH)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.ClipsDescendants = false
    tabBar.Parent = wrapper

    local tLayout = Instance.new("UIListLayout")
    tLayout.FillDirection = Enum.FillDirection.Horizontal
    tLayout.Padding = UDim.new(0, 3)
    tLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tLayout.Parent = tabBar

    self._tabBar = tabBar

    -- MainFrame — EXACT from Studio export, below tabs with 2px gap
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.BackgroundColor3 = C.mainBg
    main.BorderSizePixel = 0
    main.Position = UDim2.new(0, 0, 0, TH + 4)
    main.Size = UDim2.new(1, 0, 0, 326)
    main.Parent = wrapper
    corner(main)
    self._main = main

    -- Outer stroke on main frame
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = C.border
    outerStroke.Thickness = 2
    outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outerStroke.Parent = main

    -- Content area — SAME color as main, fills the frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -10, 1, -10)
    content.Position = UDim2.new(0, 5, 0, 5)
    content.BackgroundColor3 = C.contentBg
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = main
    corner(content)
    self._contentArea = content

    -- Drag via tabs (moves the wrapper)
    makeDraggable(wrapper, tabBar)
    -- Also drag via the main frame body
    makeDraggable(wrapper, main)

    -- Toggle key
    toggleKey = toggleKey or "K"
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode[toggleKey] then
            self._visible = not self._visible
            wrapper.Visible = self._visible
        end
    end)

    return self
end

-- ===== Tab =====
local Tab = {}
Tab.__index = Tab

function Library:_switchTab(tab)
    for _, t in pairs(self._tabs) do
        t._content.Visible = false
        t._button.BackgroundColor3 = C.tabFace
    end
    tab._content.Visible = true
    tab._button.BackgroundColor3 = C.tabActive
end

function Library.AddTab(self, name)
    local tab = setmetatable({}, Tab)
    tab._library = self

    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 0, 0, TH)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = C.tabFace
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = self._tabBar
    corner(btn)

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = C.tabBorder
    bStroke.Thickness = 1
    bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bStroke.Parent = btn

    local bPad = Instance.new("UIPadding")
    bPad.PaddingLeft = UDim.new(0, 12)
    bPad.PaddingRight = UDim.new(0, 12)
    bPad.Parent = btn

    local bLabel = Instance.new("TextLabel")
    bLabel.Size = UDim2.new(0, 0, 1, 0)
    bLabel.AutomaticSize = Enum.AutomaticSize.X
    bLabel.BackgroundTransparency = 1
    bLabel.Text = name
    bLabel.TextColor3 = C.textLight
    bLabel.FontFace = FONT
    bLabel.TextSize = 14
    bLabel.Parent = btn

    tab._button = btn

    -- Scrolling content per tab
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.sliderFill
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.Parent = self._contentArea

    local sLayout = Instance.new("UIListLayout")
    sLayout.Padding = UDim.new(0, 2)
    sLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sLayout.Parent = scroll

    local sPad = Instance.new("UIPadding")
    sPad.PaddingTop = UDim.new(0, 4)
    sPad.PaddingLeft = UDim.new(0, 6)
    sPad.PaddingRight = UDim.new(0, 6)
    sPad.Parent = scroll

    tab._content = scroll

    btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_switchTab(tab) end
    return tab
end

-- ===== Toggle (checkbox left, text right) =====
function Tab:AddToggle(flag, label, default, callback)
    local lib = self._library
    local val = default or false
    callback = callback or function() end

    local row = Instance.new("TextButton")
    row.Name = "T_" .. flag
    row.Size = UDim2.new(1, 0, 0, RH)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = self._content

    -- Checkbox
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, CS, 0, CS)
    box.Position = UDim2.new(0, 0, 0.5, -CS / 2)
    box.BackgroundColor3 = val and C.checkOn or C.checkOff
    box.BorderSizePixel = 0
    box.Parent = row
    corner(box, UDim.new(0, 3))

    local bxStroke = Instance.new("UIStroke")
    bxStroke.Color = C.checkBorder
    bxStroke.Thickness = 2
    bxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bxStroke.Parent = box

    local mark = Instance.new("TextLabel")
    mark.Size = UDim2.new(1, 0, 1, 0)
    mark.BackgroundTransparency = 1
    mark.Text = val and "✓" or ""
    mark.TextColor3 = C.white
    mark.FontFace = FONT
    mark.TextSize = 16
    mark.Parent = box

    -- Label
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -CS - 10, 1, 0)
    txt.Position = UDim2.new(0, CS + 8, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = TS
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = row

    local function set(v)
        val = v
        box.BackgroundColor3 = v and C.checkOn or C.checkOff
        mark.Text = v and "✓" or ""
        lib._flags[flag].value = v
        callback(v)
    end

    row.MouseButton1Click:Connect(function() set(not val) end)
    lib._flags[flag] = { value = val, set = set }
    if val then callback(val) end
    return row
end

-- ===== Slider =====
function Tab:AddSlider(flag, label, default, min, max, rounding, callback)
    local lib = self._library
    local val = default or min
    callback = callback or function() end
    rounding = rounding or 1

    local fr = Instance.new("Frame")
    fr.Name = "S_" .. flag
    fr.Size = UDim2.new(1, 0, 0, RH + 12)
    fr.BackgroundTransparency = 1
    fr.BorderSizePixel = 0
    fr.Parent = self._content

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -50, 0, 18)
    txt.Position = UDim2.new(0, 2, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = TS
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = fr

    local vt = Instance.new("TextLabel")
    vt.Size = UDim2.new(0, 45, 0, 18)
    vt.Position = UDim2.new(1, -47, 0, 0)
    vt.BackgroundTransparency = 1
    vt.Text = tostring(val)
    vt.TextColor3 = C.text
    vt.FontFace = FONT_R
    vt.TextSize = 14
    vt.TextXAlignment = Enum.TextXAlignment.Right
    vt.Parent = fr

    local trk = Instance.new("Frame")
    trk.Size = UDim2.new(1, -4, 0, 8)
    trk.Position = UDim2.new(0, 2, 0, 22)
    trk.BackgroundColor3 = C.sliderBg
    trk.BorderSizePixel = 0
    trk.Parent = fr
    corner(trk, UDim.new(0, 4))

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = C.sliderFill
    fill.BorderSizePixel = 0
    fill.Parent = trk
    corner(fill, UDim.new(0, 4))

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = trk

    local function set(v)
        v = math.clamp(v, min, max)
        if rounding >= 1 then
            v = math.floor(v / rounding + 0.5) * rounding
        else
            local m = 1 / rounding
            v = math.floor(v * m + 0.5) / m
        end
        val = v
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        vt.Text = tostring(v)
        lib._flags[flag].value = v
        callback(v)
    end

    local drag = false
    hit.MouseButton1Down:Connect(function() drag = true end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
            set(min + (max - min) * r)
        end
    end)

    lib._flags[flag] = { value = val, set = set }
    return fr
end

-- ===== Button =====
function Tab:AddButton(label, callback)
    callback = callback or function() end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, RH)
    btn.BackgroundColor3 = C.btnFace
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = C.textLight
    btn.FontFace = FONT
    btn.TextSize = TS
    btn.AutoButtonColor = false
    btn.Parent = self._content
    corner(btn)

    local s = Instance.new("UIStroke")
    s.Color = C.tabBorder
    s.Thickness = 1
    s.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.tabActive end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.btnFace end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ===== Label =====
function Tab:AddLabel(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.textLight
    l.FontFace = FONT_R
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = self._content

    local obj = { _label = l }
    function obj:Set(t) l.Text = t end
    return obj
end

-- ===== Separator =====
function Tab:AddSeparator()
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.border
    s.BorderSizePixel = 0
    s.Parent = self._content
end

-- ===== Config Section =====
function Tab:AddConfigSection(lib)
    self:AddSeparator()
    self:AddLabel("Config")

    local inf = Instance.new("Frame")
    inf.Size = UDim2.new(1, 0, 0, RH)
    inf.BackgroundColor3 = C.btnFace
    inf.BorderSizePixel = 0
    inf.Parent = self._content
    corner(inf)

    local iStroke = Instance.new("UIStroke")
    iStroke.Color = C.tabBorder
    iStroke.Thickness = 1
    iStroke.Parent = inf

    local ib = Instance.new("TextBox")
    ib.Size = UDim2.new(1, -8, 1, 0)
    ib.Position = UDim2.new(0, 4, 0, 0)
    ib.BackgroundTransparency = 1
    ib.Text = ""
    ib.PlaceholderText = "Config name..."
    ib.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    ib.TextColor3 = C.textLight
    ib.FontFace = FONT_R
    ib.TextSize = TS
    ib.TextXAlignment = Enum.TextXAlignment.Left
    ib.ClearTextOnFocus = false
    ib.Parent = inf

    self:AddButton("Save Config", function() local n = ib.Text; if n == "" then return end; lib:SaveConfig(n) end)
    self:AddButton("Load Config", function() local n = ib.Text; if n == "" then return end; lib:LoadConfig(n) end)
    self:AddButton("Delete Config", function() local n = ib.Text; if n == "" then return end; lib:DeleteConfig(n) end)
    self:AddButton("Set Autoload", function() local n = ib.Text; if n == "" then return end; lib:SetAutoload(n) end)
end

function Library:Destroy()
    if self._screenGui then self._screenGui:Destroy() end
end

return Library
