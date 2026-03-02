--[[
    RogueLib - Custom UI Library (IceyWare Style)
    Pure Lua, CoreGui, single-file

    Usage:
        local Library = loadstring(readfile("RogueLib.lua"))()
        local Window = Library:CreateWindow("My Hub", "K")
        local Tab = Window:AddTab("Main")
        Tab:AddToggle("Flag", "Label", false, function(v) end)
        Tab:AddSlider("Flag", "Label", 16, 0, 100, 1, function(v) end)
        Tab:AddButton("Label", function() end)
        Tab:AddLabel("Text")
        Library:Notify("Hello!", 3)
        Library:SaveConfig("default")
        Library:LoadConfig("default")
]]

local Library = {}
Library.__index = Library
Library._flags = {}
Library._configs = {}
Library._configFolder = "RogueHub/configs"
Library._notifications = {}

-- ===== COLORS =====
local COLORS = {
    bg = Color3.fromRGB(35, 40, 50),
    titleBar = Color3.fromRGB(30, 35, 45),
    tabBarBg = Color3.fromRGB(40, 45, 55),
    tabInactive = Color3.fromRGB(55, 60, 72),
    tabActive = Color3.fromRGB(75, 82, 100),
    tabBorder = Color3.fromRGB(85, 90, 105),
    content = Color3.fromRGB(42, 47, 58),
    element = Color3.fromRGB(50, 55, 68),
    elementBorder = Color3.fromRGB(70, 75, 90),
    toggleOn = Color3.fromRGB(80, 170, 120),
    toggleOff = Color3.fromRGB(65, 70, 82),
    sliderFill = Color3.fromRGB(80, 130, 200),
    sliderBg = Color3.fromRGB(55, 60, 72),
    text = Color3.fromRGB(210, 215, 225),
    textDim = Color3.fromRGB(140, 145, 158),
    notifBg = Color3.fromRGB(35, 40, 50),
    notifBorder = Color3.fromRGB(80, 130, 200),
    white = Color3.fromRGB(255, 255, 255),
}

local FONT = Font.fromEnum(Enum.Font.Code)
local FONT_SIZE = 13
local CORNER_RADIUS = UDim.new(0, 4)
local WINDOW_SIZE = UDim2.new(0, 520, 0, 370)
local TAB_HEIGHT = 28
local ELEMENT_HEIGHT = 32
local PADDING = 6

-- ===== HELPERS =====
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or CORNER_RADIUS
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.elementBorder
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ===== NOTIFICATION =====
function Library:Notify(text, duration)
    duration = duration or 3

    local screenGui = self._screenGui
    if not screenGui then return end

    -- Container for notifications (bottom right)
    if not self._notifContainer then
        local container = Instance.new("Frame")
        container.Name = "Notifications"
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(0, 250, 1, 0)
        container.Position = UDim2.new(1, -260, 0, 0)
        container.Parent = screenGui

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        layout.Padding = UDim.new(0, 6)
        layout.Parent = container

        local pad = Instance.new("UIPadding")
        pad.PaddingBottom = UDim.new(0, 10)
        pad.Parent = container

        self._notifContainer = container
    end

    local notif = Instance.new("Frame")
    notif.Name = "Notif"
    notif.Size = UDim2.new(1, 0, 0, 0) -- will auto-size
    notif.AutomaticSize = Enum.AutomaticSize.Y
    notif.BackgroundColor3 = COLORS.notifBg
    notif.BackgroundTransparency = 0
    notif.Parent = self._notifContainer
    corner(notif)
    stroke(notif, COLORS.notifBorder, 1)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = notif

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.text
    label.FontFace = FONT
    label.TextSize = FONT_SIZE
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notif

    -- Fade in
    notif.BackgroundTransparency = 1
    label.TextTransparency = 1
    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
    game:GetService("TweenService"):Create(notif, ti, {BackgroundTransparency = 0}):Play()
    game:GetService("TweenService"):Create(label, ti, {TextTransparency = 0}):Play()

    -- Auto remove
    task.delay(duration, function()
        local to = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
        game:GetService("TweenService"):Create(notif, to, {BackgroundTransparency = 1}):Play()
        game:GetService("TweenService"):Create(label, to, {TextTransparency = 1}):Play()
        task.wait(0.35)
        notif:Destroy()
    end)
