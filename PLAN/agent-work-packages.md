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
  │         │
  │         ▼
  ▼       WP-10 ──► WP-12A ──► WP-12 ──► WP-13 ──► WP-14
WP-04                                                  │
(also                                                   ▼
 needs                                               WP-14
 WP-02)                                        (also needs WP-13)

WP-22 through WP-26: Rebranding (independent of feature work, Batch 5)
WP-27 through WP-30: Polish (depends on all feature work)
WP-31: Rust PTY daemon (Batch 5, parallel with streaming)
WP-32: Terminal file drop + pickers (Batch 7, Phase 3)
WP-33: Web preview — reverse proxy + WebView tab (Batch 7, Phase 3)

Legend:
  WP-XX ──► WP-YY means "WP-YY depends on WP-XX"

Key dependency fixes vs. original plan:
  - WP-04 depends on BOTH WP-01 and WP-02 (needs model types)
  - WP-14 depends on WP-13 (needs remote terminal provider)
  - WP-12A (NEW): SimpleServer upgrade, prerequisite for WP-12
  - Rebranding moved from Batch 1 to Batch 5 (avoids merge conflicts)
```

## Parallel Batches

```
BATCH 1 ✅ COMPLETE (2026-02-26):
  WP-01 ✅, WP-02 ✅

BATCH 2 ✅ COMPLETE (2026-02-26):
  WP-03 ✅, WP-04 ✅, WP-05 ✅

BATCH 3 ✅ COMPLETE (2026-02-27):
  WP-06 ✅, WP-07 ✅, WP-08 ✅, WP-09 ✅, WP-10 ✅

BATCH 4 ✅ COMPLETE (2026-02-27):
  WP-11 ✅, WP-12A ✅

BATCH 5 ✅ COMPLETE (2026-02-27) — streaming server done, daemon/rebranding deferred:
  WP-12 ✅  (terminal streaming server)
  WP-31 ⬜  (Rust PTY daemon — deferred)
  WP-22-26 ⬜  (rebranding — deferred)

BATCH 6 ✅ COMPLETE (2026-02-28):
  WP-13 ✅, WP-14 ✅, WP-15 ✅, WP-16 ✅

BATCH 7 ✅ COMPLETE (2026-02-28):
  WP-17 ✅, WP-18 ✅, WP-19 ✅, WP-20 ✅, WP-21 ✅, WP-32 ✅, WP-33 ✅

BATCH 8 ✅ COMPLETE (2026-02-28):
  WP-27 ✅, WP-28 ✅, WP-29 ✅, WP-30 ✅
