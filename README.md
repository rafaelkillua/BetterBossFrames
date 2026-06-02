# DK Skellies

A World of Warcraft 3.3.5a (Wrath of the Lich King) addon that monitors boss-frame units (such as pets, ghouls, and skeletal minions) and displays them in a compact, draggable party-style frame.

Built for private server Synastria where certain pets are routed through the `BossTargetFrame` Blizzard UI, this addon provides a clean alternative — showing health, power, and click-to-target functionality without relying on the default boss target frames.

## Features

- **Pet Monitoring** — reads `boss1` through `boss6` unit tokens and displays them as compact unit frames
- **Auto Show/Hide** — frame appears automatically when a pet is detected, hides when none are present
- **Click to Target** — clicking a unit frame selects that unit (uses `SecureActionButtonTemplate` for combat safety)
- **Health & Power Bars** — real-time health with percentage and color-coded power bars (Mana, Rage, Energy, Runic Power)
- **Drag Handle** — draggable title bar with highlight effect
- **Scale Control** — adjustable UI scale with persistence between sessions
- **Blizzard Frame Toggle** — hides the default `BossXTargetFrame` frames; toggle with a command
- **Polling Engine** — uses an `OnUpdate` loop (0.1s) for reliability on private servers that may not fire unit events

## Commands

All commands use `/dksk` (or `/dkskellies`):

| Command | Description |
|---|---|
| `/dksk help` | Show all available commands |
| `/dksk debug` | Toggle debug logging on/off (shows show/hide events in chat) |
| `/dksk scale <0.3..3.0>` | Set the frame scale (saved between sessions) |
| `/dksk bossframes` | Toggle Blizzard default boss target frames visible/hidden |
| `/dksk reset` | Restore all settings to defaults |

## Layout

```
┌────────────────────────────┐  ← "Skeletons" title bar (drag here)
│ Warder of the Damned  [██]70%│  ← health bar with name + %
│ ██████████████████████████ │  ← power bar (color-coded)
├────────────────────────────┤
│ Ghoul                 [██]45%│
│ █████████████████          │
├────────────────────────────┤
│ ... (up to 6 pets)         │
└────────────────────────────┘
```

## Installation

1. Copy the `DKSkellies` folder into your WoW `Interface/AddOns/` directory:
   ```
   World of Warcraft/Interface/AddOns/DKSkellies/
   ```
2. Restart the game or reload with `/reload`
3. Ensure the addon is enabled in the character selection screen
4. The frame will auto-appear when pets are present; manually toggle Blizzard frames with `/dksk bossframes`

## Configuration

All settings persist between sessions via `DKSkelliesDB` saved variables:

| Setting | Default | Description |
|---|---|---|
| `scale` | `1.0` | Frame UI scale |
| `hideBossFrames` | `true` | Hide default Blizzard boss target frames |

## Files

| File | Purpose |
|---|---|
| `DKSkellies.toc` | Addon manifest (interface version, saved variables, file list) |
| `core.lua` | All addon logic (frames, polling, commands) |

## Interface Version

Targets WoW patch **3.3.5a** (Wrath of the Lich King). Interface token: `30300`.
