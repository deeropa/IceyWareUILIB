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
    mainBg      = Color3.fromRGB(80, 80, 80),
    contentBg   = Color3.fromRGB(80, 80, 80),
    tabFace     = Color3.fromRGB(65, 65, 65),
    tabActive   = Color3.fromRGB(80, 80, 80),
    tabBorder   = Color3.fromRGB(40, 40, 40),
    border      = Color3.fromRGB(40, 40, 40),
    checkOn     = Color3.fromRGB(60, 60, 60),
    checkOff    = Color3.fromRGB(60, 60, 60),
    checkBorder = Color3.fromRGB(40, 40, 40),
    text        = Color3.fromRGB(220, 220, 220),
    textLight   = Color3.fromRGB(220, 220, 220),
    white       = Color3.fromRGB(255, 255, 255),
    sliderFill  = Color3.fromRGB(45, 45, 45),
    sliderBg    = Color3.fromRGB(45, 45, 45),
    btnFace     = Color3.fromRGB(65, 65, 65),
    accent      = Color3.fromRGB(255, 255, 255),
}

local FONT = Font.fromEnum(Enum.Font.SourceSansBold)
local FONT_R = Font.fromEnum(Enum.Font.SourceSans)
local TS = 14
local CS = 20
local RH = 22
local TH = 26
local CORNER = UDim.new(0, 2)

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
    for f, i in pairs(self._flags) do
        if i.type == "keybind" then
            d[f] = i.value.Name
        elseif i.type == "colorpicker" then
            d[f] = {math.floor(i.value.R * 255), math.floor(i.value.G * 255), math.floor(i.value.B * 255)}
        else
            d[f] = i.value
        end
    end
    writefile(self._configFolder .. "/" .. n .. ".json", HS:JSONEncode(d))
end

