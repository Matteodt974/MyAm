#!/usr/bin/env bash

set -euo pipefail

API_URL="${API_BASE_URL:-http://127.0.0.1:8545}"
EMAIL="test@test.com"
PASSWORD="Password1"
PARENT_NAME="Test Parent"
CHILD_NAME="Camille"
ANDROID_DEVICE=""
PACKAGE_NAME="com.uqam.inm5151.myam"

usage() {
    cat <<'EOF'
Seed the local MyAm test account and profile data.

Usage:
  scripts/seed-local-test.sh [--api-url URL] [--android DEVICE]

Options:
  --api-url URL      Backend URL (default: http://127.0.0.1:8545)
  --android DEVICE   Also seed recent scan history on this debug Android device
  -h, --help         Show this help

Credentials:
  test@test.com / Password1

The script is safe to rerun. It reuses the account and Camille profile,
replaces their preferences, refreshes stale digestive seed data, and only
replaces Android scan rows whose titles start with "Seed -".
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --api-url)
            API_URL="${2:?--api-url requires a URL}"
            shift 2
            ;;
        --android)
            ANDROID_DEVICE="${2:?--android requires an adb device identifier}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

for command in curl jq; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Error: $command is required." >&2
        exit 1
    fi
done

API_URL="${API_URL%/}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

request() {
    local method="$1"
    local path="$2"
    local output="$3"
    local body="${4:-}"
    local -a args=(-sS -o "$output" -w '%{http_code}' -X "$method")

    if [[ -n "${ACCESS_TOKEN:-}" ]]; then
        args+=(-H "Authorization: Bearer $ACCESS_TOKEN")
    fi
    if [[ -n "$body" ]]; then
        args+=(-H 'Content-Type: application/json' --data "$body")
    fi
    curl "${args[@]}" "$API_URL$path"
}

require_success() {
    local status="$1"
    local response="$2"
    local operation="$3"
    if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
        echo "Error: $operation failed with HTTP $status." >&2
        jq '.' "$response" >&2 2>/dev/null || true
        exit 1
    fi
}

login_response="$TEMP_DIR/login.json"
status="$(request POST /auth/login "$login_response" \
    "$(jq -nc --arg email "$EMAIL" --arg password "$PASSWORD" \
        '{email:$email,password:$password}')")"

if [[ "$status" == 401 ]]; then
    register_response="$TEMP_DIR/register.json"
    status="$(request POST /auth/register "$register_response" \
        "$(jq -nc --arg email "$EMAIL" --arg password "$PASSWORD" --arg name "$PARENT_NAME" \
            '{email:$email,password:$password,displayName:$name}')")"
    require_success "$status" "$register_response" "account registration"
    cp "$register_response" "$login_response"
else
    require_success "$status" "$login_response" "account login"
fi

ACCESS_TOKEN="$(jq -er '.accessToken' "$login_response")"
PARENT_ID="$(jq -er '.user.id' "$login_response")"

children_response="$TEMP_DIR/children.json"
status="$(request GET "/v1/parents/$PARENT_ID/children" "$children_response")"
require_success "$status" "$children_response" "child profile lookup"

CHILD_ID="$(jq -r --arg name "$CHILD_NAME" \
    '.[] | select(.displayName == $name) | .id' "$children_response" | head -n 1)"
if [[ -z "$CHILD_ID" ]]; then
    child_response="$TEMP_DIR/child.json"
    status="$(request POST "/v1/parents/$PARENT_ID/children" "$child_response" \
        "$(jq -nc --arg name "$CHILD_NAME" '{displayName:$name}')")"
    require_success "$status" "$child_response" "child profile creation"
    CHILD_ID="$(jq -er '.id' "$child_response")"
fi

seed_preferences() {
    local profile_id="$1"
    local allergies="$2"
    local diets="$3"
    local response="$TEMP_DIR/preferences-$profile_id.json"
    local body
    body="$(jq -nc --argjson allergies "$allergies" --argjson diets "$diets" \
        '{allergies:$allergies,diets:$diets}')"
    status="$(request PUT "/v1/profiles/$profile_id/preferences" "$response" "$body")"
    require_success "$status" "$response" "preferences for profile $profile_id"
}

seed_preferences "$PARENT_ID" '["arachide","gluten","lait"]' '["VEGAN"]'
seed_preferences "$CHILD_ID" '["noix","oeuf"]' '["GLUTEN_FREE","LACTOSE_FREE"]'

