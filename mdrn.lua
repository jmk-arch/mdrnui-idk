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
CleanUI.Version = "1.1.0-smooth-corners"
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
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
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
        BackgroundColor3 = CleanUI.Theme.WindowBackground,
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
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = main,
    })

    -- UICorner does not always mask child frames perfectly, especially on the
    -- outer window edges. The sidebar uses a rounded base for the outside edge
    -- and a small square fill on the inside edge so the left window corners stay clean.
    addCorner(sidebar, CleanUI.Defaults.WindowCorner)

    local sidebarSquareFill = create("Frame", {
        Name = "SidebarSquareFill",
        Size = UDim2.new(0, CleanUI.Defaults.WindowCorner + 6, 1, 0),
        Position = UDim2.new(1, -(CleanUI.Defaults.WindowCorner + 6), 0, 0),
        BackgroundColor3 = CleanUI.Theme.Sidebar,
        BorderSizePixel = 0,
        Parent = sidebar,
    })

    local sideDivider = create("Frame", {
        Name = "SidebarDivider",
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = CleanUI.Theme.SidebarStroke,
        BorderSizePixel = 0,
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

    local contentRoot = create("Frame", {
        Name = "ContentRoot",
        Size = UDim2.new(1, -CleanUI.Defaults.SidebarWidth, 1, 0),
        Position = UDim2.fromOffset(CleanUI.Defaults.SidebarWidth, 0),
        BackgroundTransparency = 1,
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

    local object = setmetatable({
        Gui = screenGui,
        BackgroundDim = backgroundDim,
        Main = main,
        Sidebar = sidebar,
        TabsFrame = tabsFrame,
        ContentRoot = contentRoot,
        Topbar = topbar,
        Pages = pages,
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
        Parent = self.Topbar,
    })

    addCorner(menu, 14)
    addStroke(menu, CleanUI.Theme.Stroke, 0, 1)
    addPadding(menu, 8, 8, 8, 8)
    addList(menu, 6, false)

    local names = {
        "Default",
        "Legit",
        "Visual Only",
    }

    for _, name in ipairs(names) do
        local item = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = CleanUI.Theme.Card2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = name,
            TextColor3 = CleanUI.Theme.Text,
            TextSize = 16,
            Font = CleanUI.Defaults.FontMedium,
            Parent = menu,
        })

        addCorner(item, 8)

        item.MouseEnter:Connect(function()
            tween(item, CleanUI.Defaults.AnimationFast, { BackgroundTransparency = 0 })
        end)

        item.MouseLeave:Connect(function()
            tween(item, CleanUI.Defaults.AnimationFast, { BackgroundTransparency = 1 })
        end)

        item.MouseButton1Click:Connect(function()
            local textLabel = self.ConfigButton:FindFirstChild("Text")
            if textLabel and textLabel:IsA("TextLabel") then
                textLabel.Text = name
            end

            dropdownOpen = false
            tween(menu, CleanUI.Defaults.AnimationFast, { Size = UDim2.fromOffset(260, 0) })
            task.delay(0.12, function()
                if not dropdownOpen then
                    menu.Visible = false
                end
            end)
        end)
    end

    self.Maid:Give(self.ConfigButton.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen

        if dropdownOpen then
            menu.Visible = true
            tween(menu, CleanUI.Defaults.AnimationNormal, { Size = UDim2.fromOffset(260, 140) })
        else
            tween(menu, CleanUI.Defaults.AnimationFast, { Size = UDim2.fromOffset(260, 0) })
            task.delay(0.12, function()
                if not dropdownOpen then
                    menu.Visible = false
                end
            end)
        end
    end))
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
            tween(button, CleanUI.Defaults.AnimationFast, {
                BackgroundTransparency = 0.55,
                BackgroundColor3 = CleanUI.Theme.Hover,
            })
        end
    end)

    button.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            tween(button, CleanUI.Defaults.AnimationFast, {
                BackgroundTransparency = 1,
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

    for _, other in ipairs(self.Tabs) do
        if other ~= tab and other ~= oldTab then
            other.PageGroup.Visible = false
            other.PageGroup.Position = UDim2.fromOffset(0, 0)
            setGroupFade(other.PageGroup, 1)
            tween(other.Button, CleanUI.Defaults.AnimationFast, {
                BackgroundTransparency = 1,
            })
        end
    end

    if oldTab then
        oldTab.TransitionToken += 1
        local token = oldTab.TransitionToken

        tween(oldTab.Button, CleanUI.Defaults.AnimationFast, {
            BackgroundTransparency = 1,
        })

        oldTab.PageGroup.Visible = true
        tweenPageGroup(oldTab.PageGroup, UDim2.fromOffset(-22, 0), 1)

        task.delay(0.34, function()
            if oldTab.TransitionToken == token and self.CurrentTab ~= oldTab then
                oldTab.PageGroup.Visible = false
                oldTab.PageGroup.Position = UDim2.fromOffset(0, 0)
                setGroupFade(oldTab.PageGroup, 1)
            end
        end)
    end

    tab.TransitionToken += 1
    tab.PageGroup.Visible = true
    tab.PageGroup.Position = oldTab and UDim2.fromOffset(22, 0) or UDim2.fromOffset(0, 0)
    setGroupFade(tab.PageGroup, oldTab and 1 or 0)

    tab.Button.BackgroundColor3 = CleanUI.Theme.Selected
    tween(tab.Button, CleanUI.Defaults.AnimationFast, {
        BackgroundTransparency = 0,
        BackgroundColor3 = CleanUI.Theme.Selected,
    })

    tweenPageGroup(tab.PageGroup, UDim2.fromOffset(0, 0), 0)
    self:_applySearch()
end

---------------------------------------------------------------------
-- Tab object
---------------------------------------------------------------------

Tab = {}
Tab.__index = Tab

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

    local menuDots = create("TextLabel", {
        Name = "Dots",
        Size = UDim2.fromOffset(48, 30),
        Position = UDim2.new(1, -70, 0, 0),
        BackgroundTransparency = 1,
        Text = "...",
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 24,
        Font = CleanUI.Defaults.FontBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = header,
    })

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
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, -12, 0.5, -12)

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
            applyValue(valueFromX(input.Position.X), true)
        end
    end)

    knob.InputBegan:Connect(function(input)
        if isPointerDown(input) then
            dragging = true
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

    local menu = create("Frame", {
        Name = "Menu",
        Size = UDim2.new(0.58, 0, 0, 0),
        Position = UDim2.new(0.42, 0, 1, -2),
        BackgroundColor3 = CleanUI.Theme.Card2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 5,
        Parent = row,
    })

    addCorner(menu, 10)
    addStroke(menu, CleanUI.Theme.StrokeSoft, 0, 1)
    addPadding(menu, 6, 6, 6, 6)
    addList(menu, 4, false)

    for _, itemText in ipairs(items) do
        local item = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = CleanUI.Theme.Hover,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = itemText,
            TextColor3 = CleanUI.Theme.Text,
            TextSize = 16,
            Font = CleanUI.Defaults.Font,
            Parent = menu,
        })

        addCorner(item, 8)

        item.MouseEnter:Connect(function()
            tween(item, CleanUI.Defaults.AnimationFast, { BackgroundTransparency = 0 })
        end)

        item.MouseLeave:Connect(function()
            tween(item, CleanUI.Defaults.AnimationFast, { BackgroundTransparency = 1 })
        end)

        item.MouseButton1Click:Connect(function()
            selected = itemText
            valueLabel.Text = selected
            open = false
            tween(menu, CleanUI.Defaults.AnimationFast, { Size = UDim2.new(0.58, 0, 0, 0) })
            task.delay(0.13, function()
                if not open then
                    menu.Visible = false
                    row.Size = UDim2.new(1, 0, 0, 50)
                end
            end)
            safeCallback(callback, selected)
        end)
    end

    button.MouseButton1Click:Connect(function()
        open = not open

        if open then
            menu.Visible = true
            row.Size = UDim2.new(1, 0, 0, 50 + math.min(#items, 5) * 38 + 14)
            tween(menu, CleanUI.Defaults.AnimationNormal, {
                Size = UDim2.new(0.58, 0, 0, math.min(#items, 5) * 38 + 10),
            })
        else
            tween(menu, CleanUI.Defaults.AnimationFast, {
                Size = UDim2.new(0.58, 0, 0, 0),
            })
            task.delay(0.13, function()
                if not open then
                    menu.Visible = false
                    row.Size = UDim2.new(1, 0, 0, 50)
                end
            end)
        end
    end)

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

function Section:AddKeybind(text: string, defaultKey: Enum.KeyCode?, callback: any)
    local selectedKey = defaultKey or Enum.KeyCode.RightShift
    local listening = false

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
        Text = selectedKey.Name,
        TextColor3 = CleanUI.Theme.Text,
        TextSize = 16,
        Font = CleanUI.Defaults.FontMedium,
        Parent = row,
    })

    addCorner(button, 10)
    addStroke(button, CleanUI.Theme.StrokeSoft, 0, 1)

    button.MouseButton1Click:Connect(function()
        listening = true
        button.Text = "Press key..."
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            selectedKey = input.KeyCode
            button.Text = selectedKey.Name
            safeCallback(callback, selectedKey)
        end
    end)

    self:_registerRow(row, text .. " keybind " .. selectedKey.Name)

    local api = {}

    function api:Set(key: Enum.KeyCode)
        selectedKey = key
        button.Text = selectedKey.Name
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
    end)

    local exploitInfo = exploit:AddSection("UI Only", "This tab is only a visual placeholder. Add legitimate game settings here.")
    exploitInfo:AddLabel("No exploit logic is included in this file.")
    exploitInfo:AddButton("Example Button", function()
    end)

    window:SelectTab(combat)

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