end

-- ===== CONFIG SYSTEM =====
function Library:_ensureFolder()
    if not isfolder(self._configFolder) then
        makefolder(self._configFolder)
    end
end

function Library:SaveConfig(name)
    self:_ensureFolder()
    local data = {}
    for flag, info in pairs(self._flags) do
        data[flag] = info.value
    end
    writefile(self._configFolder .. "/" .. name .. ".json", game:GetService("HttpService"):JSONEncode(data))
    self:Notify("Config '" .. name .. "' saved!", 2)
end

function Library:LoadConfig(name)
    self:_ensureFolder()
    local path = self._configFolder .. "/" .. name .. ".json"
    if not isfile(path) then
        self:Notify("Config '" .. name .. "' not found!", 3)
        return
    end
    local data = game:GetService("HttpService"):JSONDecode(readfile(path))
    for flag, val in pairs(data) do
        if self._flags[flag] then
            self._flags[flag].set(val)
        end
    end
    self:Notify("Config '" .. name .. "' loaded!", 2)
end

function Library:DeleteConfig(name)
    self:_ensureFolder()
    local path = self._configFolder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
        self:Notify("Config '" .. name .. "' deleted!", 2)
    end
end

function Library:ListConfigs()
    self:_ensureFolder()
    local files = listfiles(self._configFolder)
    local configs = {}
    for _, f in pairs(files) do
        local name = f:match("([^/\\]+)%.json$")
        if name and name ~= "autoload" then
            table.insert(configs, name)
        end
    end
    return configs
end

function Library:SetAutoload(name)
    self:_ensureFolder()
    writefile(self._configFolder .. "/autoload.txt", name)
    self:Notify("Autoload set to '" .. name .. "'", 2)
end

function Library:LoadAutoload()
    self:_ensureFolder()
    local path = self._configFolder .. "/autoload.txt"
    if isfile(path) then
        local name = readfile(path)
        if name and name ~= "" then
            self:LoadConfig(name)
        end
    end
end

-- ===== WINDOW =====
function Library:CreateWindow(title, toggleKey)
    local self = setmetatable({}, Library)
    self._flags = {}
    self._tabs = {}
    self._activeTab = nil
    self._visible = true

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RogueLib_" .. tostring(math.random(100000, 999999))
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    if not screenGui.Parent then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    self._screenGui = screenGui

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = WINDOW_SIZE
    main.Position = UDim2.new(0.5, -260, 0.5, -185)
    main.BackgroundColor3 = COLORS.bg
    main.BorderSizePixel = 0
    main.Parent = screenGui
    corner(main, UDim.new(0, 6))
    stroke(main, COLORS.tabBorder, 1)
    self._main = main

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = COLORS.titleBar
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    corner(titleBar, UDim.new(0, 6))

    -- Bottom corner fix for title bar
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 10)
    titleFix.Position = UDim2.new(0, 0, 1, -10)
    titleFix.BackgroundColor3 = COLORS.titleBar
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "RogueLib"
    titleLabel.TextColor3 = COLORS.text
    titleLabel.FontFace = FONT
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Close / Minimize buttons
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -30, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = COLORS.textDim
    closeBtn.FontFace = FONT
    closeBtn.TextSize = 18
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Minimize"
    minBtn.Size = UDim2.new(0, 26, 0, 26)
    minBtn.Position = UDim2.new(1, -56, 0, 2)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.TextColor3 = COLORS.textDim
    minBtn.FontFace = FONT
    minBtn.TextSize = 14
    minBtn.Parent = titleBar

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            main.Size = UDim2.new(0, WINDOW_SIZE.X.Offset, 0, 30)
        else
            main.Size = WINDOW_SIZE
        end
    end)

    makeDraggable(main, titleBar)

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -8, 0, TAB_HEIGHT)
    tabBar.Position = UDim2.new(0, 4, 0, 32)
    tabBar.BackgroundColor3 = COLORS.tabBarBg
    tabBar.BorderSizePixel = 0
    tabBar.ClipsDescendants = true
    tabBar.Parent = main
    corner(tabBar, UDim.new(0, 4))

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabBar

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 2)
    tabPad.PaddingTop = UDim.new(0, 2)
    tabPad.Parent = tabBar

    self._tabBar = tabBar

    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -8, 1, -TAB_HEIGHT - 38)
    contentArea.Position = UDim2.new(0, 4, 0, TAB_HEIGHT + 36)
    contentArea.BackgroundColor3 = COLORS.content
    contentArea.BorderSizePixel = 0
    contentArea.ClipsDescendants = true
    contentArea.Parent = main
    corner(contentArea, UDim.new(0, 4))
    self._contentArea = contentArea

    -- Toggle keybind
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
    tab._elements = {}

    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 0, 1, -4)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = COLORS.tabInactive
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = self._tabBar
    corner(btn, UDim.new(0, 3))
    stroke(btn, COLORS.tabBorder, 1)

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 12)
    btnPad.PaddingRight = UDim.new(0, 12)
    btnPad.Parent = btn

    local btnLabel = Instance.new("TextLabel")
    btnLabel.Size = UDim2.new(0, 0, 1, 0)
    btnLabel.AutomaticSize = Enum.AutomaticSize.X
    btnLabel.BackgroundTransparency = 1
    btnLabel.Text = name
    btnLabel.TextColor3 = COLORS.text
    btnLabel.FontFace = FONT
    btnLabel.TextSize = FONT_SIZE
    btnLabel.Parent = btn

    tab._button = btn

    -- Content scroll frame
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

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 4)
    contentLayout.Parent = content

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingLeft = UDim.new(0, 6)
    contentPad.PaddingRight = UDim.new(0, 6)
    contentPad.PaddingTop = UDim.new(0, 6)
    contentPad.PaddingBottom = UDim.new(0, 6)
    contentPad.Parent = content

    tab._content = content

    btn.MouseButton1Click:Connect(function()
        self:_switchTab(tab)
    end)

    table.insert(self._tabs, tab)

    -- Auto-select first tab
    if #self._tabs == 1 then
        self:_switchTab(tab)
    end

    return tab
