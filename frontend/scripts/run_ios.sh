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

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Warning: iOS builds require macOS and Xcode. Proceeding anyway (e.g. CI with macOS runner)." >&2
fi

detect_lan_ip() {
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: pick the active Wi-Fi or Ethernet interface IP.
        ipconfig getifaddr en0 2>/dev/null \
            || ipconfig getifaddr en1 2>/dev/null \
            || echo "127.0.0.1"
    else
        ip route get 1 2>/dev/null | grep -oP 'src \K[0-9.]+' | head -1 \
            || hostname -I 2>/dev/null | awk '{print $1}' \
            || echo "127.0.0.1"
    fi
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
if [[ -n "${API_BASE_URL:-}" ]]; then
    API_URL="$API_BASE_URL"
elif [[ -n "${BACKEND_URL:-}" ]]; then
    API_URL="$BACKEND_URL"
elif [[ -n "${BACKEND_HOST:-}" ]]; then
    API_URL="${BACKEND_SCHEME}://${BACKEND_HOST}:${BACKEND_PORT}"
else
    API_URL="http://${LAN_IP}:${BACKEND_PORT}"
fi

MODE="--release"
DEVICE_ID=""
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
        DEVICE_ID="${!i}"
    else
        EXTRA_ARGS+=("$arg")
    fi
    i=$((i + 1))
done

echo "Backend → $API_URL"

DEVICE_ARGS=()
[[ -n "$DEVICE_ID" ]] && DEVICE_ARGS=("-d" "$DEVICE_ID")

cd "$REPO_ROOT"
"$FLUTTER" run \
    $MODE \
    --dart-define=API_BASE_URL="$API_URL" \
    --dart-define=BACKEND_URL="$API_URL" \
    "${DEVICE_ARGS[@]}" \
    "${EXTRA_ARGS[@]}"
