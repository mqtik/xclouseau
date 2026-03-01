# LocalSend Reuse Map

## Summary

xClouseau is a fork of LocalSend. We keep the entire networking stack untouched and replace the UI shell. This document maps every LocalSend module to its xClouseau fate.

```
┌─────────────────────────────────────────────────────────────────┐
│                    What We Do With LocalSend                    │
├──────────────────┬──────────────────────────────────────────────┤
│   KEEP AS-IS     │ Networking, crypto, discovery, file transfer │
│   (don't touch)  │ Rust core, isolates, multicast, HTTP server  │
│                  │ WebRTC, certificate management, DTOs          │
├──────────────────┼──────────────────────────────────────────────┤
│   EXTEND         │ HTTP server (add terminal routes)            │
│   (add to)       │ Device model (add terminal session info)     │
│                  │ Settings (add terminal preferences)          │
│                  │ Server provider (register new routes)        │
├──────────────────┼──────────────────────────────────────────────┤
│   REPLACE        │ Home page (3-tab → sidebar + workspace)     │
│   (rewrite)      │ Navigation (NavigationRail → project sidebar)│
│                  │ Home tab enum (receive/send/settings → new)  │
├──────────────────┼──────────────────────────────────────────────┤
│   RELOCATE       │ Send/Receive tabs → inside "Devices" section │
│   (move)         │ Progress page → reuse for file transfers     │
└──────────────────┴──────────────────────────────────────────────┘
```

## File-by-File Map

### KEEP UNCHANGED — Networking & Discovery

These files are the backbone. Do not modify unless fixing bugs.

```
common/lib/
├── api_route_builder.dart          KEEP  API route definitions
├── constants.dart                  KEEP  API constants
├── isolate.dart                    KEEP  Isolate management
├── model/
│   ├── device.dart                 KEEP  Device model (may extend later)
│   ├── device_info_result.dart     KEEP
│   ├── file_type.dart              KEEP
│   ├── session_status.dart         KEEP
│   ├── stored_security_context.dart KEEP
│   └── dto/
│       ├── info_dto.dart           KEEP
│       ├── register_dto.dart       KEEP
│       ├── file_dto.dart           KEEP
│       ├── multicast_dto.dart      KEEP
│       ├── prepare_upload_*.dart   KEEP
│       └── *.mapper.dart           KEEP  (generated)
└── src/
    ├── isolate/                    KEEP  (all isolate management)
    ├── task/
    │   └── discovery/
    │       ├── multicast_discovery.dart    KEEP
    │       ├── http_scan_discovery.dart    KEEP
    │       └── http_target_discovery.dart  KEEP
    └── util/                       KEEP
```

### KEEP UNCHANGED — Rust Core

**Important**: The Rust HTTP server (`core/src/http/server/mod.rs`) exists but is NOT used by the Flutter app in production. The actual HTTP server is a Dart `HttpServer` in `app/lib/provider/network/server/server_provider.dart` (port 53317). Rust core is used only for crypto, HTTP client, and WebRTC.

```
core/src/
├── crypto/
│   ├── cert.rs                     KEEP  Certificate generation/validation
│   ├── hash.rs                     KEEP  SHA-256 hashing
│   ├── nonce.rs                    KEEP  Nonce generation/validation
│   └── token.rs                    KEEP  Token signing (ed25519)
├── http/
│   ├── client/mod.rs               KEEP  HTTP client with mTLS
│   ├── server/
│   │   ├── mod.rs                  KEEP  (unused by app — standalone test harness)
│   │   ├── client_cert_verifier.rs KEEP  mTLS verification
│   │   ├── controller/
│   │   │   ├── v2.rs               KEEP  (unused by app)
│   │   │   ├── v3.rs               KEEP  (unused by app)
│   │   │   └── web.rs              KEEP  (unused by app)
│   │   └── state.rs                KEEP  (unused by app)
│   └── dto.rs                      KEEP  Data transfer objects
├── webrtc/
│   ├── signaling.rs                KEEP  WebRTC signaling
│   └── webrtc.rs                   KEEP  WebRTC connections
└── model/                          KEEP  Core models
```

### KEEP UNCHANGED — App Providers (Networking)

