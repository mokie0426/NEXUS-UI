# NEXUS UI

NEXUS UI is a modern purple-and-black Roblox Luau interface library for your own Roblox Studio experiences. It provides a responsive desktop and Android-friendly window, touch and mouse dragging, sidebar tabs, collapsible sections, animated controls, notifications, dialogs, keybinds, theme customization, and cleanup support.

Repository: [github.com/mokie0426/NEXUS-UI](https://github.com/mokie0426/NEXUS-UI)

Raw ModuleScript source: [src/NexusUI.lua](https://raw.githubusercontent.com/mokie0426/NEXUS-UI/main/src/NexusUI.lua)

The full feature example is available at [`examples/Example.client.lua`](examples/Example.client.lua).

## Features

NEXUS UI currently includes responsive window sizing, a draggable top bar, a minimize and floating restore button, an optional keyboard toggle, sidebar tabs, collapsible sections, animated buttons, toggles, sliders, textboxes, single-select dropdowns, multi-select dropdowns, keybinds, color controls, labels, paragraphs, dividers, typed notifications, confirmation dialogs, theme overrides, and connection cleanup through `Destroy()`.

The implementation uses ordinary Roblox APIs and is intended for legitimate Roblox Studio projects. It does not require an executor, `loadstring`, filesystem APIs, HTTP injection, hidden permissions, or exploit-specific functions.

## Installation

Create a `ModuleScript` named `NexusUI` under `ReplicatedStorage`. Copy the contents of [`src/NexusUI.lua`](src/NexusUI.lua) into that ModuleScript. Then create a `LocalScript` under `StarterPlayer > StarterPlayerScripts` and copy [`examples/Example.client.lua`](examples/Example.client.lua) into it.

```text
ReplicatedStorage
└── NexusUI (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    └── Example.client.lua (LocalScript)
```

Roblox does not provide a normal `require()` mechanism for arbitrary GitHub raw URLs. The raw link is included for copying and source review; the recommended runtime setup is to place the ModuleScript inside your experience.

## Quick start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NexusUI = require(ReplicatedStorage:WaitForChild("NexusUI"))

local Window = NexusUI.new({
    Name = "My Experience",
    Subtitle = "Settings and tools",
    ToggleKey = Enum.KeyCode.RightControl,
    DisplayOrder = 50,
})

local Home = Window:Tab("Home", "◆")
local Section = Home:Section("Controls")

Section:Toggle({
    Name = "Enabled",
    Default = true,
    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

## Window API

| Method or option | Purpose |
| --- | --- |
| `NexusUI.new(options)` | Creates a window on the local player's `PlayerGui`, or under `options.Parent` when supplied. |
| `Name` | Window title. |
| `Subtitle` | Window subtitle. |
| `ToggleKey` | Keyboard key that toggles visibility on non-touch devices. Defaults to `RightControl`. |
| `DisplayOrder` | ScreenGui display order. |
| `Theme` | Not a constructor option in the current implementation; use `Window:SetTheme()` after creating the window. |
| `Window:Tab(name, icon)` | Creates and returns a sidebar tab. |
| `Window:Toggle()` | Toggles the main window and floating restore button. |
| `Window:SetTheme(theme)` | Updates valid theme colors. |
| `Window:Notify(options)` | Shows a typed notification. |
| `Window:Dialog(options)` | Shows a confirmation dialog. |
| `Window:Destroy()` | Disconnects tracked connections and destroys the interface. |

## Sections and controls

A tab creates sections through `Tab:Section(sectionName)`. Controls are then added to the returned section object:

```lua
local Controls = Window:Tab("Controls", "⚙")
local Basic = Controls:Section("Basic Components")

Basic:Button({
    Name = "Click Me",
    Callback = function()
        print("Clicked")
    end,
})

local enabled = Basic:Toggle({
    Name = "Enable Feature",
    Default = false,
    Callback = function(value) end,
})

enabled:Set(true)
print(enabled:Get())

local volume = Basic:Slider({
    Name = "Volume",
    Min = 0,
    Max = 100,
    Default = 50,
    Decimals = 0,
    Callback = function(value) end,
})

volume:Set(75)
```

The available section methods are `Button`, `Toggle`, `Slider`, `Textbox`, `Dropdown`, `MultiDropdown`, `Keybind`, `Colorpicker`, `Label`, `Paragraph`, and `Divider`.

### Textbox

```lua
local input = Basic:Textbox({
    Name = "Player Name",
    Placeholder = "Enter your name...",
    Default = "",
    ClearOnFocus = false,
    Callback = function(value, enterPressed) end,
})

print(input:Get())
input:Set("Alex")
```

### Dropdown and MultiDropdown

Single-select dropdowns use `Options` and `Default`:

```lua
local mode = Basic:Dropdown({
    Name = "Choose a Mode",
    Options = {"Easy", "Normal", "Hard"},
    Default = "Normal",
    Callback = function(value) end,
})

print(mode:Get())
mode:Set("Hard")
```

MultiDropdown returns a sorted array of selected values. Use `Set()` to apply an initial or later selection:

```lua
local features = Basic:MultiDropdown({
    Name = "Features",
    Options = {"Graphics", "Shadows", "Particles"},
    Callback = function(values) end,
})

features:Set({"Graphics", "Particles"})
for _, value in ipairs(features:Get()) do
    print(value)
end
```

### Keybind and colorpicker

```lua
local action = Basic:Keybind({
    Name = "Action Key",
    Default = Enum.KeyCode.G,
    Callback = function(key) end,
    Changed = function(key) end,
})

action:Set(Enum.KeyCode.H)

local accent = Basic:Colorpicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(155, 91, 255),
    Callback = function(color) end,
})

accent:Set(Color3.fromRGB(0, 170, 255))
```

The current colorpicker is intentionally lightweight: tapping the swatch advances the hue, while `Set(Color3)` applies an exact color.

## Notifications and dialogs

Notifications accept `Title`, `Content`, `Type`, and `Duration`. Valid notification types are `Success`, `Warning`, `Error`, and `Info`.

```lua
Window:Notify({
    Title = "Saved",
    Content = "Your settings were updated.",
    Type = "Success",
    Duration = 4,
})

Window:Dialog({
    Title = "Continue?",
    Content = "This is a reversible example action.",
    ConfirmText = "Continue",
    CancelText = "Cancel",
    OnConfirm = function()
        print("Confirmed")
    end,
    OnCancel = function()
        print("Cancelled")
    end,
})
```

## Themes

Theme overrides are applied with `SetTheme()` after creating the window:

```lua
local Window = NexusUI.new({Name = "Themed Window"})

Window:SetTheme({
    Accent = Color3.fromRGB(155, 91, 255),
    AccentDark = Color3.fromRGB(105, 58, 190),
})
```

Available theme tokens are `Background`, `Surface`, `SurfaceLight`, `SurfaceHover`, `Accent`, `AccentDark`, `Text`, `Muted`, `Border`, `Success`, `Warning`, and `Error`.

## Persistence and security

The current library does not expose a `SaveConfig()` or `LoadConfig()` method. You can hold control handles and serialize their values yourself, but permanent persistence should be server-authoritative. Send only validated settings through a `RemoteEvent`, validate them again on the server, and save them from a server Script using your preferred DataStore or profile system. Never trust client-provided permissions, currency, inventory, or gameplay state.

## Compatibility

The repository example is synchronized with the current `src/NexusUI.lua` implementation. It uses the shorthand API `Window:Tab()`, `Tab:Section()`, and `Section:Button()` rather than the older `AddTab()` and `AddSection()` API from the initial library version.

## License

NEXUS UI is released under the MIT License. See [`LICENSE`](LICENSE).
