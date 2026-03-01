# Security Hardening Pass

## When

After all feature batches (1-8) are complete and manually tested. This is a dedicated pass before any public release.

## Current State (as of Batch 5)

### What's inherited from LocalSend
- TLS encryption (self-signed certs, optional HTTPS toggle)
- LAN-only discovery (UDP multicast)
- Network whitelist/blacklist (IP-level filtering)
- PIN + rate limiting for file transfer (3 attempts per IP)
- Device registration with fingerprint exchange

### What terminal streaming has now
- `terminalAllowRemoteAccess` toggle (checked on all routes, 403 if disabled)
- Nothing else — no PIN, no pairing requirement, no approval prompt

## Hardening Plan

### P1: Pairing-Based Access (must-fix)

Terminal access should require prior device pairing, not just LAN proximity.

1. **Pairing flow**: Devices exchange certificate fingerprints via PIN verification (one-time, in-person)
2. **Encrypted session token**: After pairing, derive a shared secret from the exchanged keys. Use this to generate a session token that proves pairing happened.
3. **Check on every terminal route**: Reject requests from devices that haven't completed pairing. Verify the session token / fingerprint against the known-devices list.
4. **Revocation**: Host can unpair a device at any time, immediately disconnecting all its terminal viewers.

LocalSend already has a favorites/known-devices system — extend this to be a pairing gate for terminal access.

### P2: Host Approval for Terminal Attach

1. **First attach notification**: When a paired device requests terminal access, show a system notification: "Device X wants to view your terminal. [Allow] [Deny] [Allow for session]"
2. **Per-session permission**: Host grants access per terminal session, not globally
3. **Remember choice**: Option to always allow a specific paired device (skip prompt)
4. **Active viewer list**: Host can see all connected viewers and disconnect any at will

### P3: Interactive Mode Control

1. **Host controls interactive flag**: Host sets `isInteractiveAllowed` per session. Viewers cannot self-promote to interactive.
2. **Default to view-only**: New viewer connections start as view-only. Host explicitly grants interactive access.
3. **Revoke interactive**: Host can downgrade a viewer to view-only at any time.

### P4: Viewer Identity + Audit

1. **Track viewer identity**: Store IP, device alias, fingerprint, connect time in `_ViewerConnection`
2. **GET /sessions/:id/viewers**: Endpoint for host to see who's connected
3. **Audit log**: Log all attach/detach/mode-change events with device info
4. **Notification on new viewer**: System notification when someone attaches

### P5: Rate Limiting + Input Validation

1. **Rate limit terminal routes**: Reuse `pinAttempts` pattern from file transfer
2. **Validate resize bounds**: Reject unreasonable cols/rows values (e.g., cols > 500, rows > 200)
3. **Input size limit**: Cap POST /input body size to prevent memory exhaustion
4. **WebSocket message size limit**: Cap binary frame size
5. **Max viewers per session**: Prevent viewer flooding (e.g., max 10)

### P6: Transport Security

1. **Require HTTPS for terminal routes**: Even if file transfer allows HTTP, terminal streaming should require TLS
2. **Mutual TLS**: Activate the mTLS prototype in server_provider.dart — require client certificates
3. **Certificate pinning**: After pairing, pin the remote device's certificate

## Files That Will Be Modified

| File | Changes |
|------|---------|
| `terminal_controller.dart` | PIN check, pairing verification, viewer identity, rate limiting, input validation |
| `server_provider.dart` | Expose terminal controller for viewer management API |
| `settings_state.dart` | `terminalRequireApproval` setting |
| `persistence_provider.dart` | Paired devices list for terminal access |
| `live_terminal.dart` | `isInteractiveAllowed` flag |
| `workspace_page.dart` | Viewer management UI (who's watching my terminals) |
| New: `terminal_access_provider.dart` | Manages pairing state, approval prompts, viewer permissions |

## Testing Checklist

- [ ] Unpaired device cannot list sessions (rejected before response)
- [ ] Paired device can list sessions after approval
- [ ] Host sees notification on first attach
- [ ] Host can disconnect a viewer
- [ ] Host can revoke interactive access
- [ ] View-only viewer cannot send keyboard input (server drops it)
- [ ] Rate limiting kicks in after N failed attempts
- [ ] Oversized resize/input requests rejected
- [ ] All terminal traffic encrypted (HTTPS)
- [ ] Unpairing a device disconnects all its viewers immediately
- [ ] Audit log captures all events
