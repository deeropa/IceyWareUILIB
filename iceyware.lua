--[[
    RogueLib - Custom UI Library (IceyWare Style)
    Pure Lua, CoreGui, single-file
]]

local Library = {}
Library.__index = Library
Library._flags = {}
Library._configs = {}
Library._configFolder = "RogueHub/configs"

-- ===== COLORS (IceyWare grey/silver palette) =====
local COLORS = {
    bg = Color3.fromRGB(50, 50, 55),
    titleBar = Color3.fromRGB(42, 42, 47),
    tabBarBg = Color3.fromRGB(55, 55, 60),
    tabInactive = Color3.fromRGB(62, 62, 68),
    tabActive = Color3.fromRGB(80, 80, 90),
    tabBorder = Color3.fromRGB(90, 90, 100),
    content = Color3.fromRGB(58, 58, 64),
    element = Color3.fromRGB(65, 65, 72),
    elementHover = Color3.fromRGB(75, 75, 82),
    elementBorder = Color3.fromRGB(85, 85, 95),
    checkboxBg = Color3.fromRGB(72, 72, 80),
    checkboxChecked = Color3.fromRGB(72, 72, 80),
    sliderFill = Color3.fromRGB(120, 140, 180),
    sliderBg = Color3.fromRGB(50, 50, 58),
    text = Color3.fromRGB(220, 220, 225),
    textDim = Color3.fromRGB(150, 150, 160),
    white = Color3.fromRGB(255, 255, 255),
}

local FONT = Font.fromEnum(Enum.Font.SourceSans)
local FONT_BOLD = Font.fromEnum(Enum.Font.SourceSansBold)
local FONT_SIZE = 15
local CORNER = UDim.new(0, 3)
local WINDOW_W = 540
local WINDOW_H = 340
local TAB_HEIGHT = 26
local ELEMENT_HEIGHT = 24
local ELEMENT_PAD = 1

-- ===== HELPERS =====
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = r or CORNER; c.Parent = p; return c
end

local function stroke(p, col, t)
    local s = Instance.new("UIStroke"); s.Color = col or COLORS.elementBorder; s.Thickness = t or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

local function makeDraggable(frame, handle)
    local d, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            d = true; ds = i.Position; sp = frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(i)
        if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
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
    local data = game:GetService("HttpService"):JSONDecode(readfile(path))
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
        if name and name ~= "autoload" then table.insert(configs, name) end
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
    self._activeTab = nil
    self._visible = true

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RogueLib_" .. math.random(100000, 999999)
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
    if not screenGui.Parent then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    self._screenGui = screenGui

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
    main.Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2)
    main.BackgroundColor3 = COLORS.bg
    main.BorderSizePixel = 0
    main.Parent = screenGui
    corner(main, UDim.new(0, 2))
    stroke(main, COLORS.tabBorder, 1)
    self._main = main

    -- Title bar (slim)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 22)
    titleBar.BackgroundColor3 = COLORS.titleBar
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    corner(titleBar, UDim.new(0, 2))

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 6)
    titleFix.Position = UDim2.new(0, 0, 1, -6)
    titleFix.BackgroundColor3 = COLORS.titleBar
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 8, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "RogueLib"
    titleLabel.TextColor3 = COLORS.text
    titleLabel.FontFace = FONT_BOLD
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close & minimize
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -22, 0, 1)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = COLORS.textDim
    closeBtn.FontFace = FONT_BOLD
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 20, 0, 20)
    minBtn.Position = UDim2.new(1, -42, 0, 1)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.TextColor3 = COLORS.textDim
    minBtn.FontFace = FONT
    minBtn.TextSize = 12
    minBtn.Parent = titleBar

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        main.Size = minimized and UDim2.new(0, WINDOW_W, 0, 22) or UDim2.new(0, WINDOW_W, 0, WINDOW_H)
    end)

    makeDraggable(main, titleBar)

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -6, 0, TAB_HEIGHT)
    tabBar.Position = UDim2.new(0, 3, 0, 24)
    tabBar.BackgroundColor3 = COLORS.tabBarBg
    tabBar.BorderSizePixel = 0
    tabBar.ClipsDescendants = true
    tabBar.Parent = main
    corner(tabBar, UDim.new(0, 2))

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 1)
    tabLayout.Parent = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 1)
    tabPad.PaddingTop = UDim.new(0, 1)
    tabPad.Parent = tabBar

    self._tabBar = tabBar

    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -6, 1, -TAB_HEIGHT - 28)
    contentArea.Position = UDim2.new(0, 3, 0, TAB_HEIGHT + 26)
    contentArea.BackgroundColor3 = COLORS.content
    contentArea.BorderSizePixel = 0
    contentArea.ClipsDescendants = true
    contentArea.Parent = main
    corner(contentArea, UDim.new(0, 2))
    self._contentArea = contentArea

    -- Toggle key
    toggleKey = toggleKey or "K"
    game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
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
        t._button.BackgroundColor3 = COLORS.tabInactive
    end
    tab._content.Visible = true
    tab._button.BackgroundColor3 = COLORS.tabActive
    self._activeTab = tab
