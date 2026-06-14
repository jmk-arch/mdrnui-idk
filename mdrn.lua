--!strict
--[[
    CleanUI One File
    Place this file as a LocalScript inside StarterPlayerScripts.

    This is UI-only. It recreates the dark Roblox-style panel from the reference image.
    No exploit, anti-cheat bypass, desync, or server manipulation logic is included.
    Every toggle/slider/checkbox only calls your own callback.

    Usage:
      1. Create a LocalScript in StarterPlayerScripts.
      2. Paste this whole file.
      3. Press Play.
      4. Edit the demo section at the bottom.
]]

---------------------------------------------------------------------
-- Services
---------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- CleanUI table
---------------------------------------------------------------------

local CleanUI = {}
CleanUI.__index = CleanUI
CleanUI.Version = "1.3.0-fade-tabs-header-bind-popup"
CleanUI.IsUiOnly = true

---------------------------------------------------------------------
-- Theme
---------------------------------------------------------------------

CleanUI.Theme = {
    WindowBackground = Color3.fromRGB(8, 9, 10),
    WindowBackground2 = Color3.fromRGB(10, 11, 12),
    Sidebar = Color3.fromRGB(13, 14, 15),
    SidebarStroke = Color3.fromRGB(45, 45, 48),
    Topbar = Color3.fromRGB(10, 10, 11),
    Card = Color3.fromRGB(18, 18, 19),
    Card2 = Color3.fromRGB(24, 24, 25),
    Card3 = Color3.fromRGB(28, 28, 30),
    Stroke = Color3.fromRGB(42, 42, 45),
    StrokeSoft = Color3.fromRGB(32, 32, 35),
    Text = Color3.fromRGB(235, 235, 235),
    TextDim = Color3.fromRGB(190, 190, 190),
    TextMuted = Color3.fromRGB(160, 160, 160),
    TextDark = Color3.fromRGB(32, 32, 33),
    Selected = Color3.fromRGB(66, 66, 67),
    SelectedHover = Color3.fromRGB(76, 76, 78),
    Hover = Color3.fromRGB(34, 34, 36),
    SwitchOff = Color3.fromRGB(105, 105, 105),
    SwitchOn = Color3.fromRGB(178, 178, 178),
    SwitchKnob = Color3.fromRGB(245, 245, 245),
    CheckOff = Color3.fromRGB(125, 125, 125),
    CheckOn = Color3.fromRGB(238, 238, 238),
    SliderTrack = Color3.fromRGB(150, 150, 150),
    SliderFill = Color3.fromRGB(225, 225, 225),
    Green = Color3.fromRGB(105, 170, 82),
    PreviewBox = Color3.fromRGB(103, 104, 105),
    PreviewWhite = Color3.fromRGB(246, 246, 246),
    Transparent = Color3.fromRGB(0, 0, 0),
}

---------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------

CleanUI.Defaults = {
    WindowSize = UDim2.fromOffset(1100, 785),
    WindowPosition = UDim2.fromScale(0.5, 0.5),
    SidebarWidth = 280,
    TopbarHeight = 88,
    WindowCorner = 24,
    CardCorner = 28,
    SmallCorner = 12,
    Font = Enum.Font.Gotham,
    FontMedium = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    AnimationFast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    AnimationNormal = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    AnimationSlow = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    AnimationPage = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    AnimationSoft = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

---------------------------------------------------------------------
-- Utility functions
---------------------------------------------------------------------

local function safeCallback(callback: any, ...)
    if type(callback) ~= "function" then
        return
    end

    local packed = { ... }

    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(packed))
        end)

        if not ok then
            warn("[CleanUI] callback error:", err)
        end
    end)
end

local function tween(instance: Instance, info: TweenInfo?, props: {[string]: any})
    local tw = TweenService:Create(instance, info or CleanUI.Defaults.AnimationNormal, props)
    tw:Play()
    return tw
end

local function create(className: string, properties: {[string]: any}?)
    local inst = Instance.new(className)

    if properties then
        for key, value in pairs(properties) do
            if key ~= "Parent" and key ~= "Children" then
                (inst :: any)[key] = value
            end
        end

        if properties.Children then
            for _, child in ipairs(properties.Children) do
                child.Parent = inst
            end
        end

        if properties.Parent then
            inst.Parent = properties.Parent
        end
    end

    return inst
end

local function addCorner(parent: Instance, radius: number)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    })
end

local function addStroke(parent: Instance, color: Color3?, transparency: number?, thickness: number?)
    return create("UIStroke", {
        Color = color or CleanUI.Theme.Stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        Parent = parent,
    })
end

local function addPadding(parent: Instance, left: number?, right: number?, top: number?, bottom: number?)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent,
    })
end

local function addList(parent: Instance, padding: number?, horizontal: boolean?)
    return create("UIListLayout", {
        FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 0),
        Parent = parent,
    })
end

local function addFlex(parent: Instance)
    return create("UIFlexItem", {
        FlexMode = Enum.UIFlexMode.Fill,
        Parent = parent,
    })
end

local function setZIndexRecursive(root: Instance, baseZ: number)
    pcall(function()
        (root :: any).ZIndex = baseZ
    end)

    for _, descendant in ipairs(root:GetDescendants()) do
        pcall(function()
            (descendant :: any).ZIndex = baseZ + 1
        end)
    end
end

local function getOffsetInside(container: GuiObject, object: GuiObject, extraX: number?, extraY: number?)
    local containerPos = container.AbsolutePosition
    local objectPos = object.AbsolutePosition

    return UDim2.fromOffset(
        objectPos.X - containerPos.X + (extraX or 0),
        objectPos.Y - containerPos.Y + (extraY or 0)
    )
end

local function disconnectConnection(connection: RBXScriptConnection?)
    if connection then
        connection:Disconnect()
    end
end

local function canGroupFade(instance: Instance)
    return pcall(function()
        local _ = (instance :: any).GroupTransparency
    end)
end

local function setGroupFade(instance: Instance, value: number)
    pcall(function()
        (instance :: any).GroupTransparency = value
    end)
end

local function tweenPageGroup(instance: Instance, position: UDim2, transparency: number)
    local props: {[string]: any} = {
        Position = position,
    }

    if canGroupFade(instance) then
        props.GroupTransparency = transparency
    end

    return tween(instance, CleanUI.Defaults.AnimationPage, props)
end

local function formatValue(value: number, step: number?, suffix: string?)
    local text

    if step and step < 1 then
        text = string.format("%.2f", value)
        text = text:gsub("0+$", "")
        text = text:gsub("%.$", "")
    else
        text = tostring(math.floor(value + 0.5))
    end

    return text .. (suffix or "")
end

local function lowerText(text: any)
    return string.lower(tostring(text or ""))
end

local function clamp01(x: number)
    if x < 0 then
        return 0
    end

    if x > 1 then
        return 1
    end

    return x
end

local function roundToStep(value: number, step: number)
    if step <= 0 then
        return value
    end

    return math.floor((value / step) + 0.5) * step
end

local function isTouchInput(input: InputObject)
    return input.UserInputType == Enum.UserInputType.Touch
end

local function isMouseInput(input: InputObject)
    return input.UserInputType == Enum.UserInputType.MouseButton1
end

local function isPointerDown(input: InputObject)
    return isTouchInput(input) or isMouseInput(input)
end

local function isPointerMove(input: InputObject)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function setVisibleByAlpha(guiObject: GuiObject, visible: boolean)
    guiObject.Visible = visible
end

local function getTextSize(text: string, size: number, font: Enum.Font, bounds: Vector2)
    return TextService:GetTextSize(text, size, font, bounds)
end

---------------------------------------------------------------------
-- Maid
---------------------------------------------------------------------

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({
        _items = {},
    }, Maid)
end

function Maid:Give(item: any)
    table.insert(self._items, item)
    return item
end

function Maid:Clean()
    for _, item in ipairs(self._items) do
        local itemType = typeof(item)

        if itemType == "RBXScriptConnection" then
            if item.Connected then
                item:Disconnect()
            end
        elseif itemType == "Instance" then
            if item.Parent then
                item:Destroy()
            end
        elseif type(item) == "function" then
            pcall(item)
        elseif type(item) == "table" and type(item.Destroy) == "function" then
            pcall(function()
                item:Destroy()
            end)
        end
    end

    table.clear(self._items)
end

---------------------------------------------------------------------
-- Component base helpers
---------------------------------------------------------------------

local function buildTextLabel(parent: Instance, text: string, size: number, color: Color3?, font: Enum.Font?, alignment: Enum.TextXAlignment?)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, size + 8),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or CleanUI.Theme.Text,
        TextSize = size,
        Font = font or CleanUI.Defaults.Font,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent,
    })
end

