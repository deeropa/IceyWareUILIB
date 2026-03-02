--[[
    RogueLib - IceyWare Style UI Library
    Pixel-perfect match to IceyWare
]]

local Library = {}
Library.__index = Library
Library._flags = {}
Library._configFolder = "RogueHub/configs"

-- ===== IceyWare exact colors =====
local C = {
    frameBg = Color3.fromRGB(100, 105, 110),       -- grey frame background
    frameBorder = Color3.fromRGB(65, 68, 72),       -- darker border
    tabBg = Color3.fromRGB(90, 94, 100),            -- tab background
    tabActive = Color3.fromRGB(110, 115, 122),      -- active tab slightly lighter
    tabBorder = Color3.fromRGB(60, 63, 68),         -- tab border
    contentBg = Color3.fromRGB(95, 100, 106),       -- content area
    checkOn = Color3.fromRGB(70, 100, 140),         -- checked checkbox fill (blue-grey)
    checkOff = Color3.fromRGB(180, 185, 190),       -- unchecked checkbox (light grey)
    checkBorder = Color3.fromRGB(50, 53, 58),       -- checkbox border
    text = Color3.fromRGB(35, 35, 38),              -- dark text (IceyWare uses dark text)
    textLight = Color3.fromRGB(220, 222, 225),      -- light text for tabs
    white = Color3.fromRGB(255, 255, 255),
    sliderFill = Color3.fromRGB(70, 100, 140),
    sliderBg = Color3.fromRGB(75, 78, 84),
    btnBg = Color3.fromRGB(105, 110, 116),
    btnBorder = Color3.fromRGB(60, 63, 68),
}

local FONT = Font.fromEnum(Enum.Font.SourceSans)
local FONT_BOLD = Font.fromEnum(Enum.Font.SourceSansBold)
local FONT_SIZE = 16
local ROW_HEIGHT = 22
local TAB_HEIGHT = 22
local WINDOW_W = 320
local WINDOW_H = 300

-- ===== HELPERS =====
local UIS = game:GetService("UserInputService")

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

-- ===== CONFIG SYSTEM =====
function Library:_ensureFolder()
    if not isfolder(self._configFolder) then makefolder(self._configFolder) end
end

function Library:SaveConfig(name)
    self:_ensureFolder()
    local data = {}
    for flag, info in pairs(self._flags) do data[flag] = info.value end
    writefile(self._configFolder .. "/" .. name .. ".json", game:GetService("HttpService"):JSONEncode(data))
end

function Library:LoadConfig(name)
    self:_ensureFolder()
    local path = self._configFolder .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(path)) end)
    if not ok then return false end
    for flag, val in pairs(data) do
        if self._flags[flag] then self._flags[flag].set(val) end
    end
    return true
end

function Library:DeleteConfig(name)
    self:_ensureFolder()
    local path = self._configFolder .. "/" .. name .. ".json"
    if isfile(path) then delfile(path) end
end

function Library:ListConfigs()
    self:_ensureFolder()
    local files = listfiles(self._configFolder)
    local configs = {}
    for _, f in pairs(files) do
        local name = f:match("([^/\\]+)%.json$")
        if name then table.insert(configs, name) end
    end
    return configs
end

function Library:SetAutoload(name)
    self:_ensureFolder()
    writefile(self._configFolder .. "/autoload.txt", name)
end

function Library:LoadAutoload()
    self:_ensureFolder()
    local path = self._configFolder .. "/autoload.txt"
    if isfile(path) then
        local name = readfile(path)
        if name and name ~= "" then self:LoadConfig(name) end
    end
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

    -- Main frame — NO rounded corners, positioned right side
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
    main.Position = UDim2.new(1, -WINDOW_W - 10, 0.5, -WINDOW_H / 2)
    main.BackgroundColor3 = C.frameBg
    main.BackgroundTransparency = 0.15
    main.BorderSizePixel = 0
    main.Parent = sg
    self._main = main

    -- Outer border (1px dark)
    local border = Instance.new("UIStroke")
    border.Color = C.frameBorder
    border.Thickness = 1
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = main

    -- Tab bar — flush at top, no padding, no title bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
    tabBar.Position = UDim2.new(0, 0, 0, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.ClipsDescendants = true
    tabBar.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 0)
    tabLayout.Parent = tabBar

    self._tabBar = tabBar
    makeDraggable(main, tabBar)

    -- Content area — below tabs
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -2, 1, -TAB_HEIGHT - 2)
    content.Position = UDim2.new(0, 1, 0, TAB_HEIGHT + 1)
    content.BackgroundColor3 = C.contentBg
    content.BackgroundTransparency = 0.15
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = main
    self._contentArea = content

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
        t._button.BackgroundColor3 = C.tabBg
    end
    tab._content.Visible = true
    tab._button.BackgroundColor3 = C.tabActive
end

