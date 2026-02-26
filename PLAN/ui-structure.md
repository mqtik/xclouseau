# UI Structure

## Desktop Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│  xClouseau                                              ─  □  ✕    │
├────────────┬─────────────────────────────────────────────────────────┤
│            │  ┌─────┐ ┌─────┐ ┌───────┐ ┌─────┐                    │
│  SIDEBAR   │  │ zsh │ │claude│ │ build │ │  +  │    ◫ ☰ ⊞          │
│            │  └─────┘ └─────┘ └───────┘ └─────┘    view modes      │
│ ┌────────┐ ├─────────────────────────────────────────────────────────┤
│ │PROJECTS│ │                                                         │
│ ├────────┤ │  $ claude                                               │
│ │        │ │                                                         │
│ │ ▼ Clouseau│  Hello! I'm Claude. How can I help you today?         │
│ │   ├ zsh│ │                                                         │
│ │   ├ claude│  > Can you help me build a terminal workspace manager? │
│ │   └ build│ │                                                       │
│ │        │ │  Of course! Let me help you with that. Here's what      │
│ │ ▶ MyApp│ │  I'd suggest...                                        │
│ │        │ │                                                         │
│ │ ▶ Blog │ │                                                         │
│ │        │ │                                                         │
│ ├────────┤ │                                                         │
│ │DEVICES │ │                                                         │
│ ├────────┤ │                                                         │
│ │ 📱 iPhone│ │                                                       │
│ │ 🖥 Win PC│ │                                                       │
│ │        │ │                                                         │
│ ├────────┤ │                                                         │
│ │        │ │                                                         │
│ │ ⚙ Settings│                                                       │
│ └────────┘ │  $                                                      │
│            │  █                                                      │
└────────────┴─────────────────────────────────────────────────────────┘

Sidebar width: 220px (collapsible to 60px icon-only)
Terminal area: fills remaining space
Tab bar height: 40px
```

## Mobile Layout

```
┌────────────────────────────┐
│  xClouseau          ≡     │
├────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌────┐  │
│ │ zsh  │ │claude│ │ +  │  │
│ └──────┘ └──────┘ └────┘  │
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
│                            │
│                            │
│  $                        │
│  █                        │
│                            │
├────────────────────────────┤
│  🖥 Terminals  📡 Devices  │
│              ⚙ Settings   │
└────────────────────────────┘

Bottom nav: 3 sections
  Terminals: shows active project's terminals
  Devices: nearby devices + file transfer
  Settings: app settings

Swipe left/right between tabs
Hamburger menu (≡) opens project list overlay
```

## Grid View Mode (Desktop)

```
┌────────────┬─────────────────────────────────────────────────────┐
│  SIDEBAR   │  ┌─────┐ ┌─────┐ ┌───────┐ ┌─────┐    ◫ ☰ ⊞    │
│            │  │ zsh │ │claude│ │ build │ │ logs│    [grid]     │
│ ▼ Clouseau │  └─────┘ └─────┘ └───────┘ └─────┘               │
│   ├ zsh    ├───────────────────────┬───────────────────────────│
│   ├ claude │  ┌──────────────────┐ │ ┌──────────────────────┐  │
│   ├ build  │  │ zsh              │ │ │ claude               │  │
│   └ logs   │  │                  │ │ │                      │  │
│            │  │ $ npm run build  │ │ │ > analyzing code...  │  │
│            │  │ Building...      │ │ │                      │  │
│            │  │ ████████░ 80%    │ │ │ Found 3 issues:      │  │
│            │  │                  │ │ │ 1. Missing import    │  │
│            │  └──────────────────┘ │ └──────────────────────┘  │
│            ├───────────────────────┼───────────────────────────│
│            │  ┌──────────────────┐ │ ┌──────────────────────┐  │
│            │  │ build            │ │ │ logs                 │  │
│            │  │                  │ │ │                      │  │
│            │  │ $ make release   │ │ │ [INFO] Server up     │  │
│            │  │ Compiling...     │ │ │ [INFO] Request /api  │  │
│            │  │                  │ │ │ [WARN] Slow query    │  │
│            │  └──────────────────┘ │ └──────────────────────┘  │
└────────────┴───────────────────────┴───────────────────────────┘

Grid arranges terminals in 2x2 (or NxM based on count).
Click any cell to focus it (maximize), click again to go back to grid.
All terminals update in real-time even when not focused.
```

## Carousel View Mode (Mobile)

```
┌────────────────────────────┐
│  xClouseau       ◫ ☰ ⊞   │
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
│              ⚙ Settings   │
└────────────────────────────┘

