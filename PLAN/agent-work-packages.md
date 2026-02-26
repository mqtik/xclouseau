# Agent Work Packages

## Overview

This document breaks the entire xClouseau project into independent work packages, each sized for one agent session. Agents can work in parallel on packages that don't have dependency conflicts.

## Dependency Graph

```
WP-01 ──► WP-03 ──► WP-06 ──► WP-11 ──► WP-15
  │         │         │                    │
  │         │         ▼                    ▼
  │         │       WP-07 ──► WP-11      WP-16 ──► WP-20
  │         │                              │
  │         ▼                              ▼
  │       WP-04 ──► WP-08              WP-17
  │         │
  │         ▼
  │       WP-05 ──► WP-09
  │
  ▼
WP-02 ──► WP-03
            │
            ▼
          WP-10 ──► WP-12 ──► WP-13 ──► WP-14

WP-22 through WP-26: Rebranding (independent of all feature work)
WP-27 through WP-30: Polish (depends on all feature work)

Legend:
  WP-XX ──► WP-YY means "WP-YY depends on WP-XX"
```

## Parallel Batches

```
BATCH 1 (no dependencies — start immediately):
  WP-01, WP-02, WP-22, WP-23, WP-24, WP-25, WP-26

BATCH 2 (depends on WP-01 + WP-02):
  WP-03, WP-04, WP-05

BATCH 3 (depends on WP-03):
  WP-06, WP-07, WP-08, WP-09, WP-10

BATCH 4 (depends on Batch 3):
  WP-11, WP-12

BATCH 5 (depends on Batch 4):
  WP-13, WP-14, WP-15, WP-16

BATCH 6 (depends on Batch 5):
  WP-17, WP-18, WP-19, WP-20, WP-21

BATCH 7 (depends on all):
  WP-27, WP-28, WP-29, WP-30
```

---

## Work Packages

### WP-01: Add Terminal Dependencies

**Phase**: 1 | **Batch**: 1 | **Dependencies**: none

**Scope**: Add xterm.dart and flutter_pty to the project and verify they compile.

**Input files**:
- `app/pubspec.yaml`

**Actions**:
1. Add `xterm: ^3.2.6` to dependencies
2. Add `flutter_pty: ^0.4.0` to dependencies
3. Run `flutter pub get`
4. Verify build succeeds on macOS: `flutter build macos`

**Output**: Updated `app/pubspec.yaml` with new dependencies, clean build

**Acceptance criteria**:
- [ ] `flutter pub get` succeeds
- [ ] `flutter build macos` succeeds (or `flutter run -d macos` launches)
- [ ] No dependency conflicts

---

### WP-02: Project Data Model

**Phase**: 1 | **Batch**: 1 | **Dependencies**: none

**Scope**: Create the Project, TerminalSession, and related models with JSON serialization.

**Input files**: none (new files)

**Actions**:
1. Create `app/lib/model/project.dart` with Project and TerminalSession classes
2. Create `app/lib/model/terminal_session_source.dart` with SessionSource sealed class
3. Add dart_mappable annotations for JSON serialization
4. Run code generation if needed

**Output files**:
- `app/lib/model/project.dart`
- `app/lib/model/terminal_session_source.dart`

**Reference**: See [data-model.md](data-model.md) for exact field specs

**Acceptance criteria**:
- [ ] Models serialize to/from JSON correctly
- [ ] Project contains list of TerminalSession
- [ ] SessionSource supports local and remote variants

---

### WP-03: Project Provider (State Management)

**Phase**: 1 | **Batch**: 2 | **Dependencies**: WP-01, WP-02

**Scope**: Refena provider for managing projects and their terminal sessions, with persistence.

**Input files**:
- `app/lib/model/project.dart` (from WP-02)
- `app/lib/provider/persistence_provider.dart` (existing, extend)

**Actions**:
1. Create `app/lib/provider/project_provider.dart`
2. Implement ReduxProvider with actions: CreateProject, DeleteProject, RenameProject, AddSession, RemoveSession, SetActiveProject, SetActiveSession
3. Add persistence keys to `persistence_provider.dart`: `xc_projects`, `xc_active_state`
4. Load/save projects from SharedPreferences on init/change

**Output files**:
- `app/lib/provider/project_provider.dart`
- Modified `app/lib/provider/persistence_provider.dart`

**Reference**: See [data-model.md](data-model.md) for provider actions spec

