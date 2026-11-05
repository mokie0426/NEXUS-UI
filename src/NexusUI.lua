
--[[
    NEXUS UI v1.0.0
    Modern Roblox Luau UI Library
    Purple / Black Edition

    Features:
    - Responsive mobile and desktop window
    - Draggable window (touch + mouse)
    - Minimize / floating reopen button
    - Sidebar tabs
    - Collapsible sections
    - Buttons
    - Toggles
    - Sliders
    - Textboxes
    - Dropdowns
    - MultiDropdowns
    - Keybinds
    - Colorpickers
    - Labels
    - Paragraphs
    - Dividers
    - Notifications
    - Confirmation dialogs
    - Theme customization
    - Cleanup / Destroy

    Use in a LocalScript through require().
]]

local NexusUI = {}
NexusUI.__index = NexusUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

local DefaultTheme = {
    Background = Color3.fromRGB(25, 22, 43),
    Surface = Color3.fromRGB(39, 34, 65),
    SurfaceLight = Color3.fromRGB(54, 47, 88),
    SurfaceHover = Color3.fromRGB(72, 60, 110),
    Accent = Color3.fromRGB(155, 91, 255),
    AccentDark = Color3.fromRGB(105, 58, 190),
    Text = Color3.fromRGB(247, 244, 255),
    Muted = Color3.fromRGB(177, 169, 202),
    Border = Color3.fromRGB(112, 91, 157),
    Success = Color3.fromRGB(91, 218, 150),
    Warning = Color3.fromRGB(255, 190, 85),
    Error = Color3.fromRGB(255, 99, 119)
}

local function New(class, properties, parent)
    local object = Instance.new(class)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent
    return object
end

local function Round(object, radius)
    New("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, object)
end

local function Outline(object, color, transparency)
    New("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = 1
    }, object)
end

local function Tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()
    return animation
end

local function Callback(callback, ...)
    if typeof(callback) == "function" then
        local success, err = pcall(callback, ...)

        if not success then
            warn("[NEXUS UI] " .. tostring(err))
        end
    end
end

local function Text(parent, value, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(value or ""),
        TextColor3 = color or DefaultTheme.Text,
        TextSize = size or 13,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, 22)
    }, parent)
end

local function Button(parent, value, callback, theme)
    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = theme.SurfaceLight,
        Text = tostring(value or "Button"),
        TextColor3 = theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        BorderSizePixel = 0
    }, parent)

    Round(button, 9)

    button.MouseEnter:Connect(function()
        Tween(button, 0.15, {
            BackgroundColor3 = theme.SurfaceHover
        })
    end)

    button.MouseLeave:Connect(function()
        Tween(button, 0.15, {
            BackgroundColor3 = theme.SurfaceLight
        })
    end)

    button.Activated:Connect(function()
        Callback(callback)
    end)

    return button
end

function NexusUI:_theme(key)
    return self.Theme[key] or DefaultTheme[key]
end

function NexusUI:_track(connection)
    table.insert(self.Connections, connection)
    return connection
end

function NexusUI:_control(parent, height)
    return New("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1
    }, parent)
end

-- NOTIFICATIONS

function NexusUI:Notify(options)
    options = options or {}

    local colors = {
        Success = self:_theme("Success"),
        Error = self:_theme("Error"),
        Warning = self:_theme("Warning"),
        Info = self:_theme("Accent")
    }

    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 76),
        BackgroundColor3 = self:_theme("Surface"),
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0
    }, self.ToastHolder)

    Round(card, 11)
    Outline(card, self:_theme("Border"), 0.3)

    local stripe = New("Frame", {
        Position = UDim2.new(0, 8, 0, 9),
        Size = UDim2.new(0, 4, 1, -18),
        BackgroundColor3 = colors[options.Type or "Info"] or colors.Info,
        BorderSizePixel = 0
    }, card)

    Round(stripe, 5)

    local title = Text(
        card,
        options.Title or "Notification",
        14,
        self:_theme("Text"),
        Enum.Font.GothamBold
    )

    title.Position = UDim2.new(0, 22, 0, 8)
    title.Size = UDim2.new(1, -30, 0, 22)

    local message = Text(
        card,
        options.Content or options.Message or "",
        12,
        self:_theme("Muted")
    )

    message.Position = UDim2.new(0, 22, 0, 32)
    message.Size = UDim2.new(1, -30, 0, 34)
    message.TextWrapped = true
    message.TextYAlignment = Enum.TextYAlignment.Top

    card.BackgroundTransparency = 1
    Tween(card, 0.2, {
        BackgroundTransparency = 0.03
    })

    task.delay(options.Duration or 4, function()
        if card.Parent then
            Tween(card, 0.2, {
                BackgroundTransparency = 1
            })

            task.wait(0.22)

            if card.Parent then
                card:Destroy()
            end
        end
    end)
