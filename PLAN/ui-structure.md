# UI Structure

## Design Influences

xClouseau's UX draws from the best patterns across browsers and modern terminals:

```
┌──────────────────────────────────────────────────────────────────────┐
│                      DESIGN INFLUENCES                               │
│                                                                      │
│  Chrome                                                              │
│  ├── Tab groups with colors (collapsible, named)                    │
│  ├── Pinned tabs (compact, always-left, persist across groups)      │
│  ├── Drag tabs between groups                                       │
│  ├── Right-click context menus (close others, close to right, etc.) │
│  └── Middle-click to close                                          │
│                                                                      │
│  Arc Browser                                                         │
│  ├── Spaces concept → our Projects (distinct workspaces)            │
│  ├── Icon + color per space for quick visual identification         │
│  ├── Clean, minimal sidebar                                         │
│  └── Pinned items persist across spaces                             │
│                                                                      │
│  Wave Terminal                                                       │
│  ├── Durable sessions that survive disconnection + auto-reconnect   │
│  ├── Block-based layout → our grid view mode                        │
│  ├── Drag-and-drop block arrangement                                │
│  └── Workspace switcher with icons and colors                       │
│                                                                      │
│  Warp Terminal                                                       │
│  ├── Restore recently closed tabs (undo close, 60s window)          │
│  ├── Tab error indicators (visual cue when command fails)           │
│  ├── Tab rename by double-click                                     │
│  └── Tab color derived from theme                                   │
│                                                                      │
│  What nobody else has (unique to xClouseau):                        │
│  ├── P2P terminal sharing with zero servers                         │
│  ├── Device mesh: browse any device's terminals from sidebar        │
│  ├── Remote tabs identical to local tabs (transparent)              │
│  └── Phone-to-desktop image pipeline for AI CLI sessions            │
└──────────────────────────────────────────────────────────────────────┘
```

## Desktop Layout

The tab bar is the primary navigation — Chrome-style tab groups, pinned tabs, drag-and-drop. The sidebar is narrow, showing only devices. Config opens as a tab.

```
┌──────────────────────────────────────────────────────────────────────────┐
│  📌 📌 │ ● Clouseau  [zsh] [claude] [build ✕] │ ● MyApp  [dev] │ [+]  │
├────────┬─────────────────────────────────────────────────────────────────┤
│DEVICES │                                                                 │
│        │  $ claude                                                       │
│ ▼ Mac  │                                                                 │
│   zsh  │  Hello! I'm Claude. How can I help you today?                  │
│   claude│                                                                │
│   vim  │  > Can you help me build a terminal workspace manager?         │
│ ▶ WinPC│                                                                 │
│ ○ iPad │  Of course! Let me help you with that...                       │
│        │                                                                 │
│[+ Pair]│  █                                                              │
│────────│                                                                 │
│⚙Config │                                                                 │
└────────┴─────────────────────────────────────────────────────────────────┘
```

### Tab Bar (Top) — Chrome-Style

```
┌──────────────────────────────────────────────────────────────────────────┐
│ 📌 📌 │ ● Clouseau  [zsh] [claude] [build ✕] │ ● MyApp  [dev] │ [+]   │
└──────────────────────────────────────────────────────────────────────────┘
  │        │                                      │                  │
  │        │                                      │                  └─ New tab
  │        │                                      └─ Tab group (project)
  │        └─ Tab group (project) with color + name
  └─ Pinned tabs (compact, no label, just icon)

Tab behaviors:

  From Chrome:
  • Tab groups = Projects (named, colored, collapsible)
  • Pinned tabs = compact icons, always at the left
  • Drag tabs between groups
  • Drag tabs to reorder within a group
  • Close button (✕) on hover
  • Right-click context menu: rename, pin/unpin, move to group, close
  • [+] creates new tab (in active group, or ungrouped)
  • Middle-click to close
  • Collapse a group = hides its tabs, shows only the group label

  From Arc:
  • Each tab group gets an icon + color for instant visual ID
  • Pinned tabs persist across all groups (always accessible)
  • Clean, minimal aesthetic — no clutter

  From Warp:
  • Double-click tab to rename
  • Restore recently closed tabs (Ctrl+Shift+T, within 60s window)
  • Tab error indicator: red dot or highlight when a command fails
  • Tab activity indicator: subtle pulse when output is happening
    in a background tab

  From Wave:
  • Durable sessions: terminal state survives app restart
    (reconnects to running PTY on relaunch)
  • Grid view uses Wave-style block layout (drag to rearrange)
```

