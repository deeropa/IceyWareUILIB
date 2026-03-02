--[[
    RogueLib - IceyWare Style UI Library
    Pixel-perfect match to IceyWare
]]

local Library = {}
Library.__index = Library
Library._flags = {}
Library._configFolder = "RogueHub/configs"

local UIS = game:GetService("UserInputService")
local HS = game:GetService("HttpService")

-- ===== IceyWare EXACT colors from screenshot =====
local C = {
    outerBg = Color3.fromRGB(78, 82, 88),         -- main frame bg (dark grey)
    outerBorder = Color3.fromRGB(45, 48, 52),      -- thick outer border
    tabFace = Color3.fromRGB(88, 92, 98),          -- tab button face
    tabFaceActive = Color3.fromRGB(78, 82, 88),    -- active tab (matches bg = blends in)
    tabBorderLight = Color3.fromRGB(115, 118, 124), -- tab top/left highlight
    tabBorderDark = Color3.fromRGB(50, 53, 58),    -- tab bottom/right shadow
    contentBg = Color3.fromRGB(72, 76, 82),        -- content area (slightly darker)
    contentBorder = Color3.fromRGB(50, 53, 58),    -- content inner border
    checkOnBg = Color3.fromRGB(55, 85, 130),       -- checked = blue
    checkOffBg = Color3.fromRGB(200, 203, 208),    -- unchecked = white/light
    checkBorder = Color3.fromRGB(35, 38, 42),      -- checkbox border (very dark)
    checkMark = Color3.fromRGB(255, 255, 255),     -- ✓ color
    textDark = Color3.fromRGB(20, 20, 22),         -- main text (near black)
    textTab = Color3.fromRGB(210, 212, 216),       -- tab text (light)
    sliderFill = Color3.fromRGB(55, 85, 130),
    sliderBg = Color3.fromRGB(55, 58, 64),
    btnFace = Color3.fromRGB(82, 86, 92),
    btnBorder = Color3.fromRGB(50, 53, 58),
}

local FONT = Font.fromEnum(Enum.Font.SourceSansBold)
local FONT_REG = Font.fromEnum(Enum.Font.SourceSans)
local TEXT_SIZE = 18
local CHECK_SIZE = 20
local ROW_HEIGHT = 28
local TAB_H = 24
local WIN_W = 420
local WIN_H = 320

-- ===== HELPERS =====
local function makeDraggable(frame, handle)
    local d, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            d = true; ds = i.Position; sp = frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and i.UserInputType == Enum.UserInputType.MouseMovement then
            local dt = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + dt.X, sp.Y.Scale, sp.Y.Offset + dt.Y)
        end
    end)
end

-- ===== CONFIG =====
function Library:_ensureFolder()
    if not isfolder(self._configFolder) then makefolder(self._configFolder) end
end
function Library:SaveConfig(n)
    self:_ensureFolder()
    local d = {}; for f, i in pairs(self._flags) do d[f] = i.value end
    writefile(self._configFolder.."/"..n..".json", HS:JSONEncode(d))
end
function Library:LoadConfig(n)
    self:_ensureFolder()
    local p = self._configFolder.."/"..n..".json"
    if not isfile(p) then return false end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(p)) end)
    if not ok then return false end
    for f, v in pairs(d) do if self._flags[f] then self._flags[f].set(v) end end
    return true
end
function Library:DeleteConfig(n)
    self:_ensureFolder()
    local p = self._configFolder.."/"..n..".json"
    if isfile(p) then delfile(p) end
end
function Library:ListConfigs()
    self:_ensureFolder()
    local r = {}
    for _, f in pairs(listfiles(self._configFolder)) do
        local n = f:match("([^/\\]+)%.json$")
        if n then table.insert(r, n) end
    end
    return r
end
function Library:SetAutoload(n)
    self:_ensureFolder(); writefile(self._configFolder.."/autoload.txt", n)
end
function Library:LoadAutoload()
    self:_ensureFolder()
    local p = self._configFolder.."/autoload.txt"
    if isfile(p) then local n = readfile(p); if n ~= "" then self:LoadConfig(n) end end
end

