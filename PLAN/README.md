# xClouseau

**A cross-platform terminal workspace manager with P2P device mesh.**

Forked from [LocalSend](https://github.com/localsend/localsend) — we inherit battle-tested P2P networking (mTLS, device discovery, file transfer, WebRTC) and extend it with terminal emulation, shared terminal sessions across devices, and workspace organization.

## The Problem

Developers juggle multiple terminals across multiple machines. You're running Claude Code on your Mac, but you want to see that session from your Windows PC without getting up. You want to send a screenshot from your phone directly into an AI conversation on your desktop. You want all your terminal workspaces organized by project, accessible from any device.

## The Solution

```
┌─────────────────────────────────────────────────────────────────────┐
│                       xClouseau Device Mesh                        │
│                                                                     │
│   ┌──────────┐         P2P (mTLS)         ┌──────────┐            │
│   │   Mac    │◄──────────────────────────►│ Windows  │            │
│   │          │  terminal streaming         │    PC    │            │
│   │ running  │  file transfer              │          │            │
│   │ claude   │  device discovery           │ viewing  │            │
│   │ code     │                             │ Mac's    │            │
│   └────┬─────┘                             │ terminal │            │
│        │                                   └────┬─────┘            │
│        │           P2P (mTLS)                   │                  │
│        │                                        │                  │
│        └──────────────┐    ┌────────────────────┘                  │
│                       ▼    ▼                                       │
│                   ┌──────────┐                                     │
│                   │  Phone   │                                     │
│                   │          │                                     │
│                   │ monitor  │                                     │
│                   │ both     │                                     │
│                   │ send     │                                     │
│                   │ images   │                                     │
│                   └──────────┘                                     │
│                                                                     │
│   Every device is both a server AND a client.                      │
│   No central server. No accounts. All data stays on your devices.  │
└─────────────────────────────────────────────────────────────────────┘
```

## Core Features

| Feature | Description | Inherited from LocalSend? |
|---------|-------------|--------------------------|
| Terminal emulator | Full PTY (bash, zsh, vim, nvim) via xterm.dart | New |
| Project workspaces | Sidebar + tabs to organize terminals by project | New |
| Remote terminal streaming | View/interact with terminals on other devices | New |
| Device mesh | Any device connects to any other device | Extended |
| File transfer | Send/receive files between any devices | Inherited |
| AI CLI integration | Run claude/codex/gemini, send images from phone | New |
| LAN discovery | Devices find each other automatically | Inherited |
| End-to-end encryption | mTLS with self-signed certificates | Inherited |
| Cross-platform | macOS, Windows, Linux, iOS, Android, Web | Inherited |

## Tech Stack

```
┌─────────────────────────────────────────┐
│           Flutter / Dart UI             │
│  xterm.dart (terminal) + Refena (state) │
├─────────────────────────────────────────┤
│         flutter_pty (PTY layer)         │
├─────────────────────────────────────────┤
│     Rust Core (via flutter_rust_bridge) │
│  crypto │ http server │ WebRTC          │
├─────────────────────────────────────────┤
│        Platform (macOS/Win/Linux/       │
│         iOS/Android/Web)                │
└─────────────────────────────────────────┘
```

## Documentation Index

| Document | Description |
|----------|-------------|
| [architecture.md](architecture.md) | Device mesh topology, layer diagram, data flows, platform matrix |
| [terminal-streaming.md](terminal-streaming.md) | Remote terminal protocol spec with sequence diagrams |
| [localsend-reuse.md](localsend-reuse.md) | What we keep/extend/replace from LocalSend |
| [ui-structure.md](ui-structure.md) | Wireframes, component trees, responsive design |
| [data-model.md](data-model.md) | Data models, state diagrams, provider graph |
| [phases.md](phases.md) | Implementation roadmap with dependency graph |
| [ai-integration.md](ai-integration.md) | AI CLI integration: 3-layer model + image pipeline |
| [agent-work-packages.md](agent-work-packages.md) | 20-30 parallelizable work packages for agents |
| [remote-access.md](remote-access.md) | Phase 5: off-LAN access via WebRTC, device pairing, zero servers |

## Quick Start for Contributors / Agents

1. Read [architecture.md](architecture.md) to understand the system
2. Read [localsend-reuse.md](localsend-reuse.md) to understand what already exists
3. Check [agent-work-packages.md](agent-work-packages.md) for your assigned work package
4. Each work package is self-contained with: scope, input files, output files, acceptance criteria
5. Follow existing patterns: Refena providers, ViewModelBuilder, ResponsiveBuilder
6. No comments in code unless explicitly needed — code should be self-documenting

## Repository Structure

```
clouseau-app/
├── PLAN/                  ← You are here (project documentation)
├── app/                   ← Flutter app (UI, state, platform code)
│   ├── lib/
│   │   ├── main.dart      ← App entry point
│   │   ├── config/        ← Initialization, theme
│   │   ├── pages/         ← Screens and tabs
│   │   ├── provider/      ← Refena state management
│   │   ├── model/         ← Data models
│   │   ├── widget/        ← Reusable UI components
│   │   └── util/          ← Utilities, platform helpers
│   ├── android/           ← Android platform code
│   ├── ios/               ← iOS platform code
│   ├── macos/             ← macOS platform code
│   ├── windows/           ← Windows platform code
│   ├── linux/             ← Linux platform code
│   └── web/               ← Web platform code
├── common/                ← Shared Dart code (networking, models, isolates)
├── core/                  ← Rust core (crypto, HTTP server, WebRTC)
├── cli/                   ← Command-line interface
├── server/                ← Standalone Rust signaling server
└── scripts/               ← Build and release scripts
```
