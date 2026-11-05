--[[
    NEXUS UI v2.0
    Modern Workspace Edition
    Purple / Black / Soft White

    Compatible with:
      - Roblox LocalScripts
      - Touch and mouse input
      - Desktop and mobile layouts

    API:
      NexusUI.new(options)
      Window:Tab(name, icon)
      Tab:Section(name)
      Section:Button(options)
      Section:Toggle(options)
      Section:Slider(options)
      Section:Textbox(options)
      Section:Dropdown(options)
      Section:MultiDropdown(options)
      Section:Keybind(options)
      Section:Colorpicker(options)
      Section:Label(text)
      Section:Paragraph(options)
      Section:Divider()
      Window:Notify(options)
      Window:Dialog(options)
      Window:SetTheme(theme)
      Window:Toggle()
      Window:Destroy()
]]

local NexusUI = {}
NexusUI.__index = NexusUI

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

--==================================================
-- THEME
--==================================================

local DefaultTheme = {
    Background = Color3.fromRGB(32, 27, 54),
    Surface = Color3.fromRGB(47, 40, 76),
    SurfaceLight = Color3.fromRGB(62, 53, 98),
    SurfaceHover = Color3.fromRGB(78, 65, 119),

    Accent = Color3.fromRGB(157, 104, 255),
    AccentDark = Color3.fromRGB(94, 63, 169),

    Text = Color3.fromRGB(250, 248, 255),
    Muted = Color3.fromRGB(190, 181, 215),

    Border = Color3.fromRGB(197, 178, 255),

    Success = Color3.fromRGB(82, 220, 155),
    Warning = Color3.fromRGB(255, 190, 90),
    Error = Color3.fromRGB(255, 100, 125),

    Input = Color3.fromRGB(247, 245, 252),
    InputText = Color3.fromRGB(43, 36, 67),
}

--==================================================
-- HELPERS
--==================================================

local function Create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function Corner(object, radius)
    Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12)
    }, object)
end

local function Stroke(object, color, transparency, thickness)
    return Create("UIStroke", {
        Color = color or DefaultTheme.Border,
        Transparency = transparency or 0.5,
        Thickness = thickness or 1
    }, object)
end

local function Padding(object, left, right, top, bottom)
    return Create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, object)
end

local function Animate(object, duration, properties)
    if not object or not object.Parent then
        return
    end

    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.22,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()
    return tween
end

local function SafeCallback(callback, ...)
    if typeof(callback) == "function" then
        local success, err = pcall(callback, ...)

        if not success then
            warn("[NEXUS UI] Callback error:", err)
        end
    end
end

local function MakeText(parent, value, size, color, font)
    return Create("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextSize = size or 13,
        TextColor3 = color or DefaultTheme.Text,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 22)
    }, parent)
end

local function MakeButton(parent, text, theme, callback, height)
    local button = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, height or 40),
        BackgroundColor3 = theme.SurfaceLight,
        Text = tostring(text or "Button"),
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = false,
        BorderSizePixel = 0
    }, parent)

    Corner(button, 10)

    button.MouseEnter:Connect(function()
        Animate(button, 0.16, {
            BackgroundColor3 = theme.SurfaceHover
        })
    end)

    button.MouseLeave:Connect(function()
        Animate(button, 0.16, {
            BackgroundColor3 = theme.SurfaceLight
        })
    end)

    button.Activated:Connect(function()
        SafeCallback(callback)
    end)

    return button
end

--==================================================
-- INTERNAL METHODS
--==================================================

function NexusUI:_theme(key)
    return self.Theme[key] or DefaultTheme[key]
end

function NexusUI:_track(connection)
    table.insert(self.Connections, connection)
    return connection
end

function NexusUI:_control(parent, height)
    return Create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, parent)
end

--==================================================
-- NOTIFICATIONS
--==================================================