```
app/lib/provider/
├── network/
│   ├── nearby_devices_provider.dart      KEEP  Device discovery state
│   ├── send_provider.dart                KEEP  File send orchestration
│   ├── scan_facade.dart                  KEEP  Discovery API
│   ├── server/
│   │   ├── server_provider.dart          EXTEND (add terminal routes)
│   │   ├── receive_controller.dart       KEEP  File receive endpoints
│   │   ├── send_controller.dart          KEEP  File send endpoints
│   │   └── server_utils.dart             KEEP
│   └── webrtc/
│       ├── signaling_provider.dart       KEEP
│       └── webrtc_receiver.dart          KEEP
├── persistence_provider.dart             EXTEND (add terminal settings keys)
├── settings_provider.dart                EXTEND (add terminal settings)
├── device_info_provider.dart             KEEP
├── local_ip_provider.dart                KEEP
└── selection/
    ├── selected_sending_files_provider.dart    KEEP
    └── selected_receiving_files_provider.dart  KEEP
```

### KEEP UNCHANGED — App Utilities

```
app/lib/util/
├── rhttp.dart                      KEEP  HTTP client wrapper
├── security_helper.dart            KEEP  Certificate generation
├── ip_helper.dart                  KEEP
├── file_path_helper.dart           KEEP
├── file_size_helper.dart           KEEP
├── native/
│   ├── platform_check.dart         KEEP
│   ├── autostart_helper.dart       KEEP
│   ├── device_info_helper.dart     KEEP
│   ├── tray_helper.dart            KEEP
│   └── ...                         KEEP
└── shared_preferences/             KEEP
```

### REPLACE — UI Shell

```
app/lib/pages/
├── home_page.dart                  REPLACE  3-tab layout → sidebar + workspace
├── home_page_controller.dart       REPLACE  HomeTab enum changes
├── tabs/
│   ├── receive_tab.dart            RELOCATE → "Devices" section
│   ├── receive_tab_vm.dart         KEEP     (still used inside Devices)
│   ├── send_tab.dart               RELOCATE → "Devices" section
│   ├── send_tab_vm.dart            KEEP     (still used inside Devices)
│   └── settings_tab.dart           EXTEND   (add terminal settings section)
```

### KEEP UNCHANGED — Existing Widgets (Reusable)

```
app/lib/widget/
├── responsive_builder.dart         REUSE  for desktop/mobile layouts
├── responsive_list_view.dart       REUSE  for scrollable content
├── responsive_wrap_view.dart       REUSE  for grid layouts
├── column_list_view.dart           REUSE  for hybrid layouts
├── big_button.dart                 REUSE  for action buttons
├── custom_icon_button.dart         REUSE
├── list_tile/
│   ├── custom_list_tile.dart       REUSE  for sidebar items
│   └── device_list_tile.dart       REUSE  for device list
├── dialogs/                        REUSE  (all dialogs)
├── animations/                     REUSE  (all animations)
├── watcher/
│   ├── life_cycle_watcher.dart     KEEP
│   ├── window_watcher.dart         KEEP
│   ├── shortcut_watcher.dart       EXTEND (add terminal shortcuts)
│   └── tray_watcher.dart           KEEP
└── file_thumbnail.dart             REUSE
```

### KEEP UNCHANGED — Configuration & Theme

```
app/lib/config/
├── init.dart                       EXTEND  (add terminal init in postInit)
├── theme.dart                      KEEP    (Material 3 theme system)
├── refena.dart                     KEEP    (state management config)
└── init_error.dart                 KEEP
```

### KEEP UNCHANGED — Platform Code

```
app/android/                        KEEP  (rebrand names in Phase 4)
app/ios/                            KEEP  (rebrand names in Phase 4)
app/macos/                          KEEP  (rebrand names in Phase 4)
app/windows/                        KEEP  (rebrand names in Phase 4)
app/linux/                          KEEP  (rebrand names in Phase 4)
app/web/                            KEEP  (rebrand names in Phase 4)
```

## Dependency Diagram

```
                      xClouseau NEW CODE
                    ┌─────────────────────┐
                    │  WorkspacePage       │
                    │  DeviceSidebar       │
                    │  ChromeTabBar        │
                    │  TerminalTab         │
                    └──────────┬──────────┘
                               │ depends on
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
    ┌─────────────────┐ ┌──────────┐  ┌──────────────────┐
    │ NEW PROVIDERS   │ │ xterm.dart│  │ LOCALSEND        │
    │                 │ │ flutter_pty│  │ PROVIDERS        │
    │ projectProvider │ └──────────┘  │                  │
    │ terminalProvider│               │ nearbyDevices    │
    │ remoteTerminal  │               │ serverProvider   │
    │ Provider        │               │ sendProvider     │
    └────────┬────────┘               │ settingsProvider │
             │                        │ persistenceProvider│
             │                        └────────┬─────────┘
             │                                  │
             └──────────────┬───────────────────┘
                            ▼
              ┌──────────────────────────┐
              │   LOCALSEND NETWORKING   │
              │                          │
              │  common/ (isolates, DTOs)│
              │  core/ (Rust: crypto,    │
              │         HTTP, WebRTC)    │
              └──────────────────────────┘

The new code sits ON TOP of LocalSend's stack.
It does NOT replace any networking logic.
```