local function buildButtonBase(parent: Instance, text: string)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = CleanUI.Theme.Card2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 18,
        Font = CleanUI.Defaults.FontMedium,
        Parent = parent,
    })

    addCorner(button, CleanUI.Defaults.SmallCorner)
    addStroke(button, CleanUI.Theme.StrokeSoft, 0, 1)

    button.MouseEnter:Connect(function()
        tween(button, CleanUI.Defaults.AnimationFast, {
            BackgroundColor3 = CleanUI.Theme.Hover,
        })
    end)

    button.MouseLeave:Connect(function()
        tween(button, CleanUI.Defaults.AnimationFast, {
            BackgroundColor3 = CleanUI.Theme.Card2,
        })
    end)

    return button
end

local function buildSeparator(parent: Instance)
    return create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = CleanUI.Theme.Stroke,
        BorderSizePixel = 0,
        Parent = parent,
    })
end

---------------------------------------------------------------------
-- Window object
---------------------------------------------------------------------

local Window = {}
Window.__index = Window

function CleanUI:CreateWindow(options: {[string]: any}?)
    options = options or {}

    local screenGui = create("ScreenGui", {
        Name = options.Name or "CleanUI_OneFile",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = PlayerGui,
    })

    local backgroundDim = create("Frame", {
        Name = "BackgroundDim",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Parent = screenGui,
    })

    local main = create("Frame", {
        Name = "MainWindow",
        Size = options.Size or CleanUI.Defaults.WindowSize,
        Position = options.Position or CleanUI.Defaults.WindowPosition,
        AnchorPoint = Vector2.new(0.5, 0.5),
        -- The main rounded frame itself owns the left/sidebar background.
        -- This avoids the common Roblox UICorner issue where a child sidebar
        -- leaks over the parent corner and makes the left edge look square.
        BackgroundColor3 = CleanUI.Theme.Sidebar,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    })

    addCorner(main, CleanUI.Defaults.WindowCorner)
    addStroke(main, Color3.fromRGB(24, 24, 26), 0, 1)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, CleanUI.Defaults.SidebarWidth, 1, 0),
        BackgroundColor3 = CleanUI.Theme.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 3,
        Parent = main,
    })

    -- UICorner does not always mask child frames perfectly, especially on the
    -- outer window edges. The sidebar uses a rounded base for the outside edge
    -- and a small square fill on the inside edge so the left window corners stay clean.
    addCorner(sidebar, CleanUI.Defaults.WindowCorner)

    local sidebarSquareFill = create("Frame", {
        Name = "SidebarSquareFillDisabled",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        Parent = sidebar,
    })

    local sideDivider = create("Frame", {
        Name = "SidebarDivider",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = CleanUI.Theme.SidebarStroke,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = sidebar,
    })

    local modulesTitle = create("TextLabel", {
        Name = "ModulesTitle",
        Size = UDim2.new(1, -52, 0, 34),
        Position = UDim2.fromOffset(26, 38),
        BackgroundTransparency = 1,
        Text = options.Title or "Modules",
        TextColor3 = CleanUI.Theme.TextDim,
        TextSize = 18,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebar,
    })

    local tabsFrame = create("Frame", {
        Name = "Tabs",
        Size = UDim2.new(1, -40, 1, -100),
        Position = UDim2.fromOffset(20, 88),
        BackgroundTransparency = 1,
        Parent = sidebar,
    })

    addList(tabsFrame, 6, false)

    local rightRoundedBase = create("Frame", {
        Name = "RightRoundedBase",
        Size = UDim2.new(1, -CleanUI.Defaults.SidebarWidth, 1, 0),
        Position = UDim2.fromOffset(CleanUI.Defaults.SidebarWidth, 0),
        BackgroundColor3 = CleanUI.Theme.WindowBackground,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = main,
    })

    addCorner(rightRoundedBase, CleanUI.Defaults.WindowCorner)

    local rightInnerSquareFill = create("Frame", {
        Name = "RightInnerSquareFill",
        Size = UDim2.new(0, CleanUI.Defaults.WindowCorner + 8, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = CleanUI.Theme.WindowBackground,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = rightRoundedBase,
    })

    local contentRoot = create("Frame", {
        Name = "ContentRoot",
        Size = UDim2.new(1, -CleanUI.Defaults.SidebarWidth, 1, 0),
        Position = UDim2.fromOffset(CleanUI.Defaults.SidebarWidth, 0),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = main,
    })

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, CleanUI.Defaults.TopbarHeight),
        BackgroundColor3 = CleanUI.Theme.Topbar,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = contentRoot,
    })

    local topDivider = create("Frame", {
        Name = "TopDivider",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CleanUI.Theme.Stroke,
        BorderSizePixel = 0,
        Parent = topbar,
    })

    local configButton = create("TextButton", {
        Name = "SelectConfig",
        Size = UDim2.fromOffset(260, 54),
        Position = UDim2.fromOffset(16, 16),
        BackgroundColor3 = CleanUI.Theme.Card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = topbar,
    })

    addCorner(configButton, 14)
    addStroke(configButton, CleanUI.Theme.Stroke, 0, 1)

    local configText = create("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = "Select Config",
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 20,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = configButton,
    })

    local configArrow = create("TextLabel", {
        Name = "Arrow",
        Size = UDim2.fromOffset(40, 54),
        Position = UDim2.new(1, -44, 0, 0),
        BackgroundTransparency = 1,
        Text = "⌄",
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 32,
        Font = CleanUI.Defaults.FontMedium,
        Parent = configButton,
    })

    local searchBox = create("TextBox", {
        Name = "SearchBox",
        Size = UDim2.fromOffset(260, 54),
        Position = UDim2.new(1, -280, 0, 16),
        BackgroundColor3 = CleanUI.Theme.Card,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Search...",
        TextColor3 = CleanUI.Theme.Text,
        PlaceholderColor3 = CleanUI.Theme.TextMuted,
        TextSize = 20,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = topbar,
    })

    addCorner(searchBox, 14)
    addStroke(searchBox, CleanUI.Theme.Stroke, 0, 1)
    addPadding(searchBox, 16, 16, 0, 0)

    local pages = create("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, 0, 1, -CleanUI.Defaults.TopbarHeight),
        Position = UDim2.fromOffset(0, CleanUI.Defaults.TopbarHeight),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = contentRoot,
    })

    local overlayLayer = create("Frame", {
        Name = "AlwaysOnTopOverlayLayer",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Active = false,
        ZIndex = 200,
        Parent = main,
    })

    local notificationLayer = create("Frame", {
        Name = "NotificationLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Active = false,
        ZIndex = 1000,
        Parent = screenGui,
    })

    local notificationStack = create("Frame", {
        Name = "NotificationStack",
        Size = UDim2.fromOffset(360, 600),
        Position = UDim2.new(1, -24, 1, -24),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1000,
        Parent = notificationLayer,
    })

    local notificationLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = notificationStack,
    })

    local object = setmetatable({
        Gui = screenGui,
        BackgroundDim = backgroundDim,
        Main = main,
        Sidebar = sidebar,
        TabsFrame = tabsFrame,
        ContentRoot = contentRoot,
        Topbar = topbar,
        Pages = pages,
        OverlayLayer = overlayLayer,
        NotificationLayer = notificationLayer,
        NotificationStack = notificationStack,
        NotificationLayout = notificationLayout,
        SearchBox = searchBox,
        ConfigButton = configButton,
        CurrentTab = nil,
        Tabs = {},
        Maid = Maid.new(),
        Visible = true,
        SearchText = "",
    }, Window)

    object:_bindWindowDrag(topbar)
    object:_bindSearch()
    object:_bindConfigDropdown()

    return object
end

function Window:_bindWindowDrag(topbar: GuiObject)
    local dragging = false
    local dragStart = Vector3.zero
    local startPos = self.Main.Position

    self.Maid:Give(topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Main.Position
        end
    end))

    self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart

            self.Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

function Window:_bindSearch()
    self.Maid:Give(self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self.SearchText = lowerText(self.SearchBox.Text)
        self:_applySearch()
    end))
end