**Acceptance criteria**:
- [ ] Projects persist across app restarts
- [ ] Active project/session state persists
- [ ] Default project created on first launch
- [ ] All CRUD actions work

---

### WP-04: Terminal Provider (Local PTY)

**Phase**: 1 | **Batch**: 2 | **Dependencies**: WP-01

**Scope**: Refena provider managing live Terminal and Pty instances.

**Input files**:
- `app/pubspec.yaml` (xterm + flutter_pty from WP-01)

**Actions**:
1. Create `app/lib/provider/terminal_provider.dart`
2. Implement: SpawnTerminal (creates Terminal + Pty, wires I/O), KillTerminal, ResizeTerminal, WriteToTerminal
3. Map: session ID → LiveTerminal (Terminal + Pty + status)
4. Handle PTY lifecycle: detect process exit, update status
5. Platform-aware shell detection (zsh on macOS, bash on Linux, powershell on Windows)

**Output files**:
- `app/lib/provider/terminal_provider.dart`
- `app/lib/model/live_terminal.dart`

**Reference**: See [data-model.md](data-model.md) for LiveTerminal spec

**Acceptance criteria**:
- [ ] Can spawn a shell process and get output
- [ ] Terminal.write() renders in TerminalView
- [ ] Pty.write() sends keyboard input to shell
- [ ] Process exit detected and status updated
- [ ] Resize works
- [ ] Multiple terminals can run simultaneously

---

### WP-05: Terminal Settings

**Phase**: 1 | **Batch**: 2 | **Dependencies**: WP-01

**Scope**: Add terminal-related settings to the existing settings system.

**Input files**:
- `app/lib/provider/settings_provider.dart` (existing)
- `app/lib/provider/persistence_provider.dart` (existing)
- `app/lib/model/state/settings_state.dart` (existing)

**Actions**:
1. Add terminal fields to settings state: defaultShell, fontSize, fontFamily, terminalTheme, allowRemoteAccess, requirePin, scrollbackLines
2. Add persistence keys with `xc_` prefix
3. Add settings UI section in settings_tab.dart

**Output files**:
- Modified `app/lib/provider/settings_provider.dart`
- Modified `app/lib/provider/persistence_provider.dart`
- Modified `app/lib/model/state/settings_state.dart`
- Modified `app/lib/pages/tabs/settings_tab.dart`

**Acceptance criteria**:
- [ ] Terminal settings visible in settings tab
- [ ] Settings persist across restarts
- [ ] Default shell auto-detected per platform

---

### WP-06: Project Sidebar Widget

**Phase**: 1 | **Batch**: 3 | **Dependencies**: WP-03

**Scope**: Create the sidebar widget showing projects, devices, and settings.

**Input files**:
- `app/lib/provider/project_provider.dart` (from WP-03)
- `app/lib/widget/list_tile/custom_list_tile.dart` (existing, reuse)
- `app/lib/widget/list_tile/device_list_tile.dart` (existing, reuse)
- `app/lib/provider/network/nearby_devices_provider.dart` (existing, reuse)

**Actions**:
1. Create `app/lib/widget/sidebar/project_sidebar.dart`
2. Sections: Projects (expandable with sessions), Devices (from nearbyDevicesProvider), Settings button
3. Click project → expand/collapse sessions
4. Click session → dispatch SetActiveSession
5. Click device → navigate to device detail
6. Collapsible sidebar (220px expanded, 60px icon-only)

**Output files**:
- `app/lib/widget/sidebar/project_sidebar.dart`

**Reference**: See [ui-structure.md](ui-structure.md) for wireframe

**Acceptance criteria**:
- [ ] Projects listed with color indicators
- [ ] Projects expandable to show terminal sessions
- [ ] Nearby devices shown in device section
- [ ] Settings button navigates to settings
- [ ] Sidebar collapses on narrow screens

---

### WP-07: Terminal Tab Bar Widget

**Phase**: 1 | **Batch**: 3 | **Dependencies**: WP-03

**Scope**: Horizontal scrollable tab bar for terminal sessions.

**Input files**:
- `app/lib/provider/project_provider.dart` (from WP-03)

**Actions**:
1. Create `app/lib/widget/terminal_tab_bar.dart`
2. Horizontal scrollable tabs showing session names
3. Active tab highlighted with project color
4. Close button on each tab (except last one in project)
5. "+" button to add new terminal
6. View mode toggle buttons (list/grid/carousel)
7. Drag-to-reorder tabs