function NexusUI:Notify(options)
    options = options or {}

    local colors = {
        Success = self:_theme("Success"),
        Error = self:_theme("Error"),
        Warning = self:_theme("Warning"),
        Info = self:_theme("Accent")
    }

    local card = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 78),
        BackgroundColor3 = self:_theme("Surface"),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0
    }, self.ToastHolder)

    Corner(card, 13)
    Stroke(card, self:_theme("Border"), 0.55)

    local accent = Create("Frame", {
        Position = UDim2.new(0, 9, 0, 12),
        Size = UDim2.new(0, 4, 1, -24),
        BackgroundColor3 = colors[options.Type or "Info"] or colors.Info,
        BorderSizePixel = 0
    }, card)

    Corner(accent, 5)

    local title = MakeText(
        card,
        options.Title or "Notification",
        14,
        self:_theme("Text"),
        Enum.Font.GothamBold
    )

    title.Position = UDim2.new(0, 23, 0, 10)
    title.Size = UDim2.new(1, -34, 0, 22)

    local message = MakeText(
        card,
        options.Content or options.Message or "",
        12,
        self:_theme("Muted")
    )

    message.Position = UDim2.new(0, 23, 0, 34)
    message.Size = UDim2.new(1, -34, 0, 32)
    message.TextWrapped = true
    message.TextYAlignment = Enum.TextYAlignment.Top

    card.Position = UDim2.new(1, 30, 0, 0)

    Animate(card, 0.3, {
        Position = UDim2.new(0, 0, 0, 0)
    })

    task.delay(options.Duration or 4, function()
        if card.Parent then
            Animate(card, 0.25, {
                Position = UDim2.new(1, 30, 0, 0),
                BackgroundTransparency = 1
            })

            task.wait(0.3)

            if card.Parent then
                card:Destroy()
            end
        end
    end)
end

--==================================================
-- DIALOG
--==================================================

function NexusUI:Dialog(options)
    options = options or {}

    local overlay = Create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.4,
        ZIndex = 100
    }, self.Screen)

    local panel = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.86, 0, 0, 205),
        BackgroundColor3 = self:_theme("Surface"),
        BorderSizePixel = 0,
        ZIndex = 101
    }, overlay)

    Corner(panel, 17)
    Stroke(panel, self:_theme("Border"), 0.35)

    local title = MakeText(
        panel,
        options.Title or "Confirmation",
        17,
        self:_theme("Text"),
        Enum.Font.GothamBold
    )

    title.Position = UDim2.new(0, 18, 0, 17)
    title.Size = UDim2.new(1, -36, 0, 28)
    title.ZIndex = 102

    local content = MakeText(
        panel,
        options.Content or "Are you sure?",
        13,
        self:_theme("Muted")
    )

    content.Position = UDim2.new(0, 18, 0, 55)
    content.Size = UDim2.new(1, -36, 0, 75)
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.ZIndex = 102

    local cancel = Create("TextButton", {
        Position = UDim2.new(0, 18, 1, -54),
        Size = UDim2.new(0.45, -10, 0, 38),
        BackgroundColor3 = self:_theme("SurfaceLight"),
        Text = options.CancelText or "Cancel",
        TextColor3 = self:_theme("Text"),
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        ZIndex = 102
    }, panel)

    Corner(cancel, 10)

    local confirm = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -18, 1, -54),
        Size = UDim2.new(0.55, -10, 0, 38),
        BackgroundColor3 = self:_theme("AccentDark"),
        Text = options.ConfirmText or "Confirm",
        TextColor3 = self:_theme("Text"),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        ZIndex = 102
    }, panel)

    Corner(confirm, 10)

    cancel.Activated:Connect(function()
        overlay:Destroy()
        SafeCallback(options.OnCancel)
    end)

    confirm.Activated:Connect(function()
        overlay:Destroy()
        SafeCallback(options.OnConfirm)
    end)
end

--==================================================
-- TAB SYSTEM
--==================================================