end

-- ===== TOGGLE =====
function Tab:AddToggle(flag, label, default, callback)
    local lib = self._library
    local value = default or false
    callback = callback or function() end

    local frame = Instance.new("Frame")
    frame.Name = "Toggle_" .. flag
    frame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    frame.BackgroundColor3 = COLORS.element
    frame.BorderSizePixel = 0
    frame.Parent = self._content
    corner(frame)
    stroke(frame, COLORS.elementBorder, 1)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -50, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = COLORS.text
    textLabel.FontFace = FONT
    textLabel.TextSize = FONT_SIZE
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(1, -30, 0.5, -9)
    box.BackgroundColor3 = value and COLORS.toggleOn or COLORS.toggleOff
    box.BorderSizePixel = 0
    box.Parent = frame
    corner(box, UDim.new(0, 3))
    stroke(box, COLORS.elementBorder, 1)

    local check = Instance.new("TextLabel")
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Text = value and "✓" or ""
    check.TextColor3 = COLORS.white
    check.FontFace = FONT
    check.TextSize = 12
    check.Parent = box

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    local function setVal(v)
        value = v
        box.BackgroundColor3 = v and COLORS.toggleOn or COLORS.toggleOff
        check.Text = v and "✓" or ""
        callback(v)
    end

    btn.MouseButton1Click:Connect(function()
        setVal(not value)
    end)

    lib._flags[flag] = {
        value = value,
        set = function(v)
            setVal(v)
            lib._flags[flag].value = v
        end
    }

    -- Keep value synced
    local orig_set = lib._flags[flag].set
    lib._flags[flag].set = function(v)
        value = v
        lib._flags[flag].value = v
        box.BackgroundColor3 = v and COLORS.toggleOn or COLORS.toggleOff
        check.Text = v and "✓" or ""
        callback(v)
    end

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
    frame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT + 14)
    frame.BackgroundColor3 = COLORS.element
    frame.BorderSizePixel = 0
    frame.Parent = self._content
    corner(frame)
    stroke(frame, COLORS.elementBorder, 1)

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -60, 0, 18)
    textLabel.Position = UDim2.new(0, 10, 0, 4)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = COLORS.text
    textLabel.FontFace = FONT
    textLabel.TextSize = FONT_SIZE
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 50, 0, 18)
    valLabel.Position = UDim2.new(1, -56, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(value)
    valLabel.TextColor3 = COLORS.textDim
    valLabel.FontFace = FONT
    valLabel.TextSize = FONT_SIZE
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    -- Slider track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -20, 0, 8)
    track.Position = UDim2.new(0, 10, 0, 28)
    track.BackgroundColor3 = COLORS.sliderBg
    track.BorderSizePixel = 0
    track.Parent = frame
    corner(track, UDim.new(0, 4))

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.sliderFill
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, UDim.new(0, 4))

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
        callback(v)
    end

    local dragging = false
    inputBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local absPos = track.AbsolutePosition.X
            local absSize = track.AbsoluteSize.X
            local relative = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
            setVal(min + (max - min) * relative)
        end
    end)

    inputBtn.MouseButton1Click:Connect(function()
        local absPos = track.AbsolutePosition.X
        local absSize = track.AbsoluteSize.X
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        local relative = math.clamp((mouse.X - absPos) / absSize, 0, 1)
        setVal(min + (max - min) * relative)
    end)

    lib._flags[flag] = {
        value = value,
        set = function(v)
            setVal(v)
            lib._flags[flag].value = v
        end
    }

    return frame