**Output files**:
- `app/lib/widget/terminal_tab_bar.dart`

**Reference**: See [ui-structure.md](ui-structure.md) for wireframe

**Acceptance criteria**:
- [ ] Tabs display session names
- [ ] Active tab visually highlighted
- [ ] Close button removes session
- [ ] "+" creates new terminal in active project
- [ ] View mode toggle buttons present (functionality in WP-20)
- [ ] Scrolls when too many tabs

---

### WP-08: Terminal Tab Widget (Local Mode)

**Phase**: 1 | **Batch**: 3 | **Dependencies**: WP-04

**Scope**: Terminal tab that renders a local PTY using xterm.dart.

**Input files**:
- `app/lib/provider/terminal_provider.dart` (from WP-04)

**Actions**:
1. Create `app/lib/pages/tabs/terminal_tab.dart`
2. Wraps xterm.dart TerminalView widget
3. Connects to TerminalProvider for the session's Terminal instance
4. Handles focus (keyboard goes to active terminal)
5. Handles resize (LayoutBuilder → TerminalProvider.resize)
6. Context menu: copy, paste, clear

**Output files**:
- `app/lib/pages/tabs/terminal_tab.dart`

**Acceptance criteria**:
- [ ] Terminal renders shell output with ANSI colors
- [ ] Keyboard input works
- [ ] vim/nvim works inside terminal
- [ ] Resize re-flows content correctly
- [ ] Copy/paste works
- [ ] Multiple terminal tabs can exist simultaneously

---

### WP-09: Settings Tab Extension

**Phase**: 1 | **Batch**: 3 | **Dependencies**: WP-05

**Scope**: Add terminal settings section to existing settings tab.

**Input files**:
- `app/lib/pages/tabs/settings_tab.dart` (existing)
- `app/lib/provider/settings_provider.dart` (modified in WP-05)

**Actions**:
1. Add "Terminal" section to settings tab
2. Shell selector dropdown
3. Font size slider
4. Font family picker
5. Terminal theme dropdown
6. Remote access toggle
7. PIN input for terminal access

**Output files**:
- Modified `app/lib/pages/tabs/settings_tab.dart`

**Acceptance criteria**:
- [ ] Terminal settings section visible
- [ ] Changes apply to new terminals
- [ ] Settings persist

---

### WP-10: Navigation Restructure

**Phase**: 1 | **Batch**: 3 | **Dependencies**: WP-03

**Scope**: Replace LocalSend's 3-tab NavigationRail with sidebar + workspace layout.

**Input files**:
- `app/lib/pages/home_page.dart` (existing, replace)
- `app/lib/pages/home_page_controller.dart` (existing, replace)
- `app/lib/main.dart` (existing, modify)

**Actions**:
1. Create `app/lib/pages/workspace_page.dart` — new main page
2. Desktop: Row with ProjectSidebar + Expanded content area
3. Mobile: PageView with bottom NavigationBar (Terminals/Devices/Settings)
4. Update HomeTab enum to {workspace, devices, settings}
5. Update main.dart to use WorkspacePage instead of HomePage
6. Keep existing send/receive tabs accessible under "Devices"

**Output files**:
- `app/lib/pages/workspace_page.dart`
- Modified `app/lib/pages/home_page_controller.dart`
- Modified `app/lib/main.dart`

**Reference**: See [ui-structure.md](ui-structure.md) for layout wireframes

**Acceptance criteria**:
- [ ] Desktop shows sidebar + content area
- [ ] Mobile shows bottom nav with 3 sections
- [ ] File transfer still works via Devices section
- [ ] Responsive transitions at breakpoints (700px, 800px)

---

### WP-11: Wire Everything Together (Phase 1 Complete)

**Phase**: 1 | **Batch**: 4 | **Dependencies**: WP-06, WP-07, WP-08, WP-10

**Scope**: Integration of all Phase 1 components into a working app.

**Input files**: All files from WP-01 through WP-10

**Actions**:
1. Register projectProvider and terminalProvider in Refena container (main.dart)
2. Add terminal initialization in config/init.dart postInit()
3. Connect sidebar clicks → project/session switching → terminal display
4. Connect tab bar → terminal switching
5. Default project with one terminal on first launch
6. Verify complete flow: launch → sidebar → tab → terminal → type → works

**Output files**:
- Modified `app/lib/main.dart`
- Modified `app/lib/config/init.dart`

