local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NexusUI = require(ReplicatedStorage:WaitForChild("NexusUI"))

local window = NexusUI.new({
    Name = "NEXUS UI",
    Subtitle = "Studio-safe, mobile-first interface library",
})

local dashboard = window:AddTab({Name = "Dashboard", Icon = "⌂"})
local settings = window:AddTab({Name = "Settings", Icon = "⚙"})

local overview = window:AddSection(dashboard, {Name = "Overview"})
overview:AddParagraph({
    Text = "NEXUS UI is a responsive Luau component library for your own Roblox experiences. It works with mouse, touch, keyboard, and gamepad-friendly Activated events.",
})
overview:AddButton({
    Name = "Show notification",
    Callback = function()
        window:Notify({Title = "Welcome", Content = "Your callback ran successfully.", Duration = 3})
    end,
})
overview:AddButton({
    Name = "Open confirmation dialog",
    Callback = function()
        window:Dialog({
            Title = "Example dialog",
            Content = "This is a reversible demo action.",
            OnConfirm = function()
                window:Notify({Title = "Confirmed", Content = "The action was confirmed."})
            end,
        })
    end,
})

overview:AddDivider()
local enabled = overview:AddToggle({
    Name = "Enable feature",
    Default = true,
    Callback = function(value)
        print("Feature enabled:", value)
    end,
})

overview:AddSlider({
    Name = "Volume",
    Min = 0,
    Max = 100,
    Default = 65,
    Callback = function(value)
        print("Volume:", value)
    end,
})

overview:AddDropdown({
    Name = "Quality",
    Values = {"Low", "Medium", "High"},
    Default = "High",
    Callback = function(value)
        print("Quality:", value)
    end,
})

local preferences = window:AddSection(settings, {Name = "Preferences"})
preferences:AddTextbox({
    Name = "Display name",
    Placeholder = "Enter a name",
    Callback = function(text)
        print("Name changed:", text)
    end,
})
preferences:AddKeybind({
    Name = "Toggle window",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        window:SetMinimized(not window.Minimized)
    end,
})
preferences:AddColorpicker({
    Name = "Accent color",
    Callback = function(color)
        print("Color changed:", color)
    end,
})

-- SaveConfig returns plain Luau data. Persist it using your own server-authoritative
-- DataStore flow or a profile system; LocalScripts cannot safely write DataStores.
local saved = window:SaveConfig()
window:LoadConfig(saved)