function NexusUI:Tab(name, icon)
    assert(not self.Destroyed, "NEXUS UI has been destroyed")

    local tabButton = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = self:_theme("AccentDark"),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0
    }, self.TabList)

    Corner(tabButton, 10)

    local iconLabel = MakeText(
        tabButton,
        icon or "◆",
        16,
        self:_theme("Muted"),
        Enum.Font.GothamBold
    )

    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.Size = UDim2.new(0, 27, 1, 0)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local nameLabel = MakeText(
        tabButton,
        name,
        13,
        self:_theme("Muted"),
        Enum.Font.GothamMedium
    )

    nameLabel.Position = UDim2.new(0, 43, 0, 0)
    nameLabel.Size = UDim2.new(1, -48, 1, 0)

    local page = Create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self:_theme("Accent"),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, self.PageHolder)

    Padding(page, 4, 8, 4, 10)

    Create("UIListLayout", {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    local tab = {
        Library = self,
        Name = name,
        Button = tabButton,
        Page = page,
        Label = nameLabel,
        Icon = iconLabel
    }

    table.insert(self.Tabs, tab)

    local function selectTab()
        if self.ActiveTab == tab then
            return
        end

        for _, other in ipairs(self.Tabs) do
            local active = other == tab

            Animate(other.Button, 0.2, {
                BackgroundTransparency = active and 0 or 1
            })

            other.Label.TextColor3 = active
                and self:_theme("Text")
                or self:_theme("Muted")

            other.Icon.TextColor3 = other.Label.TextColor3
            other.Page.Visible = active
        end

        self.ActiveTab = tab
    end

    tabButton.Activated:Connect(selectTab)

    if #self.Tabs == 1 then
        self.ActiveTab = tab
        page.Visible = true
        tabButton.BackgroundTransparency = 0
        nameLabel.TextColor3 = self:_theme("Text")
        iconLabel.TextColor3 = self:_theme("Text")
    end

    return tab
end

--==================================================
-- SECTION SYSTEM
--==================================================

function NexusUI:Section(sectionName)
    local tab = self
    local library = tab.Library

    local section = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = library:_theme("Surface"),
        BorderSizePixel = 0
    }, tab.Page)

    Corner(section, 14)
    Stroke(section, library:_theme("Border"), 0.7)

    Padding(section, 13, 13, 10, 12)

    local header = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 27),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    }, section)

    local heading = MakeText(
        header,
        sectionName or "Section",
        14,
        library:_theme("Text"),
        Enum.Font.GothamBold
    )

    heading.Size = UDim2.new(1, -30, 1, 0)

    local arrow = MakeText(
        header,
        "⌄",
        18,
        library:_theme("Muted")
    )

    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.Size = UDim2.new(0, 25, 1, 0)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local content = Create("Frame", {
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    }, section)

    Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, content)

    local collapsed = false

    header.Activated:Connect(function()
        collapsed = not collapsed
        content.Visible = not collapsed
        arrow.Text = collapsed and "›" or "⌄"
    end)

    local API = {
        Library = library,
        Container = content
    }

    -- BUTTON

    function API:Button(options)
        if typeof(options) ~= "table" then
            options = {Name = tostring(options)}
        end

        local item = self.Library:_control(
            self.Container,
            options.Height or 40
        )

        local button = MakeButton(
            item,
            options.Name or "Button",
            self.Library.Theme,
            options.Callback,
            options.Height or 40
        )

        return {
            SetText = function(_, value)
                button.Text = tostring(value)
            end,

            SetEnabled = function(_, enabled)
                button.Active = enabled
                button.TextTransparency = enabled and 0 or 0.5
            end
        }
    end

    -- TOGGLE

    function API:Toggle(options)
        options = options or {}

        local value = options.Default == true
        local item = self.Library:_control(self.Container, 42)

        local label = MakeText(
            item,
            options.Name or "Toggle",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -75, 1, 0)

        local track = Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 48, 0, 26),
            BackgroundColor3 = value
                and self.Library:_theme("Accent")
                or self.Library:_theme("SurfaceLight"),
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false
        }, item)

        Corner(track, 20)

        local knob = Create("Frame", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = value
                and UDim2.new(1, -23, 0.5, -10)
                or UDim2.new(0, 3, 0.5, -10),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0
        }, track)

        Corner(knob, 20)

        local function set(newValue, fire)
            value = newValue == true

            Animate(track, 0.18, {
                BackgroundColor3 = value
                    and self.Library:_theme("Accent")
                    or self.Library:_theme("SurfaceLight")
            })

            Animate(knob, 0.18, {
                Position = value
                    and UDim2.new(1, -23, 0.5, -10)
                    or UDim2.new(0, 3, 0.5, -10)
            })

            if fire then
                SafeCallback(options.Callback, value)
            end
        end

        track.Activated:Connect(function()
            set(not value, true)
        end)

        return {
            Get = function()
                return value
            end,

            Set = function(_, newValue)
                set(newValue, true)
            end
        }
    end

    -- SLIDER

    function API:Slider(options)
        options = options or {}

        local min = tonumber(options.Min) or 0
        local max = tonumber(options.Max) or 100
        local decimals = tonumber(options.Decimals) or 0

        assert(max > min, "Slider Max must be greater than Min")

        local value = math.clamp(
            tonumber(options.Default) or min,
            min,
            max
        )

        local item = self.Library:_control(self.Container, 62)

        local label = MakeText(
            item,
            options.Name or "Slider",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -70, 0, 23)

        local valueLabel = MakeText(
            item,
            tostring(value),
            12,
            self.Library:_theme("Accent"),
            Enum.Font.GothamBold
        )

        valueLabel.Position = UDim2.new(1, -65, 0, 0)
        valueLabel.Size = UDim2.new(0, 65, 0, 23)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right

        local bar = Create("TextButton", {
            Position = UDim2.new(0, 0, 0, 38),
            Size = UDim2.new(1, 0, 0, 8),
            BackgroundColor3 = self.Library:_theme("SurfaceLight"),
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false
        }, item)

        Corner(bar, 8)

        local fill = Create("Frame", {
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = self.Library:_theme("Accent"),
            BorderSizePixel = 0
        }, bar)

        Corner(fill, 8)

        local dragging = false

        local function setValue(newValue, fire)
            local multiplier = 10 ^ decimals

            value = math.clamp(
                math.floor(newValue * multiplier + 0.5) / multiplier,
                min,
                max
            )

            local ratio = (value - min) / (max - min)

            Animate(fill, 0.08, {
                Size = UDim2.new(ratio, 0, 1, 0)
            })

            valueLabel.Text = tostring(value)

            if fire then
                SafeCallback(options.Callback, value)
            end
        end

        local function fromX(x)
            local ratio = math.clamp(
                (x - bar.AbsolutePosition.X) /
                math.max(bar.AbsoluteSize.X, 1),
                0,
                1
            )

            setValue(min + (max - min) * ratio, true)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = true
                fromX(input.Position.X)
            end
        end)

        self.Library:_track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                fromX(input.Position.X)
            end
        end))

        self.Library:_track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        return {
            Get = function()
                return value
            end,

            Set = function(_, newValue)
                setValue(tonumber(newValue) or min, true)
            end
        }
    end

    -- TEXTBOX

    function API:Textbox(options)
        options = options or {}

        local item = self.Library:_control(self.Container, 72)

        local label = MakeText(
            item,
            options.Name or "Textbox",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, 0, 0, 22)

        local box = Create("TextBox", {
            Position = UDim2.new(0, 0, 0, 29),
            Size = UDim2.new(1, 0, 0, 39),
            BackgroundColor3 = self.Library:_theme("Input"),
            Text = tostring(options.Default or ""),
            PlaceholderText = options.Placeholder or "Type something...",
            PlaceholderColor3 = Color3.fromRGB(135, 128, 155),
            TextColor3 = self.Library:_theme("InputText"),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            ClearTextOnFocus = options.ClearOnFocus == true,
            BorderSizePixel = 0
        }, item)

        Corner(box, 10)

        Padding(box, 12, 12, 0, 0)

        box.FocusLost:Connect(function(enterPressed)
            SafeCallback(options.Callback, box.Text, enterPressed)
        end)

        return {
            Get = function()
                return box.Text
            end,

            Set = function(_, value)
                box.Text = tostring(value)
            end
        }
    end

    -- DROPDOWN

    function API:Dropdown(options)
        options = options or {}

        local values = options.Options or {}
        local selected = options.Default
        local opened = false

        local item = self.Library:_control(self.Container, 72)

        local label = MakeText(
            item,
            options.Name or "Dropdown",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, 0, 0, 22)

        local trigger = Create("TextButton", {
            Position = UDim2.new(0, 0, 0, 29),
            Size = UDim2.new(1, 0, 0, 39),
            BackgroundColor3 = self.Library:_theme("Input"),
            Text = tostring(selected or options.Placeholder or "Select an option") .. "    ▾",
            TextColor3 = self.Library:_theme("InputText"),
            TextSize = 13,
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            AutoButtonColor = false
        }, item)

        Corner(trigger, 10)

        local menu = Create("Frame", {
            Position = UDim2.new(0, 0, 0, 73),
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = self.Library:_theme("SurfaceLight"),
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = true,
            ZIndex = 20
        }, item)

        Corner(menu, 10)

        local list = Create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 21
        }, menu)

        Padding(list, 5, 5, 5, 5)

        Create("UIListLayout", {
            Padding = UDim.new(0, 4)
        }, list)

        local function refresh()
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            for _, option in ipairs(values) do
                local choice = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = self.Library:_theme("Surface"),
                    Text = tostring(option),
                    TextColor3 = self.Library:_theme("Text"),
                    TextSize = 12,
                    Font = Enum.Font.GothamMedium,
                    BorderSizePixel = 0,
                    ZIndex = 22
                }, list)

                Corner(choice, 8)

                choice.Activated:Connect(function()
                    selected = option
                    trigger.Text = tostring(option) .. "    ▾"

                    opened = false
                    menu.Visible = false
                    item.Size = UDim2.new(1, 0, 0, 72)

                    SafeCallback(options.Callback, option)
                end)
            end
        end

        refresh()

        trigger.Activated:Connect(function()
            opened = not opened

            local height = math.min(#values * 38 + 10, 155)

            menu.Visible = opened

            Animate(menu, 0.2, {
                Size = UDim2.new(1, 0, 0, opened and height or 0)
            })

            item.Size = UDim2.new(
                1, 0, 0,
                opened and (83 + height) or 72
            )
        end)

        return {
            Get = function()
                return selected
            end,

            Set = function(_, value)
                selected = value
                trigger.Text = tostring(value) .. "    ▾"
                SafeCallback(options.Callback, value)
            end,

            Refresh = function(_, newValues)
                values = newValues or {}
                refresh()
            end
        }
    end

    -- MULTI DROPDOWN

    function API:MultiDropdown(options)
        options = options or {}

        local selected = {}

        local dropdown = self:Dropdown({
            Name = options.Name or "Multi Dropdown",
            Options = options.Options or {},
            Placeholder = options.Placeholder or "Select options",

            Callback = function(value)
                if selected[value] then
                    selected[value] = nil
                else
                    selected[value] = true
                end

                local result = {}

                for key in pairs(selected) do
                    table.insert(result, key)
                end

                table.sort(result)

                SafeCallback(options.Callback, result)
            end
        })

        return {
            Get = function()
                local result = {}

                for key in pairs(selected) do
                    table.insert(result, key)
                end

                table.sort(result)
                return result
            end,

            Set = function(_, values)
                selected = {}

                for _, value in ipairs(values or {}) do
                    selected[value] = true
                end

                local result = {}

                for key in pairs(selected) do
                    table.insert(result, key)
                end

                table.sort(result)

                SafeCallback(options.Callback, result)
            end,

            Refresh = function(_, values)
                dropdown:Refresh(values)
            end
        }
    end

    -- KEYBIND

    function API:Keybind(options)
        options = options or {}

        local current = options.Default or Enum.KeyCode.RightShift
        local listening = false

        local item = self.Library:_control(self.Container, 42)

        local label = MakeText(
            item,
            options.Name or "Keybind",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -110, 1, 0)

        local keyButton = Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 105, 0, 34),
            BackgroundColor3 = self.Library:_theme("SurfaceLight"),
            Text = current.Name,
            TextColor3 = self.Library:_theme("Text"),
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            BorderSizePixel = 0
        }, item)

        Corner(keyButton, 9)

        keyButton.Activated:Connect(function()
            listening = true
            keyButton.Text = "Press key..."
        end)

        self.Library:_track(UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end

            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode
                keyButton.Text = current.Name
                listening = false

                SafeCallback(options.Changed, current)

            elseif not listening and input.KeyCode == current then
                SafeCallback(options.Callback, current)
            end
        end))

        return {
            Get = function()
                return current
            end,

            Set = function(_, key)
                if typeof(key) == "EnumItem"
                    and key.EnumType == Enum.KeyCode then

                    current = key
                    keyButton.Text = key.Name
                end
            end
        }
    end

    -- COLORPICKER

    function API:Colorpicker(options)
        options = options or {}

        local color = options.Default or self.Library:_theme("Accent")

        local item = self.Library:_control(self.Container, 42)

        local label = MakeText(
            item,
            options.Name or "Colorpicker",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -60, 1, 0)

        local swatch = Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 43, 0, 29),
            BackgroundColor3 = color,
            Text = "",
            BorderSizePixel = 0
        }, item)

        Corner(swatch, 9)
        Stroke(swatch, Color3.new(1, 1, 1), 0.65)

        swatch.Activated:Connect(function()
            local h, s, v = color:ToHSV()

            color = Color3.fromHSV(
                (h + 0.08) % 1,
                s,
                v
            )

            swatch.BackgroundColor3 = color
            SafeCallback(options.Callback, color)
        end)

        return {
            Get = function()
                return color
            end,

            Set = function(_, newColor)
                if typeof(newColor) == "Color3" then
                    color = newColor
                    swatch.BackgroundColor3 = color

                    SafeCallback(options.Callback, color)
                end
            end
        }
    end

    -- LABEL

    function API:Label(value)
        local item = self.Library:_control(self.Container, 28)

        local label = MakeText(
            item,
            value,
            13,
            self.Library:_theme("Muted")
        )

        label.Size = UDim2.new(1, 0, 1, 0)

        return {
            SetText = function(_, newValue)
                label.Text = tostring(newValue)
            end
        }
    end

    -- PARAGRAPH

    function API:Paragraph(options)
        options = options or {}

        local item = self.Library:_control(self.Container, 62)

        local title = MakeText(
            item,
            options.Title or "Information",
            13,
            self.Library:_theme("Text"),
            Enum.Font.GothamBold
        )

        title.Size = UDim2.new(1, 0, 0, 22)

        local body = MakeText(
            item,
            options.Content or "",
            12,
            self.Library:_theme("Muted")
        )

        body.Position = UDim2.new(0, 0, 0, 25)
        body.Size = UDim2.new(1, 0, 0, 36)
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top

        return {
            SetContent = function(_, value)
                body.Text = tostring(value)
            end,

            SetTitle = function(_, value)
                title.Text = tostring(value)
            end
        }
    end

    -- DIVIDER

    function API:Divider()
        local item = self.Library:_control(self.Container, 12)

        return Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = self.Library:_theme("Border"),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0
        }, item)
    end

    return API