Carousel: full-width cards, swipe horizontally.
Dots indicate current tab position.
Pinch-to-zoom on terminal content.
```

## Component Tree

```
MaterialApp
└── RefenaScope
    └── WorkspacePage                        ← NEW (replaces HomePage)
        ├── ResponsiveBuilder
        │   ├── [Desktop] Row
        │   │   ├── ProjectSidebar           ← NEW
        │   │   │   ├── ProjectSection
        │   │   │   │   ├── ProjectListItem  (per project)
        │   │   │   │   │   └── SessionListItem (per terminal)
        │   │   │   │   └── NewProjectButton
        │   │   │   ├── DeviceSection
        │   │   │   │   └── DeviceListTile   (reused from LocalSend)
        │   │   │   └── SettingsButton
        │   │   └── Expanded
        │   │       └── Column
        │   │           ├── TerminalTabBar   ← NEW
        │   │           │   ├── TabItem (per session)
        │   │           │   ├── NewTabButton
        │   │           │   └── ViewModeToggle
        │   │           └── Expanded
        │   │               └── TerminalContent
        │   │                   ├── [list]  TerminalTab       ← NEW
        │   │                   ├── [grid]  GridView<TerminalTab>
        │   │                   └── [carousel] PageView<TerminalTab>
        │   │
        │   └── [Mobile] Column
        │       ├── TerminalTabBar           (horizontal scroll)
        │       ├── Expanded
        │       │   └── PageView             (swipeable)
        │       │       ├── TerminalContent
        │       │       ├── DevicesPage       (reused send/receive)
        │       │       └── SettingsTab       (reused from LocalSend)
        │       └── NavigationBar
        │           ├── Terminals
        │           ├── Devices
        │           └── Settings
        │
        └── Watchers (from LocalSend, unchanged)
            ├── LifeCycleWatcher
            ├── WindowWatcher
            ├── ShortcutWatcher   (extended with terminal shortcuts)
            └── TrayWatcher
```

## TerminalTab Widget (Key Component)

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
│   ├── WebSocket connection to host
│   └── StatusBar
│       ├── Device name + session name
│       ├── Interactive / View-only toggle
│       └── Connection status indicator
│
└── [Common]
    ├── Context menu (right-click)
    │   ├── Copy
    │   ├── Paste
    │   ├── Clear
    │   ├── Split (future)
    │   └── Rename tab
    └── Drag-to-reorder (tab bar)
```

## Responsive Breakpoints

```
┌─────────────────────────────────────────────────────────────┐
│                    Breakpoints                              │
├──────────┬──────────────────────────────────────────────────┤
│ < 500px  │ Mobile compact                                  │
│          │ • Bottom nav, no sidebar                         │
│          │ • Single terminal fills screen                   │
│          │ • Carousel view mode default                     │
├──────────┼──────────────────────────────────────────────────┤
│ 500-699  │ Mobile                                          │
│          │ • Bottom nav, no sidebar                         │
│          │ • Tab bar above content                          │
│          │ • List view mode default                         │
├──────────┼──────────────────────────────────────────────────┤
│ 700-799  │ Tablet                                          │
│          │ • Sidebar (icon-only, 60px)                      │
│          │ • Tab bar + content                              │
│          │ • Grid view available                            │
├──────────┼──────────────────────────────────────────────────┤
│ >= 800   │ Desktop                                         │
│          │ • Sidebar (expanded, 220px)                      │
│          │ • Tab bar + content                              │
│          │ • All view modes available                       │
│          │ • Keyboard shortcuts active                      │
└──────────┴──────────────────────────────────────────────────┘

These align with LocalSend's existing ResponsiveBuilder:
  isMobile:          width < 700
  isTabletOrDesktop: width >= 700
  isDesktop:         width >= 800
```

## View Mode Toggle

```
┌──────────────────────────────────────────────┐
│  Tab bar:                                    │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌───┐    ◫ ☰ ⊞  │
│  │ zsh │ │ vim │ │logs │ │ + │    ↑        │
│  └─────┘ └─────┘ └─────┘ └───┘    │        │
│                                view mode    │
│                                toggle       │
│                                             │
│  ◫ = List (single terminal, tabs switch)    │
│  ☰ = Grid (2x2 or NxM, all visible)        │
│  ⊞ = Carousel (swipe between cards)         │
└──────────────────────────────────────────────┘
```

## Theme Integration

```
Terminal colors integrate with the app theme:

Light mode:
  Terminal background: #FFFFFF
  Terminal foreground: #1A1A1A
  Sidebar background:  Surface color
  Tab bar:            Surface variant

Dark mode:
  Terminal background: #0D1117
  Terminal foreground: #E6EDF3
  Sidebar background:  Surface color
  Tab bar:            Surface variant

OLED mode:
  Terminal background: #000000
  Terminal foreground: #FFFFFF
  Sidebar background:  #000000
  Tab bar:            #111111

Custom terminal themes supported via settings:
  Solarized, Dracula, Monokai, Nord, etc.
  Applied per-terminal or globally
```

## Key Implementation Files

| Widget | File | Reuses |
|--------|------|--------|
| WorkspacePage | `app/lib/pages/workspace_page.dart` | ResponsiveBuilder pattern |
| ProjectSidebar | `app/lib/widget/sidebar/project_sidebar.dart` | CustomListTile |
| TerminalTabBar | `app/lib/widget/terminal_tab_bar.dart` | — |
| TerminalTab | `app/lib/pages/tabs/terminal_tab.dart` | — |
| DeviceSection | reuses `device_list_tile.dart` | DeviceListTile |
| SettingsTab | extends `settings_tab.dart` | Existing settings UI |