function Window:_bindConfigDropdown()
    local dropdownOpen = false

    local menu = create("Frame", {
        Name = "ConfigDropdown",
        Size = UDim2.fromOffset(260, 0),
        Position = UDim2.fromOffset(16, 74),
        BackgroundColor3 = CleanUI.Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 240,
        Parent = self.OverlayLayer,
    })

    addCorner(menu, 14)
    addStroke(menu, CleanUI.Theme.Stroke, 0, 1)
    addPadding(menu, 8, 8, 8, 8)
    addList(menu, 6, false)
    setZIndexRecursive(menu, 240)

    local names = {
        "Default",
        "Legit",
        "Visual Only",
    }

    local function updateMenuPosition()
        menu.Position = getOffsetInside(self.Main, self.ConfigButton, 0, self.ConfigButton.AbsoluteSize.Y + 4)
        menu.Size = UDim2.fromOffset(self.ConfigButton.AbsoluteSize.X, menu.Size.Y.Offset)
    end

    local function closeMenu()
        dropdownOpen = false
        tween(menu, CleanUI.Defaults.AnimationFast, { Size = UDim2.fromOffset(self.ConfigButton.AbsoluteSize.X, 0) })
        task.delay(0.13, function()
            if not dropdownOpen then
                menu.Visible = false
            end
        end)
    end

    for _, name in ipairs(names) do
        local item = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = CleanUI.Theme.Hover,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = name,
            TextColor3 = CleanUI.Theme.Text,
            TextSize = 16,
            Font = CleanUI.Defaults.FontMedium,
            ZIndex = 241,
            Parent = menu,
        })

        addCorner(item, 8)

        item.MouseEnter:Connect(function()
            tween(item, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 0,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            })
        end)

        item.MouseLeave:Connect(function()
            tween(item, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 1,
                TextColor3 = CleanUI.Theme.Text,
            })
        end)

        item.MouseButton1Click:Connect(function()
            local textLabel = self.ConfigButton:FindFirstChild("Text")
            if textLabel and textLabel:IsA("TextLabel") then
                textLabel.Text = name
            end

            closeMenu()
        end)
    end

    self.Maid:Give(self.ConfigButton.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        updateMenuPosition()

        if dropdownOpen then
            menu.Visible = true
            menu.Size = UDim2.fromOffset(self.ConfigButton.AbsoluteSize.X, 0)
            tween(menu, CleanUI.Defaults.AnimationNormal, { Size = UDim2.fromOffset(self.ConfigButton.AbsoluteSize.X, 140) })
        else
            closeMenu()
        end
    end))

    self.Maid:Give(self.Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if dropdownOpen then
            updateMenuPosition()
        end
    end))
end

function Window:Notify(options: {[string]: any}?)
    options = options or {}

    local title = tostring(options.Title or "Notification")
    local content = tostring(options.Content or "")
    local subContent = tostring(options.SubContent or "")
    local duration = options.Duration

    if duration == nil then
        duration = 4
    end

    local card = create("CanvasGroup", {
        Name = "Notification",
        Size = UDim2.fromOffset(340, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = CleanUI.Theme.Card,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 1001,
        Parent = self.NotificationStack,
    })

    addCorner(card, 16)
    addStroke(card, CleanUI.Theme.StrokeSoft, 0, 1)
    addPadding(card, 16, 16, 14, 14)

    local layout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = card,
    })

    local titleLabel = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 18,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1002,
        Parent = card,
    })

    local contentLabel = create("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, content == "" and 0 or 38),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = CleanUI.Theme.TextDim,
        TextSize = 15,
        Font = CleanUI.Defaults.Font,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Visible = content ~= "",
        ZIndex = 1002,
        Parent = card,
    })

    local subLabel = create("TextLabel", {
        Name = "SubContent",
        Size = UDim2.new(1, 0, 0, subContent == "" and 0 or 20),
        BackgroundTransparency = 1,
        Text = subContent,
        TextColor3 = CleanUI.Theme.TextMuted,
        TextSize = 13,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Visible = subContent ~= "",
        ZIndex = 1002,
        Parent = card,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        card.Size = UDim2.fromOffset(340, layout.AbsoluteContentSize.Y + 28)
    end)

    card.Position = UDim2.fromOffset(26, 0)
    tween(card, CleanUI.Defaults.AnimationSoft, {
        GroupTransparency = 0,
        Position = UDim2.fromOffset(0, 0),
    })

    local closed = false
    local function close()
        if closed then
            return
        end

        closed = true
        tween(card, CleanUI.Defaults.AnimationNormal, {
            GroupTransparency = 1,
            Position = UDim2.fromOffset(30, 0),
        })

        task.delay(0.24, function()
            if card then
                card:Destroy()
            end
        end)
    end

    if duration and duration > 0 then
        task.delay(duration, close)
    end

    return {
        Close = close,
        Instance = card,
    }
end

function Window:SetVisible(visible: boolean)
    self.Visible = visible
    self.Gui.Enabled = visible
end

function Window:ToggleVisible()
    self:SetVisible(not self.Visible)
end

function Window:Destroy()
    if self.Maid then
        self.Maid:Clean()
    end

    if self.Gui then
        self.Gui:Destroy()
    end
end

function Window:_applySearch()
    local query = self.SearchText or ""
    local tab = self.CurrentTab

    if not tab then
        return
    end

    for _, section in ipairs(tab.Sections) do
        section:_applySearch(query)
    end
end

function Window:CreateTab(name: string)
    local button = create("TextButton", {
        Name = name .. "TabButton",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = CleanUI.Theme.Selected,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = name,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 19,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TabsFrame,
    })

    addCorner(button, 10)
    addPadding(button, 14, 0, 0, 0)

    local pageGroup = create("CanvasGroup", {
        Name = name .. "PageGroup",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        GroupTransparency = 1,
        Visible = false,
        Parent = self.Pages,
    })

    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
        Visible = true,
        Parent = pageGroup,
    })

    addPadding(page, 26, 26, 22, 24)

    local layout = addList(page, 20, false)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 52)
    end)

    local tab = {
        Window = self,
        Name = name,
        Button = button,
        PageGroup = pageGroup,
        Page = page,
        Layout = layout,
        Sections = {},
        TransitionToken = 0,
    }

    setmetatable(tab, {
        __index = function(_, key)
            return Tab[key]
        end,
    })

    button.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            tween(button, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 0.25,
                BackgroundColor3 = CleanUI.Theme.Hover,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            })
        end
    end)

    button.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            tween(button, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 1,
                TextColor3 = CleanUI.Theme.Text,
            })
        end
    end)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if not self.CurrentTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab: any)
    if not tab or self.CurrentTab == tab then
        return
    end

    local oldTab = self.CurrentTab
    self.CurrentTab = tab

    -- Close floating overlay menus when a tab changes, so dropdowns/keybind popups
    -- never remain visually stuck above the wrong page.
    for _, child in ipairs(self.OverlayLayer:GetChildren()) do
        if child:IsA("GuiObject") and child.Name ~= "ConfigDropdown" then
            child.Visible = false
        end
    end

    for _, other in ipairs(self.Tabs) do
        if other ~= tab and other ~= oldTab then
            other.PageGroup.Visible = false
            other.PageGroup.Position = UDim2.fromOffset(0, 0)
            setGroupFade(other.PageGroup, 1)
            tween(other.Button, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 1,
                BackgroundColor3 = CleanUI.Theme.Hover,
                TextColor3 = CleanUI.Theme.Text,
            })
        end
    end

    if oldTab then
        oldTab.TransitionToken += 1
        local token = oldTab.TransitionToken

        tween(oldTab.Button, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = 1,
            BackgroundColor3 = CleanUI.Theme.Hover,
            TextColor3 = CleanUI.Theme.Text,
        })

        -- Fade only. No side slide, because the old slide could look like
        -- the page was dragging sideways when switching tabs quickly.
        oldTab.PageGroup.Visible = true
        oldTab.PageGroup.Position = UDim2.fromOffset(0, 0)
        tweenPageGroup(oldTab.PageGroup, UDim2.fromOffset(0, 0), 1)

        task.delay(0.24, function()
            if oldTab.TransitionToken == token and self.CurrentTab ~= oldTab then
                oldTab.PageGroup.Visible = false
                oldTab.PageGroup.Position = UDim2.fromOffset(0, 0)
                setGroupFade(oldTab.PageGroup, 1)
            end
        end)
    end

    tab.TransitionToken += 1
    tab.PageGroup.Visible = true
    tab.PageGroup.Position = UDim2.fromOffset(0, 0)
    setGroupFade(tab.PageGroup, oldTab and 1 or 0)

    tab.Button.BackgroundColor3 = CleanUI.Theme.Selected
    tween(tab.Button, CleanUI.Defaults.AnimationSoft, {
        BackgroundTransparency = 0,
        BackgroundColor3 = CleanUI.Theme.Selected,
        TextColor3 = Color3.fromRGB(255, 255, 255),
    })

    tweenPageGroup(tab.PageGroup, UDim2.fromOffset(0, 0), 0)
    self:_applySearch()
end

---------------------------------------------------------------------
-- Tab object
---------------------------------------------------------------------

Tab = {}
Tab.__index = Tab


local function keyDisplayName(inputValue: any): string
    if typeof(inputValue) == "EnumItem" then
        if inputValue == Enum.UserInputType.MouseButton1 then
            return "M1B"
        elseif inputValue == Enum.UserInputType.MouseButton2 then
            return "M2B"
        elseif inputValue == Enum.UserInputType.MouseButton3 then
            return "M3B"
        elseif tostring(inputValue):find("KeyCode") then
            return inputValue.Name
        else
            return inputValue.Name
        end
    end

    return tostring(inputValue or "None")
end

local function inputObjectToBind(input: InputObject): any?
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
            return input.KeyCode
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        return Enum.UserInputType.MouseButton1
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        return Enum.UserInputType.MouseButton2
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
        return Enum.UserInputType.MouseButton3
    end

    return nil
end