**Acceptance criteria**:
- [ ] `flutter run -d macos` shows sidebar with default project
- [ ] Terminal tab runs user's shell
- [ ] Can create new projects and terminals
- [ ] Can switch between terminals
- [ ] Nearby devices visible
- [ ] File send/receive works
- [ ] No crashes on resize

---

### WP-12: Terminal Streaming Server (Host Side)

**Phase**: 2 | **Batch**: 4 | **Dependencies**: WP-04, WP-10

**Scope**: Server-side routes that expose terminal sessions for remote viewing.

**Input files**:
- `app/lib/provider/terminal_provider.dart` (from WP-04)
- `app/lib/provider/network/server/server_provider.dart` (existing)
- `app/lib/provider/network/server/controller/receive_controller.dart` (existing, reference pattern)

**Actions**:
1. Create `app/lib/provider/network/server/controller/terminal_controller.dart`
2. Implement routes: GET /sessions, GET /sessions/:id/attach (WebSocket), POST /sessions/:id/input, POST /sessions/:id/resize
3. WebSocket handler: pipe PTY output to WebSocket binary frames, receive keyboard input
4. Support multiple viewers per session
5. Register routes in server_provider.dart
6. Respect allowRemoteAccess and PIN settings

**Output files**:
- `app/lib/provider/network/server/controller/terminal_controller.dart`
- Modified `app/lib/provider/network/server/server_provider.dart`

**Reference**: See [terminal-streaming.md](terminal-streaming.md) for full protocol spec

**Acceptance criteria**:
- [ ] GET /sessions returns list of active sessions
- [ ] WebSocket attach receives PTY output bytes
- [ ] Input sent over WebSocket writes to PTY
- [ ] Resize propagates to PTY
- [ ] Multiple WebSocket connections to same session work
- [ ] PIN check if configured

---

### WP-13: Remote Terminal Provider (Client Side)

**Phase**: 2 | **Batch**: 5 | **Dependencies**: WP-12

**Scope**: Client-side provider for connecting to remote terminal sessions.

**Input files**:
- `app/lib/provider/terminal_provider.dart` (from WP-04, reference pattern)

**Actions**:
1. Create `app/lib/provider/remote_terminal_provider.dart`
2. Manage WebSocket connections to remote devices
3. Create local xterm.dart Terminal instance for rendering
4. Pipe WebSocket binary frames → Terminal.write()
5. Pipe keyboard input → WebSocket binary frames
6. Handle mode switching (interactive/view-only)
7. Handle reconnection on network loss (3 retries, exponential backoff)
8. Handle session close notification

**Output files**:
- `app/lib/provider/remote_terminal_provider.dart`

**Acceptance criteria**:
- [ ] Can connect to remote terminal via WebSocket
- [ ] Output renders in local Terminal instance
- [ ] Keyboard input sent to remote PTY
- [ ] Mode toggle sends control message
- [ ] Reconnection attempts on disconnect
- [ ] Session close handled gracefully

---

### WP-14: Device Terminal Browser

**Phase**: 2 | **Batch**: 5 | **Dependencies**: WP-12

**Scope**: Page showing available terminal sessions on a remote device.

**Input files**:
- `app/lib/provider/network/nearby_devices_provider.dart` (existing)
- `app/lib/provider/remote_terminal_provider.dart` (from WP-13)

**Actions**:
1. Create `app/lib/pages/device_terminals_page.dart`
2. Fetch GET /sessions from selected device
3. Show list of available sessions with name, project, size
4. Tap session → create remote TerminalSession in active project → attach
5. Also show file transfer options (send/receive buttons)

**Output files**:
- `app/lib/pages/device_terminals_page.dart`

**Acceptance criteria**:
- [ ] Tapping device in sidebar shows its terminals
- [ ] Terminal list updates on refresh
- [ ] Tapping terminal opens remote tab in current project
- [ ] File transfer options still accessible

---

### WP-15: Terminal Tab Widget (Remote Mode)

**Phase**: 2 | **Batch**: 5 | **Dependencies**: WP-08, WP-13

**Scope**: Extend terminal_tab.dart to support remote mode.

**Input files**:
- `app/lib/pages/tabs/terminal_tab.dart` (from WP-08)
- `app/lib/provider/remote_terminal_provider.dart` (from WP-13)

