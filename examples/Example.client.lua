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

    This example is synchronized with the current NexusUI.lua API.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NexusUI = require(ReplicatedStorage:WaitForChild("NexusUI"))

-- CREATE WINDOW

local Window = NexusUI.new({
    Name = "NEXUS UI",
    Subtitle = "Advanced Roblox Interface",
    ToggleKey = Enum.KeyCode.RightControl,
    DisplayOrder = 50,
})

Window:SetTheme({
    Accent = Color3.fromRGB(155, 91, 255),
    AccentDark = Color3.fromRGB(105, 58, 190),
})

-- HOME TAB

local Home = Window:Tab("Home", "◆")
local Welcome = Home:Section("Welcome")

Welcome:Paragraph({
    Title = "Welcome to NEXUS",
    Content = "A modern, responsive Roblox UI library designed for desktop and Android devices.",
})

Welcome:Button({
    Name = "Show Notification",
    Callback = function()
        Window:Notify({
            Title = "NEXUS UI",
            Content = "Your interface is working successfully!",
            Type = "Success",
            Duration = 4,
        })
    end,
})

Welcome:Divider()
Welcome:Label("Library Version: 1.0.0")

Welcome:Button({
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
                    Type = "Success",
                })
            end,
            OnCancel = function()
                Window:Notify({
                    Title = "Cancelled",
                    Content = "You cancelled the action.",
                    Type = "Warning",
                })
            end,
        })
    end,
})

-- CONTROLS TAB

local Controls = Window:Tab("Controls", "⚙")
local Basic = Controls:Section("Basic Components")

Basic:Button({
    Name = "Click Me",
    Callback = function()
        print("NEXUS: Button clicked!")
        Window:Notify({
            Title = "Button",
            Content = "Button successfully clicked.",
            Type = "Info",
        })
    end,
})

local Enabled = Basic:Toggle({
    Name = "Enable Feature",
    Default = false,
    Callback = function(value)
        print("Feature Enabled:", value)
    end,
})

Basic:Button({
    Name = "Toggle Programmatically",
    Callback = function()
        Enabled:Set(not Enabled:Get())
    end,
})

Basic:Divider()

local Slider = Basic:Slider({
    Name = "Volume",
    Min = 0,
    Max = 100,
    Default = 50,
    Decimals = 0,
    Callback = function(value)
        print("Volume:", value)
    end,
})

Basic:Button({
    Name = "Set Volume to 75",
    Callback = function()
        Slider:Set(75)
    end,
})

-- INPUT TAB

local InputTab = Window:Tab("Input", "⌨")
local InputSection = InputTab:Section("Text Input")

local PlayerName = InputSection:Textbox({
    Name = "Player Name",
    Placeholder = "Enter your name...",
    Default = "",
    Callback = function(value, enterPressed)
        print("Player Name:", value)
        print("Pressed Enter:", enterPressed)
    end,
})

InputSection:Button({
    Name = "Read Textbox",
    Callback = function()
        Window:Notify({
            Title = "Textbox Value",
            Content = "Current text: " .. PlayerName:Get(),
            Type = "Info",
        })
    end,
})

-- DROPDOWN TAB

local DropdownTab = Window:Tab("Dropdowns", "▾")
local DropSection = DropdownTab:Section("Selection Components")

local Dropdown = DropSection:Dropdown({
    Name = "Choose a Mode",
    Options = {"Easy", "Normal", "Hard", "Extreme"},
    Default = "Normal",
    Callback = function(value)
        print("Selected Mode:", value)
    end,
})

DropSection:Button({
    Name = "Print Selected Mode",
    Callback = function()
        print("Current Mode:", Dropdown:Get())
    end,
})

local Multi = DropSection:MultiDropdown({
    Name = "Choose Multiple Options",
    Options = {"Graphics", "Shadows", "Effects", "Particles", "Animations"},
    Callback = function(values)
        print("Selected options:")
        for _, value in ipairs(values) do
            print("-", value)
        end
    end,
})

-- MultiDropdown supports Set() for initial or later selections.
Multi:Set({"Graphics", "Effects"})

DropSection:Button({
    Name = "Show Multi Selection",
    Callback = function()
        for _, value in ipairs(Multi:Get()) do
            print(value)
        end
    end,
})

-- KEYBIND TAB

local KeybindTab = Window:Tab("Keybinds", "⌘")
local KeySection = KeybindTab:Section("Keyboard Controls")

KeySection:Keybind({
    Name = "Action Key",
    Default = Enum.KeyCode.G,
    Callback = function(key)
        print("Pressed:", key.Name)
        Window:Notify({
            Title = "Keybind Activated",
            Content = "You pressed " .. key.Name,
            Type = "Success",
        })
    end,
    Changed = function(key)
        print("New key:", key.Name)
    end,
})

-- COLOR TAB

local ColorTab = Window:Tab("Appearance", "✦")
local ColorSection = ColorTab:Section("Color Customization")

local AccentColor = ColorSection:Colorpicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(155, 91, 255),
    Callback = function(color)
        Window:SetTheme({
            Accent = color,
            AccentDark = color:Lerp(Color3.new(0, 0, 0), 0.35),
        })
        print("New accent color:", color)
    end,
})

ColorSection:Button({
    Name = "Reset Accent",
    Callback = function()
        AccentColor:Set(Color3.fromRGB(155, 91, 255))
    end,
})

-- INFORMATION TAB

local InfoTab = Window:Tab("Information", "ⓘ")
local InfoSection = InfoTab:Section("About")

InfoSection:Paragraph({
    Title = "NEXUS UI",
    Content = "NEXUS is a customizable Roblox Luau interface library with responsive layouts, interactive controls, notifications, theme customization, and mobile support.",
})

InfoSection:Label("Platform: Roblox")
InfoSection:Label("Language: Luau")
InfoSection:Label("Version: 1.0.0")
InfoSection:Divider()

InfoSection:Button({
    Name = "Destroy Interface",
    Callback = function()
        Window:Destroy()
    end,
})

-- INITIAL NOTIFICATION

Window:Notify({
    Title = "NEXUS UI Loaded",
    Content = "All example tabs have been initialized.",
    Type = "Success",
    Duration = 5,
})

print("[NEXUS UI] Example loaded successfully.")