### Tab Group Context Menu

```
Right-click on tab group label:
┌──────────────────────┐
│ Rename group         │
│ Change color      ►  │
│ Ungroup tabs         │
│ Close group          │
│ New tab in group     │
└──────────────────────┘

Right-click on a tab:
┌──────────────────────┐
│ Rename tab           │
│ Pin tab              │
│ Move to group     ►  │
│   ● Clouseau         │
│   ● MyApp            │
│   + New group...     │
│ ──────────────────── │
│ Close tab            │
│ Close other tabs     │
│ Close tabs to right  │
└──────────────────────┘
```

### Device Sidebar (Left) — Narrow

```
┌────────┐
│DEVICES │
│        │
│ ▼ Mac  │  ← expanded: shows Mac's open terminals
│   zsh  │     tap → opens as remote tab in tab bar
│   claude│
│   vim  │
│ ▶ WinPC│  ← collapsed: tap to expand
│ ○ iPad │  ← offline/unreachable (greyed out)
│        │
│[+ Pair]│  ← opens pairing flow
│────────│
│⚙Config │  ← opens Config as a tab
└────────┘

Sidebar width: ~140px (collapsible to icon-only ~40px)
Only shows devices — no projects (those are tab groups)
```

### Device States

```
● Mac     = online, reachable (LAN or remote)
○ iPad    = offline / unreachable
◐ WinPC   = connecting...

Tap online device → expand to show its terminals
Tap offline device → attempt reconnection (if paired)
Tap terminal under device → opens as remote tab in tab bar

Remote tabs look identical to local tabs, with a small
indicator icon (e.g., tiny device icon on the tab) to
show it's remote.
```

## Mobile Layout

```
┌────────────────────────────┐
│  xClouseau          ≡     │
├────────────────────────────┤
│ 📌│ ● Clouseau [zsh][claude]│
├────────────────────────────┤
│                            │
│  $ claude                  │
│                            │
│  Hello! I'm Claude...     │
│                            │
│  > help me build...       │
│                            │
│  Of course! Let me help   │
│  you with that...         │
│                            │
│  $                        │
│  █                        │
│                            │
├────────────────────────────┤
│  🖥 Terminals  📡 Devices  │
│              ⚙ Config     │
└────────────────────────────┘

Bottom nav: 3 sections
  Terminals: tab bar + active terminal
  Devices: paired/nearby devices, tap to view their terminals
  Config: settings, pairing, file transfer preferences

Hamburger (≡) opens tab group list as overlay
Swipe left/right between tabs
Tab groups shown as colored sections in the tab bar
```

## Grid View Mode (Desktop)

```
┌────────┬────────────────────────────────────────────────────────────────┐
│DEVICES │ 📌 📌│● Clouseau [zsh][claude][build][logs]│● MyApp [dev]│[+]│
│        ├────────────────────────────────────────────────────────────────┤
│ ▶ Mac  │  ┌──────────────────────┐  ┌──────────────────────┐          │
│ ▶ WinPC│  │ zsh                  │  │ claude               │          │
│        │  │                      │  │                      │          │
│[+ Pair]│  │ $ npm run build      │  │ > analyzing code...  │          │
│────────│  │ Building...          │  │                      │          │
│⚙Config │  │ ████████░ 80%        │  │ Found 3 issues:      │          │
│        │  └──────────────────────┘  └──────────────────────┘          │
│        │  ┌──────────────────────┐  ┌──────────────────────┐          │
│        │  │ build                │  │ logs                 │          │
│        │  │                      │  │                      │          │
│        │  │ $ make release       │  │ [INFO] Server up     │          │
│        │  │ Compiling...         │  │ [INFO] Request /api  │          │
│        │  └──────────────────────┘  └──────────────────────┘          │
└────────┴────────────────────────────────────────────────────────────────┘

Grid shows all terminals in the active tab group simultaneously.
Click any cell to focus/maximize it. Click again (or Esc) to return to grid.
All terminals update in real-time even when not focused.
Grid adapts: 2x2 for 4 tabs, 2x3 for 5-6, 3x3 for 7-9, etc.

Inspired by Wave Terminal's block layout:
  • Drag-and-drop to rearrange grid cells
  • Resize cells by dragging borders (future)
  • Each cell shows tab name + error/activity indicator
  • Double-click cell header to maximize
```

## Carousel View Mode (Mobile)