## What Gets Reused for Terminal Features

### File Pickers → Terminal Context

All 6 `FilePickerOption` types from `app/lib/util/native/file_picker.dart` are reused for terminal context. Instead of sending to a device, they paste into the active terminal.

```
FilePickerOption.file       → paste file path into PTY
FilePickerOption.folder     → paste folder path into PTY
FilePickerOption.media      → paste path (normal) or clipboard Cmd+V (AI CLI)
FilePickerOption.text       → type text directly into PTY
FilePickerOption.clipboard  → paste clipboard text into PTY
FilePickerOption.app        → N/A (Android only, not terminal-relevant)
```

See WP-32 in agent-work-packages.md for implementation details.

### Tray + Window Infrastructure → Terminal Persistence

The existing tray and window management gives us free process persistence (Layer 1):

```
window_watcher.dart    → checks minimizeToTray, calls hideToTray() on close
tray_helper.dart       → hideToTray() / showFromTray() implementation
autostart_helper.dart  → auto-start with --hidden flag (cross-platform)
```

- Window close → app hides to tray → Flutter process stays alive → PTY processes survive
- Scrollback intact in memory (xterm.dart Terminal objects stay alive)
- Layer 1 persistence requires zero new code — just enable `minimizeToTray: true` by default

See data-model.md "Durable Sessions" section for the full 3-layer persistence architecture.

### Receive Flow → "Paste to Terminal" Option

When a file is received from another device, the receive flow is extended with a terminal option:

```
receive_controller.dart receives file
        │
        ▼
Show notification with context-aware options:
  [Save to Downloads]          ← existing LocalSend behavior
  [Paste to terminal]          ← NEW: pastes path into active terminal
  [Open]                       ← existing
```

See WP-18 in agent-work-packages.md for context-aware paste behavior.

## What Gets Extended (Details)

### 1. `server_provider.dart` — Add Terminal Routes

```
Current routes (LocalSend):
  POST /api/localsend/v2/register
  POST /api/localsend/v2/prepare-upload
  POST /api/localsend/v2/upload
  POST /api/localsend/v2/cancel
  POST /api/localsend/v3/nonce
  POST /api/localsend/v3/register

New routes (xClouseau):
  GET  /api/xclouseau/v1/sessions
  GET  /api/xclouseau/v1/sessions/:id/attach  (WebSocket)
  POST /api/xclouseau/v1/sessions/:id/input
  POST /api/xclouseau/v1/sessions/:id/resize
  GET  /api/xclouseau/v1/ports                (list listening localhost ports)
  GET  /api/xclouseau/v1/web/:port/*path      (reverse proxy to localhost)
  GET  /api/xclouseau/v1/web/:port/_ws/*path  (WebSocket proxy for HMR)
```

Both sets of routes coexist on the same Dart HTTP server (port 53317).

**Prerequisite**: The current routing in `simple_server.dart` uses exact path matching — no parameterized routes (`:id`) and no WebSocket upgrade support. This must be upgraded first (see WP-12A in agent-work-packages.md).

### 2. `settings_provider.dart` — Add Terminal Settings

```
New settings:
  • defaultShell: String (e.g., "/bin/zsh", "powershell.exe")
  • terminalFontSize: double
  • terminalFontFamily: String
  • terminalTheme: String (dark, light, solarized, etc.)
  • allowRemoteTerminalAccess: bool
  • requirePinForTerminals: bool
  • defaultWorkingDirectory: String
```

### 3. `persistence_provider.dart` — Add Storage Keys

```
New keys:
  'xc_projects'              → JSON list of Project objects
  'xc_default_shell'         → String
  'xc_terminal_font_size'    → double
  'xc_terminal_theme'        → String
  'xc_allow_remote_terminal' → bool
  'xc_terminal_pin'          → String?
```

### 4. `shortcut_watcher.dart` — Add Terminal Shortcuts

```
New shortcuts:
  Ctrl+T        → new terminal tab
  Ctrl+W        → close terminal tab
  Ctrl+Tab      → next terminal tab
  Ctrl+Shift+Tab → previous terminal tab
  Ctrl+N        → new project
  Ctrl+1-9      → switch to tab N
```