function Library:LoadConfig(n)
    self:_ef()
    local p = self._configFolder .. "/" .. n .. ".json"
    if not isfile(p) then return end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(p)) end)
    if not ok then return end
    for f, v in pairs(d) do
        if self._flags[f] then
            if self._flags[f].type == "keybind" and type(v) == "string" then
                local ok2, kc = pcall(function() return Enum.KeyCode[v] end)
                if ok2 then self._flags[f].set(kc) end
            elseif self._flags[f].type == "colorpicker" and type(v) == "table" then
                self._flags[f].set(v)
            else
                self._flags[f].set(v)
            end
        end
    end
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

    -- Tab bar — ScrollingFrame for horizontal overflow
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 6, 0, TH + 12)
    tabBar.Position = UDim2.new(0, -3, 0, 0)
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.ClipsDescendants = true
    tabBar.ScrollBarThickness = 0
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBar.ElasticBehavior = Enum.ElasticBehavior.Never
    tabBar.Parent = wrapper

    local tLayout = Instance.new("UIListLayout")
    tLayout.FillDirection = Enum.FillDirection.Horizontal
    tLayout.Padding = UDim.new(0, 8)
    tLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tLayout.Parent = tabBar

    local tPad = Instance.new("UIPadding")
    tPad.PaddingTop = UDim.new(0, 3)
    tPad.PaddingBottom = UDim.new(0, 3)
    tPad.PaddingLeft = UDim.new(0, 3)
    tPad.PaddingRight = UDim.new(0, 3)
    tPad.Parent = tabBar

    self._tabBar = tabBar



    -- MainFrame — EXACT from Studio export, below tabs with 2px gap
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.BackgroundColor3 = C.mainBg
    main.BorderSizePixel = 0
    main.Position = UDim2.new(0, 0, 0, TH + 12 + 2) -- tab bar height + gap
    main.Size = UDim2.new(1, 0, 0, 300)
    main.Parent = wrapper
    corner(main, UDim.new(0, 1))
    self._main = main

    -- Outer stroke on main frame
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = C.border
    outerStroke.Thickness = 3
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
    corner(content, UDim.new(0, 1))
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
    btn.Size = UDim2.new(0, 0, 0, TH+4)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = C.tabFace
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = self._tabBar
    corner(btn, UDim.new(0, 1))

    local bStroke = Instance.new("UIStroke")
    bStroke.Color = C.tabBorder
    bStroke.Thickness = 3
    bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bStroke.Parent = btn

    local bPad = Instance.new("UIPadding")
    bPad.PaddingLeft = UDim.new(0, 8)
    bPad.PaddingRight = UDim.new(0, 8)
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
    box.Size = UDim2.new(0, 16, 0, 16)
    box.Position = UDim2.new(0, 0, 0.5, -8)
    box.BackgroundColor3 = val and C.checkOn or C.checkOff
    box.BorderSizePixel = 0
    box.Parent = row
    corner(box, UDim.new(0, 1))

    local bxStroke = Instance.new("UIStroke")
    bxStroke.Color = C.checkBorder
    bxStroke.Thickness = 3
    bxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bxStroke.Parent = box

    local mark = Instance.new("TextLabel")
    mark.Size = UDim2.new(1, 0, 1, 0)
    mark.BackgroundTransparency = 1
    mark.Text = val and "✓" or ""
    mark.TextColor3 = C.white
    mark.FontFace = FONT
    mark.TextSize = 14
    mark.Parent = box

    -- Label
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -CS - 10, 1, 0)
    txt.Position = UDim2.new(0, 24, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = 14
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
    lib._flags[flag] = { value = val, set = set, type = "toggle" }
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
    fr.Size = UDim2.new(1, 0, 0, RH)
    fr.BackgroundTransparency = 1
    fr.BorderSizePixel = 0
    fr.Parent = self._content

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0, 150, 1, 0)
    txt.Position = UDim2.new(0, 2, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label .. ": " .. tostring(val)
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = 14
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = fr

    local trk = Instance.new("Frame")
    trk.Size = UDim2.new(1, -160, 0, 5)
    trk.Position = UDim2.new(0, 155, 0.5, -2)
    trk.BackgroundColor3 = C.sliderBg
    trk.BorderSizePixel = 0
    trk.Parent = fr
    corner(trk, UDim.new(0, 4))

    local trkStroke = Instance.new("UIStroke")
    trkStroke.Color = C.border
    trkStroke.Thickness = 3
    trkStroke.Parent = trk

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0)
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.Parent = trk

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 4, 0, 11)
    knob.Position = UDim2.new(fill.Size.X.Scale, -2, 0.5, -5)
    knob.BackgroundColor3 = C.accent
    knob.BorderSizePixel = 0
    knob.Parent = trk
    corner(knob, UDim.new(0, 1))

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
        knob.Position = UDim2.new(fill.Size.X.Scale, -3, 0.5, -7)
        txt.Text = label .. ": " .. tostring(v)
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

    lib._flags[flag] = { value = val, set = set, type = "slider" }
    return fr
end

-- ===== Keybind =====
function Tab:AddKeybind(flag, label, default, onPress, onBind)
    local lib = self._library
    local current = default or Enum.KeyCode.F2
    onPress = onPress or function() end
    onBind = onBind or function() end

    local row = Instance.new("Frame")
    row.Name = "K_" .. flag
    row.Size = UDim2.new(1, 0, 0, RH)
    row.BackgroundTransparency = 1
    row.Parent = self._content

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -70, 1, 0)
    txt.Position = UDim2.new(0, 0, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = TS
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 0, 0, 18)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.BackgroundColor3 = C.btnFace
    btn.Text = current.Name
    btn.TextColor3 = C.text
    btn.FontFace = FONT_R
    btn.TextSize = 13
    btn.Parent = row
    corner(btn, UDim.new(0, 2))

    local bPad = Instance.new("UIPadding")
    bPad.PaddingLeft = UDim.new(0, 6)
    bPad.PaddingRight = UDim.new(0, 6)
    bPad.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.tabBorder
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn

    local binding = false
    btn.MouseButton1Click:Connect(function()
        btn.Text = "..."
        binding = true
    end)

    UIS.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            if binding then
                -- Rebinding mode: assign new key
                current = i.KeyCode
                btn.Text = current.Name
                binding = false
                lib._flags[flag].value = current
                onBind(current)
            elseif i.KeyCode == current then
                -- Gameplay: fire onPress when bound key is pressed
                onPress(current)
            end
        end
    end)

    local function set(v)
        current = v
        btn.Text = v.Name
        lib._flags[flag].value = v
    end

    lib._flags[flag] = { value = current, set = set, type = "keybind" }
    return row
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