end

function Library.AddTab(self, name)
    local tab = setmetatable({}, Tab)
    tab._library = self
    tab._name = name

    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 0, 1, -2)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = COLORS.tabInactive
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = self._tabBar
    corner(btn, UDim.new(0, 2))
    stroke(btn, COLORS.tabBorder, 1)

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 10)
    btnPad.PaddingRight = UDim.new(0, 10)
    btnPad.Parent = btn

    local btnLabel = Instance.new("TextLabel")
    btnLabel.Size = UDim2.new(0, 0, 1, 0)
    btnLabel.AutomaticSize = Enum.AutomaticSize.X
    btnLabel.BackgroundTransparency = 1
    btnLabel.Text = name
    btnLabel.TextColor3 = COLORS.text
    btnLabel.FontFace = FONT_BOLD
    btnLabel.TextSize = 13
    btnLabel.Parent = btn

    tab._button = btn

    -- Scrolling content
    local content = Instance.new("ScrollingFrame")
    content.Name = name .. "_Content"
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = COLORS.sliderFill
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Visible = false
    content.Parent = self._contentArea

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, ELEMENT_PAD)
    layout.Parent = content

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.Parent = content

    tab._content = content

    btn.MouseButton1Click:Connect(function() self:_switchTab(tab) end)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then self:_switchTab(tab) end

    return tab
end

-- ===== TOGGLE (checkbox on LEFT, IceyWare style) =====
function Tab:AddToggle(flag, label, default, callback)
    local lib = self._library
    local value = default or false
    callback = callback or function() end

    local frame = Instance.new("TextButton")
    frame.Name = "Toggle_" .. flag
    frame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    frame.BackgroundColor3 = COLORS.element
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Parent = self._content

    -- Checkbox (left side)
    local box = Instance.new("TextLabel")
    box.Name = "Checkbox"
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 6, 0.5, -9)
    box.BackgroundColor3 = COLORS.checkboxBg
    box.BorderSizePixel = 0
    box.Text = value and "✓" or ""
    box.TextColor3 = COLORS.white
    box.FontFace = FONT_BOLD
    box.TextSize = 14
    box.Parent = frame
    corner(box, UDim.new(0, 2))
    stroke(box, COLORS.elementBorder, 1)

    -- Label (right of checkbox)
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -32, 1, 0)
    textLabel.Position = UDim2.new(0, 30, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = COLORS.text
    textLabel.FontFace = FONT
    textLabel.TextSize = FONT_SIZE
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame

    local function setVal(v)
        value = v
        box.Text = v and "✓" or ""
        lib._flags[flag].value = v
        callback(v)
    end

    frame.MouseButton1Click:Connect(function() setVal(not value) end)
    frame.MouseEnter:Connect(function() frame.BackgroundTransparency = 0.1 end)
    frame.MouseLeave:Connect(function() frame.BackgroundTransparency = 0.3 end)

    lib._flags[flag] = { value = value, set = setVal }
    if value then callback(value) end

    return frame
end

-- ===== SLIDER =====
function Tab:AddSlider(flag, label, default, min, max, rounding, callback)
    local lib = self._library
    local value = default or min
    callback = callback or function() end
    rounding = rounding or 1

    local frame = Instance.new("Frame")
    frame.Name = "Slider_" .. flag
    frame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT + 12)
    frame.BackgroundColor3 = COLORS.element
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = self._content

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -55, 0, 16)
    textLabel.Position = UDim2.new(0, 8, 0, 2)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = COLORS.text
    textLabel.FontFace = FONT
    textLabel.TextSize = FONT_SIZE
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 45, 0, 16)
    valLabel.Position = UDim2.new(1, -50, 0, 2)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(value)
    valLabel.TextColor3 = COLORS.textDim
    valLabel.FontFace = FONT
    valLabel.TextSize = 13
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 6)
    track.Position = UDim2.new(0, 8, 0, 22)
    track.BackgroundColor3 = COLORS.sliderBg
    track.BorderSizePixel = 0
    track.Parent = frame
    corner(track, UDim.new(0, 3))

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.sliderFill
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, UDim.new(0, 3))

    local inputBtn = Instance.new("TextButton")
    inputBtn.Size = UDim2.new(1, 0, 1, 0)
    inputBtn.BackgroundTransparency = 1
    inputBtn.Text = ""
    inputBtn.Parent = track

    local function setVal(v)
        v = math.clamp(v, min, max)
        if rounding >= 1 then
            v = math.floor(v / rounding + 0.5) * rounding
        else
            local mult = 1 / rounding
            v = math.floor(v * mult + 0.5) / mult
        end
        value = v
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        valLabel.Text = tostring(v)
        lib._flags[flag].value = v
        callback(v)
    end

    local dragging = false
    inputBtn.MouseButton1Down:Connect(function() dragging = true end)
    game:GetService("UserInputService").InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setVal(min + (max - min) * rel)
        end
    end)
    inputBtn.MouseButton1Click:Connect(function()
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        local rel = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        setVal(min + (max - min) * rel)
    end)

    lib._flags[flag] = { value = value, set = setVal }
    return frame
