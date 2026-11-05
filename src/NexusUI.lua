--!strict
--[=[
    NEXUS UI
    A mobile-first Roblox Studio GUI library.

    Designed for LocalScripts and ModuleScripts in your own experiences.
    No executor-specific APIs are used.
]=]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

export type Theme = {
    Accent: Color3?,
    Accent2: Color3?,
    Background: Color3?,
    Surface: Color3?,
    SurfaceAlt: Color3?,
    Text: Color3?,
    MutedText: Color3?,
    Stroke: Color3?,
    Success: Color3?,
    Warning: Color3?,
    Danger: Color3?,
}

type Options = {[string]: any}

local DEFAULT_THEME: Theme = {
    Accent = Color3.fromRGB(126, 87, 255),
    Accent2 = Color3.fromRGB(175, 105, 255),
    Background = Color3.fromRGB(18, 15, 31),
    Surface = Color3.fromRGB(31, 26, 50),
    SurfaceAlt = Color3.fromRGB(43, 36, 68),
    Text = Color3.fromRGB(245, 243, 255),
    MutedText = Color3.fromRGB(170, 164, 195),
    Stroke = Color3.fromRGB(83, 71, 120),
    Success = Color3.fromRGB(87, 214, 142),
    Warning = Color3.fromRGB(255, 190, 87),
    Danger = Color3.fromRGB(255, 102, 121),
}

local function mergeTheme(theme: Theme?): Theme
    local result: Theme = {}
    for key, value in pairs(DEFAULT_THEME) do
        result[key] = value
    end
    if theme then
        for key, value in pairs(theme) do
            result[key] = value
        end
    end
    return result
end

local function create<T>(className: string, properties: {[string]: any}, parent: Instance?): T
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        (instance :: any)[property] = value
    end
    if parent then
        instance.Parent = parent
    end
    return instance :: any
end

local function tween(instance: Instance, properties: {[string]: any}, duration: number?): Tween
    local animation = TweenService:Create(instance, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
    animation:Play()
    return animation
end

local function corner(parent: Instance, radius: number)
    return create("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent: Instance, color: Color3, transparency: number?, thickness: number?)
    return create("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function padding(parent: Instance, value: number)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, value),
        PaddingBottom = UDim.new(0, value),
        PaddingLeft = UDim.new(0, value),
        PaddingRight = UDim.new(0, value),
    }, parent)
end

local function bindActivation(button: GuiButton, callback: () -> ())
    button.Activated:Connect(function()
        task.spawn(callback)
    end)
end

local function safeCallback(callback: any, ...: any)
    if type(callback) ~= "function" then
        return
    end
    task.spawn(function(...)
        local ok, err = xpcall(callback, debug.traceback, ...)
        if not ok then
            warn("[NEXUS UI] Callback error:\n" .. tostring(err))
        end
    end, ...)
end

local function makeDraggable(handle: GuiObject, target: GuiObject)
    local dragging = false
    local dragStart: Vector2?
    local startPosition: UDim2?

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragStart or not startPosition then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end)
end

local NexusUI = {}
NexusUI.__index = NexusUI