local function pointInGui(point: Vector2, gui: GuiObject): boolean
    local pos = gui.AbsolutePosition
    local size = gui.AbsoluteSize

    return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function createHeaderBindMenu(section: any, anchorButton: GuiButton)
    local window = section.Tab.Window
    local overlay = window.OverlayLayer
    local selectedInput: any = Enum.UserInputType.MouseButton1
    local mode = "Hold"
    local listening = false
    local acceptInput = false
    local miniOpen = false
    local menuOpen = false
    local onChangedCallback: any = nil
    local outsideConnections = {}
    local listenConnection: RBXScriptConnection? = nil

    local mini = create("Frame", {
        Name = section.Title .. "HeaderBindMini",
        Size = UDim2.fromOffset(70, 70),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.fromRGB(31, 35, 43),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 300,
        Parent = overlay,
    })

    addCorner(mini, 16)
    addStroke(mini, Color3.fromRGB(40, 46, 55), 0, 1)

    local miniButton = create("TextButton", {
        Name = "OpenBindMenu",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "...",
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 28,
        Font = CleanUI.Defaults.FontBold,
        ZIndex = 301,
        Parent = mini,
    })

    local menu = create("Frame", {
        Name = section.Title .. "HeaderBindMenu",
        Size = UDim2.fromOffset(304, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Color3.fromRGB(17, 22, 29),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 320,
        Parent = overlay,
    })

    addCorner(menu, 14)
    addStroke(menu, Color3.fromRGB(35, 42, 52), 0, 1)
    addPadding(menu, 24, 18, 18, 18)

    local menuLayout = addList(menu, 14, false)

    local topRow = create("Frame", {
        Name = "TopRow",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = 321,
        Parent = menu,
    })

    create("TextLabel", {
        Name = "KeyLabel",
        Size = UDim2.new(0, 86, 1, 0),
        BackgroundTransparency = 1,
        Text = "Key",
        TextColor3 = CleanUI.Theme.TextDim,
        TextSize = 26,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 322,
        Parent = topRow,
    })

    local resetButton = create("TextButton", {
        Name = "ResetButton",
        Size = UDim2.fromOffset(48, 48),
        Position = UDim2.new(0, 96, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "C",
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 25,
        Font = CleanUI.Defaults.FontMedium,
        ZIndex = 322,
        Parent = topRow,
    })

    local keyButton = create("TextButton", {
        Name = "KeyButton",
        Size = UDim2.fromOffset(86, 48),
        Position = UDim2.new(1, -86, 0, 0),
        BackgroundColor3 = Color3.fromRGB(20, 26, 34),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = keyDisplayName(selectedInput),
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 24,
        Font = CleanUI.Defaults.FontMedium,
        ZIndex = 322,
        Parent = topRow,
    })

    addCorner(keyButton, 10)
    addStroke(keyButton, Color3.fromRGB(36, 44, 56), 0, 1)

    local separator = create("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(34, 41, 51),
        BorderSizePixel = 0,
        ZIndex = 321,
        Parent = menu,
    })

    local function makeModeRow(title: string)
        local row = create("TextButton", {
            Name = title .. "ModeRow",
            Size = UDim2.new(1, 0, 0, 46),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 321,
            Parent = menu,
        })

        local circle = create("Frame", {
            Name = "Circle",
            Size = UDim2.fromOffset(34, 34),
            Position = UDim2.fromOffset(0, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 322,
            Parent = row,
        })

        addCorner(circle, 17)
        addStroke(circle, Color3.fromRGB(37, 45, 57), 0, 3)

        local dot = create("Frame", {
            Name = "Dot",
            Size = UDim2.fromOffset(22, 22),
            Position = UDim2.fromOffset(6, 6),
            BackgroundColor3 = Color3.fromRGB(235, 238, 244),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 323,
            Parent = circle,
        })

        addCorner(dot, 11)

        create("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -54, 1, 0),
            Position = UDim2.fromOffset(56, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = CleanUI.Theme.TextDim,
            TextSize = 25,
            Font = CleanUI.Defaults.FontMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 322,
            Parent = row,
        })

        return row, circle, dot
    end

    local toggleRow, toggleCircle, toggleDot = makeModeRow("Toggle")
    local holdRow, holdCircle, holdDot = makeModeRow("Hold")

    local function updateMiniPosition()
        local pos = getOffsetInside(window.Main, anchorButton, -12, -10)
        mini.Position = pos
    end

    local function updateMenuPosition()
        local base = getOffsetInside(window.Main, anchorButton, -280, 40)
        local x = math.max(10, math.min(base.X.Offset, window.Main.AbsoluteSize.X - 324))
        local y = math.max(10, math.min(base.Y.Offset, window.Main.AbsoluteSize.Y - 232))
        menu.Position = UDim2.fromOffset(x, y)
    end

    local function fireChanged()
        safeCallback(onChangedCallback, selectedInput, mode)
    end

    local function repaintModes()
        local isToggle = mode == "Toggle"

        tween(toggleCircle, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = isToggle and 0.1 or 1,
        })
        tween(toggleDot, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = isToggle and 0 or 1,
        })
        tween(holdCircle, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = (not isToggle) and 0.1 or 1,
        })
        tween(holdDot, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = (not isToggle) and 0 or 1,
        })
    end

    local function clearOutsideConnections()
        for _, connection in ipairs(outsideConnections) do
            disconnectConnection(connection)
        end
        table.clear(outsideConnections)
    end

    local function closeMini()
        if not miniOpen then
            return
        end

        miniOpen = false
        tween(mini, CleanUI.Defaults.AnimationFast, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(58, 58),
        })

        task.delay(0.13, function()
            if not miniOpen then
                mini.Visible = false
                mini.Size = UDim2.fromOffset(70, 70)
            end
        end)
    end

    local function closeMenu()
        if not menuOpen then
            return
        end

        menuOpen = false
        listening = false
        acceptInput = false
        keyButton.Text = keyDisplayName(selectedInput)
        clearOutsideConnections()
        tween(menu, CleanUI.Defaults.AnimationFast, {
            Size = UDim2.fromOffset(304, 0),
        })

        task.delay(0.14, function()
            if not menuOpen then
                menu.Visible = false
            end
        end)
    end

    local function openMini()
        closeMenu()
        updateMiniPosition()
        miniOpen = true
        mini.Visible = true
        mini.Size = UDim2.fromOffset(58, 58)
        mini.BackgroundTransparency = 1
        setZIndexRecursive(mini, 300)

        tween(mini, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(70, 70),
        })

        clearOutsideConnections()
        task.delay(0.04, function()
            if not miniOpen then
                return
            end

            table.insert(outsideConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                local mouse = UserInputService:GetMouseLocation()
                if not pointInGui(mouse, mini) and not pointInGui(mouse, anchorButton) then
                    closeMini()
                end
            end))
        end)
    end

    local function openMenu()
        closeMini()
        updateMenuPosition()
        menuOpen = true
        menu.Visible = true
        menu.Size = UDim2.fromOffset(304, 0)
        setZIndexRecursive(menu, 320)
        repaintModes()

        tween(menu, CleanUI.Defaults.AnimationNormal, {
            Size = UDim2.fromOffset(304, 218),
        })

        clearOutsideConnections()
        task.delay(0.04, function()
            if not menuOpen then
                return
            end

            table.insert(outsideConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                    return
                end

                local mouse = UserInputService:GetMouseLocation()
                if not pointInGui(mouse, menu) and not pointInGui(mouse, anchorButton) and not pointInGui(mouse, mini) then
                    closeMenu()
                end
            end))
        end)
    end

    local hoverTicket = 0

    local function cancelHoverClose()
        hoverTicket += 1
    end

    local function scheduleMiniHoverClose()
        hoverTicket += 1
        local currentTicket = hoverTicket

        task.delay(0.12, function()
            if currentTicket ~= hoverTicket then
                return
            end

            if menuOpen then
                return
            end

            local mouse = UserInputService:GetMouseLocation()
            if pointInGui(mouse, anchorButton) or (mini.Visible and pointInGui(mouse, mini)) then
                return
            end

            closeMini()
            tween(anchorButton, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 1,
            })
        end)
    end

    anchorButton.MouseEnter:Connect(function()
        cancelHoverClose()
        tween(anchorButton, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(31, 35, 43),
        })

        if not menuOpen then
            openMini()
        end
    end)

    anchorButton.MouseLeave:Connect(function()
        scheduleMiniHoverClose()
    end)

    mini.MouseEnter:Connect(function()
        cancelHoverClose()
        tween(anchorButton, CleanUI.Defaults.AnimationSoft, {
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(31, 35, 43),
        })
    end)

    mini.MouseLeave:Connect(function()
        scheduleMiniHoverClose()
    end)

    miniButton.MouseButton1Click:Connect(function()
        openMenu()
    end)

    keyButton.MouseEnter:Connect(function()
        tween(keyButton, CleanUI.Defaults.AnimationSoft, { BackgroundColor3 = Color3.fromRGB(25, 32, 42) })
    end)

    keyButton.MouseLeave:Connect(function()
        tween(keyButton, CleanUI.Defaults.AnimationSoft, { BackgroundColor3 = Color3.fromRGB(20, 26, 34) })
    end)

    keyButton.MouseButton1Click:Connect(function()
        listening = true
        acceptInput = false
        keyButton.Text = "..."

        task.delay(0.12, function()
            if listening then
                acceptInput = true
            end
        end)
    end)

    resetButton.MouseButton1Click:Connect(function()
        selectedInput = Enum.UserInputType.MouseButton1
        keyButton.Text = keyDisplayName(selectedInput)
        fireChanged()
    end)

    toggleRow.MouseButton1Click:Connect(function()
        mode = "Toggle"
        repaintModes()
        fireChanged()
    end)

    holdRow.MouseButton1Click:Connect(function()
        mode = "Hold"
        repaintModes()
        fireChanged()
    end)

    listenConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not listening or not acceptInput then
            return
        end

        local bindValue = inputObjectToBind(input)
        if not bindValue then
            return
        end

        selectedInput = bindValue
        listening = false
        acceptInput = false
        keyButton.Text = keyDisplayName(selectedInput)
        fireChanged()
    end)

    window.Maid:Give(listenConnection)
    window.Maid:Give(window.Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if miniOpen then
            updateMiniPosition()
        end

        if menuOpen then
            updateMenuPosition()
        end
    end))

    window.Maid:Give(window.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if miniOpen then
            updateMiniPosition()
        end

        if menuOpen then
            updateMenuPosition()
        end
    end))

    section.Bind = {
        Set = function(_, inputValue: any, newMode: string?)
            selectedInput = inputValue or selectedInput
            if newMode == "Toggle" or newMode == "Hold" then
                mode = newMode
            end
            keyButton.Text = keyDisplayName(selectedInput)
            repaintModes()
            fireChanged()
        end,
        Get = function()
            return selectedInput, mode
        end,
        OnChanged = function(_, callback: any)
            onChangedCallback = callback
        end,
    }

    repaintModes()
