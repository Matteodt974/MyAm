#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FLUTTER="flutter"
if ! command -v flutter &>/dev/null; then
    if [[ -x "$HOME/fvm/versions/stable/bin/flutter" ]]; then
        FLUTTER="$HOME/fvm/versions/stable/bin/flutter"
    else
        echo "Error: flutter not found on PATH or at ~/fvm/versions/stable/bin/flutter." >&2
        exit 1
    fi
fi

ADB="adb"
if ! command -v adb &>/dev/null; then
    for candidate in \
        "$HOME/Android/Sdk/platform-tools/adb" \
        "$HOME/.android/sdk/platform-tools/adb" \
        "/opt/android-sdk/platform-tools/adb"; do
        if [[ -x "$candidate" ]]; then
            ADB="$candidate"
            break
        fi
    done
    if ! command -v "$ADB" &>/dev/null && [[ "$ADB" == "adb" ]]; then
        echo "Warning: adb not found. Install Android platform-tools or add to PATH." >&2
        ADB=""
    fi
fi

detect_lan_ip() {
    ip route get 1 2>/dev/null | grep -oP 'src \K[0-9.]+' | head -1 \
        || hostname -I 2>/dev/null | awk '{print $1}' \
        || echo "127.0.0.1"
}
LAN_IP="$(detect_lan_ip)"

ENV_FILE="$REPO_ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
fi

BACKEND_SCHEME="${BACKEND_SCHEME:-http}"
BACKEND_PORT="${BACKEND_PORT:-8545}"
PARENT_USER_ID="${PARENT_USER_ID:-1}"

# Check if adb reverse is active for USB debugging
ADB_REVERSE_ACTIVE=false
if [[ -n "$ADB" ]] && "$ADB" reverse --list 2>/dev/null | grep -q "tcp:8545 tcp:8545"; then
    ADB_REVERSE_ACTIVE=true
fi

if [[ -n "${API_BASE_URL:-}" ]]; then
    API_URL="$API_BASE_URL"
elif [[ -n "${BACKEND_URL:-}" ]]; then
    API_URL="$BACKEND_URL"
elif [[ -n "${BACKEND_HOST:-}" ]]; then
    API_URL="${BACKEND_SCHEME}://${BACKEND_HOST}:${BACKEND_PORT}"
elif [[ "$ADB_REVERSE_ACTIVE" == true ]]; then
    # USB debugging with adb reverse — use localhost
    API_URL="http://localhost:${BACKEND_PORT}"
else
    # Wireless debugging — use LAN IP
    API_URL="http://${LAN_IP}:${BACKEND_PORT}"
fi

MODE="--release"
DEVICE_ADDR=""
EXTRA_ARGS=()
i=1
while [[ $i -le $# ]]; do
    arg="${!i}"
    if [[ "$arg" == "--debug" ]]; then
        MODE="--debug"
    elif [[ "$arg" == "--release" ]]; then
        MODE="--release"
    elif [[ "$arg" == "--api-url" ]]; then
        i=$((i + 1))
        API_URL="${!i}"
    elif [[ "$arg" == "-d" ]]; then
        i=$((i + 1))
        DEVICE_ADDR="${!i}"
    else
        EXTRA_ARGS+=("$arg")
    fi
    i=$((i + 1))
done

if [[ -n "$ADB" && -n "$DEVICE_ADDR" ]]; then
    if [[ "$DEVICE_ADDR" != *:* ]]; then
        echo "Error: -d requires IP:PORT for wireless ADB (e.g. 192.168.1.42:38765)." >&2
        echo "Find the port under Developer options → Wireless debugging." >&2
        exit 1
    fi
    echo "Connecting to $DEVICE_ADDR via ADB..."
    "$ADB" connect "$DEVICE_ADDR" || true
fi

echo "Backend → $API_URL"
echo "Parent user ID → $PARENT_USER_ID"

DEVICE_ARGS=()
[[ -n "$DEVICE_ADDR" ]] && DEVICE_ARGS=("-d" "$DEVICE_ADDR")

cd "$REPO_ROOT"
"$FLUTTER" run \
    $MODE \
    --dart-define=API_BASE_URL="$API_URL" \
    --dart-define=BACKEND_URL="$API_URL" \
    --dart-define=PARENT_USER_ID="$PARENT_USER_ID" \
    ${DEVICE_ARGS[@]+"${DEVICE_ARGS[@]}"} \
    ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