function NexusUI.new(options: Options?): any
    options = options or {}
    local self = setmetatable({}, NexusUI)
    self.Theme = mergeTheme(options.Theme)
    self.Name = options.Name or "NexusUI"
    self.Subtitle = options.Subtitle or "A modern Roblox interface"
    self.Size = options.Size or UDim2.fromOffset(760, 500)
    self.Tabs = {}
    self.ActiveTab = nil
    self.Elements = {}
    self._connections = {}
    self._destroyed = false

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = create("ScreenGui", {
        Name = self.Name,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 20,
        IgnoreGuiInset = true,
    }, playerGui)

    local overlay = create("Frame", {
        Name = "Overlay",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, self.Gui)
    self.Overlay = overlay

    local window = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = self.Size,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, overlay)
    self.Window = window
    corner(window, 16)
    stroke(window, self.Theme.Stroke, 0.35, 1)

    local sizeConstraint = create("UISizeConstraint", {
        MinSize = Vector2.new(310, 280),
        MaxSize = Vector2.new(1100, 760),
    }, window)
    self.SizeConstraint = sizeConstraint

    local scale = create("UIScale", {Scale = 1}, window)
    self.Scale = scale

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
    }, window)
    self.Header = header

    local title = create("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(22, 12),
        Size = UDim2.new(1, -150, 0, 25),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = self.Name,
        TextColor3 = self.Theme.Text,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    self.Title = title

    local subtitle = create("TextLabel", {
        Name = "Subtitle",
        Position = UDim2.fromOffset(23, 38),
        Size = UDim2.new(1, -150, 0, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = self.Subtitle,
        TextColor3 = self.Theme.MutedText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    local minimize = create("TextButton", {
        Name = "Minimize",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -48, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = self.Theme.SurfaceAlt,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "—",
        TextColor3 = self.Theme.Text,
        TextSize = 17,
    }, header)
    corner(minimize, 8)

    local close = create("TextButton", {
        Name = "Close",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = self.Theme.SurfaceAlt,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = self.Theme.Text,
        TextSize = 20,
    }, header)
    corner(close, 8)

    self.Content = create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(0, 68),
        Size = UDim2.new(1, 0, 1, -68),
        BackgroundTransparency = 1,
    }, window)

    self.Sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 184, 1, -18),
        Position = UDim2.fromOffset(9, 9),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, self.Content)
    corner(self.Sidebar, 12)
    padding(self.Sidebar, 10)
    self.SidebarLayout = create("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, self.Sidebar)

    self.PageHolder = create("Frame", {
        Name = "PageHolder",
        Position = UDim2.new(0, 202, 0, 9),
        Size = UDim2.new(1, -211, 1, -18),
        BackgroundTransparency = 1,
    }, self.Content)

    self.FloatingButton = create("TextButton", {
        Name = "FloatingButton",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.fromOffset(52, 52),
        BackgroundColor3 = self.Theme.Accent,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = "N",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 20,
        Visible = false,
    }, overlay)
    corner(self.FloatingButton, 16)
    stroke(self.FloatingButton, self.Theme.Accent2, 0.3, 1)

    makeDraggable(header, window)

    bindActivation(minimize, function()
        self:SetMinimized(not self.Minimized)
    end)
    bindActivation(close, function()
        self:Destroy()
    end)
    bindActivation(self.FloatingButton, function()
        self:SetMinimized(false)
    end)

    self._connections.viewport = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        self:_responsive()
    end)
    self:_responsive()
    return self
end

function NexusUI:_responsive()
    if not self.Window or not workspace.CurrentCamera then
        return
    end
    local viewport = workspace.CurrentCamera.ViewportSize
    if viewport.X < 650 then
        self.Sidebar.Size = UDim2.new(0, 132, 1, -18)
        self.PageHolder.Position = UDim2.new(0, 150, 0, 9)
        self.PageHolder.Size = UDim2.new(1, -159, 1, -18)
        self.SizeConstraint.MinSize = Vector2.new(300, 280)
    else
        self.Sidebar.Size = UDim2.new(0, 184, 1, -18)
        self.PageHolder.Position = UDim2.new(0, 202, 0, 9)
        self.PageHolder.Size = UDim2.new(1, -211, 1, -18)
    end
end

function NexusUI:SetMinimized(minimized: boolean)
    self.Minimized = minimized
    self.Window.Visible = not minimized
    self.FloatingButton.Visible = minimized
end