```

---

## Work Packages

### WP-01: Add Terminal Dependencies

**Phase**: 1 | **Batch**: 1 | **Dependencies**: none

**Scope**: Add xterm.dart and flutter_pty to the project and verify they compile.

**Input files**:
- `app/pubspec.yaml`

**Actions**:
1. Add `xterm: ^4.0.0` (latest on pub.dev). Test keyboard input — if typing doesn't work (issue #207, broken on Flutter 3.32+), switch to git dependency with PR #210 fix:
   ```yaml
   xterm:
     git:
       url: https://github.com/mqtik/xterm.dart.git
       ref: fix-flutter-3.32
   ```
   (Fork xterm.dart, cherry-pick PR #210, push as `fix-flutter-3.32` branch)
2. Add `flutter_pty: ^0.4.2` to dependencies (only for non-web platforms — add platform conditional if needed)
3. Run `flutter pub get`
4. Verify build succeeds on macOS: `flutter build macos`
5. Test keyboard input specifically — type characters and verify they appear in terminal

**Backup plan**: If xterm.dart doesn't work with Flutter 3.35.6 even with PR #210, use xterm.js via flutter_inappwebview as fallback (see architecture.md notes)

**Output**: Updated `app/pubspec.yaml` with new dependencies, clean build

**Acceptance criteria**:
- [ ] `flutter pub get` succeeds
- [ ] `flutter build macos` succeeds (or `flutter run -d macos` launches)
- [ ] No dependency conflicts
- [ ] Terminal renders basic output (echo "hello")

---

### WP-02: Project Data Model

**Phase**: 1 | **Batch**: 1 | **Dependencies**: none

**Scope**: Create all data models with JSON serialization: Project (with icon, isCollapsed, viewMode), TerminalSession (with isPinned, order), SessionSource (local, remote, config), LiveTerminal (with lastExitCode, hasUnreadOutput), ClosedTab, ViewMode enum.

**Input files**: none (new files)

**Actions**:
1. Create `app/lib/model/project.dart` with Project class (id, name, colorValue, icon, isCollapsed, viewMode, sessions, defaultWorkingDir, createdAt)
2. Create `app/lib/model/terminal_session.dart` with TerminalSession class (id, name, workingDir, source, isPinned, order, createdAt)
3. Create `app/lib/model/terminal_session_source.dart` with SessionSource sealed class (local, remote, config)
4. Create `app/lib/model/live_terminal.dart` with LiveTerminal class (sessionId, terminal, pty, webSocket, mode, status, lastExitCode, hasUnreadOutput)
5. Create `app/lib/model/closed_tab.dart` with ClosedTab class (session, projectId, closedAt)
6. Add dart_mappable annotations for JSON serialization on persisted models
7. Run code generation if needed

**Output files**:
- `app/lib/model/project.dart`
- `app/lib/model/terminal_session.dart`
- `app/lib/model/terminal_session_source.dart`
- `app/lib/model/live_terminal.dart`
- `app/lib/model/closed_tab.dart`

**Reference**: See [data-model.md](data-model.md) for exact field specs

**Acceptance criteria**:
- [ ] Models serialize to/from JSON correctly
- [ ] Project contains list of TerminalSession with all Chrome-style fields
- [ ] SessionSource supports local, remote, and config variants
- [ ] ClosedTab model works for restore-recently-closed feature
- [ ] LiveTerminal includes lastExitCode and hasUnreadOutput fields

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

**Phase**: 1 | **Batch**: 2 | **Dependencies**: WP-01, WP-02

**Scope**: Refena provider managing live Terminal and Pty instances.

**Input files**:
- `app/pubspec.yaml` (xterm + flutter_pty from WP-01)
- `app/lib/model/project.dart` (TerminalSession model from WP-02)

**Actions**:
1. Create `app/lib/provider/terminal_provider.dart`
2. Define `PtyBackend` abstract interface (spawn, write, resize, kill) so the backend can be swapped from flutter_pty (Phase 1) to daemon client (Phase 2) without changing the provider
3. Create `app/lib/provider/pty_backend_local.dart` — flutter_pty implementation of PtyBackend
4. Implement: SpawnTerminal (creates Terminal + PtyBackend, wires I/O), KillTerminal, ResizeTerminal, WriteToTerminal
5. Map: session ID → LiveTerminal (Terminal + PtyBackend + status)
6. Handle PTY lifecycle: detect process exit, update status
7. Platform-aware shell detection (zsh on macOS, bash on Linux, powershell on Windows)
8. Parse OSC 7 escape sequences from PTY output to track `currentWorkingDir` per session

**Output files**:
- `app/lib/provider/terminal_provider.dart`
- `app/lib/provider/pty_backend.dart` (abstract interface)
- `app/lib/provider/pty_backend_local.dart` (flutter_pty implementation)
- `app/lib/model/live_terminal.dart`
- `app/lib/util/osc7_parser.dart`

**Reference**: See [data-model.md](data-model.md) for LiveTerminal spec

**Acceptance criteria**:
- [ ] Can spawn a shell process and get output
- [ ] Terminal.write() renders in TerminalView
- [ ] Pty.write() sends keyboard input to shell
- [ ] Process exit detected and status updated
- [ ] Resize works
- [ ] Multiple terminals can run simultaneously
- [ ] PtyBackend interface allows swapping implementation without provider changes
- [ ] OSC 7 parsing updates currentWorkingDir on LiveTerminal

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

### WP-06: Device Sidebar Widget

**Phase**: 1 | **Batch**: 3 | **Dependencies**: WP-03

**Scope**: Create a narrow sidebar showing devices only (no projects — those are tab groups in the tab bar). Inspired by Arc's clean, minimal sidebar.

**Input files**:
- `app/lib/widget/list_tile/device_list_tile.dart` (existing, reuse)
- `app/lib/provider/network/nearby_devices_provider.dart` (existing, reuse)

**Actions**:
1. Create `app/lib/widget/sidebar/device_sidebar.dart`
2. Device section: paired + nearby devices (from nearbyDevicesProvider)
3. Each device expandable to show its remote terminal sessions
4. Tap a remote terminal → opens as a tab in the tab bar
5. Device states: ● online, ○ offline, ◐ connecting
6. [+ Pair] button at bottom opens pairing flow
7. ⚙ Config button opens Config as a tab
8. Collapsible sidebar (~140px expanded, ~40px icon-only)

**Output files**:
- `app/lib/widget/sidebar/device_sidebar.dart`

**Reference**: See [ui-structure.md](ui-structure.md) for wireframe

**Acceptance criteria**:
- [ ] Paired and nearby devices listed with status indicators
- [ ] Devices expandable to show remote terminal sessions
- [ ] Config button opens Config as a tab
- [ ] Pair button present
- [ ] Sidebar collapses on narrow screens / tablet

---

### WP-07: Chrome-Style Tab Bar Widget

**Phase**: 1 | **Batch**: 3 | **Dependencies**: WP-03

**Scope**: Chrome-style tab bar with tab groups (projects), pinned tabs, drag-and-drop, and context menus. This is the primary navigation — no project sidebar.

**Design influences**: Chrome (tab groups, pins, drag), Arc (icon+color per group), Warp (restore closed tabs, error indicators).

**Input files**:
- `app/lib/provider/project_provider.dart` (from WP-03)

**Actions**:
1. Create `app/lib/widget/chrome_tab_bar.dart`
2. Tab groups = projects (colored label, collapsible, named)
3. Pinned tabs = compact icons at far left, persist across groups
4. Drag tabs to reorder within group
5. Drag tabs between groups
6. Close button (✕) on hover, middle-click to close
7. [+] button creates new tab in active group
8. Collapse group = hides tabs, shows only colored label
9. Double-click tab to rename (Warp-style)
10. Right-click tab → context menu: rename, pin/unpin, move to group, close, close others, close to right
11. Right-click group label → rename group, change color, ungroup, close group
12. View mode toggle (list/grid/carousel) at right end
13. Tab indicators: error dot (red), activity pulse (background tab output)
14. Restore recently closed tab (Ctrl+Shift+T, stack of last 10)

**Output files**:
- `app/lib/widget/chrome_tab_bar.dart`
- `app/lib/widget/tab_group.dart`

**Reference**: See [ui-structure.md](ui-structure.md) for wireframe and design influences

**Acceptance criteria**:
- [ ] Tab groups display with project color + name
- [ ] Pinned tabs stay at left, compact
- [ ] Drag tabs between groups works
- [ ] Collapse/expand groups works
- [ ] Close button removes session
- [ ] Context menus work (tab + group label)
- [ ] Double-click to rename
- [ ] [+] creates new terminal in active group
- [ ] View mode toggle buttons present
- [ ] Tab error/activity indicators visible
- [ ] Ctrl+Shift+T restores last closed tab
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
7. Create `app/lib/util/url_detector.dart` — regex-based URL detection over terminal buffer text
8. URL interaction: Cmd+click (desktop) or long-press (mobile) on detected URL opens menu with "Open in browser" / "Open in web preview tab" options
9. URL highlight: detected URLs get underline styling on hover (desktop) or when long-press target (mobile)

**Output files**:
- `app/lib/pages/tabs/terminal_tab.dart`
- `app/lib/util/url_detector.dart`

**Acceptance criteria**:
- [ ] Terminal renders shell output with ANSI colors
- [ ] Keyboard input works
- [ ] vim/nvim works inside terminal
- [ ] Resize re-flows content correctly
- [ ] Copy/paste works
- [ ] Multiple terminal tabs can exist simultaneously
- [ ] URLs in terminal output are detected and highlighted on hover/long-press
- [ ] Cmd+click (desktop) or long-press (mobile) on URL shows action menu
- [ ] "Open in browser" launches system browser
- [ ] "Open in web preview" opens a web preview tab (localhost URLs only)

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

**Scope**: Replace LocalSend's 3-tab NavigationRail with Chrome-style tab bar + narrow device sidebar layout.

**Input files**:
- `app/lib/pages/home_page.dart` (existing, replace)
- `app/lib/pages/home_page_controller.dart` (existing, replace)
- `app/lib/main.dart` (existing, modify)

**Actions**:
1. Create `app/lib/pages/workspace_page.dart` — new main page
2. Desktop: Row with DeviceSidebar (~140px) + Expanded(Column(ChromeTabBar + TerminalContent))
3. Mobile: Column(ChromeTabBar + PageView + BottomNavigationBar(Terminals/Devices/Config))
4. Config opens as a tab (not a separate page) — like chrome://settings
5. Update main.dart to use WorkspacePage instead of HomePage
6. Keep existing send/receive accessible via Config tab

**Output files**:
- `app/lib/pages/workspace_page.dart`
- `app/lib/pages/config_page.dart` (Config as a tab)
- Modified `app/lib/pages/home_page_controller.dart`
- Modified `app/lib/main.dart`

**Reference**: See [ui-structure.md](ui-structure.md) for layout wireframes

**Acceptance criteria**:
- [ ] Desktop shows Chrome-style tab bar + device sidebar + terminal content
- [ ] Mobile shows compact tab bar + bottom nav (Terminals/Devices/Config)
- [ ] Config opens as a tab, not a separate screen
- [ ] File transfer accessible via Config tab
- [ ] Responsive transitions at breakpoints (500, 700, 900px)

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

### WP-12A: SimpleServer Routing Upgrade

**Phase**: 2 | **Batch**: 4 | **Dependencies**: WP-11

**Scope**: Upgrade the Dart HTTP server routing to support parameterized routes and WebSocket upgrades — prerequisites for terminal streaming.

**Input files**:
- `app/lib/util/simple_server.dart` (existing)
- `app/lib/provider/network/server/server_provider.dart` (existing)

**Actions**:
1. Extend SimpleServer to support parameterized routes (e.g., `/sessions/:id/attach`)
2. Add WebSocket upgrade handling (detect `Upgrade: websocket` header, use `dart:io WebSocket.fromUpgradedSocket()`)
3. Ensure existing file transfer routes still work unchanged
4. Add route pattern matching with parameter extraction

**Options**:
- Option A: Extend SimpleServer with regex-based route matching + WebSocket detection
- Option B: Replace SimpleServer with `shelf` + `shelf_web_socket` packages
- Option C: Handle WebSocket upgrade inside individual route handlers using raw HttpRequest

**Output files**:
- Modified `app/lib/util/simple_server.dart` (or replacement)

**Acceptance criteria**:
- [ ] Parameterized routes work: GET /api/xclouseau/v1/sessions/:id/attach extracts `:id`
- [ ] WebSocket upgrade works: connection upgrades successfully
- [ ] Existing file transfer routes unaffected
- [ ] All existing tests pass

---

### WP-12: Terminal Streaming Server (Host Side)

**Phase**: 2 | **Batch**: 5 | **Dependencies**: WP-04, WP-10, WP-12A

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

**Phase**: 2 | **Batch**: 6 | **Dependencies**: WP-12

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

**Phase**: 2 | **Batch**: 6 | **Dependencies**: WP-12, WP-13

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

**Phase**: 2 | **Batch**: 6 | **Dependencies**: WP-08, WP-13

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

**Phase**: 2 | **Batch**: 6 | **Dependencies**: WP-15

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

**Phase**: 3 | **Batch**: 7 | **Dependencies**: WP-15

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

**Phase**: 3 | **Batch**: 7 | **Dependencies**: WP-11, WP-19

**Scope**: When a file is received from another device, perform context-aware paste: AI CLI mode copies to clipboard + simulates Cmd+V; normal terminal copies file to pwd and types filename.

**Input files**:
- `app/lib/provider/network/server/controller/receive_controller.dart` (existing)
- `app/lib/provider/terminal_provider.dart` (from WP-04)
- `app/lib/util/ai_cli_detector.dart` (from WP-19)

**Actions**:
1. Create `app/lib/provider/file_terminal_bridge.dart`
2. Listen for file receive events from receive_controller
3. Terminal-targeted files saved to platform cache dir:
   - macOS: `~/Library/Caches/xClouseau/received/`
   - Linux: `~/.cache/xclouseau/received/`
   - Windows: `%LOCALAPPDATA%\xClouseau\cache\received\`
4. When file received: show notification with "Paste to terminal" and "Save to Downloads"
5. Context-aware paste logic:
   - AI CLI detected → copy image to clipboard → simulate Cmd+V/Ctrl+V key event
   - Normal terminal → copy file to terminal's `currentWorkingDir` (from OSC 7) → type filename into PTY
6. Auto-cleanup: delete cached files older than 7 days (configurable in settings)
7. Regular file transfers still use LocalSend's `destination` setting (~/Downloads)

**Output files**:
- `app/lib/provider/file_terminal_bridge.dart`
- Modified `app/lib/provider/network/server/controller/receive_controller.dart` (add hook)

**Reference**: See [ai-integration.md](ai-integration.md) for pipeline diagram

**Acceptance criteria**:
- [ ] File received → notification appears with context-aware options
- [ ] AI CLI active → image pasted via clipboard Cmd+V
- [ ] Normal terminal → file copied to pwd, filename typed
- [ ] Terminal-targeted files stored in platform cache dir (not ~/Downloads)
- [ ] Auto-cleanup of cached files works
- [ ] Regular file transfers still use LocalSend's destination setting

---

### WP-19: AI CLI Detection

**Phase**: 3 | **Batch**: 7 | **Dependencies**: WP-08

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

**Phase**: 3 | **Batch**: 7 | **Dependencies**: WP-08, WP-07

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

**Phase**: 3 | **Batch**: 7 | **Dependencies**: WP-11

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

**Key challenge**: Shortcuts like Ctrl+T, Ctrl+W, Ctrl+N conflict with terminal programs (vim, tmux, etc.). The PTY receives ALL keyboard input when focused. App-level shortcuts must intercept BEFORE the PTY gets the keystrokes.

**Approach**: Use a modifier key (e.g., Ctrl+Shift) for app shortcuts to avoid PTY conflicts. Alternatively, use a "leader key" pattern (press Escape or Ctrl+A first, then the shortcut key — like tmux).

**Acceptance criteria**:
- [ ] All shortcuts work on desktop
- [ ] Shortcuts don't conflict with terminal apps (vim, tmux, etc.)
- [ ] PTY-focused shortcuts use a distinct modifier (Ctrl+Shift or leader key)
- [ ] Shortcuts documented in settings

---

### WP-22: Rebranding — Android

**Phase**: 4 | **Batch**: 5 | **Dependencies**: WP-11

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

**Phase**: 4 | **Batch**: 5 | **Dependencies**: WP-11

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

**Phase**: 4 | **Batch**: 5 | **Dependencies**: WP-11

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

**Phase**: 4 | **Batch**: 5 | **Dependencies**: WP-11

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

**Phase**: 4 | **Batch**: 5 | **Dependencies**: WP-11

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

**Phase**: Polish | **Batch**: 8 | **Dependencies**: WP-08

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

**Phase**: Polish | **Batch**: 8 | **Dependencies**: WP-08

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

**Phase**: Polish | **Batch**: 8 | **Dependencies**: all

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

**Phase**: Polish | **Batch**: 8 | **Dependencies**: none

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

---

### WP-31: Rust PTY Daemon

**Phase**: 2 | **Batch**: 5 | **Dependencies**: WP-04

**Scope**: Separate Rust binary that manages PTY processes independently of the Flutter app. Desktop only (macOS, Linux, Windows). Enables true tmux-style persistence — terminals survive app quit, crash, and reboot.

**Input files**:
- `core/Cargo.toml` (existing Rust core)
- `app/lib/provider/pty_backend.dart` (abstract interface from WP-04)

**Actions**:
1. Add `portable-pty` crate to `core/Cargo.toml`
2. Add daemon binary target to `core/Cargo.toml`
3. Create `core/src/pty/mod.rs` — PTY management module
4. Create `core/src/pty/daemon.rs` — daemon main loop, session management, accept client connections
5. Create `core/src/pty/protocol.rs` — IPC message types and serialization (length-prefixed binary)
6. Create `core/src/bin/xclouseau-daemon.rs` — daemon binary entry point
7. IPC protocol over Unix socket (macOS/Linux) or named pipe (Windows):
   - Client → Daemon: SPAWN, INPUT, RESIZE, KILL, LIST, ATTACH, DETACH
   - Daemon → Client: OUTPUT, EXITED, SESSIONS
8. Create `app/lib/util/daemon_client.dart` — Dart client for daemon IPC
9. Create `app/lib/provider/pty_backend_daemon.dart` — daemon implementation of PtyBackend interface
10. Swap TerminalProvider to use daemon backend on desktop, keep local backend as fallback
11. Daemon lifecycle: lazy start on first terminal, auto-exit after 30s with no terminals and no clients

**Output files**:
- `core/src/pty/mod.rs`
- `core/src/pty/daemon.rs`
- `core/src/pty/protocol.rs`
- `core/src/bin/xclouseau-daemon.rs`
- Modified `core/Cargo.toml`
- `app/lib/util/daemon_client.dart`
- `app/lib/provider/pty_backend_daemon.dart`

**Platform notes**:
- macOS/Linux: Unix domain socket at `~/.xclouseau/daemon.sock`
- Windows: Named pipe at `\\.\pipe\xclouseau`
- Mobile/Web: N/A (viewer only, no local terminals)

**Acceptance criteria**:
- [ ] Daemon binary compiles and runs on macOS, Linux, Windows
- [ ] Flutter app spawns terminals via daemon
- [ ] Quit Flutter app → reopen → terminals still running with scrollback
- [ ] Kill Flutter process → reopen → terminals reconnect
- [ ] Daemon auto-exits after all terminals closed + 30s grace period
- [ ] Daemon auto-starts when Flutter app needs a terminal
- [ ] Fallback to flutter_pty if daemon unavailable

---

### WP-32: Terminal File Drop + Pickers

**Phase**: 3 | **Batch**: 7 | **Dependencies**: WP-08, WP-18, WP-19

**Scope**: Reuse LocalSend's file picker types (file, media, text, clipboard, folder) for terminal context. Add a toolbar near the terminal that picks files/media and pastes paths or content into the PTY.

**Input files**:
- `app/lib/util/native/file_picker.dart` (existing — FilePickerOption enum + PickFileAction)
- `app/lib/pages/tabs/terminal_tab.dart` (from WP-08)
- `app/lib/provider/terminal_provider.dart` (from WP-04)
- `app/lib/util/ai_cli_detector.dart` (from WP-19)

**Actions**:
1. Create `app/lib/widget/terminal_file_toolbar.dart` — row of picker buttons near terminal
2. Reuse FilePickerOption for terminal context with different targets:
   - file → save to received dir, paste path into PTY
   - media → save to received dir, paste path into PTY (or clipboard Cmd+V if AI CLI)
   - text → type text directly into PTY
   - clipboard → paste clipboard text into PTY, or save clipboard image and paste path
   - folder → paste folder path into PTY
3. Toolbar always visible on desktop terminals (collapsible)
4. On mobile: accessible via action button
5. Context-aware: if AI CLI detected, media picker copies to clipboard instead of pasting path

**Output files**:
- `app/lib/widget/terminal_file_toolbar.dart`
- Modified `app/lib/pages/tabs/terminal_tab.dart` (integrate toolbar)

**Reference**: See [ai-integration.md](ai-integration.md) for context-aware paste behavior

**Acceptance criteria**:
- [ ] Toolbar with File/Media/Paste/Text buttons visible near terminal
- [ ] File picker → file path pasted into PTY
- [ ] Media picker → path pasted (normal) or clipboard Cmd+V (AI CLI)
- [ ] Text picker → text typed into PTY
- [ ] Clipboard paste works for text and images
- [ ] Folder path pasted correctly
- [ ] Toolbar collapsible on desktop

---

### WP-33: Web Preview — Reverse Proxy + WebView Tab

**Phase**: 3 | **Batch**: 7 | **Dependencies**: WP-12A, WP-12

**Scope**: Any device can view another device's localhost web servers (dev servers, dashboards, etc.) through a reverse proxy. Adds a WebView tab type, localhost URL detection in terminal output, and a proxy route on the host's server. Works in all directions — phone previews Mac's localhost, Mac previews Windows' localhost, etc.

**Input files**:
- `app/lib/provider/network/server/server_provider.dart` (existing, add proxy routes)
- `app/lib/util/simple_server.dart` (upgraded in WP-12A)
- `app/lib/pages/tabs/terminal_tab.dart` (from WP-08, for URL detection)

**Actions**:
1. Create `app/lib/provider/network/server/controller/web_preview_controller.dart`
   - Route: `GET /api/xclouseau/v1/web/:port/*path` → reverse proxy to `localhost:<port>/<path>`
   - WebSocket proxy: handle `Upgrade: websocket` on proxied paths for HMR/hot reload
   - Route: `GET /api/xclouseau/v1/ports` → list localhost ports currently listening
2. Create `app/lib/pages/tabs/web_preview_tab.dart`
   - WebView widget (webview_flutter or flutter_inappwebview) loading the proxied URL
   - URL bar showing the proxied address
   - Refresh button, back/forward navigation
   - Tab shows favicon or site title
3. Create `app/lib/util/localhost_detector.dart`
   - Parse terminal output for localhost URL patterns: `localhost:\d+`, `127.0.0.1:\d+`, `0.0.0.0:\d+`
   - Detect framework-specific output: "ready in" (Vite), "started server on" (Next.js), "Listening on" (Express)
   - When detected: show prompt with "Open Preview" and "Open on Other Device" options
4. Add `SessionSource.webPreview` variant to data model (deviceFingerprint, port, basePath)
5. Register proxy routes in server_provider.dart
6. Port scanner: periodically check common dev ports (3000-3999, 4000-4999, 5000-5999, 8000-8999) for listening TCP sockets
7. Include detected ports in `GET /api/xclouseau/v1/sessions` response

**Output files**:
- `app/lib/provider/network/server/controller/web_preview_controller.dart`
- `app/lib/pages/tabs/web_preview_tab.dart`
- `app/lib/util/localhost_detector.dart`
- Modified `app/lib/provider/network/server/server_provider.dart`
- Modified `app/lib/model/terminal_session_source.dart` (add webPreview variant)

**Reference**: See [terminal-streaming.md](terminal-streaming.md) for proxy route spec

**Security notes**:
- Only localhost ports are proxied — never external addresses
- Host can disable web preview in settings (allowWebPreview toggle)
- All proxy traffic goes through the existing mTLS server (:53317)
- PIN protection applies if configured

**Acceptance criteria**:
- [ ] Phone can open Mac's localhost:3000 in a WebView tab
- [ ] Mac can open Windows' localhost:8080 in a WebView tab
- [ ] WebSocket proxied correctly (HMR/hot reload works in preview)
- [ ] Localhost URL detected in terminal output → prompt shown
- [ ] "Open Preview" opens WebView on current device
- [ ] "Open on Other Device" shows device picker
- [ ] Port list available via GET /ports endpoint
- [ ] Proxy respects allowWebPreview setting
- [ ] Self-signed cert handled in WebView (no cert errors)