end

-- CONFIRMATION DIALOG

function NexusUI:Dialog(options)
    options = options or {}

    local overlay = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.35,
        ZIndex = 30
    }, self.Screen)

    local panel = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.85, 0, 0, 190),
        BackgroundColor3 = self:_theme("Surface"),
        BorderSizePixel = 0,
        ZIndex = 31
    }, overlay)

    Round(panel, 14)
    Outline(panel, self:_theme("Border"), 0.2)

    local title = Text(
        panel,
        options.Title or "Confirm action",
        17,
        self:_theme("Text"),
        Enum.Font.GothamBold
    )

    title.Position = UDim2.new(0, 15, 0, 12)
    title.Size = UDim2.new(1, -30, 0, 28)
    title.ZIndex = 32

    local content = Text(
        panel,
        options.Content or "Are you sure?",
        13,
        self:_theme("Muted")
    )

    content.Position = UDim2.new(0, 15, 0, 48)
    content.Size = UDim2.new(1, -30, 0, 75)
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.ZIndex = 32

    local cancel = New("TextButton", {
        Position = UDim2.new(0, 15, 1, -50),
        Size = UDim2.new(0.42, -5, 0, 36),
        BackgroundColor3 = self:_theme("SurfaceLight"),
        Text = options.CancelText or "Cancel",
        TextColor3 = self:_theme("Text"),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        BorderSizePixel = 0,
        ZIndex = 33
    }, panel)

    Round(cancel, 8)

    local confirm = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -15, 1, -50),
        Size = UDim2.new(0.48, -5, 0, 36),
        BackgroundColor3 = self:_theme("AccentDark"),
        Text = options.ConfirmText or "Confirm",
        TextColor3 = self:_theme("Text"),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
        ZIndex = 33
    }, panel)

    Round(confirm, 8)

    cancel.Activated:Connect(function()
        overlay:Destroy()
        Callback(options.OnCancel)
    end)

    confirm.Activated:Connect(function()
        overlay:Destroy()
        Callback(options.OnConfirm)
    end)
end

-- TAB SYSTEM