seed_journal() {
    local profile_id="$1"
    shift
    local response="$TEMP_DIR/journal-$profile_id.json"
    status="$(request GET "/v1/digestive-journal?profileId=$profile_id" "$response")"
    require_success "$status" "$response" "journal lookup for profile $profile_id"

    local cutoff_epoch
    cutoff_epoch="$(date -u -d '60 hours ago' +%s)"
    if jq -e --argjson cutoff "$cutoff_epoch" \
        'any(.[]; (.occurredAt | fromdateiso8601) >= $cutoff)' "$response" >/dev/null; then
        return
    fi

    while [[ $# -gt 0 ]]; do
        local hours_ago="$1"
        local bristol_type="$2"
        local notes="$3"
        shift 3
        local entry_response="$TEMP_DIR/journal-entry-$profile_id-$hours_ago.json"
        local occurred_at
        occurred_at="$(date -u -d "$hours_ago hours ago" +%Y-%m-%dT%H:%M:%SZ)"
        local body
        body="$(jq -nc \
            --argjson profileId "$profile_id" \
            --argjson bristolType "$bristol_type" \
            --arg occurredAt "$occurred_at" \
            --arg notes "$notes" \
            '{profileId:$profileId,bristolType:$bristolType,occurredAt:$occurredAt,notes:$notes}')"
        status="$(request POST /v1/digestive-journal "$entry_response" "$body")"
        require_success "$status" "$entry_response" "digestive entry for profile $profile_id"
    done
}

seed_journal "$PARENT_ID" \
    44 3 "Seed - normal" \
    25 6 "Seed - reaction digestive" \
    7 7 "Seed - reaction digestive recente"
seed_journal "$CHILD_ID" \
    42 4 "Seed - normal Camille" \
    23 2 "Seed - constipation Camille" \
    6 2 "Seed - constipation recente Camille"

seed_android_history() {
    local device="$1"
    for command in adb sqlite3; do
        if ! command -v "$command" >/dev/null 2>&1; then
            echo "Error: $command is required for --android." >&2
            exit 1
        fi
    done

    local db="$TEMP_DIR/scan_history.db"
    adb -s "$device" shell am force-stop "$PACKAGE_NAME"
    if ! adb -s "$device" exec-out run-as "$PACKAGE_NAME" \
        cat databases/scan_history.db >"$db"; then
        echo "Error: could not read the app database. Install a debug build and open it once." >&2
        exit 1
    fi

    local now_ms
    now_ms="$(date +%s%3N)"
    sqlite3 "$db" <<SQL
BEGIN;
DELETE FROM scan_history
WHERE title LIKE 'Seed - %' AND profile_id IN ($PARENT_ID, $CHILD_ID);
INSERT INTO scan_history(type,title,scanned_at,risk_level,matched_allergens,raw_json,profile_id) VALUES
('barcode','Seed - Yaourt au lait',${now_ms}-158400000,'DANGER','["lait"]','{}',$PARENT_ID),
('dish','Seed - Curry de légumes',${now_ms}-90000000,'SAFE','[]','{}',$PARENT_ID),
('label','Seed - Barre aux arachides',${now_ms}-25200000,'DANGER','["arachide"]','{}',$PARENT_ID),
('barcode','Seed - Pain sans gluten',${now_ms}-151200000,'SAFE','[]','{}',$CHILD_ID),
('dish','Seed - Omelette',${now_ms}-82800000,'DANGER','["oeuf"]','{}',$CHILD_ID),
('label','Seed - Boisson aux noix',${now_ms}-21600000,'DANGER','["noix"]','{}',$CHILD_ID);
COMMIT;
SQL

    adb -s "$device" push "$db" /data/local/tmp/myam-scan-history.db >/dev/null
    adb -s "$device" shell run-as "$PACKAGE_NAME" \
        cp /data/local/tmp/myam-scan-history.db databases/scan_history.db
    adb -s "$device" shell rm /data/local/tmp/myam-scan-history.db
    adb -s "$device" shell monkey -p "$PACKAGE_NAME" 1 >/dev/null
}

if [[ -n "$ANDROID_DEVICE" ]]; then
    seed_android_history "$ANDROID_DEVICE"
fi

echo "Seed complete."
echo "  Login:   $EMAIL / $PASSWORD"
echo "  Parent:  $PARENT_NAME (profile $PARENT_ID)"
echo "  Child:   $CHILD_NAME (profile $CHILD_ID)"
if [[ -z "$ANDROID_DEVICE" ]]; then
    echo "  Android: not seeded (pass --android DEVICE to add recent scan history)"
else
    echo "  Android: recent parent and child scan history seeded on $ANDROID_DEVICE"
fi
