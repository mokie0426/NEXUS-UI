# NEXUS UI

NEXUS UI is a modern, mobile-first Roblox Luau GUI library for your own Roblox Studio experiences. It takes visual direction from polished purple dashboard interfaces while keeping the implementation simple, responsive, and Studio-safe.

Repository: [github.com/mokie0426/NEXUS-UI](https://github.com/mokie0426/NEXUS-UI)

Raw ModuleScript source: [NexusUI.lua](https://raw.githubusercontent.com/mokie0426/NEXUS-UI/main/src/NexusUI.lua)

NEXUS UI uses normal Roblox APIs only. It does not require an executor, `loadstring`, filesystem APIs, HTTP injection, hidden permissions, or exploit-specific functions.

## What is included

The library provides a draggable window, responsive narrow-screen layout, mobile restore button, sidebar tabs, collapsible sections, animated controls, notifications, confirmation dialogs, theme tokens, keyboard bindings, and state serialization helpers. Components include buttons, toggles, sliders, dropdowns, multi-select dropdowns, textboxes, keybinds, color controls, labels, paragraphs, and dividers.

The complete adapted example is available at [`examples/Example.client.lua`](examples/Example.client.lua). It demonstrates the full current API and includes the GitHub source link in its header.

## Installation in Roblox Studio

Create a `ModuleScript` named `NexusUI` under `ReplicatedStorage`, then copy the contents of [`src/NexusUI.lua`](src/NexusUI.lua) into it. Create a `LocalScript` named `Example.client.lua` under `StarterPlayer > StarterPlayerScripts` and copy the example into it.

The runtime library is intentionally local to your experience. Roblox does not provide a normal `require()` mechanism for arbitrary GitHub raw URLs, so the raw source link is provided for convenient copying and review rather than being fetched at runtime.

```text
ReplicatedStorage
└── NexusUI (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    └── Example.client.lua (LocalScript)
```

Minimal setup:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NexusUI = require(ReplicatedStorage:WaitForChild("NexusUI"))

local window = NexusUI.new({
    Name = "My Experience",
    Subtitle = "Settings and tools",
})

local home = window:AddTab({Name = "Home", Icon = "⌂"})
local controls = window:AddSection(home, {Name = "Controls"})

controls:AddToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = true,
    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

## Current API

### Window methods

| Method | Purpose |
| --- | --- |
| `NexusUI.new(options)` | Creates a new window. Supports `Name`, `Subtitle`, `Size`, `DisplayOrder`, and `Theme`. |
| `window:AddTab({Name, Icon})` | Creates a sidebar tab. |
| `window:AddSection(tab, {Name, Open})` | Adds a collapsible section to a tab. |
| `window:SelectTab(name)` | Selects a tab by name. |
| `window:SetMinimized(boolean)` | Hides or restores the main window. |
| `window:Notify(options)` | Shows an animated notification. Supports `Title`, `Content`, `Duration`, and `Color`. |
| `window:Dialog(options)` | Shows a confirmation dialog with `OnConfirm` and `OnCancel` callbacks. |
| `window:SaveConfig()` | Returns state from registered controls as a plain Luau table. |
| `window:LoadConfig(config)` | Applies saved values through each control's `Set()` method. |
| `window:Destroy()` | Disconnects tracked connections and removes the interface. |

### Section methods

```lua
section:AddLabel("Small heading")
section:AddParagraph({Text = "Description text"})
section:AddDivider()

section:AddButton({
    Name = "Run",
    Callback = function() end,
})

section:AddToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = false,
    Callback = function(value) end,
})

section:AddSlider({
    Name = "Amount",
    Flag = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Decimals = 0,
    Callback = function(value) end,
})

section:AddDropdown({
    Name = "Mode",
    Flag = "Mode",
    Values = {"Safe", "Fast"},
    Default = "Safe",
    Callback = function(value) end,
})

section:AddDropdown({
    Name = "Features",
    Flag = "Features",
    Values = {"Graphics", "Shadows", "Particles"},
    Multi = true,
    Default = {"Graphics"},
    Callback = function(values) end,
})

section:AddTextbox({
    Name = "Message",
    Flag = "Message",
    Placeholder = "Type here",
    Callback = function(text, enterPressed) end,
})

section:AddKeybind({
    Name = "Shortcut",
    Flag = "Shortcut",
    Default = Enum.KeyCode.RightShift,
    Callback = function(key) end,
    Changed = function(key) end,
})

section:AddColorpicker({
    Name = "Accent",
    Flag = "Accent",
    Default = Color3.fromRGB(126, 87, 255),
    Callback = function(color) end,
})
```

Stateful controls return handles with `Get()` and `Set(value)` methods. For example:

```lua
local toggle = section:AddToggle({Name = "Feature", Flag = "Feature"})
toggle:Set(true)
print(toggle:Get())
```

Use a unique `Flag` for every control that should participate in configuration saving. If no `Flag` is provided, the control name is used as its key.

## Notifications and dialogs

```lua
window:Notify({
    Title = "Saved",
    Content = "Your settings were updated.",
    Color = window.Theme.Success,
    Duration = 4,
})

window:Dialog({
    Title = "Delete profile?",
    Content = "This example action is reversible.",
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

Theme tokens can be overridden when creating the window:

```lua
local window = NexusUI.new({
    Theme = {
        Accent = Color3.fromRGB(0, 170, 255),
        Accent2 = Color3.fromRGB(90, 210, 255),
        Background = Color3.fromRGB(12, 18, 25),
        Surface = Color3.fromRGB(22, 30, 40),
    },
})
```

Available tokens are `Accent`, `Accent2`, `Background`, `Surface`, `SurfaceAlt`, `Text`, `MutedText`, `Stroke`, `Success`, `Warning`, and `Danger`.

## Configuration and security

`SaveConfig()` returns ordinary Luau data; it does not write to disk or to a DataStore. For permanent persistence, send only validated settings to the server through a `RemoteEvent`, validate them again on the server, and save them from a server Script using your preferred DataStore or profile system. Never trust client-provided permissions, currency, inventory, or gameplay state.

```lua
local saved = window:SaveConfig()
-- Store `saved` through a server-authoritative persistence flow.
window:LoadConfig(saved)
```

## Compatibility note

The example supplied in the project history used an older shorthand API such as `Window:Tab()` and `Section:Button()`. The current library uses the explicit API names `Window:AddTab()`, `Window:AddSection(tab, options)`, and `section:AddButton()`. The repository example has been adapted to the current `src/NexusUI.lua` implementation so it can be copied into Studio without relying on unsupported methods.

## License

NEXUS UI is released under the MIT License. See [`LICENSE`](LICENSE).