```
┌────────────────────────────┐
│  xClouseau          ≡     │
├────────────────────────────┤
│                            │
│   ┌────────────────────┐   │
│   │                    │   │
│   │   claude           │   │
│   │                    │   │
│   │  > help me with    │   │
│   │    this bug...     │   │
│   │                    │   │
│   │  Sure! Let me look │   │
│   │  at the code...   │   │
│   │                    │   │
│   │  $                 │   │
│   │  █                 │   │
│   │                    │   │
│   └────────────────────┘   │
│                            │
│        ● ○ ○ ○             │
│    swipe ← → for tabs     │
├────────────────────────────┤
│  🖥 Terminals  📡 Devices  │
│              ⚙ Config     │
└────────────────────────────┘

Carousel: full-width cards, swipe horizontally.
Dots indicate position within active tab group.
Pinch-to-zoom on terminal content.
```

## View Mode Toggle

```
View mode toggle lives in the tab bar area (right side):

  ...tabs...  │ [+]  ◫ ☰ ⊞

  ◫ = List (single terminal, tabs switch)     ← default desktop
  ☰ = Grid (2x2 or NxM, all visible)
  ⊞ = Carousel (swipe between cards)          ← default mobile

View mode persists per tab group (project).
```

## Config Tab

Config opens as a regular tab in the tab bar (like chrome://settings).

```
┌────────┬────────────────────────────────────────────────────────────────┐
│DEVICES │ 📌 📌│● Clouseau [zsh][claude]│⚙ Config ✕│                [+]│
│        ├────────────────────────────────────────────────────────────────┤
│ ▶ Mac  │                                                               │
│ ▶ WinPC│  ┌─────────────────────────────────────────────────────┐      │
│        │  │ Settings                                            │      │
│[+ Pair]│  │                                                     │      │
│────────│  │ TERMINAL                                            │      │
│⚙Config │  │   Shell:           [/bin/zsh        ▼]             │      │
│        │  │   Font size:       [14] ──●────── [24]             │      │
│        │  │   Font family:     [JetBrains Mono  ▼]             │      │
│        │  │   Theme:           [Dark            ▼]             │      │
│        │  │   Scrollback:      [10000 lines     ▼]             │      │
│        │  │                                                     │      │
│        │  │ DEVICES & SHARING                                   │      │
│        │  │   Allow remote terminal access: [ON]                │      │
│        │  │   Require PIN:                  [OFF]               │      │
│        │  │   Received files directory:     [/tmp/xclouseau]   │      │
│        │  │   Auto-paste file paths:        [OFF]               │      │
│        │  │                                                     │      │
│        │  │ PAIRED DEVICES                                      │      │
│        │  │   Mac (paired 2026-02-15)              [Unpair]    │      │
│        │  │   iPad (paired 2026-02-20)             [Unpair]    │      │
│        │  │                                                     │      │
│        │  │ ABOUT                                               │      │
│        │  │   xClouseau v1.0.0                                  │      │
│        │  └─────────────────────────────────────────────────────┘      │
└────────┴────────────────────────────────────────────────────────────────┘

Config is just another tab — closeable, not pinned by default.
Tap ⚙ in sidebar or use keyboard shortcut to open it.
```

## Pairing Flow (One-Time)

```
Step 1: User taps [+ Pair] in sidebar

Step 2: Pairing screen opens (as a tab or modal)
┌─────────────────────────────────────────┐
│                                         │
│  Pair a New Device                      │
│                                         │
│  Make sure both devices are on the      │
│  same WiFi network.                     │
│                                         │
│  Nearby devices:                        │
│  ┌───────────────────────────────────┐  │
│  │ 📱 Ivan's iPhone          [Pair] │  │
│  │ 🖥 Office Windows PC      [Pair] │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Don't see your device?                │
│  [Enter IP manually]                    │
│                                         │
└─────────────────────────────────────────┘

Step 3: User taps [Pair] → PIN shown on one device
┌─────────────────────────────────────────┐
│                                         │
│  Pairing with Ivan's iPhone             │
│                                         │
│  Enter this PIN on your iPhone:         │
│                                         │
│           ┌─────────────┐               │
│           │    4 8 2 9   │               │
│           └─────────────┘               │
│                                         │
│  Waiting for confirmation...            │
│                                         │
│  [Cancel]                               │
│                                         │
└─────────────────────────────────────────┘

Step 4: Other device enters PIN → paired forever
┌─────────────────────────────────────────┐
│                                         │
│  ✓ Paired with Ivan's iPhone            │
│                                         │
│  You can now access this device's       │
│  terminals from anywhere.               │
│                                         │
│  [Done]                                 │
│                                         │
└─────────────────────────────────────────┘

After pairing:
  Device appears in sidebar permanently
  Shows ● when reachable, ○ when offline
  Never needs to pair again
```

## Interaction Flows

### Opening a Remote Terminal

```
1. User sees "Mac" in sidebar with ● (online)
2. Tap ▶ Mac → expands to show Mac's terminals:
     zsh
     claude
     vim
3. Tap "claude" → new tab appears in tab bar:
     📌 📌│● Clouseau [zsh][build]│🖥claude ✕│[+]
                                    ↑
                              remote tab (🖥 icon = remote)
4. Terminal shows live output from Mac's claude session
5. User can type — input goes to Mac's PTY
6. Right-click tab → "View only" to stop sending input
```

### Creating a New Local Terminal

```
1. Click [+] in tab bar
   → new terminal opens in current group (or ungrouped)
   → runs default shell
   → tab named "zsh" (or shell name)

OR

1. Right-click tab group label → "New tab in group"
   → same as above, but explicitly in that group
```

### Creating a New Tab Group (Project)

```
1. Right-click tab bar → "New group"
   OR drag a tab out of its group → "New group..." option

2. Enter group name: "Blog"
3. Pick color: 🔴 🟢 🔵 🟡 🟣 🟠
4. Group appears in tab bar with its color
```

### Pinning a Tab

```
1. Right-click tab → "Pin tab"
2. Tab moves to the left, becomes compact (icon only)
3. Pinned tabs stay visible regardless of which group is active
4. Right-click pinned tab → "Unpin" to restore
```

### Moving a Tab Between Groups

```
Option A: Drag and drop
  Grab tab → drag to another group → drop

Option B: Right-click
  Right-click tab → "Move to group" → select target group
```

### Receiving a File (from another device)

```
1. Phone sends file via LocalSend protocol
2. Desktop receives → notification appears:
   ┌────────────────────────────────────────┐
   │ 📷 photo.jpg received from iPhone      │
   │                                        │
   │ [Paste to terminal]  [Open]  [Dismiss] │
   └────────────────────────────────────────┘
3. "Paste to terminal" types the file path into the active terminal
4. File saved to configured directory (default: /tmp/xclouseau/)

This works regardless of which screen the user is on.
The notification is an overlay, not a page change.
```

## Component Tree

```
MaterialApp
└── RefenaScope
    └── WorkspacePage
        ├── ResponsiveBuilder
        │   ├── [Desktop] Row
        │   │   ├── DeviceSidebar                     ← narrow, devices only
        │   │   │   ├── DeviceSection
        │   │   │   │   ├── DeviceListItem            (per device)
        │   │   │   │   │   └── RemoteSessionItem     (per remote terminal)
        │   │   │   │   └── PairButton
        │   │   │   └── ConfigButton
        │   │   └── Expanded
        │   │       └── Column
        │   │           ├── ChromeTabBar               ← Chrome-style
        │   │           │   ├── PinnedTabs
        │   │           │   ├── TabGroup (per project)
        │   │           │   │   ├── GroupLabel (colored)
        │   │           │   │   └── TabItem (per session)
        │   │           │   ├── NewTabButton
        │   │           │   └── ViewModeToggle
        │   │           └── Expanded
        │   │               └── TabContent
        │   │                   ├── [list]     TerminalTab
        │   │                   ├── [grid]     GridView<TerminalTab>
        │   │                   ├── [carousel] PageView<TerminalTab>
        │   │                   └── [config]   ConfigPage
        │   │
        │   └── [Mobile] Column
        │       ├── ChromeTabBar                (compact, horizontal scroll)
        │       ├── Expanded
        │       │   └── PageView
        │       │       ├── TabContent
        │       │       ├── DevicesPage
        │       │       └── ConfigPage
        │       └── NavigationBar
        │           ├── Terminals
        │           ├── Devices
        │           └── Config
        │
        └── Watchers (from LocalSend, unchanged)
            ├── LifeCycleWatcher
            ├── WindowWatcher
            ├── ShortcutWatcher
            └── TrayWatcher
```

## TerminalTab Widget

```
TerminalTab
├── [Local Mode]
│   ├── TerminalView (xterm.dart)
│   │   └── CustomPainter (60fps canvas rendering)
│   └── flutter_pty Pty instance
│       └── Shell process (bash, zsh, etc.)
│
├── [Remote Mode]
│   ├── TerminalView (xterm.dart)
│   │   └── Same rendering, different data source
│   ├── WebSocket connection to host device
│   └── StatusIndicator
│       ├── Remote device icon (small, on tab)
│       └── Connection status (connected/reconnecting)
│
└── [Common]
    ├── Context menu (right-click)
    │   ├── Copy
    │   ├── Paste
    │   ├── Clear
    │   ├── Rename tab
    │   ├── Pin / Unpin
    │   ├── Move to group ►
    │   ├── View only (remote tabs only)
    │   └── Close / Close others / Close to right
    ├── Tab interactions
    │   ├── Drag to reorder
    │   ├── Drag to move between groups
    │   ├── Middle-click to close
    │   └── Double-click to rename
    ├── Tab indicators (from Warp)
    │   ├── Error: red dot when last command exited non-zero
    │   ├── Activity: subtle pulse when background tab has new output
    │   └── Running: spinner when a long command is executing
    ├── Restore closed tab (from Warp)
    │   ├── Ctrl+Shift+T reopens last closed tab
    │   ├── Keeps a stack of recently closed tabs (last 10, within 60s)
    │   └── Restores tab position, group, and terminal scrollback
    └── Durable sessions (from Wave)
        ├── Local: PTY keeps running if tab is closed but process alive
        │   (can reattach from recently closed list)
        ├── Remote: auto-reconnect on network interruption
        │   (3 retries, exponential backoff, then show reconnect button)
        └── App restart: restore last session state
            (reopen tabs, reconnect to running PTYs)
```

## Responsive Breakpoints

```
┌───────────┬──────────────────────────────────────────────────┐
│ < 500px   │ Mobile compact                                   │
│           │ • Bottom nav (Terminals / Devices / Config)       │
│           │ • Tab bar: compact, horizontal scroll             │
│           │ • No sidebar                                      │
│           │ • Carousel view default                           │
├───────────┼──────────────────────────────────────────────────┤
│ 500-699   │ Mobile                                           │
│           │ • Bottom nav                                      │
│           │ • Tab bar: full, horizontal scroll                │
│           │ • No sidebar                                      │
│           │ • List view default                               │
├───────────┼──────────────────────────────────────────────────┤
│ 700-899   │ Tablet                                           │
│           │ • Device sidebar (icon-only, ~40px)               │
│           │ • Tab bar + content                               │
│           │ • Grid view available                             │
├───────────┼──────────────────────────────────────────────────┤
│ >= 900    │ Desktop                                          │
│           │ • Device sidebar (expanded, ~140px)               │
│           │ • Chrome-style tab bar + content                  │
│           │ • All view modes                                  │
│           │ • Keyboard shortcuts active                       │
└───────────┴──────────────────────────────────────────────────┘
```

## Theme Integration

```
Terminal colors integrate with the app theme:

Light mode:
  Terminal background: #FFFFFF
  Terminal foreground: #1A1A1A
  Tab bar background:  Surface color
  Sidebar background:  Surface variant

Dark mode:
  Terminal background: #0D1117
  Terminal foreground: #E6EDF3
  Tab bar background:  Surface color
  Sidebar background:  Surface variant

OLED mode:
  Terminal background: #000000
  Terminal foreground: #FFFFFF
  Tab bar background:  #111111
  Sidebar background:  #000000

Tab group colors (user-selectable):
  🔴 Red, 🟠 Orange, 🟡 Yellow, 🟢 Green,
  🔵 Blue, 🟣 Purple, 🩷 Pink, ⚪ Grey

Custom terminal themes via Config:
  Solarized, Dracula, Monokai, Nord, One Dark, etc.
```

## Key Implementation Files

| Widget | File | Notes |
|--------|------|-------|
| WorkspacePage | `app/lib/pages/workspace_page.dart` | ResponsiveBuilder |
| ChromeTabBar | `app/lib/widget/chrome_tab_bar.dart` | Tab groups, pins, drag |
| TabGroup | `app/lib/widget/tab_group.dart` | Colored, collapsible |
| DeviceSidebar | `app/lib/widget/sidebar/device_sidebar.dart` | Narrow, devices only |
| TerminalTab | `app/lib/pages/tabs/terminal_tab.dart` | Local + remote modes |
| ConfigPage | `app/lib/pages/config_page.dart` | Opens as a tab |
| PairingFlow | `app/lib/pages/pairing_page.dart` | One-time setup |