end

--==================================================
-- THEME
--==================================================

function NexusUI:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        if DefaultTheme[key] and typeof(value) == "Color3" then
            self.Theme[key] = value
        end
    end
end

--==================================================
-- WINDOW TOGGLE
--==================================================

function NexusUI:Toggle()
    if self.Destroyed then
        return
    end

    self.Visible = not self.Visible

    if self.Visible then
        self.Main.Visible = true
        self.Floating.Visible = false

        self.Main.Size = self.OriginalSize
        self.Main.BackgroundTransparency = 1

        Animate(self.Main, 0.24, {
            BackgroundTransparency = 0
        })
    else
        self.Main.Visible = false
        self.Floating.Visible = true
    end
end

--==================================================
-- DESTROY
--==================================================

function NexusUI:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if self.Screen then
        self.Screen:Destroy()
    end
end

--==================================================
-- CREATE WINDOW
--==================================================

function NexusUI.new(options)
    options = options or {}

    local self = setmetatable({}, NexusUI)

    self.Name = options.Name or "NEXUS UI"
    self.Subtitle = options.Subtitle or "Modern Workspace Interface"

    self.Theme = table.clone(DefaultTheme)
    self.Connections = {}
    self.Tabs = {}

    self.Visible = true
    self.Destroyed = false

    local parent = options.Parent

    if not parent then
        assert(Player, "NEXUS UI must run on the client")
        parent = Player:WaitForChild("PlayerGui")
    end

    self.Screen = Create("ScreenGui", {
        Name = "NEXUS_UI_" .. HttpService:GenerateGUID(false):sub(1, 8),
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 50
    }, parent)

    -- MAIN WINDOW

    self.Main = Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(820, 540),
        BackgroundColor3 = self:_theme("Background"),
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, self.Screen)

    Corner(self.Main, 19)
    Stroke(self.Main, self:_theme("Border"), 0.12, 1.5)

    self.OriginalSize = UDim2.fromOffset(820, 540)

    -- RESPONSIVE LAYOUT

    local function updateSize()
        local camera = workspace.CurrentCamera

        if not camera then
            return
        end

        local viewport = camera.ViewportSize

        local width = math.clamp(
            viewport.X * 0.94,
            300,
            1050
        )

        local height = math.clamp(
            viewport.Y * 0.84,
            340,
            760
        )

        self.OriginalSize = UDim2.fromOffset(width, height)
        self.Main.Size = self.OriginalSize

        local mobile = viewport.X < 650

        self.Sidebar.Size = mobile
            and UDim2.new(0, 112, 1, -85)
            or UDim2.new(0, 215, 1, -85)

        self.PageHolder.Position = mobile
            and UDim2.new(0, 124, 0, 72)
            or UDim2.new(0, 227, 0, 72)

        self.PageHolder.Size = mobile
            and UDim2.new(1, -136, 1, -85)
            or UDim2.new(1, -239, 1, -85)

        self.ProfileTitle.TextSize = mobile and 12 or 14
        self.ProfileSubtitle.TextSize = mobile and 9 or 11
    end

    -- HEADER

    local topbar = Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = self:_theme("Surface"),
        BorderSizePixel = 0
    }, self.Main)

    local title = MakeText(
        topbar,
        self.Name,
        17,
        self:_theme("Text"),
        Enum.Font.GothamBold
    )

    title.Position = UDim2.new(0, 20, 0, 8)
    title.Size = UDim2.new(1, -100, 0, 25)

    local subtitle = MakeText(
        topbar,
        self.Subtitle,
        10,
        self:_theme("Muted")
    )

    subtitle.Position = UDim2.new(0, 21, 0, 34)
    subtitle.Size = UDim2.new(1, -100, 0, 16)

    local minimize = Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -16, 0.5, 0),
        Size = UDim2.new(0, 38, 0, 35),
        BackgroundColor3 = self:_theme("SurfaceLight"),
        Text = "—",
        TextColor3 = self:_theme("Text"),
        TextSize = 19,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0
    }, topbar)

    Corner(minimize, 10)

    minimize.Activated:Connect(function()
        self:Toggle()
    end)

    -- DRAGGING

    local dragging = false
    local dragStart
    local startPosition

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = self.Main.Position
        end
    end)

    self:_track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

            local delta = input.Position - dragStart

            self.Main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))

    self:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = false
        end
    end))

    -- PROFILE / STATUS CARD

    self.Sidebar = Create("Frame", {
        Name = "Sidebar",
        Position = UDim2.new(0, 12, 0, 72),
        Size = UDim2.new(0, 215, 1, -85),
        BackgroundColor3 = self:_theme("Surface"),
        BorderSizePixel = 0
    }, self.Main)

    Corner(self.Sidebar, 15)

    local profile = Create("Frame", {
        Position = UDim2.new(0, 9, 0, 9),
        Size = UDim2.new(1, -18, 0, 91),
        BackgroundColor3 = self:_theme("Input"),
        BorderSizePixel = 0
    }, self.Sidebar)

    Corner(profile, 12)

    local avatar = Create("Frame", {
        Position = UDim2.new(0, 12, 0.5, -23),
        Size = UDim2.new(0, 46, 0, 46),
        BackgroundColor3 = self:_theme("AccentDark"),
        BorderSizePixel = 0
    }, profile)

    Corner(avatar, 24)

    local avatarText = MakeText(
        avatar,
        "N",
        21,
        Color3.new(1, 1, 1),
        Enum.Font.GothamBlack
    )

    avatarText.Size = UDim2.fromScale(1, 1)
    avatarText.TextXAlignment = Enum.TextXAlignment.Center

    self.ProfileTitle = MakeText(
        profile,
        self.Name,
        14,
        self:_theme("InputText"),
        Enum.Font.GothamBold
    )

    self.ProfileTitle.Position = UDim2.new(0, 68, 0, 22)
    self.ProfileTitle.Size = UDim2.new(1, -75, 0, 22)

    self.ProfileSubtitle = MakeText(
        profile,
        "Workspace manager",
        11,
        Color3.fromRGB(105, 96, 127)
    )

    self.ProfileSubtitle.Position = UDim2.new(0, 68, 0, 47)
    self.ProfileSubtitle.Size = UDim2.new(1, -75, 0, 20)

    -- NAVIGATION HEADER

    local navigationLabel = MakeText(
        self.Sidebar,
        "NAVIGATION",
        10,
        self:_theme("Muted"),
        Enum.Font.GothamBold
    )

    navigationLabel.Position = UDim2.new(0, 13, 0, 111)
    navigationLabel.Size = UDim2.new(1, -26, 0, 20)

    -- TAB LIST

    self.TabList = Create("ScrollingFrame", {
        Position = UDim2.new(0, 9, 0, 137),
        Size = UDim2.new(1, -18, 1, -195),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = self:_theme("Accent"),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, self.Sidebar)

    Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, self.TabList)

    -- SIDEBAR BOTTOM BUTTONS

    local bottom = Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 9, 1, -9),
        Size = UDim2.new(1, -18, 0, 39),
        BackgroundTransparency = 1
    }, self.Sidebar)

    Create("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 1, 0),
        CellPadding = UDim2.new(0, 8, 0, 0),
        FillDirectionMaxCells = 2
    }, bottom)

    local sendButton = MakeButton(
        bottom,
        "Send",
        self.Theme,
        function()
            self:Notify({
                Title = "NEXUS UI",
                Content = "Interface is active.",
                Type = "Success"
            })
        end,
        39
    )

    local closeButton = MakeButton(
        bottom,
        "Exit",
        self.Theme,
        function()
            self:Destroy()
        end,
        39
    )

    -- PAGE HOLDER

    self.PageHolder = Create("Frame", {
        Name = "PageHolder",
        Position = UDim2.new(0, 227, 0, 72),
        Size = UDim2.new(1, -239, 1, -85),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, self.Main)

    -- CONTENT HEADER

    local pageHeader = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 91),
        BackgroundColor3 = self:_theme("Input"),
        BorderSizePixel = 0
    }, self.PageHolder)

    Corner(pageHeader, 13)

    local pageIcon = Create("Frame", {
        Position = UDim2.new(0, 13, 0.5, -17),
        Size = UDim2.new(0, 34, 0, 34),
        BackgroundColor3 = self:_theme("AccentDark"),
        BorderSizePixel = 0
    }, pageHeader)

    Corner(pageIcon, 20)

    local pageIconText = MakeText(
        pageIcon,
        "◆",
        15,
        Color3.new(1, 1, 1),
        Enum.Font.GothamBold
    )

    pageIconText.Size = UDim2.fromScale(1, 1)
    pageIconText.TextXAlignment = Enum.TextXAlignment.Center

    local pageTitle = MakeText(
        pageHeader,
        "Workspace",
        16,
        self:_theme("InputText"),
        Enum.Font.GothamBold
    )

    pageTitle.Position = UDim2.new(0, 57, 0, 19)
    pageTitle.Size = UDim2.new(1, -70, 0, 24)

    local pageDescription = MakeText(
        pageHeader,
        "Select a section from the navigation panel",
        10,
        Color3.fromRGB(111, 102, 135)
    )

    pageDescription.Position = UDim2.new(0, 58, 0, 46)
    pageDescription.Size = UDim2.new(1, -70, 0, 19)

    -- CONTENT BACKGROUND

    local contentBackground = Create("Frame", {
        Position = UDim2.new(0, 0, 0, 103),
        Size = UDim2.new(1, 0, 1, -103),
        BackgroundColor3 = self:_theme("Surface"),
        BorderSizePixel = 0
    }, self.PageHolder)

    Corner(contentBackground, 13)

    -- PAGE CONTAINER

    self.PageHolder = contentBackground

    -- REPLACE PAGE HOLDER CONTENT WITH A CONTAINER

    local pageContainer = Create("Frame", {
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(1, -24, 1, -24),
        BackgroundTransparency = 1
    }, contentBackground)

    self.PageHolder = pageContainer

    -- UPDATE PAGE HEADER WHEN TAB CHANGES

    local oldTab = self.Tab

    function self:Tab(name, icon)
        local tab = oldTab(self, name, icon)

        tab.Button.Activated:Connect(function()
            pageTitle.Text = name
            pageDescription.Text = "Manage " .. name .. " settings"

            pageIconText.Text = icon or "◆"
        end)

        if #self.Tabs == 1 then
            pageTitle.Text = name
            pageDescription.Text = "Manage " .. name .. " settings"
            pageIconText.Text = icon or "◆"
        end

        return tab
    end

    -- NOTIFICATIONS

    self.ToastHolder = Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.new(0, 285, 1, -28),
        BackgroundTransparency = 1,
        ZIndex = 150
    }, self.Screen)

    Create("UIListLayout", {
        Padding = UDim.new(0, 9),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, self.ToastHolder)

    -- FLOATING ACTION BUTTON

    self.Floating = Create("TextButton", {
        Name = "NEXUS_FloatingButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -48, 0.5, 0),
        Size = UDim2.new(0, 57, 0, 57),
        BackgroundColor3 = self:_theme("AccentDark"),
        Text = "N",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 24,
        Font = Enum.Font.GothamBlack,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 200
    }, self.Screen)

    Corner(self.Floating, 20)
    Stroke(self.Floating, self:_theme("Border"), 0.15, 1.5)

    self.Floating.Activated:Connect(function()
        self:Toggle()
    end)

    -- FLOATING BUTTON DRAGGING

    local floatingDrag = false
    local floatingStart
    local floatingPosition

    self.Floating.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            floatingDrag = true
            floatingStart = input.Position
            floatingPosition = self.Floating.Position
        end
    end)

    self:_track(UserInputService.InputChanged:Connect(function(input)
        if floatingDrag and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

            local delta = input.Position - floatingStart

            self.Floating.Position = UDim2.new(
                floatingPosition.X.Scale,
                floatingPosition.X.Offset + delta.X,
                floatingPosition.Y.Scale,
                floatingPosition.Y.Offset + delta.Y
            )
        end
    end))

    self:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            floatingDrag = false
        end
    end))

    -- RESPONSIVE INITIALIZATION

    updateSize()

    if workspace.CurrentCamera then
        self:_track(
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
                updateSize
            )
        )
    end

    -- KEYBOARD TOGGLE

    if not UserInputService.TouchEnabled then
        self:_track(UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == (
                options.ToggleKey or Enum.KeyCode.RightControl
            ) then
                self:Toggle()
            end
        end))
    end

    return self
end

return NexusUI