end

function Tab:AddSection(title: string, description: string?)
    local card = create("Frame", {
        Name = title .. "Section",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = CleanUI.Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = self.Page,
    })

    addCorner(card, CleanUI.Defaults.CardCorner)
    addStroke(card, CleanUI.Theme.StrokeSoft, 0, 1)
    addPadding(card, 28, 28, 24, 28)

    local layout = addList(card, 14, false)

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, description and 74 or 42),
        BackgroundTransparency = 1,
        Parent = card,
    })

    local titleLabel = create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -90, 0, 32),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 25,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local descriptionLabel

    if description and description ~= "" then
        descriptionLabel = create("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -90, 0, 46),
            Position = UDim2.fromOffset(0, 32),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = CleanUI.Theme.TextDim,
            TextSize = 19,
            Font = CleanUI.Defaults.Font,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = header,
        })
    end

    local menuDots = create("TextButton", {
        Name = "BindDots",
        Size = UDim2.fromOffset(48, 34),
        Position = UDim2.new(1, -70, 0, -2),
        BackgroundColor3 = CleanUI.Theme.Card3,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "...",
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 24,
        Font = CleanUI.Defaults.FontBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = header,
    })

    addCorner(menuDots, 12)

    local separator = buildSeparator(card)

    local section = {
        Tab = self,
        Card = card,
        Header = header,
        Layout = layout,
        Title = title,
        Description = description or "",
        SearchText = lowerText(title .. " " .. (description or "")),
        Rows = {},
        RowMap = {},
    }

    setmetatable(section, {
        __index = function(_, key)
            return Section[key]
        end,
    })

    createHeaderBindMenu(section, menuDots)

    table.insert(self.Sections, section)

    self.Window:_applySearch()

    return section
end

function Tab:AddCompactSection()
    local card = create("Frame", {
        Name = "CompactSection",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = CleanUI.Theme.Card,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = self.Page,
    })

    addCorner(card, CleanUI.Defaults.CardCorner)
    addStroke(card, CleanUI.Theme.StrokeSoft, 0, 1)
    addPadding(card, 28, 28, 10, 24)

    local layout = addList(card, 5, false)

    local section = {
        Tab = self,
        Card = card,
        Header = nil,
        Layout = layout,
        Title = "",
        Description = "",
        SearchText = "",
        Rows = {},
        RowMap = {},
    }

    setmetatable(section, {
        __index = function(_, key)
            return Section[key]
        end,
    })

    table.insert(self.Sections, section)

    self.Window:_applySearch()

    return section
end

---------------------------------------------------------------------
-- Section object
---------------------------------------------------------------------

Section = {}
Section.__index = Section

function Section:_registerRow(row: GuiObject, searchText: string)
    row:SetAttribute("SearchText", lowerText(searchText))
    table.insert(self.Rows, row)
    return row
end

function Section:_applySearch(query: string)
    if query == "" then
        self.Card.Visible = true

        for _, row in ipairs(self.Rows) do
            row.Visible = true
        end

        return
    end

    local sectionMatch = string.find(self.SearchText, query, 1, true) ~= nil
    local anyRow = false

    for _, row in ipairs(self.Rows) do
        local rowText = lowerText(row:GetAttribute("SearchText"))
        local rowMatch = sectionMatch or string.find(rowText, query, 1, true) ~= nil
        row.Visible = rowMatch

        if rowMatch then
            anyRow = true
        end
    end

    self.Card.Visible = sectionMatch or anyRow
end