**Actions**:
1. Modify terminal_tab.dart to check SessionSource (local vs remote)
2. Local: use Pty (existing behavior)
3. Remote: use RemoteTerminalProvider (WebSocket)
4. Show connection status indicator (connected/reconnecting/disconnected)
5. Show remote device name in tab or status bar

**Output files**:
- Modified `app/lib/pages/tabs/terminal_tab.dart`

**Acceptance criteria**:
- [ ] Remote terminals render correctly
- [ ] Connection status visible
- [ ] Seamless switch between local and remote tabs

---

### WP-16: View-Only Toggle

**Phase**: 2 | **Batch**: 5 | **Dependencies**: WP-15

**Scope**: Toggle between interactive and view-only mode on remote terminals.

**Input files**:
- `app/lib/pages/tabs/terminal_tab.dart` (from WP-15)
- `app/lib/provider/remote_terminal_provider.dart` (from WP-13)

**Actions**:
1. Add toggle button to remote terminal status bar
2. View-only: disable keyboard forwarding, show read-only indicator
3. Interactive: enable keyboard forwarding
4. Send mode control message over WebSocket
5. Default to interactive mode

**Output files**:
- Modified `app/lib/pages/tabs/terminal_tab.dart`

**Acceptance criteria**:
- [ ] Toggle button visible on remote terminals
- [ ] View-only mode blocks keyboard input
- [ ] Interactive mode allows keyboard input
- [ ] Mode change communicated to host

---

### WP-17: Mobile Terminal Viewer

**Phase**: 3 | **Batch**: 6 | **Dependencies**: WP-15

**Scope**: Optimize terminal viewing for mobile devices.

**Input files**:
- `app/lib/pages/tabs/terminal_tab.dart` (from WP-15)

**Actions**:
1. Adjust font size for mobile (smaller default)
2. Add pinch-to-zoom gesture on terminal content
3. Soft keyboard integration for interactive mode
4. Swipe gestures for tab switching
5. Landscape mode support

**Output files**:
- Modified `app/lib/pages/tabs/terminal_tab.dart`

**Acceptance criteria**:
- [ ] Terminal readable on phone screen
- [ ] Pinch-to-zoom works
- [ ] Keyboard shows when tapping in interactive mode
- [ ] Landscape mode renders correctly

---

### WP-18: Image-to-Terminal Pipeline

**Phase**: 3 | **Batch**: 6 | **Dependencies**: WP-11

**Scope**: When a file is received from another device, offer to paste its path into the active terminal.

**Input files**:
- `app/lib/provider/network/server/controller/receive_controller.dart` (existing)
- `app/lib/provider/terminal_provider.dart` (from WP-04)

**Actions**:
1. Create `app/lib/provider/file_terminal_bridge.dart`
2. Listen for file receive events from receive_controller
3. When file received: show notification with file name, thumbnail (if image), and "Paste to terminal" button
4. "Paste to terminal": calls terminalProvider.writeToTerminal(activeSessionId, filePath)
5. File path is written as text input to the PTY

**Output files**:
- `app/lib/provider/file_terminal_bridge.dart`
- Modified `app/lib/provider/network/server/controller/receive_controller.dart` (add hook)

**Reference**: See [ai-integration.md](ai-integration.md) for pipeline diagram

**Acceptance criteria**:
- [ ] File received → notification appears
- [ ] Notification shows file name and thumbnail for images
- [ ] "Paste to terminal" types path into active terminal
- [ ] Works with any file type

---

### WP-19: AI CLI Detection

**Phase**: 3 | **Batch**: 6 | **Dependencies**: WP-08

**Scope**: Detect when an AI CLI tool is running in a terminal tab and show enhanced UI.

**Input files**:
- `app/lib/pages/tabs/terminal_tab.dart` (from WP-08)

**Actions**:
1. Create `app/lib/util/ai_cli_detector.dart`
2. Check PTY child process name against known patterns (claude, codex, gemini, aider)
3. When detected: show AI indicator on tab, show image drop zone below terminal
4. Image drop zone: drag-and-drop area that pastes file path to terminal on drop

**Output files**:
- `app/lib/util/ai_cli_detector.dart`
- `app/lib/widget/image_drop_zone.dart`
- Modified `app/lib/pages/tabs/terminal_tab.dart`

**Reference**: See [ai-integration.md](ai-integration.md) for detection spec

**Acceptance criteria**:
- [ ] Running `claude` in terminal shows AI indicator
- [ ] Image drop zone appears when AI CLI detected
- [ ] Dropping image pastes path to terminal
- [ ] Detection works for claude, codex, gemini