-- ===== WINDOW =====
function Library:CreateWindow(title, toggleKey)
    local self = setmetatable({}, Library)
    self._flags = {}
    self._tabs = {}
    self._visible = true

    local sg = Instance.new("ScreenGui")
    sg.Name = "RogueLib"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
    self._screenGui = sg

    -- Main frame — OPAQUE dark grey, sharp corners
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
    main.Position = UDim2.new(1, -WIN_W - 10, 0.15, 0)
    main.BackgroundColor3 = C.outerBg
    main.BackgroundTransparency = 0
    main.BorderSizePixel = 0
    main.Parent = sg
    self._main = main

    -- THICK outer border (2px, very dark)
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = C.outerBorder
    outerStroke.Thickness = 2
    outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outerStroke.Parent = main

    -- Tab bar at top
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, TAB_H + 4)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.ClipsDescendants = true
    tabBar.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 4)
    tabPad.PaddingTop = UDim.new(0, 4)
    tabPad.Parent = tabBar

    self._tabBar = tabBar
    makeDraggable(main, tabBar)

    -- Content area — darker inset box below tabs
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -8, 1, -TAB_H - 10)
    content.Position = UDim2.new(0, 4, 0, TAB_H + 6)
    content.BackgroundColor3 = C.contentBg
    content.BackgroundTransparency = 0
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = main
    self._contentArea = content

    -- Content inner border
    local cStroke = Instance.new("UIStroke")
    cStroke.Color = C.contentBorder
    cStroke.Thickness = 2
    cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cStroke.Parent = content

    -- Toggle key
    toggleKey = toggleKey or "K"
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode[toggleKey] then
            self._visible = not self._visible
            main.Visible = self._visible
        end
    end)

    return self
end

-- ===== TAB =====
local Tab = {}
Tab.__index = Tab

function Library:_switchTab(tab)
    for _, t in pairs(self._tabs) do
        t._content.Visible = false
        t._button.BackgroundColor3 = C.tabFace
    end
    tab._content.Visible = true
    tab._button.BackgroundColor3 = C.tabFaceActive
end

function Library.AddTab(self, name)
    local tab = setmetatable({}, Tab)
    tab._library = self

    -- Tab button — raised 3D look with border
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 0, 0, TAB_H)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = C.tabFace
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = self._tabBar

    -- Tab border (embossed look)
    local tStroke = Instance.new("UIStroke")
    tStroke.Color = C.tabBorderDark
    tStroke.Thickness = 2
    tStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tStroke.Parent = btn

    local bPad = Instance.new("UIPadding")
    bPad.PaddingLeft = UDim.new(0, 12)
    bPad.PaddingRight = UDim.new(0, 12)
    bPad.Parent = btn

    local bLabel = Instance.new("TextLabel")
    bLabel.Size = UDim2.new(0, 0, 1, 0)
    bLabel.AutomaticSize = Enum.AutomaticSize.X
    bLabel.BackgroundTransparency = 1
    bLabel.Text = name
    bLabel.TextColor3 = C.textTab
    bLabel.FontFace = FONT
    bLabel.TextSize = 14
    bLabel.Parent = btn

    tab._button = btn

    -- Scrolling content
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

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = scroll

    tab._content = scroll

    btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_switchTab(tab) end
    return tab
end