-- ===== Text Input =====
function Tab:AddInput(flag, label, default, placeholder, callback)
    local lib = self._library
    default = default or ""
    placeholder = placeholder or ""
    callback = callback or function() end

    local row = Instance.new("Frame")
    row.Name = "I_" .. (flag or label)
    row.Size = UDim2.new(1, 0, 0, RH)
    row.BackgroundTransparency = 1
    row.Parent = self._content

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(0, 120, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = TS
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = row

    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.new(1, -125, 0, 18)
    boxFrame.Position = UDim2.new(0, 125, 0.5, -9)
    boxFrame.BackgroundColor3 = C.btnFace
    boxFrame.BorderSizePixel = 0
    boxFrame.Parent = row
    corner(boxFrame, UDim.new(0, 2))

    local bfStroke = Instance.new("UIStroke")
    bfStroke.Color = C.border
    bfStroke.Thickness = 1
    bfStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bfStroke.Parent = boxFrame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -8, 1, 0)
    input.Position = UDim2.new(0, 4, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = tostring(default)
    input.PlaceholderText = placeholder
    input.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    input.TextColor3 = C.textLight
    input.FontFace = FONT_R
    input.TextSize = 13
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.Parent = boxFrame

    input.FocusLost:Connect(function(enterPressed)
        if flag and lib then lib._flags[flag].value = input.Text end
        callback(input.Text)
    end)

    local obj = {}
    function obj:Set(v)
        input.Text = tostring(v)
        if flag and lib then lib._flags[flag].value = v end
    end
    function obj:Get() return input.Text end

    if flag then
        local function set(v)
            input.Text = tostring(v)
        end
        lib._flags[flag] = { value = default, set = set, type = "input" }
    end

    return obj
end

-- ===== Color Picker =====
function Tab:AddColorpicker(flag, label, default, callback)
    local lib = self._library
    default = default or Color3.fromRGB(255, 255, 255)
    callback = callback or function() end
    local r, g, b = math.floor(default.R * 255), math.floor(default.G * 255), math.floor(default.B * 255)
    local expanded = false

    local container = Instance.new("Frame")
    container.Name = "CP_" .. (flag or label)
    container.Size = UDim2.new(1, 0, 0, RH)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = self._content

    -- Header row
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, RH)
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    header.Parent = container

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -40, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = C.text
    txt.FontFace = FONT
    txt.TextSize = TS
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Parent = header

    -- Color preview box
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 28, 0, 14)
    preview.AnchorPoint = Vector2.new(1, 0.5)
    preview.Position = UDim2.new(1, 0, 0.5, 0)
    preview.BackgroundColor3 = default
    preview.BorderSizePixel = 0
    preview.Parent = header
    corner(preview, UDim.new(0, 2))

    local pvStroke = Instance.new("UIStroke")
    pvStroke.Color = C.border
    pvStroke.Thickness = 1
    pvStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pvStroke.Parent = preview

    -- Expanded panel with RGB sliders
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 0, 66)
    panel.Position = UDim2.new(0, 0, 0, RH + 2)
    panel.BackgroundColor3 = C.btnFace
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = container
    corner(panel, UDim.new(0, 2))

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = C.border
    pStroke.Thickness = 1
    pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    pStroke.Parent = panel

    local function updateColor()
        local c = Color3.fromRGB(r, g, b)
        preview.BackgroundColor3 = c
        if flag and lib then lib._flags[flag].value = c end
        callback(c)
    end

    local function makeChannelSlider(chName, y, val, setVal)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 16, 0, 18)
        lbl.Position = UDim2.new(0, 4, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = chName
        lbl.TextColor3 = C.textLight
        lbl.FontFace = FONT
        lbl.TextSize = 12
        lbl.Parent = panel

        local trk = Instance.new("Frame")
        trk.Size = UDim2.new(1, -70, 0, 5)
        trk.Position = UDim2.new(0, 22, 0, y + 7)
        trk.BackgroundColor3 = C.sliderBg
        trk.BorderSizePixel = 0
        trk.Parent = panel
        corner(trk, UDim.new(0, 3))

        local trkStroke = Instance.new("UIStroke")
        trkStroke.Color = C.border
        trkStroke.Thickness = 1
        trkStroke.Parent = trk

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 4, 0, 11)
        knob.Position = UDim2.new(val / 255, -2, 0.5, -5)
        knob.BackgroundColor3 = C.accent
        knob.BorderSizePixel = 0
        knob.Parent = trk
        corner(knob, UDim.new(0, 1))

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 40, 0, 18)
        valLbl.Position = UDim2.new(1, -44, 0, y)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(val)
        valLbl.TextColor3 = C.textLight
        valLbl.FontFace = FONT_R
        valLbl.TextSize = 12
        valLbl.Parent = panel

        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, 0, 1, 6)
        hit.Position = UDim2.new(0, 0, 0, -3)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Parent = trk

        local drag = false
        hit.MouseButton1Down:Connect(function() drag = true end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UIS.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local ratio = math.clamp((i.Position.X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
                local v = math.floor(ratio * 255 + 0.5)
                setVal(v)
                knob.Position = UDim2.new(v / 255, -2, 0.5, -5)
                valLbl.Text = tostring(v)
                updateColor()
            end
        end)

        return { knob = knob, valLbl = valLbl }
    end

    makeChannelSlider("R", 2, r, function(v) r = v end)
    makeChannelSlider("G", 22, g, function(v) g = v end)
    makeChannelSlider("B", 42, b, function(v) b = v end)

    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        panel.Visible = expanded
    end)

    local obj = {}
    function obj:OnChanged(cb) callback = cb; return obj end
    function obj:SetColor(c)
        r = math.floor(c.R * 255)
        g = math.floor(c.G * 255)
        b = math.floor(c.B * 255)
        updateColor()
    end

    if flag then
        local function set(v)
            if typeof(v) == "table" then
                r = v[1] or 255; g = v[2] or 255; b = v[3] or 255
            end
            updateColor()
        end
        lib._flags[flag] = { value = default, set = set, type = "colorpicker" }
    end

    return obj
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

-- ===== Dropdown =====
function Tab:AddDropdown(flag, label, options, default, callback)
    local lib = self._library
    options = options or {}
    callback = callback or function() end
    local selected = default or (options[1] or "")
    local open = false

    local container = Instance.new("Frame")
    container.Name = "D_" .. (flag or label)
    container.Size = UDim2.new(1, 0, 0, RH)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = false
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = self._content

    -- Header row
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, RH)
    header.BackgroundColor3 = C.btnFace
    header.BorderSizePixel = 0
    header.Text = ""
    header.AutoButtonColor = false
    header.Parent = container
    corner(header)

    local hStroke = Instance.new("UIStroke")
    hStroke.Color = C.tabBorder
    hStroke.Thickness = 1
    hStroke.Parent = header

    local hLabel = Instance.new("TextLabel")
    hLabel.Size = UDim2.new(1, -30, 1, 0)
    hLabel.Position = UDim2.new(0, 6, 0, 0)
    hLabel.BackgroundTransparency = 1
    hLabel.Text = label .. ": " .. tostring(selected)
    hLabel.TextColor3 = C.textLight
    hLabel.FontFace = FONT
    hLabel.TextSize = TS
    hLabel.TextXAlignment = Enum.TextXAlignment.Left
    hLabel.Parent = header

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = C.textLight
    arrow.FontFace = FONT
    arrow.TextSize = 12
    arrow.Parent = header

    -- Options list
    local optList = Instance.new("Frame")
    optList.Name = "Options"
    optList.Size = UDim2.new(1, 0, 0, 0)
    optList.Position = UDim2.new(0, 0, 0, RH + 2)
    optList.BackgroundColor3 = C.btnFace
    optList.BorderSizePixel = 0
    optList.ClipsDescendants = true
    optList.AutomaticSize = Enum.AutomaticSize.Y
    optList.Visible = false
    optList.Parent = container
    corner(optList)

    local olStroke = Instance.new("UIStroke")
    olStroke.Color = C.tabBorder
    olStroke.Thickness = 1
    olStroke.Parent = optList

    local olLayout = Instance.new("UIListLayout")
    olLayout.Padding = UDim.new(0, 0)
    olLayout.SortOrder = Enum.SortOrder.LayoutOrder
    olLayout.Parent = optList

    local function buildOptions(opts)
        for _, child in pairs(optList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for i, opt in ipairs(opts) do
            local ob = Instance.new("TextButton")
            ob.Size = UDim2.new(1, 0, 0, RH)
            ob.BackgroundColor3 = C.btnFace
            ob.BorderSizePixel = 0
            ob.Text = tostring(opt)
            ob.TextColor3 = C.textLight
            ob.FontFace = FONT_R
            ob.TextSize = TS
            ob.AutoButtonColor = false
            ob.LayoutOrder = i
            ob.Parent = optList

            ob.MouseEnter:Connect(function() ob.BackgroundColor3 = C.tabActive end)
            ob.MouseLeave:Connect(function() ob.BackgroundColor3 = C.btnFace end)
            ob.MouseButton1Click:Connect(function()
                selected = opt
                hLabel.Text = label .. ": " .. tostring(opt)
                open = false
                optList.Visible = false
                arrow.Text = "▼"
                if lib and flag then lib._flags[flag].value = selected end
                callback(selected)
            end)
        end
    end

    buildOptions(options)

    header.MouseButton1Click:Connect(function()
        open = not open
        optList.Visible = open
        arrow.Text = open and "▲" or "▼"
    end)

    local obj = { value = selected }
    function obj:Refresh(newOpts)
        options = newOpts or {}
        buildOptions(options)
    end
    function obj:SetSelected(v)
        selected = v
        hLabel.Text = label .. ": " .. tostring(v)
        if lib and flag then lib._flags[flag].value = v end
    end
    function obj:GetSelected()
        return selected
    end

    if flag then
        local function set(v)
            selected = v
            hLabel.Text = label .. ": " .. tostring(v)
        end
        lib._flags[flag] = { value = selected, set = set, type = "dropdown" }
    end

    return obj
end

-- ===== Config Section =====
function Tab:AddConfigSection(lib)
    self:AddSeparator()
    self:AddLabel("Config")

    -- Text input for config name
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

    -- Dropdown to select existing configs
    local configDropdown = self:AddDropdown(nil, "Saved Configs", {}, nil, function(selected)
        ib.Text = selected
    end)

    -- Refresh dropdown when configs might have changed
    local function refreshConfigs()
        local ok, configs = pcall(function() return lib:ListConfigs() end)
        if ok and configs then
            configDropdown:Refresh(configs)
        end
    end

    self:AddButton("Save Config", function()
        local n = ib.Text; if n == "" then return end
        lib:SaveConfig(n)
        refreshConfigs()
    end)
    self:AddButton("Load Config", function()
        local n = ib.Text; if n == "" then return end
        lib:LoadConfig(n)
    end)
    self:AddButton("Delete Config", function()
        local n = ib.Text; if n == "" then return end
        lib:DeleteConfig(n)
        refreshConfigs()
    end)
    self:AddButton("Set Autoload", function()
        local n = ib.Text; if n == "" then return end
        lib:SetAutoload(n)
    end)

    -- Initial refresh
    pcall(refreshConfigs)
end

function Library:Destroy()
    if self._screenGui then self._screenGui:Destroy() end
end

return Library