function NexusUI:Notify(options: Options)
    options = options or {}
    local toast = create("Frame", {
        Name = "Toast",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 340, 1, -20),
        Size = UDim2.fromOffset(300, 78),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
    }, self.Overlay)
    corner(toast, 12)
    stroke(toast, self.Theme.Stroke, 0.25, 1)
    local accent = create("Frame", {Size = UDim2.fromOffset(4, 78), BackgroundColor3 = options.Color or self.Theme.Accent, BorderSizePixel = 0}, toast)
    corner(accent, 3)
    create("TextLabel", {Position = UDim2.fromOffset(18, 11), Size = UDim2.new(1, -28, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = options.Title or "NEXUS UI", TextColor3 = self.Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, toast)
    create("TextLabel", {Position = UDim2.fromOffset(18, 34), Size = UDim2.new(1, -28, 0, 32), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = options.Content or options.Message or "", TextColor3 = self.Theme.MutedText, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, toast)
    tween(toast, {Position = UDim2.new(1, -20, 1, -20)}, 0.28)
    task.delay(options.Duration or 4, function()
        if toast.Parent then
            tween(toast, {Position = UDim2.new(1, 340, 1, -20)}, 0.25)
            task.delay(0.3, function() toast:Destroy() end)
        end
    end)
    return toast
end

function NexusUI:Dialog(options: Options)
    options = options or {}
    local modal = create("Frame", {Name = "DialogOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, ZIndex = 50}, self.Overlay)
    local box = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(350, 190), BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, ZIndex = 51}, modal)
    corner(box, 14)
    stroke(box, self.Theme.Stroke, 0.2, 1)
    create("TextLabel", {Position = UDim2.fromOffset(22, 19), Size = UDim2.new(1, -44, 0, 26), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = options.Title or "Confirm action", TextColor3 = self.Theme.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52}, box)
    create("TextLabel", {Position = UDim2.fromOffset(22, 54), Size = UDim2.new(1, -44, 0, 60), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = options.Content or options.Message or "Are you sure?", TextColor3 = self.Theme.MutedText, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 52}, box)
    local cancel = create("TextButton", {Position = UDim2.new(0, 22, 1, -50), Size = UDim2.new(0.5, -28, 0, 34), BackgroundColor3 = self.Theme.SurfaceAlt, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = options.CancelText or "Cancel", TextColor3 = self.Theme.Text, TextSize = 12, ZIndex = 52}, box)
    corner(cancel, 8)
    local confirm = create("TextButton", {Position = UDim2.new(0.5, 6, 1, -50), Size = UDim2.new(0.5, -28, 0, 34), BackgroundColor3 = options.ConfirmColor or self.Theme.Accent, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = options.ConfirmText or "Confirm", TextColor3 = Color3.new(1, 1, 1), TextSize = 12, ZIndex = 52}, box)
    corner(confirm, 8)
    bindActivation(cancel, function() modal:Destroy(); safeCallback(options.OnCancel) end)
    bindActivation(confirm, function() modal:Destroy(); safeCallback(options.OnConfirm) end)
    return modal
end

function NexusUI:AddTab(options: Options): any
    options = options or {}
    local tab = {Name = options.Name or "Tab", Icon = options.Icon or "•", Page = nil, Button = nil, Sections = {}}
    tab.Page = create("ScrollingFrame", {Name = tab.Name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = self.Theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, self.PageHolder)
    padding(tab.Page, 2)
    tab.Layout = create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, tab.Page)
    tab.Button = create("TextButton", {Name = tab.Name, Size = UDim2.new(1, 0, 0, 39), BackgroundColor3 = self.Theme.Surface, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = "  " .. tab.Icon .. "   " .. tab.Name, TextColor3 = self.Theme.MutedText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, self.Sidebar)
    corner(tab.Button, 9)
    bindActivation(tab.Button, function() self:SelectTab(tab.Name) end)
    table.insert(self.Tabs, tab)
    if not self.ActiveTab then self:SelectTab(tab.Name) end
    return tab
end

function NexusUI:SelectTab(name: string)
    for _, tab in ipairs(self.Tabs) do
        local active = tab.Name == name
        tab.Page.Visible = active
        tab.Button.BackgroundColor3 = active and self.Theme.Accent or self.Theme.Surface
        tab.Button.TextColor3 = active and Color3.new(1, 1, 1) or self.Theme.MutedText
        if active then self.ActiveTab = tab end
    end
end

function NexusUI:AddSection(tab: any, options: Options): any
    options = options or {}
    local section = {Name = options.Name or "Section", Open = options.Open ~= false, Elements = {}}
    local holder = create("Frame", {Name = section.Name, Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0}, tab.Page)
    corner(holder, 12)
    stroke(holder, self.Theme.Stroke, 0.5, 1)
    local heading = create("TextButton", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "  " .. section.Name .. "                                      ˅", TextColor3 = self.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, holder)
    local body = create("Frame", {Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = section.Open}, holder)
    padding(body, 12)
    local layout = create("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    section.Holder, section.Body = holder, body
    bindActivation(heading, function()
        section.Open = not section.Open
        body.Visible = section.Open
        heading.Text = "  " .. section.Name .. (section.Open and "                                      ˅" or "                                      ›")
    end)
    function section:AddLabel(text: string) return self._owner:_addLabel(self, text) end
    section._owner = self
    function section:AddParagraph(options2: Options) return self._owner:_addParagraph(self, options2) end
    function section:AddButton(options2: Options) return self._owner:_addButton(self, options2) end
    function section:AddToggle(options2: Options) return self._owner:_addToggle(self, options2) end
    function section:AddSlider(options2: Options) return self._owner:_addSlider(self, options2) end
    function section:AddDropdown(options2: Options) return self._owner:_addDropdown(self, options2) end
    function section:AddTextbox(options2: Options) return self._owner:_addTextbox(self, options2) end
    function section:AddKeybind(options2: Options) return self._owner:_addKeybind(self, options2) end
    function section:AddColorpicker(options2: Options) return self._owner:_addColorpicker(self, options2) end
    function section:AddDivider() return self._owner:_addDivider(self) end
    return section
end

function NexusUI:_register(options: Options, api: any)
    local key = options.Flag or options.Name
    if key and key ~= "" then
        self.Elements[key] = api
    end
end

local function baseRow(self: any, section: any, height: number?): Frame
    local row = create("Frame", {Size = UDim2.new(1, 0, 0, height or 42), BackgroundColor3 = self.Theme.SurfaceAlt, BorderSizePixel = 0}, section.Body)
    corner(row, 8)
    return row
end

function NexusUI:_addLabel(section: any, text: string)
    local label = create("TextLabel", {Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = text, TextColor3 = self.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, section.Body)
    return {Instance = label}
end

function NexusUI:_addParagraph(section: any, options: Options)
    local row = baseRow(self, section, options.Height or 58)
    padding(row, 10)
    create("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = options.Text or options.Content or "", TextColor3 = self.Theme.MutedText, TextSize = options.TextSize or 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, row)
    return {Instance = row}
end

function NexusUI:_addButton(section: any, options: Options)
    local button = create("TextButton", {Size = UDim2.new(1, 0, 0, options.Height or 38), BackgroundColor3 = options.Color or self.Theme.Accent, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = options.Name or "Button", TextColor3 = Color3.new(1, 1, 1), TextSize = 12}, section.Body)
    corner(button, 8)
    bindActivation(button, function() safeCallback(options.Callback) end)
    button.MouseEnter:Connect(function() tween(button, {BackgroundColor3 = self.Theme.Accent2}, 0.12) end)
    button.MouseLeave:Connect(function() tween(button, {BackgroundColor3 = options.Color or self.Theme.Accent}, 0.12) end)
    return {Instance = button, SetText = function(_, text) button.Text = text end}
end

function NexusUI:_addToggle(section: any, options: Options)
    local row = baseRow(self, section)
    local value = options.Default == true
    create("TextLabel", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -74, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = options.Name or "Toggle", TextColor3 = self.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local switch = create("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(42, 23), BackgroundColor3 = self.Theme.Surface, AutoButtonColor = false, Text = "",}, row)
    corner(switch, 12)
    local knob = create("Frame", {Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(17, 17), BackgroundColor3 = self.Theme.MutedText}, switch)
    corner(knob, 9)
    local api = {Instance = row, Value = value}
    local function render(notify)
        api.Value = value
        tween(switch, {BackgroundColor3 = value and self.Theme.Accent or self.Theme.Surface}, 0.15)
        tween(knob, {Position = value and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = value and Color3.new(1, 1, 1) or self.Theme.MutedText}, 0.15)
        if notify then safeCallback(options.Callback, value) end
    end
    function api:Set(nextValue: boolean) value = nextValue == true; render(true) end
    function api:Get() return value end
    bindActivation(switch, function() value = not value; render(true) end)
    render(false)
    self:_register(options, api)
    return api
end

function NexusUI:_addSlider(section: any, options: Options)
    local row = baseRow(self, section, 62)
    local min, max = options.Min or 0, options.Max or 100
    local value = math.clamp(options.Default or min, min, max)
    local title = create("TextLabel", {Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -70, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = options.Name or "Slider", TextColor3 = self.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local valueLabel = create("TextLabel", {Position = UDim2.new(1, -62, 0, 8), Size = UDim2.fromOffset(50, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextColor3 = self.Theme.Accent2, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right}, row)
    local track = create("Frame", {Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0}, row)
    corner(track, 4)
    local fill = create("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0}, track)
    corner(fill, 4)
    local knob = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, track)
    corner(knob, 7)
    local api = {Instance = row, Value = value}
    local function render(notify)
        local alpha = (value - min) / (max - min)
        api.Value = value
        valueLabel.Text = tostring(options.Decimals and string.format("%." .. options.Decimals .. "f", value) or math.round(value))
        tween(fill, {Size = UDim2.new(alpha, 0, 1, 0)}, 0.1)
        tween(knob, {Position = UDim2.new(alpha, 0, 0.5, 0)}, 0.1)
        if notify then safeCallback(options.Callback, value) end
    end
    local function setFromInput(input)
        local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = min + (max - min) * alpha
        if options.Decimals then local factor = 10 ^ options.Decimals; value = math.round(value * factor) / factor else value = math.round(value) end
        render(true)
    end
    track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then setFromInput(input) end end)
    UserInputService.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then setFromInput(input) end end end)
    function api:Set(nextValue: number) value = math.clamp(nextValue, min, max); render(true) end
    function api:Get() return value end
    render(false)
    self:_register(options, api)
    return api
end

function NexusUI:_addDropdown(section: any, options: Options)
    local row = baseRow(self, section, options.Multi and 74 or 42)
    local values = options.Values or {}
    local selected: {[any]: boolean} = {}
    local display = create("TextLabel", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -52, 0, 42), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = options.Name or "Dropdown", TextColor3 = self.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local arrow = create("TextLabel", {Position = UDim2.new(1, -35, 0, 0), Size = UDim2.fromOffset(25, 42), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "⌄", TextColor3 = self.Theme.MutedText, TextSize = 16}, row)
    local hit = create("TextButton", {Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, AutoButtonColor = false, Text = ""}, row)
    local list = create("Frame", {Position = UDim2.fromOffset(8, 43), Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = self.Theme.Background, Visible = false, ZIndex = 10}, row)
    corner(list, 8); padding(list, 5)
    create("UIListLayout", {Padding = UDim.new(0, 3)}, list)
    local api = {Instance = row}
    local function update()
        local names = {}
        for value, isSelected in pairs(selected) do if isSelected then table.insert(names, tostring(value)) end end
        display.Text = (options.Name or "Dropdown") .. (#names > 0 and ": " .. table.concat(names, ", ") or "")
    end
    for _, value in ipairs(values) do
        local item = create("TextButton", {Size = UDim2.new(1, 0, 0, 29), BackgroundColor3 = self.Theme.SurfaceAlt, AutoButtonColor = false, Font = Enum.Font.Gotham, Text = tostring(value), TextColor3 = self.Theme.Text, TextSize = 11, ZIndex = 11}, list)
        corner(item, 6)
        bindActivation(item, function()
            if options.Multi then selected[value] = not selected[value] else selected = {[value] = true}; list.Visible = false end
            update(); safeCallback(options.Callback, options.Multi and selected or value)
        end)
    end
    bindActivation(hit, function() list.Visible = not list.Visible end)
    function api:Set(value: any) selected = {[value] = true}; update(); safeCallback(options.Callback, value) end
    function api:Get() if options.Multi then return selected end for value, isSelected in pairs(selected) do if isSelected then return value end end return nil end
    if options.Default ~= nil then
        if options.Multi and type(options.Default) == "table" then
            selected = {}
            for _, defaultValue in ipairs(options.Default) do selected[defaultValue] = true end
        else
            selected = {[options.Default] = true}
        end
    end
    update()
    self:_register(options, api)
    return api
end

function NexusUI:_addTextbox(section: any, options: Options)
    local row = baseRow(self, section, 60)
    create("TextLabel", {Position = UDim2.fromOffset(12, 7), Size = UDim2.new(1, -24, 0, 17), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = options.Name or "Textbox", TextColor3 = self.Theme.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local input = create("TextBox", {Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -20, 0, 25), BackgroundColor3 = self.Theme.Surface, ClearTextOnFocus = false, Font = Enum.Font.Gotham, PlaceholderText = options.Placeholder or "Type here...", Text = options.Default or "", TextColor3 = self.Theme.Text, PlaceholderColor3 = self.Theme.MutedText, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, row)
    corner(input, 6); padding(input, 6)
    local api = {Instance = row, Input = input}
    input.FocusLost:Connect(function(enterPressed) safeCallback(options.Callback, input.Text, enterPressed) end)
    function api:Set(text: string) input.Text = text end
    function api:Get() return input.Text end
    self:_register(options, api)
    return api
end

function NexusUI:_addKeybind(section: any, options: Options)
    local row = baseRow(self, section)
    create("TextLabel", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = options.Name or "Keybind", TextColor3 = self.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local key = options.Default or Enum.KeyCode.RightShift
    local button = create("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(86, 27), BackgroundColor3 = self.Theme.Surface, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = key.Name, TextColor3 = self.Theme.Accent2, TextSize = 11}, row)
    corner(button, 6)
    local listening = false
    local api = {Instance = row, Key = key}
    bindActivation(button, function() listening = true; button.Text = "Press key..." end)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then listening = false; key = input.KeyCode; api.Key = key; button.Text = key.Name; safeCallback(options.Changed, key) elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then safeCallback(options.Callback, key) end
    end)
    function api:Set(nextKey: Enum.KeyCode) key = nextKey; api.Key = key; button.Text = key.Name end
    function api:Get() return key end
    self:_register(options, api)
    return api
end

function NexusUI:_addColorpicker(section: any, options: Options)
    local row = baseRow(self, section)
    local color = options.Default or Color3.fromRGB(126, 87, 255)
    create("TextLabel", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = options.Name or "Color", TextColor3 = self.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local swatch = create("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(42, 25), BackgroundColor3 = color, AutoButtonColor = false, Text = ""}, row)
    corner(swatch, 7)
    local api = {Instance = row, Color = color}
    -- Roblox Studio does not expose a native Color3 picker. This compact cycling picker is safe and extensible.
    local colors = options.Colors or {Color3.fromRGB(126, 87, 255), Color3.fromRGB(61, 180, 255), Color3.fromRGB(87, 214, 142), Color3.fromRGB(255, 190, 87), Color3.fromRGB(255, 102, 121)}
    local index = 1
    for i, candidate in ipairs(colors) do if candidate == color then index = i end end
    bindActivation(swatch, function() index = index % #colors + 1; color = colors[index]; api.Color = color; swatch.BackgroundColor3 = color; safeCallback(options.Callback, color) end)
    function api:Set(nextColor: Color3) color = nextColor; api.Color = color; swatch.BackgroundColor3 = color; safeCallback(options.Callback, color) end
    function api:Get() return color end
    self:_register(options, api)
    return api
end

function NexusUI:_addDivider(section: any)
    local divider = create("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = self.Theme.Stroke, BackgroundTransparency = 0.35, BorderSizePixel = 0}, section.Body)
    return {Instance = divider}
end

function NexusUI:SaveConfig(): {[string]: any}
    local config: {[string]: any} = {}
    for key, element in pairs(self.Elements) do
        if type(element.Get) == "function" then config[key] = element:Get() end
    end
    return config
end

function NexusUI:LoadConfig(config: {[string]: any})
    for key, value in pairs(config or {}) do
        local element = self.Elements[key]
        if element and type(element.Set) == "function" then element:Set(value) end
    end
end

function NexusUI:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, connection in pairs(self._connections) do connection:Disconnect() end
    if self.Gui then self.Gui:Destroy() end
end

return NexusUI