---

### WP-20: View Modes (Grid + Carousel)

**Phase**: 3 | **Batch**: 6 | **Dependencies**: WP-08, WP-07

**Scope**: Grid and carousel view modes for terminal tabs.

**Input files**:
- `app/lib/pages/tabs/terminal_tab.dart` (from WP-08)
- `app/lib/widget/terminal_tab_bar.dart` (from WP-07)
- `app/lib/pages/workspace_page.dart` (from WP-10)

**Actions**:
1. Add view mode state to project provider (list/grid/carousel)
2. List mode: single terminal fills content area (current default)
3. Grid mode: GridView of TerminalTab widgets (2x2 or auto)
4. Carousel mode: PageView with dot indicators
5. View mode toggle buttons in tab bar switch the layout
6. Click grid cell → focuses that terminal (maximizes)

**Output files**:
- Modified `app/lib/pages/workspace_page.dart`
- Modified `app/lib/widget/terminal_tab_bar.dart`
- Modified `app/lib/provider/project_provider.dart`

**Reference**: See [ui-structure.md](ui-structure.md) for view mode wireframes

**Acceptance criteria**:
- [ ] Grid shows all terminals simultaneously
- [ ] All terminals update in real-time in grid
- [ ] Carousel swipes between terminals
- [ ] View mode persists per project
- [ ] Click grid cell focuses terminal

---

### WP-21: Keyboard Shortcuts

**Phase**: 3 | **Batch**: 6 | **Dependencies**: WP-11

**Scope**: Desktop keyboard shortcuts for workspace management.

**Input files**:
- `app/lib/widget/watcher/shortcut_watcher.dart` (existing)
- `app/lib/provider/project_provider.dart` (from WP-03)
- `app/lib/provider/terminal_provider.dart` (from WP-04)

**Actions**:
1. Extend shortcut_watcher.dart with terminal shortcuts
2. Ctrl+T: new terminal tab
3. Ctrl+W: close terminal tab
4. Ctrl+Tab / Ctrl+Shift+Tab: next/previous tab
5. Ctrl+N: new project
6. Ctrl+1-9: switch to tab N
7. Ctrl+Shift+Left/Right: move tab

**Output files**:
- Modified `app/lib/widget/watcher/shortcut_watcher.dart`

**Acceptance criteria**:
- [ ] All shortcuts work on desktop
- [ ] Shortcuts don't conflict with terminal (Ctrl handled at app level vs PTY)
- [ ] Shortcuts documented in settings

---

### WP-22: Rebranding — Android

**Phase**: 4 | **Batch**: 1 | **Dependencies**: none

**Scope**: Rename LocalSend → xClouseau in Android platform files.

**Input files**:
- `app/android/app/build.gradle`
- `app/android/app/src/main/AndroidManifest.xml`
- `app/android/app/src/debug/AndroidManifest.xml`
- Kotlin source files in `app/android/app/src/main/kotlin/org/localsend/`

**Actions**:
1. Change namespace and applicationId in build.gradle
2. Change package and label in AndroidManifest files
3. Move Kotlin source from `org/localsend/localsend_app/` to `org/xclouseau/xclouseau_app/`
4. Update package declarations in Kotlin files

**Pattern**: `org.localsend.localsend_app` → `org.xclouseau.xclouseau_app`, `LocalSend` → `xClouseau`

**Acceptance criteria**:
- [ ] `flutter build apk` succeeds
- [ ] App shows "xClouseau" in Android launcher

---

### WP-23: Rebranding — iOS

**Phase**: 4 | **Batch**: 1 | **Dependencies**: none

**Scope**: Rename in iOS platform files.

**Input files**:
- `app/ios/Runner/Info.plist`
- `app/ios/ShareExtension/Info.plist`
- iOS project settings

**Actions**:
1. Change display name and bundle name in Info.plist files
2. Update bundle identifier

**Acceptance criteria**:
- [ ] `flutter build ios` succeeds (or at least no naming errors)
- [ ] App shows "xClouseau" on iOS home screen

---

### WP-24: Rebranding — macOS

**Phase**: 4 | **Batch**: 1 | **Dependencies**: none

**Scope**: Rename in macOS platform files.

**Input files**:
- `app/macos/Runner/Configs/AppInfo.xcconfig`
- `app/macos/Runner/Info.plist`
- `app/macos/ShareExtension/Info.plist`