end

-- ===== BUTTON =====
function Tab:AddButton(label, callback)
    callback = callback or function() end

    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. label
    btn.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    btn.BackgroundColor3 = COLORS.element
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = COLORS.text
    btn.FontFace = FONT
    btn.TextSize = FONT_SIZE
    btn.AutoButtonColor = false
    btn.Parent = self._content
    stroke(btn, COLORS.elementBorder, 1)

    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.1 end)
    btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.3 end)
    btn.MouseButton1Click:Connect(callback)

    return btn
end

-- ===== LABEL =====
function Tab:AddLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.textDim
    label.FontFace = FONT
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self._content

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 6)
    pad.Parent = label

    local obj = {_label = label}
    function obj:Set(t) label.Text = t end
    return obj
end

-- ===== SEPARATOR =====
function Tab:AddSeparator()
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = COLORS.elementBorder
    sep.BackgroundTransparency = 0.5
    sep.BorderSizePixel = 0
    sep.Parent = self._content
    return sep
end

-- ===== CONFIG UI =====
function Tab:AddConfigSection(lib)
    self:AddSeparator()
    self:AddLabel("Config")

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    inputFrame.BackgroundColor3 = COLORS.element
    inputFrame.BackgroundTransparency = 0.3
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = self._content
    stroke(inputFrame, COLORS.elementBorder, 1)

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -12, 1, 0)
    inputBox.Position = UDim2.new(0, 6, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.Text = ""
    inputBox.PlaceholderText = "Config name..."
    inputBox.PlaceholderColor3 = COLORS.textDim
    inputBox.TextColor3 = COLORS.text
    inputBox.FontFace = FONT
    inputBox.TextSize = FONT_SIZE
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputFrame

    self:AddButton("Save Config", function()
        local n = inputBox.Text; if n == "" then return end
        lib:SaveConfig(n)
    end)
    self:AddButton("Load Config", function()
        local n = inputBox.Text; if n == "" then return end
        lib:LoadConfig(n)
    end)
    self:AddButton("Delete Config", function()
        local n = inputBox.Text; if n == "" then return end
        lib:DeleteConfig(n)
    end)
    self:AddButton("Set Autoload", function()
        local n = inputBox.Text; if n == "" then return end
        lib:SetAutoload(n)
    end)
end

-- ===== DESTROY =====
function Library:Destroy()
    if self._screenGui then self._screenGui:Destroy() end
end

return Library