end

-- ===== BUTTON =====
function Tab:AddButton(label, callback)
    callback = callback or function() end

    local btn = Instance.new("TextButton")
    btn.Name = "Button_" .. label
    btn.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    btn.BackgroundColor3 = COLORS.element
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = COLORS.text
    btn.FontFace = FONT
    btn.TextSize = FONT_SIZE
    btn.Parent = self._content
    corner(btn)
    stroke(btn, COLORS.elementBorder, 1)

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = COLORS.tabActive
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = COLORS.element
    end)
    btn.MouseButton1Click:Connect(function()
        callback()
    end)

    return btn
end

-- ===== LABEL =====
function Tab:AddLabel(text)
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.textDim
    label.FontFace = FONT
    label.TextSize = FONT_SIZE
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = self._content

    -- Return object with update method
    local obj = {_label = label}
    function obj:Set(newText)
        label.Text = newText
    end
    return obj
end

-- ===== SEPARATOR =====
function Tab:AddSeparator()
    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = COLORS.elementBorder
    sep.BorderSizePixel = 0
    sep.Parent = self._content
    return sep
end

-- ===== CONFIG UI SECTION =====
function Tab:AddConfigSection(lib)
    self:AddSeparator()
    self:AddLabel("— Config —")

    -- Config name input
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "ConfigInput"
    inputFrame.Size = UDim2.new(1, 0, 0, ELEMENT_HEIGHT)
    inputFrame.BackgroundColor3 = COLORS.element
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = self._content
    corner(inputFrame)
    stroke(inputFrame, COLORS.elementBorder, 1)

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 1, 0)
    inputBox.Position = UDim2.new(0, 10, 0, 0)
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

    -- Buttons
    self:AddButton("💾 Save Config", function()
        local name = inputBox.Text
        if name == "" then lib:Notify("Enter a config name!", 2) return end
        lib:SaveConfig(name)
    end)

    self:AddButton("📂 Load Config", function()
        local name = inputBox.Text
        if name == "" then lib:Notify("Enter a config name!", 2) return end
        lib:LoadConfig(name)
    end)

    self:AddButton("🗑 Delete Config", function()
        local name = inputBox.Text
        if name == "" then lib:Notify("Enter a config name!", 2) return end
        lib:DeleteConfig(name)
    end)

    self:AddButton("⭐ Set Autoload", function()
        local name = inputBox.Text
        if name == "" then lib:Notify("Enter a config name!", 2) return end
        lib:SetAutoload(name)
    end)

    self:AddButton("📋 List Configs", function()
        local configs = lib:ListConfigs()
        if #configs == 0 then
            lib:Notify("No configs found!", 2)
        else
            lib:Notify("Configs: " .. table.concat(configs, ", "), 4)
        end
    end)
end

-- ===== DESTROY =====
function Library:Destroy()
    if self._screenGui then
        self._screenGui:Destroy()
    end
end

return Library