function NexusUI:Tab(name, icon)
    assert(not self.Destroyed, "NEXUS UI has been destroyed")

    local tabButton = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = self:_theme("AccentDark"),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, self.TabList)

    Round(tabButton, 9)

    local iconText = Text(
        tabButton,
        icon or "◆",
        15,
        self:_theme("Muted"),
        Enum.Font.GothamBold
    )

    iconText.Position = UDim2.new(0, 10, 0, 0)
    iconText.Size = UDim2.new(0, 25, 1, 0)
    iconText.TextXAlignment = Enum.TextXAlignment.Center

    local tabName = Text(
        tabButton,
        name,
        13,
        self:_theme("Muted"),
        Enum.Font.GothamMedium
    )

    tabName.Position = UDim2.new(0, 42, 0, 0)
    tabName.Size = UDim2.new(1, -45, 1, 0)

    local page = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self:_theme("Accent"),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, self.PageHolder)

    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 7)
    }, page)

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    local tab = {
        Library = self,
        Name = name,
        Button = tabButton,
        Page = page,
        Label = tabName,
        Icon = iconText
    }

    table.insert(self.Tabs, tab)

    local function selectTab()
        if self.ActiveTab == tab then
            return
        end

        for _, other in ipairs(self.Tabs) do
            local active = other == tab

            Tween(other.Button, 0.15, {
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
        tabName.TextColor3 = self:_theme("Text")
        iconText.TextColor3 = self:_theme("Text")
    end

    return tab
end

-- SECTION SYSTEM

function NexusUI:Section(sectionName)
    local tab = self

    local section = New("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = tab.Library:_theme("Surface"),
        BorderSizePixel = 0
    }, tab.Page)

    Round(section, 11)
    Outline(section, tab.Library:_theme("Border"), 0.7)

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 11),
        PaddingRight = UDim.new(0, 11),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 10)
    }, section)

    local header = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    }, section)

    local heading = Text(
        header,
        sectionName or "Section",
        13,
        tab.Library:_theme("Text"),
        Enum.Font.GothamBold
    )

    heading.Size = UDim2.new(1, -25, 1, 0)

    local arrow = Text(header, "⌄", 18, tab.Library:_theme("Muted"))
    arrow.Position = UDim2.new(1, -22, 0, 0)
    arrow.Size = UDim2.new(0, 22, 1, 0)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local content = New("Frame", {
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    }, section)

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, content)

    local collapsed = false

    header.Activated:Connect(function()
        collapsed = not collapsed
        content.Visible = not collapsed
        arrow.Text = collapsed and "›" or "⌄"
    end)

    local API = {}
    API.Library = tab.Library
    API.Container = content

    -- BUTTON

    function API:Button(options)
        if typeof(options) ~= "table" then
            options = { Name = tostring(options) }
        end

        local item = self.Library:_control(
            self.Container,
            options.Height or 38
        )

        local button = Button(
            item,
            options.Name or "Button",
            options.Callback,
            self.Library.Theme
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

        local item = self.Library:_control(self.Container, 38)

        local label = Text(
            item,
            options.Name or "Toggle",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -65, 1, 0)

        local track = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 48, 0, 25),
            BackgroundColor3 = value
                and self.Library:_theme("Accent")
                or self.Library:_theme("SurfaceLight"),
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0
        }, item)

        Round(track, 20)

        local knob = New("Frame", {
            Size = UDim2.new(0, 19, 0, 19),
            Position = value
                and UDim2.new(1, -22, 0.5, -9)
                or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0
        }, track)

        Round(knob, 20)

        local function set(newValue, fire)
            value = newValue == true

            Tween(track, 0.15, {
                BackgroundColor3 = value
                    and self.Library:_theme("Accent")
                    or self.Library:_theme("SurfaceLight")
            })

            Tween(knob, 0.15, {
                Position = value
                    and UDim2.new(1, -22, 0.5, -9)
                    or UDim2.new(0, 3, 0.5, -9)
            })

            if fire then
                Callback(options.Callback, value)
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

        local item = self.Library:_control(self.Container, 57)

        local label = Text(
            item,
            options.Name or "Slider",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -65, 0, 21)

        local valueLabel = Text(
            item,
            tostring(value),
            12,
            self.Library:_theme("Accent")
        )

        valueLabel.Position = UDim2.new(1, -65, 0, 0)
        valueLabel.Size = UDim2.new(0, 65, 0, 21)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right

        local bar = New("TextButton", {
            Position = UDim2.new(0, 0, 0, 34),
            Size = UDim2.new(1, 0, 0, 8),
            BackgroundColor3 = self.Library:_theme("SurfaceLight"),
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false
        }, item)

        Round(bar, 8)

        local fill = New("Frame", {
            Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = self.Library:_theme("Accent"),
            BorderSizePixel = 0
        }, bar)

        Round(fill, 8)

        local dragging = false

        local function setFromX(x, fire)
            local ratio = math.clamp(
                (x - bar.AbsolutePosition.X) /
                math.max(bar.AbsoluteSize.X, 1),
                0,
                1
            )

            local raw = min + (max - min) * ratio
            local multiplier = 10 ^ decimals

            value = math.clamp(
                math.floor(raw * multiplier + 0.5) / multiplier,
                min,
                max
            )

            fill.Size = UDim2.new(
                (value - min) / (max - min),
                0, 1, 0
            )

            valueLabel.Text = tostring(value)

            if fire then
                Callback(options.Callback, value)
            end
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = true
                setFromX(input.Position.X, true)
            end
        end)

        self.Library:_track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                setFromX(input.Position.X, true)
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
                value = math.clamp(tonumber(newValue) or min, min, max)

                local ratio = (value - min) / (max - min)

                setFromX(
                    bar.AbsolutePosition.X + bar.AbsoluteSize.X * ratio,
                    true
                )
            end
        }
    end

    -- TEXTBOX

    function API:Textbox(options)
        options = options or {}

        local item = self.Library:_control(self.Container, 68)

        local label = Text(
            item,
            options.Name or "Textbox",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, 0, 0, 20)

        local box = New("TextBox", {
            Position = UDim2.new(0, 0, 0, 26),
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = self.Library:_theme("SurfaceLight"),
            Text = tostring(options.Default or ""),
            PlaceholderText = options.Placeholder or "Enter text...",
            PlaceholderColor3 = self.Library:_theme("Muted"),
            TextColor3 = self.Library:_theme("Text"),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            ClearTextOnFocus = options.ClearOnFocus == true,
            BorderSizePixel = 0
        }, item)

        Round(box, 8)

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        }, box)

        box.FocusLost:Connect(function(enterPressed)
            Callback(options.Callback, box.Text, enterPressed)
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

        local item = self.Library:_control(self.Container, 66)

        local label = Text(
            item,
            options.Name or "Dropdown",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, 0, 0, 20)

        local trigger = New("TextButton", {
            Position = UDim2.new(0, 0, 0, 25),
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = self.Library:_theme("SurfaceLight"),
            Text = tostring(selected or options.Placeholder or "Select option") .. "   ▾",
            TextColor3 = self.Library:_theme("Text"),
            TextSize = 13,
            Font = Enum.Font.Gotham,
            BorderSizePixel = 0,
            AutoButtonColor = false
        }, item)

        Round(trigger, 8)

        local menu = New("ScrollingFrame", {
            Position = UDim2.new(0, 0, 0, 65),
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = self.Library:_theme("Background"),
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 10
        }, item)

        Round(menu, 8)

        New("UIListLayout", {
            Padding = UDim.new(0, 3)
        }, menu)

        New("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5)
        }, menu)

        local function refresh()
            for _, child in ipairs(menu:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            for _, option in ipairs(values) do
                local choice = New("TextButton", {
                    Size = UDim2.new(1, -4, 0, 31),
                    BackgroundColor3 = self.Library:_theme("SurfaceLight"),
                    Text = tostring(option),
                    TextColor3 = self.Library:_theme("Text"),
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    BorderSizePixel = 0,
                    ZIndex = 11
                }, menu)

                Round(choice, 6)

                choice.Activated:Connect(function()
                    selected = option

                    trigger.Text = tostring(option) .. "   ▾"

                    opened = false
                    menu.Visible = false
                    item.Size = UDim2.new(1, 0, 0, 66)

                    Callback(options.Callback, option)
                end)
            end
        end

        refresh()

        trigger.Activated:Connect(function()
            opened = not opened
            menu.Visible = opened

            local height = math.min(#values * 34 + 10, 150)

            menu.Size = UDim2.new(
                1, 0,
                0, opened and height or 0
            )

            item.Size = UDim2.new(
                1, 0,
                0, opened and (76 + height) or 66
            )
        end)

        return {
            Get = function()
                return selected
            end,

            Set = function(_, value)
                selected = value
                trigger.Text = tostring(value) .. "   ▾"
                Callback(options.Callback, value)
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

                Callback(options.Callback, result)
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
                Callback(options.Callback, result)
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

        local item = self.Library:_control(self.Container, 38)

        local label = Text(
            item,
            options.Name or "Keybind",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -110, 1, 0)

        local keyButton = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 100, 0, 30),
            BackgroundColor3 = self.Library:_theme("SurfaceLight"),
            Text = current.Name,
            TextColor3 = self.Library:_theme("Text"),
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            BorderSizePixel = 0
        }, item)

        Round(keyButton, 7)

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

                Callback(options.Changed, current)

            elseif not listening and input.KeyCode == current then
                Callback(options.Callback, current)
            end
        end))

        return {
            Get = function()
                return current
            end,

            Set = function(_, key)
                if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
                    current = key
                    keyButton.Text = key.Name
                end
            end
        }
    end

    -- COLORPICKER
    -- Tap to cycle hue. Set(Color3) for an exact color.

    function API:Colorpicker(options)
        options = options or {}

        local color = options.Default or self.Library:_theme("Accent")

        local item = self.Library:_control(self.Container, 40)

        local label = Text(
            item,
            options.Name or "Colorpicker",
            13,
            self.Library:_theme("Text")
        )

        label.Size = UDim2.new(1, -55, 1, 0)

        local swatch = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 42, 0, 27),
            BackgroundColor3 = color,
            Text = "",
            BorderSizePixel = 0
        }, item)

        Round(swatch, 7)

        swatch.Activated:Connect(function()
            local h, s, v = color:ToHSV()

            color = Color3.fromHSV(
                (h + 0.08) % 1,
                s,
                v
            )

            swatch.BackgroundColor3 = color
            Callback(options.Callback, color)
        end)

        return {
            Get = function()
                return color
            end,

            Set = function(_, newColor)
                if typeof(newColor) == "Color3" then
                    color = newColor
                    swatch.BackgroundColor3 = color
                    Callback(options.Callback, color)
                end
            end
        }
    end

    -- LABEL

    function API:Label(value)
        local item = self.Library:_control(self.Container, 25)

        local label = Text(
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

        local item = self.Library:_control(self.Container, 58)

        local title = Text(
            item,
            options.Title or "Information",
            13,
            self.Library:_theme("Text"),
            Enum.Font.GothamBold
        )

        title.Size = UDim2.new(1, 0, 0, 20)

        local body = Text(
            item,
            options.Content or "",
            12,
            self.Library:_theme("Muted")
        )

        body.Position = UDim2.new(0, 0, 0, 22)
        body.Size = UDim2.new(1, 0, 0, 34)
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
        local item = self.Library:_control(self.Container, 10)

        local line = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = self.Library:_theme("Border"),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0
        }, item)

        return line
    end

    return API