**Actions**:
1. Change PRODUCT_NAME, PRODUCT_BUNDLE_IDENTIFIER in AppInfo.xcconfig
2. Change display name in Info.plist files
3. Update copyright

**Acceptance criteria**:
- [ ] `flutter build macos` succeeds
- [ ] App shows "xClouseau" in macOS dock and title bar

---

### WP-25: Rebranding — Windows + Linux

**Phase**: 4 | **Batch**: 1 | **Dependencies**: none

**Scope**: Rename in Windows and Linux platform files.

**Input files**:
- `app/windows/CMakeLists.txt`
- `app/windows/runner/Runner.rc`
- `app/linux/CMakeLists.txt`
- `app/linux/packaging/deb/make_config.yaml`
- `app/linux/packaging/rpm/make_config.yaml`

**Actions**:
1. Change project name, binary name in CMakeLists.txt files
2. Change file description, product name in Runner.rc
3. Change display name, package name in make_config files

**Acceptance criteria**:
- [ ] Windows/Linux builds produce correctly named executables
- [ ] App title shows "xClouseau"

---

### WP-26: Rebranding — Web + Build Scripts + pubspec

**Phase**: 4 | **Batch**: 1 | **Dependencies**: none

**Scope**: Rename in web platform, build scripts, and pubspec.

**Input files**:
- `app/web/index.html`
- `app/web/manifest.json`
- `app/pubspec.yaml`
- `msix/AppxManifest.xml`
- `scripts/compile_*.sh`, `scripts/compile_*.ps1`, `scripts/compile_*.iss`

**Actions**:
1. Change title, meta tags in index.html
2. Change name, short_name in manifest.json
3. Change package name in pubspec.yaml
4. Update MSIX manifest
5. Update all build script file names and references

**Acceptance criteria**:
- [ ] Web build shows "xClouseau" in browser tab
- [ ] Build scripts produce correctly named outputs
- [ ] No remaining "LocalSend" in user-visible text

---

### WP-27: Terminal Themes

**Phase**: Polish | **Batch**: 7 | **Dependencies**: WP-08

**Scope**: Bundled terminal color themes.

**Actions**:
1. Create `app/lib/config/terminal_themes.dart`
2. Bundle themes: Dark, Light, Solarized Dark, Solarized Light, Dracula, Monokai, Nord, One Dark
3. Each theme maps to xterm.dart TerminalTheme
4. Theme selector in terminal settings
5. Theme preview in settings

**Acceptance criteria**:
- [ ] 8+ themes available
- [ ] Theme applies immediately to terminal
- [ ] Theme persists per-project or globally

---

### WP-28: Terminal Font Selection

**Phase**: Polish | **Batch**: 7 | **Dependencies**: WP-08

**Scope**: Font family and size configuration for terminals.

**Actions**:
1. Bundle monospace fonts: JetBrains Mono, Fira Code, Source Code Pro, Cascadia Code
2. Font picker in settings
3. Font size slider (8-24pt)
4. Font preview in settings

**Acceptance criteria**:
- [ ] Multiple fonts available
- [ ] Font size adjustable
- [ ] Changes apply to all terminals

---

### WP-29: Integration Testing

**Phase**: Polish | **Batch**: 7 | **Dependencies**: all

**Scope**: End-to-end tests for critical flows.

**Actions**:
1. Test: launch app → default project exists → terminal works
2. Test: create project → add terminal → switch between terminals
3. Test: file transfer still works (send/receive)
4. Test: settings persist across restart
5. Test: remote terminal connection (if two instances available)

**Acceptance criteria**:
- [ ] All critical paths tested
- [ ] No regressions in LocalSend file transfer

---

### WP-30: App Icon

**Phase**: Polish | **Batch**: 7 | **Dependencies**: none

**Scope**: Design and place xClouseau app icon across all platforms.

**Actions**:
1. Design icon (or use placeholder)
2. Generate platform-specific sizes
3. Replace icons in:
   - `app/assets/img/`
   - `app/android/app/src/main/res/mipmap-*/`
   - `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - `app/macos/Runner/Assets.xcassets/AppIcon.appiconset/`
   - `app/windows/runner/resources/app_icon.ico`
   - `app/web/icons/`
   - `msix/Images/`

**Acceptance criteria**:
- [ ] Custom icon appears on all platforms
- [ ] No remaining LocalSend icon