function Library.AddTab(self, name)
    local tab = setmetatable({}, Tab)
    tab._library = self

    -- Tab button — sharp edges, border
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = C.tabBg
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = self._tabBar

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = C.tabBorder
    bStroke.Thickness = 1
    bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bStroke.Parent = btn

    local bPad = Instance.new("UIPadding")
    bPad.PaddingLeft = UDim.new(0, 10)
    bPad.PaddingRight = UDim.new(0, 10)
    bPad.Parent = btn

    local bLabel = Instance.new("TextLabel")
    bLabel.Size = UDim2.new(0, 0, 1, 0)
    bLabel.AutomaticSize = Enum.AutomaticSize.X
    bLabel.BackgroundTransparency = 1
    bLabel.Text = name
    bLabel.TextColor3 = C.textLight
    bLabel.FontFace = FONT_BOLD
    bLabel.TextSize = 14
    bLabel.Parent = btn

    tab._button = btn

    -- Content scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = C.sliderFill
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Visible = false
    scroll.Parent = self._contentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 0)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    pad.Parent = scroll

    tab._content = scroll

    btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_switchTab(tab) end

    return tab
end

-- ===== TOGGLE — IceyWare exact: checkbox LEFT, text RIGHT, no bg =====
function Tab:AddToggle(flag, label, default, callback)
    local lib = self._library
    local value = default or false
    callback = callback or function() end

    local row = Instance.new("TextButton")
    row.Name = "T_" .. flag
    row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = self._content

    -- Checkbox square — sharp corners
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 16, 0, 16)
    box.Position = UDim2.new(0, 0, 0.5, -8)
    box.BackgroundColor3 = value and C.checkOn or C.checkOff
    box.BorderSizePixel = 0
    box.Parent = row

    local boxBorder = Instance.new("UIStroke")
    boxBorder.Color = C.checkBorder
    boxBorder.Thickness = 1
    boxBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    boxBorder.Parent = box

    local checkMark = Instance.new("TextLabel")
    checkMark.Size = UDim2.new(1, 0, 1, 0)
    checkMark.BackgroundTransparency = 1
    checkMark.Text = value and "✓" or ""
    checkMark.TextColor3 = C.white
    checkMark.FontFace = FONT_BOLD
    checkMark.TextSize = 14
    checkMark.Parent = box

    -- Label text
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -24, 1, 0)
    txt.Position = UDim2.new(0, 22, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = FONT_SIZE
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = row

    local function setVal(v)
        value = v
        box.BackgroundColor3 = v and C.checkOn or C.checkOff
        checkMark.Text = v and "✓" or ""
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
    frame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT + 10)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = self._content

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -45, 0, 14)
    txt.Position = UDim2.new(0, 2, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = FONT_SIZE
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = frame

    local valTxt = Instance.new("TextLabel")
    valTxt.Size = UDim2.new(0, 40, 0, 14)
    valTxt.Position = UDim2.new(1, -42, 0, 0)
    valTxt.BackgroundTransparency = 1
    valTxt.Text = tostring(value)
    valTxt.TextColor3 = C.text
    valTxt.FontFace = FONT
    valTxt.TextSize = 13
    valTxt.TextXAlignment = Enum.TextXAlignment.Right
    valTxt.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -4, 0, 6)
    track.Position = UDim2.new(0, 2, 0, 18)
    track.BackgroundColor3 = C.sliderBg
    track.BorderSizePixel = 0
    track.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
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
        if rounding >= 1 then v = math.floor(v / rounding + 0.5) * rounding
        else local m = 1/rounding; v = math.floor(v * m + 0.5) / m end
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
    btn.BackgroundColor3 = C.btnBg
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = C.text
    btn.FontFace = FONT
    btn.TextSize = FONT_SIZE
    btn.AutoButtonColor = false
    btn.Parent = self._content

    local s = Instance.new("UIStroke")
    s.Color = C.btnBorder
    s.Thickness = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0 end)
    btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.2 end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ===== LABEL =====
function Tab:AddLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.text
    lbl.FontFace = FONT
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = self._content

    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 2)
    p.Parent = lbl

    local obj = {_label = lbl}
    function obj:Set(t) lbl.Text = t end
    return obj
end

-- ===== SEPARATOR =====
function Tab:AddSeparator()
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.frameBorder
    s.BorderSizePixel = 0
    s.Parent = self._content
end

-- ===== CONFIG UI =====
function Tab:AddConfigSection(lib)
    self:AddSeparator()
    self:AddLabel("Config")

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
    inputFrame.BackgroundColor3 = C.btnBg
    inputFrame.BackgroundTransparency = 0.2
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = self._content

    local iStroke = Instance.new("UIStroke")
    iStroke.Color = C.btnBorder
    iStroke.Thickness = 1
    iStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    iStroke.Parent = inputFrame

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -8, 1, 0)
    inputBox.Position = UDim2.new(0, 4, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text = ""
    inputBox.PlaceholderText = "Config name..."
    inputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 85)
    inputBox.TextColor3 = C.text
    inputBox.FontFace = FONT
    inputBox.TextSize = FONT_SIZE
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputFrame

    self:AddButton("Save Config", function()
        local n = inputBox.Text; if n == "" then return end; lib:SaveConfig(n)
    end)
    self:AddButton("Load Config", function()
        local n = inputBox.Text; if n == "" then return end; lib:LoadConfig(n)
    end)
    self:AddButton("Delete Config", function()
        local n = inputBox.Text; if n == "" then return end; lib:DeleteConfig(n)
    end)
    self:AddButton("Set Autoload", function()
        local n = inputBox.Text; if n == "" then return end; lib:SetAutoload(n)
    end)
end

-- ===== DESTROY =====
function Library:Destroy()
    if self._screenGui then self._screenGui:Destroy() end
end

return Library