end

-- THEME

function NexusUI:SetTheme(theme)
    for key, value in pairs(theme or {}) do
        if DefaultTheme[key] and typeof(value) == "Color3" then
            self.Theme[key] = value
        end
    end
end

-- WINDOW VISIBILITY

function NexusUI:Toggle()
    if self.Destroyed then
        return
    end

    self.Visible = not self.Visible

    self.Main.Visible = self.Visible
    self.Floating.Visible = not self.Visible
end

-- CLEANUP

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

-- CREATE WINDOW

function NexusUI.new(options)
    options = options or {}

    local self = setmetatable({}, NexusUI)

    self.Name = options.Name or "NEXUS UI"
    self.Subtitle = options.Subtitle or "Roblox Interface Library"
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

    self.Screen = New("ScreenGui", {
        Name = "NEXUS_UI_" .. HttpService:GenerateGUID(false):sub(1, 8),
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = options.DisplayOrder or 20
    }, parent)

    -- MAIN WINDOW

    self.Main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(720, 470),
        BackgroundColor3 = self:_theme("Background"),
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, self.Screen)

    Round(self.Main, 16)
    Outline(self.Main, self:_theme("Border"), 0.08)

    New("UISizeConstraint", {
        MinSize = Vector2.new(300, 330),
        MaxSize = Vector2.new(900, 650)
    }, self.Main)

    -- RESPONSIVE WINDOW

    local function updateSize()
        local camera = workspace.CurrentCamera

        if not camera then
            return
        end

        local viewport = camera.ViewportSize

        local width = math.clamp(
            viewport.X * 0.92,
            300,
            900
        )

        local height = math.clamp(
            viewport.Y * 0.78,
            330,
            650
        )

        self.Main.Size = UDim2.fromOffset(width, height)
    end

    updateSize()

    if workspace.CurrentCamera then
        self:_track(
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
        )
    end

    -- TOP BAR

    local topbar = New("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = self:_theme("Surface"),
        BorderSizePixel = 0
    }, self.Main)

    local title = Text(
        topbar,
        self.Name,
        17,
        self:_theme("Text"),
        Enum.Font.GothamBold
    )

    title.Position = UDim2.new(0, 18, 0, 6)
    title.Size = UDim2.new(1, -110, 0, 25)

    local subtitle = Text(
        topbar,
        self.Subtitle,
        10,
        self:_theme("Muted")
    )

    subtitle.Position = UDim2.new(0, 19, 0, 32)
    subtitle.Size = UDim2.new(1, -110, 0, 15)

    local minimize = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.new(0, 35, 0, 32),
        BackgroundColor3 = self:_theme("SurfaceLight"),
        Text = "—",
        TextColor3 = self:_theme("Text"),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0
    }, topbar)

    Round(minimize, 8)

    minimize.Activated:Connect(function()
        self:Toggle()
    end)

    -- DRAGGING: TOUCH + MOUSE

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

    -- SIDEBAR

    self.Sidebar = New("Frame", {
        Position = UDim2.new(0, 12, 0, 70),
        Size = UDim2.new(0, 174, 1, -82),
        BackgroundColor3 = self:_theme("Surface"),
        BorderSizePixel = 0
    }, self.Main)

    Round(self.Sidebar, 12)

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 9)
    }, self.Sidebar)

    self.TabList = New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1
    }, self.Sidebar)

    New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, self.TabList)

    -- PAGE HOLDER

    self.PageHolder = New("Frame", {
        Position = UDim2.new(0, 198, 0, 70),
        Size = UDim2.new(1, -210, 1, -82),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, self.Main)

    -- NOTIFICATION HOLDER

    self.ToastHolder = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.new(0, 270, 1, -24),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, self.Screen)

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    }, self.ToastHolder)

    -- FLOATING BUTTON

    self.Floating = New("TextButton", {
        Name = "NEXUS_FloatingButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -48, 0.5, 0),
        Size = UDim2.new(0, 54, 0, 54),
        BackgroundColor3 = self:_theme("AccentDark"),
        Text = "N",
        TextColor3 = self:_theme("Text"),
        TextSize = 23,
        Font = Enum.Font.GothamBlack,
        BorderSizePixel = 0,
        Visible = false
    }, self.Screen)

    Round(self.Floating, 18)
    Outline(self.Floating, self:_theme("Border"), 0.1)

    self.Floating.Activated:Connect(function()
        self:Toggle()
    end)

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