-- ===== TOGGLE — IceyWare exact style =====
function Tab:AddToggle(flag, label, default, callback)
    local lib = self._library
    local value = default or false
    callback = callback or function() end

    -- Row — transparent background
    local row = Instance.new("TextButton")
    row.Name = "T_" .. flag
    row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = self._content

    -- BIG checkbox with THICK border
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, CHECK_SIZE, 0, CHECK_SIZE)
    box.Position = UDim2.new(0, 0, 0.5, -CHECK_SIZE/2)
    box.BackgroundColor3 = value and C.checkOnBg or C.checkOffBg
    box.BorderSizePixel = 0
    box.Parent = row

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = C.checkBorder
    boxStroke.Thickness = 2
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxStroke.Parent = box

    -- Check mark — bold, centered
    local mark = Instance.new("TextLabel")
    mark.Size = UDim2.new(1, 0, 1, 0)
    mark.BackgroundTransparency = 1
    mark.Text = value and "✓" or ""
    mark.TextColor3 = C.checkMark
    mark.FontFace = FONT
    mark.TextSize = 16
    mark.Parent = box

    -- Label — BOLD, DARK, LARGE like IceyWare
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -CHECK_SIZE - 10, 1, 0)
    txt.Position = UDim2.new(0, CHECK_SIZE + 8, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.textDark
    txt.FontFace = FONT
    txt.TextSize = TEXT_SIZE
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = row

    local function setVal(v)
        value = v
        box.BackgroundColor3 = v and C.checkOnBg or C.checkOffBg
        mark.Text = v and "✓" or ""
        lib._flags[flag].value = v
        callback(v)
    end

    row.MouseButton1Click:Connect(function() setVal(not value) end)
    lib._flags[flag] = { value = value, set = setVal }
    if value then callback(value) end
    return row
end

-- ===== SLIDER =====
function Tab:AddSlider(flag, label, default, min, max, rounding, callback)
    local lib = self._library
    local value = default or min
    callback = callback or function() end
    rounding = rounding or 1

    local frame = Instance.new("Frame")
    frame.Name = "S_" .. flag
    frame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT + 12)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = self._content

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -50, 0, 18)
    txt.Position = UDim2.new(0, 2, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.textDark
    txt.FontFace = FONT
    txt.TextSize = TEXT_SIZE
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = frame

    local valTxt = Instance.new("TextLabel")
    valTxt.Size = UDim2.new(0, 45, 0, 18)
    valTxt.Position = UDim2.new(1, -47, 0, 0)
    valTxt.BackgroundTransparency = 1
    valTxt.Text = tostring(value)
    valTxt.TextColor3 = C.textDark
    valTxt.FontFace = FONT_REG
    valTxt.TextSize = 15
    valTxt.TextXAlignment = Enum.TextXAlignment.Right
    valTxt.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -4, 0, 8)
    track.Position = UDim2.new(0, 2, 0, 22)
    track.BackgroundColor3 = C.sliderBg
    track.BorderSizePixel = 0
    track.Parent = frame

    local tStroke = Instance.new("UIStroke")
    tStroke.Color = C.checkBorder
    tStroke.Thickness = 1
    tStroke.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((value-min)/(max-min), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = C.sliderFill
    fill.BorderSizePixel = 0
    fill.Parent = track

    local hitArea = Instance.new("TextButton")
    hitArea.Size = UDim2.new(1, 0, 1, 0)
    hitArea.BackgroundTransparency = 1
    hitArea.Text = ""
    hitArea.Parent = track

    local function setVal(v)
        v = math.clamp(v, min, max)
        if rounding >= 1 then v = math.floor(v/rounding+0.5)*rounding
        else local m=1/rounding; v = math.floor(v*m+0.5)/m end
        value = v
        fill.Size = UDim2.new((v-min)/(max-min), 0, 1, 0)
        valTxt.Text = tostring(v)
        lib._flags[flag].value = v
        callback(v)
    end

    local dragging = false
    hitArea.MouseButton1Down:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local r = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setVal(min + (max-min) * r)
        end
    end)

    lib._flags[flag] = { value = value, set = setVal }
    return frame
end

-- ===== BUTTON =====
function Tab:AddButton(label, callback)
    callback = callback or function() end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    btn.BackgroundColor3 = C.btnFace
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = C.textDark
    btn.FontFace = FONT
    btn.TextSize = TEXT_SIZE
    btn.AutoButtonColor = false
    btn.Parent = self._content

    local s = Instance.new("UIStroke")
    s.Color = C.btnBorder; s.Thickness = 2; s.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.tabFace end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.btnFace end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ===== LABEL =====
function Tab:AddLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.textDark
    lbl.FontFace = FONT_REG
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = self._content
    local obj = {_label = lbl}
    function obj:Set(t) lbl.Text = t end
    return obj
end

-- ===== SEPARATOR =====
function Tab:AddSeparator()
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 2)
    s.BackgroundColor3 = C.contentBorder
    s.BorderSizePixel = 0
    s.Parent = self._content
end

-- ===== CONFIG UI =====
function Tab:AddConfigSection(lib)
    self:AddSeparator()
    self:AddLabel("Config")

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    inputFrame.BackgroundColor3 = C.btnFace
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = self._content
    local iS = Instance.new("UIStroke"); iS.Color = C.btnBorder; iS.Thickness = 2; iS.Parent = inputFrame

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -8, 1, 0)
    inputBox.Position = UDim2.new(0, 4, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text = ""; inputBox.PlaceholderText = "Config name..."
    inputBox.PlaceholderColor3 = Color3.fromRGB(100, 103, 108)
    inputBox.TextColor3 = C.textDark
    inputBox.FontFace = FONT_REG; inputBox.TextSize = TEXT_SIZE
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputFrame

    self:AddButton("Save Config", function() local n=inputBox.Text; if n=="" then return end; lib:SaveConfig(n) end)
    self:AddButton("Load Config", function() local n=inputBox.Text; if n=="" then return end; lib:LoadConfig(n) end)
    self:AddButton("Delete Config", function() local n=inputBox.Text; if n=="" then return end; lib:DeleteConfig(n) end)
    self:AddButton("Set Autoload", function() local n=inputBox.Text; if n=="" then return end; lib:SetAutoload(n) end)
end

function Library:Destroy()
    if self._screenGui then self._screenGui:Destroy() end
end

return Library