function Section:AddLabel(text: string)
    local row = create("Frame", {
        Name = "LabelRow",
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    create("TextLabel", {
        Name = "Text",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.TextDim,
        TextSize = 18,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    self:_registerRow(row, text)
    return row
end

function Section:AddSeparator()
    local sep = buildSeparator(self.Card)
    self:_registerRow(sep, "separator")
    return sep
end

function Section:AddButton(text: string, callback: any)
    local button = buildButtonBase(self.Card, text)

    button.MouseButton1Click:Connect(function()
        safeCallback(callback)
    end)

    self:_registerRow(button, text)
    return button
end

function Section:AddToggle(text: string, defaultValue: boolean?, callback: any)
    local state = defaultValue == true

    local row = create("Frame", {
        Name = text .. "ToggleRow",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    local label = create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -92, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 20,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local switch = create("TextButton", {
        Name = "Switch",
        Size = UDim2.fromOffset(64, 34),
        Position = UDim2.new(1, -64, 0.5, -17),
        BackgroundColor3 = CleanUI.Theme.SwitchOff,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })

    addCorner(switch, 17)

    local knob = create("Frame", {
        Name = "Knob",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = CleanUI.Theme.SwitchKnob,
        BorderSizePixel = 0,
        Parent = switch,
    })

    addCorner(knob, 14)

    local function repaint(instant: boolean?)
        local switchColor = state and CleanUI.Theme.SwitchOn or CleanUI.Theme.SwitchOff
        local knobPos = state and UDim2.new(1, -31, 0, 3) or UDim2.fromOffset(3, 3)

        if instant then
            switch.BackgroundColor3 = switchColor
            knob.Position = knobPos
        else
            tween(switch, CleanUI.Defaults.AnimationSoft, { BackgroundColor3 = switchColor })
            tween(knob, CleanUI.Defaults.AnimationSoft, { Position = knobPos })
        end
    end

    local function set(value: boolean, call: boolean?)
        state = value == true
        repaint(false)

        if call ~= false then
            safeCallback(callback, state)
        end
    end

    switch.MouseButton1Click:Connect(function()
        set(not state, true)
    end)

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            set(not state, true)
        end
    end)

    repaint(true)
    self:_registerRow(row, text)

    local api = {}

    function api:Set(value: boolean)
        set(value, true)
    end

    function api:Get()
        return state
    end

    function api:SilentSet(value: boolean)
        set(value, false)
    end

    return api
end

function Section:AddCheckbox(text: string, defaultValue: boolean?, callback: any)
    local state = defaultValue == true

    local row = create("Frame", {
        Name = text .. "CheckboxRow",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    local box = create("TextButton", {
        Name = "Box",
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.fromOffset(0, 7),
        BackgroundColor3 = state and CleanUI.Theme.CheckOn or CleanUI.Theme.CheckOff,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = state and "✓" or "",
        TextColor3 = CleanUI.Theme.TextDark,
        TextSize = 24,
        Font = CleanUI.Defaults.FontBold,
        Parent = row,
    })

    addCorner(box, 7)

    local label = create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -46, 1, 0),
        Position = UDim2.fromOffset(48, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 20,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local function repaint()
        box.Text = state and "✓" or ""
        tween(box, CleanUI.Defaults.AnimationFast, {
            BackgroundColor3 = state and CleanUI.Theme.CheckOn or CleanUI.Theme.CheckOff,
        })
    end

    local function set(value: boolean, call: boolean?)
        state = value == true
        repaint()

        if call ~= false then
            safeCallback(callback, state)
        end
    end

    box.MouseButton1Click:Connect(function()
        set(not state, true)
    end)

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            set(not state, true)
        end
    end)

    self:_registerRow(row, text)

    local api = {}

    function api:Set(value: boolean)
        set(value, true)
    end

    function api:Get()
        return state
    end

    function api:SilentSet(value: boolean)
        set(value, false)
    end

    return api
end

function Section:AddSlider(text: string, minValue: number, maxValue: number, defaultValue: number?, suffix: string?, step: number?, callback: any)
    minValue = minValue or 0
    maxValue = maxValue or 100
    step = step or 1
    suffix = suffix or ""

    local value = math.clamp(defaultValue or minValue, minValue, maxValue)

    local row = create("Frame", {
        Name = text .. "SliderRow",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    local label = create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.56, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 20,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local valueLabel = create("TextLabel", {
        Name = "Value",
        Size = UDim2.fromOffset(78, 48),
        Position = UDim2.new(1, -318, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 18,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local bar = create("Frame", {
        Name = "Bar",
        Size = UDim2.fromOffset(240, 6),
        Position = UDim2.new(1, -240, 0.5, -3),
        BackgroundColor3 = CleanUI.Theme.SliderTrack,
        BorderSizePixel = 0,
        Parent = row,
    })

    addCorner(bar, 3)

    local fill = create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CleanUI.Theme.SliderFill,
        BorderSizePixel = 0,
        Parent = bar,
    })

    addCorner(fill, 3)

    local knob = create("Frame", {
        Name = "Knob",
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(0, -12, 0.5, -12),
        BackgroundColor3 = CleanUI.Theme.SwitchKnob,
        BorderSizePixel = 0,
        Parent = bar,
    })

    addCorner(knob, 12)
    addStroke(knob, Color3.fromRGB(87, 87, 90), 0, 1)

    local dragging = false

    local function setSliderHover(isHovering: boolean)
        if dragging then
            return
        end

        tween(knob, CleanUI.Defaults.AnimationSoft, {
            Size = isHovering and UDim2.fromOffset(28, 28) or UDim2.fromOffset(24, 24),
        })
    end

    bar.MouseEnter:Connect(function()
        setSliderHover(true)
    end)

    bar.MouseLeave:Connect(function()
        setSliderHover(false)
    end)

    knob.MouseEnter:Connect(function()
        setSliderHover(true)
    end)

    knob.MouseLeave:Connect(function()
        setSliderHover(false)
    end)

    local function percentFromValue(v: number)
        if maxValue == minValue then
            return 0
        end

        return clamp01((v - minValue) / (maxValue - minValue))
    end

    local function applyValue(newValue: number, call: boolean?)
        newValue = roundToStep(newValue, step)
        newValue = math.clamp(newValue, minValue, maxValue)
        value = newValue

        local percent = percentFromValue(value)
        valueLabel.Text = formatValue(value, step, suffix)

        local targetFill = UDim2.new(percent, 0, 1, 0)
        local targetKnob = UDim2.new(percent, -12, 0.5, -12)

        if dragging then
            tween(fill, TweenInfo.new(0.075, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = targetFill })
            tween(knob, TweenInfo.new(0.075, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Position = targetKnob })
        else
            tween(fill, CleanUI.Defaults.AnimationSoft, { Size = targetFill })
            tween(knob, CleanUI.Defaults.AnimationSoft, { Position = targetKnob })
        end

        if call ~= false then
            safeCallback(callback, value)
        end
    end

    local function valueFromX(x: number)
        local absX = bar.AbsolutePosition.X
        local absW = bar.AbsoluteSize.X
        local percent = clamp01((x - absX) / absW)
        return minValue + ((maxValue - minValue) * percent)
    end

    bar.InputBegan:Connect(function(input)
        if isPointerDown(input) then
            dragging = true
            tween(knob, CleanUI.Defaults.AnimationFast, { Size = UDim2.fromOffset(30, 30) })
            applyValue(valueFromX(input.Position.X), true)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if isPointerDown(input) then
            dragging = true
            tween(knob, CleanUI.Defaults.AnimationFast, { Size = UDim2.fromOffset(30, 30) })
            applyValue(valueFromX(input.Position.X), true)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and isPointerMove(input) then
            applyValue(valueFromX(input.Position.X), true)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            tween(knob, CleanUI.Defaults.AnimationSoft, { Size = UDim2.fromOffset(24, 24) })
        end
    end)

    applyValue(value, false)
    self:_registerRow(row, text)

    local api = {}

    function api:Set(newValue: number)
        applyValue(newValue, true)
    end

    function api:SilentSet(newValue: number)
        applyValue(newValue, false)
    end

    function api:Get()
        return value
    end

    return api
end

function Section:AddTextbox(text: string, placeholder: string?, defaultText: string?, callback: any)
    local row = create("Frame", {
        Name = text .. "TextboxRow",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    local label = create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.42, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 19,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local box = create("TextBox", {
        Name = "Input",
        Size = UDim2.new(0.58, 0, 0, 40),
        Position = UDim2.new(0.42, 0, 0.5, -20),
        BackgroundColor3 = CleanUI.Theme.Card2,
        BorderSizePixel = 0,
        Text = defaultText or "",
        PlaceholderText = placeholder or "",
        TextColor3 = CleanUI.Theme.Text,
        PlaceholderColor3 = CleanUI.Theme.TextMuted,
        TextSize = 17,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = row,
    })

    addCorner(box, 10)
    addStroke(box, CleanUI.Theme.StrokeSoft, 0, 1)
    addPadding(box, 12, 12, 0, 0)

    box.Focused:Connect(function()
        tween(box, CleanUI.Defaults.AnimationFast, { BackgroundColor3 = CleanUI.Theme.Card3 })
    end)

    box.FocusLost:Connect(function()
        tween(box, CleanUI.Defaults.AnimationFast, { BackgroundColor3 = CleanUI.Theme.Card2 })
        safeCallback(callback, box.Text)
    end)

    self:_registerRow(row, text .. " " .. (placeholder or ""))

    local api = {}

    function api:Set(value: string)
        box.Text = value
        safeCallback(callback, box.Text)
    end

    function api:SilentSet(value: string)
        box.Text = value
    end

    function api:Get()
        return box.Text
    end

    return api
end

function Section:AddDropdown(text: string, items: {string}, defaultItem: string?, callback: any)
    local selected = defaultItem or items[1] or ""
    local open = false
    local maxVisibleItems = 6
    local itemHeight = 34
    local menuPadding = 12
    local activeConnections = {}

    local row = create("Frame", {
        Name = text .. "DropdownRow",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    local label = create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.42, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 19,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local button = create("TextButton", {
        Name = "Button",
        Size = UDim2.new(0.58, 0, 0, 40),
        Position = UDim2.new(0.42, 0, 0.5, -20),
        BackgroundColor3 = CleanUI.Theme.Card2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })

    addCorner(button, 10)
    addStroke(button, CleanUI.Theme.StrokeSoft, 0, 1)

    local valueLabel = create("TextLabel", {
        Name = "Value",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = selected,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 17,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button,
    })

    local arrow = create("TextLabel", {
        Name = "Arrow",
        Size = UDim2.fromOffset(36, 40),
        Position = UDim2.new(1, -40, 0, 0),
        BackgroundTransparency = 1,
        Text = "⌄",
        TextColor3 = CleanUI.Theme.TextDim,
        TextSize = 25,
        Font = CleanUI.Defaults.FontMedium,
        Parent = button,
    })

    local overlay = self.Tab.Window.OverlayLayer
    local menu = create("Frame", {
        Name = text .. "DropdownMenu",
        Size = UDim2.fromOffset(220, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = CleanUI.Theme.Card2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 260,
        Parent = overlay,
    })

    addCorner(menu, 10)
    addStroke(menu, CleanUI.Theme.StrokeSoft, 0, 1)

    local scroller = create("ScrollingFrame", {
        Name = "Items",
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.fromOffset(6, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = #items > maxVisibleItems and 3 or 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ClipsDescendants = true,
        ZIndex = 261,
        Parent = menu,
    })

    local list = addList(scroller, 4, false)

    local function menuHeight()
        return math.min(#items, maxVisibleItems) * (itemHeight + 4) + menuPadding
    end

    local function updateMenuPosition()
        local width = button.AbsoluteSize.X
        menu.Position = getOffsetInside(self.Tab.Window.Main, button, 0, button.AbsoluteSize.Y + 6)
        menu.Size = UDim2.fromOffset(width, menu.Size.Y.Offset)
        scroller.Size = UDim2.new(1, -12, 1, -12)
    end

    local function clearOutsideConnections()
        for _, connection in ipairs(activeConnections) do
            disconnectConnection(connection)
        end
        table.clear(activeConnections)
    end

    local function closeMenu()
        if not open then
            return
        end

        open = false
        clearOutsideConnections()
        tween(arrow, CleanUI.Defaults.AnimationSoft, { Rotation = 0 })
        tween(button, CleanUI.Defaults.AnimationSoft, { BackgroundColor3 = CleanUI.Theme.Card2 })
        tween(menu, CleanUI.Defaults.AnimationFast, { Size = UDim2.fromOffset(button.AbsoluteSize.X, 0) })

        task.delay(0.14, function()
            if not open then
                menu.Visible = false
            end
        end)
    end

    for _, itemText in ipairs(items) do
        local item = create("TextButton", {
            Size = UDim2.new(1, 0, 0, itemHeight),
            BackgroundColor3 = CleanUI.Theme.Hover,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = itemText,
            TextColor3 = CleanUI.Theme.Text,
            TextSize = 16,
            Font = CleanUI.Defaults.Font,
            ZIndex = 262,
            Parent = scroller,
        })

        addCorner(item, 8)

        item.MouseEnter:Connect(function()
            tween(item, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 0,
                TextColor3 = Color3.fromRGB(255, 255, 255),
            })
        end)

        item.MouseLeave:Connect(function()
            tween(item, CleanUI.Defaults.AnimationSoft, {
                BackgroundTransparency = 1,
                TextColor3 = CleanUI.Theme.Text,
            })
        end)

        item.MouseButton1Click:Connect(function()
            selected = itemText
            valueLabel.Text = selected
            closeMenu()
            safeCallback(callback, selected)
        end)
    end

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroller.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 6)
    end)

    button.MouseEnter:Connect(function()
        if not open then
            tween(button, CleanUI.Defaults.AnimationSoft, { BackgroundColor3 = CleanUI.Theme.Card3 })
        end
    end)

    button.MouseLeave:Connect(function()
        if not open then
            tween(button, CleanUI.Defaults.AnimationSoft, { BackgroundColor3 = CleanUI.Theme.Card2 })
        end
    end)

    button.MouseButton1Click:Connect(function()
        open = not open
        updateMenuPosition()

        if open then
            menu.Visible = true
            menu.Size = UDim2.fromOffset(button.AbsoluteSize.X, 0)
            setZIndexRecursive(menu, 260)
            tween(arrow, CleanUI.Defaults.AnimationSoft, { Rotation = 180 })
            tween(button, CleanUI.Defaults.AnimationSoft, { BackgroundColor3 = CleanUI.Theme.Card3 })
            tween(menu, CleanUI.Defaults.AnimationNormal, { Size = UDim2.fromOffset(button.AbsoluteSize.X, menuHeight()) })

            table.insert(activeConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then
                    return
                end

                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mouse = UserInputService:GetMouseLocation()
                    local menuPos = menu.AbsolutePosition
                    local menuSize = menu.AbsoluteSize
                    local buttonPos = button.AbsolutePosition
                    local buttonSize = button.AbsoluteSize

                    local inMenu = mouse.X >= menuPos.X and mouse.X <= menuPos.X + menuSize.X and mouse.Y >= menuPos.Y and mouse.Y <= menuPos.Y + menuSize.Y
                    local inButton = mouse.X >= buttonPos.X and mouse.X <= buttonPos.X + buttonSize.X and mouse.Y >= buttonPos.Y and mouse.Y <= buttonPos.Y + buttonSize.Y

                    if not inMenu and not inButton then
                        closeMenu()
                    end
                end
            end))
        else
            closeMenu()
        end
    end)

    self.Tab.Window.Maid:Give(self.Tab.Window.Main:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        if open then
            updateMenuPosition()
        end
    end))

    self.Tab.Window.Maid:Give(self.Tab.Window.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if open then
            updateMenuPosition()
        end
    end))

    self:_registerRow(row, text .. " " .. table.concat(items, " "))

    local api = {}

    function api:Set(value: string)
        selected = value
        valueLabel.Text = value
        safeCallback(callback, selected)
    end

    function api:SilentSet(value: string)
        selected = value
        valueLabel.Text = value
    end

    function api:Get()
        return selected
    end

    function api:Close()
        closeMenu()
    end

    return api
end

function Section:AddNametagPreview(options: {[string]: any}?)
    options = options or {}

    local row = create("Frame", {
        Name = "NametagPreviewRow",
        Size = UDim2.new(1, 0, 0, 126),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    local left = create("Frame", {
        Name = "LeftControls",
        Size = UDim2.new(0.52, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = row,
    })

    local right = create("Frame", {
        Name = "RightPreview",
        Size = UDim2.new(0.36, 0, 1, 0),
        Position = UDim2.new(0.64, 0, 0, 0),
        BackgroundColor3 = CleanUI.Theme.PreviewBox,
        BorderSizePixel = 0,
        Parent = row,
    })

    addCorner(right, 12)

    local tag = create("Frame", {
        Name = "Tag",
        Size = UDim2.fromOffset(218, 48),
        Position = UDim2.new(0.5, -109, 0.5, -24),
        BackgroundColor3 = CleanUI.Theme.PreviewWhite,
        BorderSizePixel = 0,
        Parent = right,
    })

    addCorner(tag, 9)

    local nameLabel = create("TextLabel", {
        Name = "Name",
        Size = UDim2.fromOffset(135, 48),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = options.NameText or "CyberHunter",
        TextColor3 = Color3.fromRGB(35, 35, 38),
        TextSize = 20,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tag,
    })

    local healthLabel = create("TextLabel", {
        Name = "Health",
        Size = UDim2.fromOffset(70, 48),
        Position = UDim2.new(1, -78, 0, 0),
        BackgroundTransparency = 1,
        Text = options.HealthText or "17.337",
        TextColor3 = CleanUI.Theme.Green,
        TextSize = 19,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tag,
    })

    local pointer = create("TextLabel", {
        Name = "Pointer",
        Size = UDim2.fromOffset(28, 24),
        Position = UDim2.new(0.5, -14, 1, -5),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = CleanUI.Theme.PreviewWhite,
        TextSize = 26,
        Font = CleanUI.Defaults.FontBold,
        Parent = tag,
    })

    self:_registerRow(row, "nametag preview cyberhunter health distance decimal")

    return {
        Row = row,
        Left = left,
        Right = right,
        NameLabel = nameLabel,
        HealthLabel = healthLabel,
        SetName = function(_, value: string)
            nameLabel.Text = value
        end,
        SetHealth = function(_, value: string)
            healthLabel.Text = value
        end,
    }
end

function Section:AddInlineNametagSettings(callbacks: {[string]: any}?)
    callbacks = callbacks or {}

    local row = create("Frame", {
        Name = "InlineNametagSettings",
        Size = UDim2.new(1, 0, 0, 126),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    local left = create("Frame", {
        Name = "Left",
        Size = UDim2.new(0.54, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = row,
    })

    local leftLayout = addList(left, 8, false)

    local right = create("Frame", {
        Name = "Right",
        Size = UDim2.new(0.35, 0, 1, 0),
        Position = UDim2.new(0.65, 0, 0, 0),
        BackgroundColor3 = CleanUI.Theme.PreviewBox,
        BorderSizePixel = 0,
        Parent = row,
    })

    addCorner(right, 12)

    local tag = create("Frame", {
        Name = "Tag",
        Size = UDim2.fromOffset(218, 48),
        Position = UDim2.new(0.5, -109, 0.5, -24),
        BackgroundColor3 = CleanUI.Theme.PreviewWhite,
        BorderSizePixel = 0,
        Parent = right,
    })

    addCorner(tag, 9)

    local nameLabel = create("TextLabel", {
        Name = "Name",
        Size = UDim2.fromOffset(135, 48),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = "CyberHunter",
        TextColor3 = Color3.fromRGB(35, 35, 38),
        TextSize = 20,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tag,
    })

    local healthLabel = create("TextLabel", {
        Name = "Health",
        Size = UDim2.fromOffset(72, 48),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundTransparency = 1,
        Text = "17.337",
        TextColor3 = CleanUI.Theme.Green,
        TextSize = 19,
        Font = CleanUI.Defaults.FontMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tag,
    })

    local pointer = create("TextLabel", {
        Name = "Pointer",
        Size = UDim2.fromOffset(28, 24),
        Position = UDim2.new(0.5, -14, 1, -5),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = CleanUI.Theme.PreviewWhite,
        TextSize = 26,
        Font = CleanUI.Defaults.FontBold,
        Parent = tag,
    })

    local function smallCheckbox(labelText: string, defaultValue: boolean, callback: any)
        local state = defaultValue == true

        local item = create("Frame", {
            Name = labelText .. "Item",
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundTransparency = 1,
            Parent = left,
        })

        local box = create("TextButton", {
            Name = "Box",
            Size = UDim2.fromOffset(30, 30),
            Position = UDim2.fromOffset(0, 7),
            BackgroundColor3 = state and CleanUI.Theme.CheckOn or CleanUI.Theme.CheckOff,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = state and "✓" or "",
            TextColor3 = CleanUI.Theme.TextDark,
            TextSize = 24,
            Font = CleanUI.Defaults.FontBold,
            Parent = item,
        })

        addCorner(box, 7)

        create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -48, 1, 0),
            Position = UDim2.fromOffset(48, 0),
            BackgroundTransparency = 1,
            Text = labelText,
            TextColor3 = CleanUI.Theme.Text,
            TextSize = 20,
            Font = CleanUI.Defaults.Font,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = item,
        })

        local function repaint()
            box.Text = state and "✓" or ""
            box.BackgroundColor3 = state and CleanUI.Theme.CheckOn or CleanUI.Theme.CheckOff
        end

        local function set(value: boolean)
            state = value == true
            repaint()
            safeCallback(callback, state)
        end

        box.MouseButton1Click:Connect(function()
            set(not state)
        end)

        item.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                set(not state)
            end
        end)

        return {
            Set = function(_, value: boolean)
                set(value)
            end,
            Get = function()
                return state
            end,
        }
    end

    local showHealth = smallCheckbox("Show Health", true, callbacks.ShowHealth)
    local showDistance = smallCheckbox("Show Distance", false, callbacks.ShowDistance)
    local showDecimal = smallCheckbox("Show decimal", true, callbacks.ShowDecimal)

    self:_registerRow(row, "Show Health Show Distance Show decimal CyberHunter 17.337")

    return {
        Row = row,
        ShowHealth = showHealth,
        ShowDistance = showDistance,
        ShowDecimal = showDecimal,
        NameLabel = nameLabel,
        HealthLabel = healthLabel,
    }
end

---------------------------------------------------------------------
-- Extra utility components
---------------------------------------------------------------------

function Section:AddKeybind(text: string, defaultKey: any?, callback: any)
    local selectedKey = defaultKey or Enum.UserInputType.MouseButton1
    local listening = false
    local acceptInput = false

    local row = create("Frame", {
        Name = text .. "KeybindRow",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -180, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 19,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local button = create("TextButton", {
        Name = "KeyButton",
        Size = UDim2.fromOffset(160, 38),
        Position = UDim2.new(1, -160, 0.5, -19),
        BackgroundColor3 = CleanUI.Theme.Card2,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = keyDisplayName(selectedKey),
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 16,
        Font = CleanUI.Defaults.FontMedium,
        Parent = row,
    })

    addCorner(button, 10)
    addStroke(button, CleanUI.Theme.StrokeSoft, 0, 1)

    button.MouseButton1Click:Connect(function()
        listening = true
        acceptInput = false
        button.Text = "..."

        task.delay(0.12, function()
            if listening then
                acceptInput = true
            end
        end)
    end)

    self.Tab.Window.Maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening and acceptInput then
            local bindValue = inputObjectToBind(input)
            if bindValue then
                listening = false
                acceptInput = false
                selectedKey = bindValue
                button.Text = keyDisplayName(selectedKey)
                safeCallback(callback, selectedKey)
            end
        end
    end))

    self:_registerRow(row, text .. " keybind " .. keyDisplayName(selectedKey))

    local api = {}

    function api:Set(key: any)
        selectedKey = key
        button.Text = keyDisplayName(selectedKey)
        safeCallback(callback, selectedKey)
    end

    function api:Get()
        return selectedKey
    end

    return api
end

function Section:AddColorPreview(text: string, defaultColor: Color3?, callback: any)
    local color = defaultColor or Color3.fromRGB(255, 255, 255)

    local row = create("Frame", {
        Name = text .. "ColorRow",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        Parent = self.Card,
    })

    create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -90, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 19,
        Font = CleanUI.Defaults.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local preview = create("TextButton", {
        Name = "Preview",
        Size = UDim2.fromOffset(64, 34),
        Position = UDim2.new(1, -64, 0.5, -17),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Parent = row,
    })

    addCorner(preview, 9)
    addStroke(preview, CleanUI.Theme.StrokeSoft, 0, 1)

    preview.MouseButton1Click:Connect(function()
        safeCallback(callback, color)
    end)

    self:_registerRow(row, text .. " color")

    local api = {}

    function api:Set(newColor: Color3)
        color = newColor
        preview.BackgroundColor3 = color
        safeCallback(callback, color)
    end

    function api:Get()
        return color
    end

    return api
end

function CleanUI:Notify(options: {[string]: any}?)
    if _G.CleanUIWindow and type((_G.CleanUIWindow :: any).Notify) == "function" then
        return (_G.CleanUIWindow :: any):Notify(options)
    end

    return nil
end

---------------------------------------------------------------------
-- Reference demo builder
---------------------------------------------------------------------

local function buildReferenceDemo()
    local window = CleanUI:CreateWindow({
        Title = "Modules",
        Name = "CleanUI_Reference_OneFile",
        Size = UDim2.fromOffset(1100, 785),
    })

    local combat = window:CreateTab("Combat")
    local movement = window:CreateTab("Movement")
    local visual = window:CreateTab("Visual")
    local player = window:CreateTab("Player")
    local exploit = window:CreateTab("Exploit")

    -- Top compact card, matching the visible upper card in the image.
    local top = combat:AddCompactSection()

    top:AddSlider("Smoothing", 0, 100, 50, "%", 1, function(value)
        -- Connect your own game setting here.
    end)

    top:AddSlider("Reaction Time", 0, 1, 0.13, "s", 0.01, function(value)
        -- Connect your own game setting here.
    end)

    top:AddToggle("Test Option", false, function(enabled)
        -- Connect your own game setting here.
    end)

    local nametags = combat:AddSection("Nametags", "Renders nametags on enemies through walls")

    local masterToggle = nametags:AddToggle("", false, function(enabled)
        -- UI-only placeholder.
    end)

    -- Move the nametag master toggle visually into the header right side.
    do
        local row = nametags.Rows[#nametags.Rows]
        row.Size = UDim2.fromOffset(0, 0)
        row.Visible = false
        local switch = row:FindFirstChild("Switch")
        if switch and switch:IsA("TextButton") then
            switch.Parent = nametags.Header
            switch.Position = UDim2.new(1, -64, 0, 16)
            switch.Size = UDim2.fromOffset(64, 34)
            switch.Visible = true
        end
    end

    nametags:AddInlineNametagSettings({
        ShowHealth = function(enabled)
        end,
        ShowDistance = function(enabled)
        end,
        ShowDecimal = function(enabled)
        end,
    })

    -- UI-only section. The callback is intentionally empty.
    local desync = combat:AddSection("Desync", "Prevent the server from replicating your current\nposition to other players")

    local desyncToggle = desync:AddToggle("", false, function(enabled)
        -- UI-only placeholder. No networking or server behavior is changed.
    end)

    do
        local row = desync.Rows[#desync.Rows]
        row.Size = UDim2.fromOffset(0, 0)
        row.Visible = false
        local switch = row:FindFirstChild("Switch")
        if switch and switch:IsA("TextButton") then
            switch.Parent = desync.Header
            switch.Position = UDim2.new(1, -64, 0, 16)
            switch.Size = UDim2.fromOffset(64, 34)
            switch.Visible = true
        end
    end

    local movementSection = movement:AddSection("Movement", "Reusable safe movement UI for your own game")
    movementSection:AddSlider("Walk Speed", 8, 32, 16, "", 1, function(value)
    end)
    movementSection:AddSlider("Jump Power", 25, 100, 50, "", 1, function(value)
    end)
    movementSection:AddToggle("Sprint", false, function(enabled)
    end)
    movementSection:AddKeybind("Sprint Key", Enum.KeyCode.LeftShift, function(key)
    end)

    local visualSection = visual:AddSection("Visual", "General visual options")
    visualSection:AddCheckbox("Show UI Blur", false, function(enabled)
    end)
    visualSection:AddSlider("Overlay Alpha", 0, 100, 30, "%", 1, function(value)
    end)
    visualSection:AddDropdown("Theme", {"Dark", "Darker", "Rounded"}, "Dark", function(value)
    end)

    local playerSection = player:AddSection("Player", "Safe player settings")
    playerSection:AddTextbox("Display Name", "Type name", "CyberHunter", function(text)
    end)
    playerSection:AddButton("Save Settings", function()
        window:Notify({
            Title = "Settings",
            Content = "Your settings were saved locally in this UI demo.",
            SubContent = "Example notification",
            Duration = 4,
        })
    end)

    local exploitInfo = exploit:AddSection("UI Only", "This tab is only a visual placeholder. Add legitimate game settings here.")
    exploitInfo:AddLabel("No exploit logic is included in this file.")
    exploitInfo:AddButton("Example Button", function()
    end)

    window:SelectTab(combat)

    window:Notify({
        Title = "CleanUI",
        Content = "UI loaded. Corners, hover, slider, dropdown layer, and notifications are enabled.",
        Duration = 5,
    })

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.RightShift then
            window:ToggleVisible()
        end
    end)

    return window
end

---------------------------------------------------------------------
-- Build UI
---------------------------------------------------------------------

local WindowInstance = buildReferenceDemo()

---------------------------------------------------------------------
-- Public access for advanced users
---------------------------------------------------------------------

_G.CleanUI = CleanUI
_G.CleanUIWindow = WindowInstance


---------------------------------------------------------------------
-- Customization reference / extension slots
---------------------------------------------------------------------
--[[
    The following notes are intentionally kept inside this one file so
    you can customize the UI without needing another module.
    They do not run. They are safe comments.
]]
