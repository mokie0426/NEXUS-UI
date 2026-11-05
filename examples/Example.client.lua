--[[
    NEXUS UI v1.0.0
    Example.client.lua

    Library source:
    https://github.com/mokie0426/NEXUS-UI

    Raw ModuleScript source:
    https://raw.githubusercontent.com/mokie0426/NEXUS-UI/main/src/NexusUI.lua

    Installation:
    ReplicatedStorage
        └── NexusUI (ModuleScript copied from src/NexusUI.lua)

    StarterPlayer
        └── StarterPlayerScripts
            └── Example.client.lua (LocalScript)

    This example uses the current AddTab/AddSection API from NexusUI.lua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NexusUI = require(ReplicatedStorage:WaitForChild("NexusUI"))

local Window = NexusUI.new({
    Name = "NEXUS UI",
    Subtitle = "Advanced Roblox Interface",
    DisplayOrder = 50,
    Theme = {
        Accent = Color3.fromRGB(155, 91, 255),
        Accent2 = Color3.fromRGB(190, 130, 255),
    },
})

-- HOME TAB

local Home = Window:AddTab({Name = "Home", Icon = "◆"})
local Welcome = Window:AddSection(Home, {Name = "Welcome"})

Welcome:AddParagraph({
    Text = "A modern, responsive Roblox UI library designed for desktop and Android devices. This example demonstrates the complete current component API.",
})

Welcome:AddButton({
    Name = "Show Notification",
    Callback = function()
        Window:Notify({
            Title = "NEXUS UI",
            Content = "Your interface is working successfully!",
            Color = Window.Theme.Success,
            Duration = 4,
        })
    end,
})

Welcome:AddDivider()
Welcome:AddLabel("Library Version: 1.0.0")

Welcome:AddButton({
    Name = "Test Confirmation Dialog",
    Callback = function()
        Window:Dialog({
            Title = "Confirmation",
            Content = "Do you want to execute this example action?",
            ConfirmText = "Continue",
            CancelText = "Cancel",
            OnConfirm = function()
                Window:Notify({
                    Title = "Confirmed",
                    Content = "You pressed Continue.",
                    Color = Window.Theme.Success,
                })
            end,
            OnCancel = function()
                Window:Notify({
                    Title = "Cancelled",
                    Content = "You cancelled the action.",
                    Color = Window.Theme.Warning,
                })
            end,
        })
    end,
})

-- CONTROLS TAB

local Controls = Window:AddTab({Name = "Controls", Icon = "⚙"})
local Basic = Window:AddSection(Controls, {Name = "Basic Components"})

Basic:AddButton({
    Name = "Click Me",
    Callback = function()
        print("NEXUS: Button clicked!")
        Window:Notify({
            Title = "Button",
            Content = "Button successfully clicked.",
            Color = Window.Theme.Accent,
        })
    end,
})

local Enabled = Basic:AddToggle({
    Name = "Enable Feature",
    Flag = "EnableFeature",
    Default = false,
    Callback = function(value)
        print("Feature Enabled:", value)
    end,
})

Basic:AddButton({
    Name = "Toggle Programmatically",
    Callback = function()
        Enabled:Set(not Enabled:Get())
    end,
})

Basic:AddDivider()

local Slider = Basic:AddSlider({
    Name = "Volume",
    Flag = "Volume",
    Min = 0,
    Max = 100,
    Default = 50,
    Decimals = 0,
    Callback = function(value)
        print("Volume:", value)
    end,
})

Basic:AddButton({
    Name = "Set Volume to 75",
    Callback = function()
        Slider:Set(75)
    end,
})

-- INPUT TAB

local InputTab = Window:AddTab({Name = "Input", Icon = "⌨"})
local InputSection = Window:AddSection(InputTab, {Name = "Text Input"})

local PlayerName = InputSection:AddTextbox({
    Name = "Player Name",
    Flag = "PlayerName",
    Placeholder = "Enter your name...",
    Default = "",
    Callback = function(value, enterPressed)
        print("Player Name:", value)
        print("Pressed Enter:", enterPressed)
    end,
})

InputSection:AddButton({
    Name = "Read Textbox",
    Callback = function()
        Window:Notify({
            Title = "Textbox Value",
            Content = "Current text: " .. PlayerName:Get(),
            Color = Window.Theme.Accent,
        })
    end,
})

-- DROPDOWN TAB

local DropdownTab = Window:AddTab({Name = "Dropdowns", Icon = "▾"})
local DropSection = Window:AddSection(DropdownTab, {Name = "Selection Components"})

local Dropdown = DropSection:AddDropdown({
    Name = "Choose a Mode",
    Flag = "Mode",
    Values = {"Easy", "Normal", "Hard", "Extreme"},
    Default = "Normal",
    Callback = function(value)
        print("Selected Mode:", value)
    end,
})

DropSection:AddButton({
    Name = "Print Selected Mode",
    Callback = function()
        print("Current Mode:", Dropdown:Get())
    end,
})

local Multi = DropSection:AddDropdown({
    Name = "Choose Multiple Options",
    Flag = "Options",
    Values = {"Graphics", "Shadows", "Effects", "Particles", "Animations"},
    Multi = true,
    Default = {"Graphics", "Effects"},
    Callback = function(values)
        print("Selected options:")
        for value, selected in pairs(values) do
            if selected then
                print("-", value)
            end
        end
    end,
})

DropSection:AddButton({
    Name = "Show Multi Selection",
    Callback = function()
        local values = Multi:Get()
        for value, selected in pairs(values) do
            if selected then
                print(value)
            end
        end
    end,
})

-- KEYBIND TAB

local KeybindTab = Window:AddTab({Name = "Keybinds", Icon = "⌘"})
local KeySection = Window:AddSection(KeybindTab, {Name = "Keyboard Controls"})

KeySection:AddKeybind({
    Name = "Action Key",
    Flag = "ActionKey",
    Default = Enum.KeyCode.G,
    Callback = function(key)
        print("Pressed:", key.Name)
        Window:Notify({
            Title = "Keybind Activated",
            Content = "You pressed " .. key.Name,
            Color = Window.Theme.Success,
        })
    end,
    Changed = function(key)
        print("New key:", key.Name)
    end,
})

-- COLOR TAB

local ColorTab = Window:AddTab({Name = "Appearance", Icon = "✦"})
local ColorSection = Window:AddSection(ColorTab, {Name = "Color Customization"})

local AccentColor = ColorSection:AddColorpicker({
    Name = "Accent Color",
    Flag = "AccentColor",
    Default = Color3.fromRGB(155, 91, 255),
    Callback = function(color)
        print("New accent color:", color)
        Window:Notify({
            Title = "Accent Color",
            Content = "The selected accent preset was applied to the control.",
            Color = color,
            Duration = 2,
        })
    end,
})

ColorSection:AddButton({
    Name = "Reset Accent",
    Callback = function()
        AccentColor:Set(Color3.fromRGB(155, 91, 255))
    end,
})

-- INFORMATION TAB

local InfoTab = Window:AddTab({Name = "Information", Icon = "ⓘ"})
local InfoSection = Window:AddSection(InfoTab, {Name = "About"})

InfoSection:AddParagraph({
    Text = "NEXUS UI is a customizable Roblox Luau interface library with responsive layouts, interactive controls, notifications, and mobile support.",
})
InfoSection:AddLabel("Platform: Roblox")
InfoSection:AddLabel("Language: Luau")
InfoSection:AddLabel("Version: 1.0.0")
InfoSection:AddDivider()

InfoSection:AddButton({
    Name = "Destroy Interface",
    Callback = function()
        Window:Destroy()
    end,
})

-- CONFIGURATION DEMO

-- SaveConfig returns plain Luau data. For permanent persistence, send validated
-- values to a server and save them from a server Script/DataStore system.
local savedConfig = Window:SaveConfig()
Window:LoadConfig(savedConfig)

Window:Notify({
    Title = "NEXUS UI Loaded",
    Content = "All example tabs have been initialized.",
    Color = Window.Theme.Success,
    Duration = 5,
})

print("[NEXUS UI] Example loaded successfully.")
