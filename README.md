# NEXUS UI

A polished, mobile-first Roblox Luau GUI library for legitimate Roblox Studio experiences. NEXUS UI is inspired by modern purple dashboard interfaces: rounded surfaces, responsive layout, animated controls, sidebar navigation, notifications, dialogs, and a clean component API.

NEXUS UI is intentionally Studio-safe. It uses normal Roblox services and APIs only; it does not require an executor, exploit environment, `loadstring`, filesystem APIs, HTTP injection, or hidden permissions.

## Features

- Responsive window that adapts to narrow mobile viewports.
- Mouse, touch, and keyboard-friendly interactions through `Activated` and input events.
- Draggable window, minimize button, floating restore button, and close behavior.
- Sidebar tabs and collapsible sections.
- Button, label, paragraph, divider, toggle, slider, dropdown, textbox, keybind, and colorpicker components.
- Search-ready structure, theme tokens, animated states, notifications, and confirmation dialogs.
- `SaveConfig()` and `LoadConfig()` APIs for integrating with your own profile/DataStore architecture.
- Luau strict mode annotations and callback error isolation.

## Installation

1. Create a `ModuleScript` named `NexusUI` under `ReplicatedStorage`.
2. Copy `src/NexusUI.lua` into that ModuleScript.
3. Require it from a `LocalScript` under `StarterPlayerScripts` or `StarterGui`.
4. See [`examples/Example.client.lua`](examples/Example.client.lua) for a complete setup.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NexusUI = require(ReplicatedStorage:WaitForChild("NexusUI"))

local window = NexusUI.new({
    Name = "My Experience",
    Subtitle = "Settings and tools",
})

local tab = window:AddTab({Name = "Home", Icon = "⌂"})
local section = window:AddSection(tab, {Name = "Controls"})
section:AddToggle({
    Name = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

## API overview

### Window

- `NexusUI.new(options)` creates a window. Options include `Name`, `Subtitle`, `Size`, `DisplayOrder`, and `Theme`.
- `window:AddTab({Name, Icon})` creates a tab.
- `window:AddSection(tab, {Name, Open})` creates a collapsible section.
- `window:SelectTab(name)` selects a tab.
- `window:SetMinimized(boolean)` hides or restores the window.
- `window:Notify({Title, Content, Duration, Color})` displays a toast.
- `window:Dialog({Title, Content, ConfirmText, CancelText, OnConfirm, OnCancel})` displays a confirmation dialog.
- `window:SaveConfig()` returns plain Luau data from registered element handles.
- `window:LoadConfig(config)` applies values through element `Set` methods.
- `window:Destroy()` disconnects internal connections and removes the GUI.

### Section components

All section components return a handle with `Instance`, and stateful components also expose `Get()` and `Set(value)` where appropriate.

```lua
section:AddLabel("Small heading")
section:AddParagraph({Text = "Description text"})
section:AddDivider()
section:AddButton({Name = "Run", Callback = function() end})
section:AddToggle({Name = "Enabled", Default = false, Callback = function(value) end})
section:AddSlider({Name = "Amount", Min = 0, Max = 100, Default = 50, Decimals = 0, Callback = function(value) end})
section:AddDropdown({Name = "Mode", Values = {"Safe", "Fast"}, Multi = false, Callback = function(value) end})
section:AddTextbox({Name = "Message", Placeholder = "Type here", Callback = function(text) end})
section:AddKeybind({Name = "Shortcut", Default = Enum.KeyCode.RightShift, Callback = function() end})
section:AddColorpicker({Name = "Accent", Default = Color3.fromRGB(126, 87, 255), Callback = function(color) end})
```

## Persistence and security

A Roblox client should not write DataStores directly. `SaveConfig()` only returns UI state as a normal Luau table. For persistence, send validated values to the server with a `RemoteEvent`, validate them server-side, and save them from a server Script using a profile/DataStore system. Never trust client-provided permissions, currency, or gameplay state.

## Theming

Theme tokens can be overridden at creation time:

```lua
local window = NexusUI.new({
    Theme = {
        Accent = Color3.fromRGB(0, 170, 255),
        Accent2 = Color3.fromRGB(90, 210, 255),
        Background = Color3.fromRGB(12, 18, 25),
    },
})
```

Available tokens: `Accent`, `Accent2`, `Background`, `Surface`, `SurfaceAlt`, `Text`, `MutedText`, `Stroke`, `Success`, `Warning`, and `Danger`.

## License

MIT. See [`LICENSE`](LICENSE).
