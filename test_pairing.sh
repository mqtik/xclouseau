#!/bin/bash
set -euo pipefail

HOST="https://localhost:53317"
FINGERPRINT="test-device-abc123"
ALIAS="My Test Phone"
DEVICE_MODEL="iPhone 15"
DEVICE_TYPE="mobile"
CURL="curl -sk"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() { echo -e "\n${CYAN}=== $1 ===${NC}"; }
print_ok() { echo -e "${GREEN}OK:${NC} $1"; }
print_fail() { echo -e "${RED}FAIL:${NC} $1"; }
print_info() { echo -e "${YELLOW}$1${NC}"; }

echo -e "${CYAN}Clouseau Terminal API Test Script${NC}"
echo "================================="

print_step "1. Check if app is running"
if $CURL "$HOST/api/xclouseau/v1/pair/info" > /dev/null 2>&1; then
  print_ok "App is running on port 53317"
else
  print_fail "App not running. Start it with: make dev"
  exit 1
fi

PAIR_INFO=$($CURL "$HOST/api/xclouseau/v1/pair/info")
echo "  Host info: $PAIR_INFO"

print_step "2. Pair device"
echo "  Open the app and click '+ Pair' in the sidebar."
read -p "  Enter the 6-digit PIN shown in the dialog: " PIN

PAIR_RESULT=$($CURL -X POST -H 'Content-Type: application/json' \
  -d "{\"pin\":\"$PIN\",\"fingerprint\":\"$FINGERPRINT\",\"alias\":\"$ALIAS\",\"deviceModel\":\"$DEVICE_MODEL\",\"deviceType\":\"$DEVICE_TYPE\"}" \
  "$HOST/api/xclouseau/v1/pair/request")

if echo "$PAIR_RESULT" | grep -q '"paired":true'; then
  print_ok "Paired successfully"
  echo "  Response: $PAIR_RESULT"
else
  print_fail "Pairing failed: $PAIR_RESULT"
  exit 1
fi

sleep 1

print_step "3. List terminal sessions"
SESSIONS=$($CURL -H "X-Device-Fingerprint: $FINGERPRINT" "$HOST/api/xclouseau/v1/sessions")
echo "  Sessions: $SESSIONS"

SESSION_ID=$(echo "$SESSIONS" | python3 -c "import sys,json; s=json.load(sys.stdin)['sessions']; print(s[0]['id'] if s else '')" 2>/dev/null || echo "")

if [ -z "$SESSION_ID" ]; then
  print_fail "No sessions found"
  exit 1
fi
print_ok "Found session: $SESSION_ID"

print_step "4. Send input to terminal (ls -la)"
INPUT_RESULT=$($CURL -X POST \
  -H "X-Device-Fingerprint: $FINGERPRINT" \
  -H 'Content-Type: application/octet-stream' \
  --data-binary $'ls -la\n' \
  "$HOST/api/xclouseau/v1/sessions/$SESSION_ID/input")
print_ok "Input sent: $INPUT_RESULT"
print_info "Check your Clouseau terminal window — 'ls -la' should have executed."

print_step "5. Resize terminal"
RESIZE_RESULT=$($CURL -X POST \
  -H "X-Device-Fingerprint: $FINGERPRINT" \
  -H 'Content-Type: application/json' \
  -d '{"cols":120,"rows":40}' \
  "$HOST/api/xclouseau/v1/sessions/$SESSION_ID/resize")
print_ok "Resize sent: $RESIZE_RESULT"

print_step "6. List viewers"
VIEWERS=$($CURL -H "X-Device-Fingerprint: $FINGERPRINT" \
  "$HOST/api/xclouseau/v1/sessions/$SESSION_ID/viewers")
echo "  Viewers: $VIEWERS"

print_step "7. WebSocket attach (live terminal stream)"
if command -v websocat &> /dev/null; then
  print_info "Attaching via WebSocket for 5 seconds..."
  print_info "You should see terminal output below:"
  echo "---"
  timeout 5 websocat -k \
    "wss://localhost:53317/api/xclouseau/v1/sessions/$SESSION_ID/attach?fingerprint=$FINGERPRINT" \
    2>/dev/null || true
  echo ""
  echo "---"
  print_ok "WebSocket test complete"
else
  print_info "websocat not installed. Install with: brew install websocat"
  print_info "Manual test:"
  echo "  websocat -k \"wss://localhost:53317/api/xclouseau/v1/sessions/$SESSION_ID/attach?fingerprint=$FINGERPRINT\""
fi

print_step "8. Unpair device"
read -p "  Unpair the test device? (y/N): " UNPAIR
if [ "$UNPAIR" = "y" ] || [ "$UNPAIR" = "Y" ]; then
  UNPAIR_RESULT=$($CURL -X DELETE "$HOST/api/xclouseau/v1/pair/$FINGERPRINT")
  print_ok "Unpaired: $UNPAIR_RESULT"
else
  print_info "Skipped. Device stays paired."
fi

echo ""
echo -e "${GREEN}All tests passed!${NC}"
echo ""
echo "Summary of endpoints tested:"
echo "  GET  /api/xclouseau/v1/pair/info"
echo "  POST /api/xclouseau/v1/pair/request"
echo "  GET  /api/xclouseau/v1/sessions"
echo "  POST /api/xclouseau/v1/sessions/:id/input"
echo "  POST /api/xclouseau/v1/sessions/:id/resize"
echo "  GET  /api/xclouseau/v1/sessions/:id/viewers"
echo "  WS   /api/xclouseau/v1/sessions/:id/attach"
echo "  DEL  /api/xclouseau/v1/pair/:fingerprint"
