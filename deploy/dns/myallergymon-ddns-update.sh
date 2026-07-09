#!/usr/bin/env bash

# Updates myallergymon.ca DNS A records with the current public IP.

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
CF_API_TOKEN="REPLACE_WITH_SCOPED_DNS_WRITE_TOKEN"
CF_ZONE_ID="6f12df877c81989c4769e0ee52864af5"
CF_RECORDS=("api.myallergymon.ca:true" "ssh.myallergymon.ca:false")
TTL=60
STATE_FILE="/var/lib/myallergymon-ddns/last_ip"
# ─────────────────────────────────────────────────────────────────────────────

log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }

# ── Get current public IP ─────────────────────────────────────────────────────
get_public_ip() {
	local ip
	for source in \
		"https://api4.my-ip.io/ip" \
		"https://ipv4.icanhazip.com" \
		"https://api.ipify.org" \
		"https://checkip.amazonaws.com"; do
		ip=$(curl -sf --max-time 5 "$source" 2>/dev/null | tr -d '[:space:]') &&
			[[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] &&
			echo "$ip" && return 0
	done
	log "ERROR: Could not determine public IP from any source"
	return 1
}

# ── Update a single DNS record ───────────────────────────────────────────────
update_record() {
	local record_name="$1"
	local proxied="$2"
	local current_ip="$3"
	local cf_api="https://api.cloudflare.com/client/v4"

	local record_data
	record_data=$(curl -s \
		-H "Authorization: Bearer $CF_API_TOKEN" \
		-H "Content-Type: application/json" \
		"${cf_api}/zones/${CF_ZONE_ID}/dns_records?type=A&name=${record_name}")

	if ! echo "$record_data" | grep -q '"success":true'; then
		log "ERROR: Failed to query Cloudflare API for $record_name: $record_data"
		return 1
	fi

	local record_id
	record_id=$(echo "$record_data" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

	if [[ -z "$record_id" ]]; then
		log "ERROR: No A record found for '$record_name' in zone $CF_ZONE_ID"
		log "       Create the record manually in the Cloudflare dashboard first."
		return 1
	fi

	log "Found record ID for $record_name: $record_id"

	local update_result
	update_result=$(curl -sf -X PATCH \
		-H "Authorization: Bearer $CF_API_TOKEN" \
		-H "Content-Type: application/json" \
		--data "{\"type\":\"A\",\"name\":\"${record_name}\",\"content\":\"${current_ip}\",\"ttl\":${TTL},\"proxied\":${proxied}}" \
		"${cf_api}/zones/${CF_ZONE_ID}/dns_records/${record_id}")

	if echo "$update_result" | grep -q '"success":true'; then
		log "SUCCESS: Updated $record_name → $current_ip"
	else
		log "ERROR: Cloudflare update failed for $record_name: $update_result"
		return 1
	fi
}

# ── Check against last known IP ───────────────────────────────────────────────
mkdir -p "$(dirname "$STATE_FILE")"

CURRENT_IP=$(get_public_ip)
log "Current public IP: $CURRENT_IP"

if [[ -f "$STATE_FILE" ]]; then
	LAST_IP=$(cat "$STATE_FILE")
	if [[ "$CURRENT_IP" == "$LAST_IP" ]]; then
		log "IP unchanged ($CURRENT_IP) — skipping update"
		exit 0
	fi
fi

# ── Update all records ────────────────────────────────────────────────────────
FAILED=0
for ENTRY in "${CF_RECORDS[@]}"; do
	RECORD="${ENTRY%%:*}"
	PROXIED="${ENTRY##*:}"
	update_record "$RECORD" "$PROXIED" "$CURRENT_IP" || FAILED=1
done

if [[ "$FAILED" -eq 0 ]]; then
	echo "$CURRENT_IP" >"$STATE_FILE"
	log "All records updated successfully"
else
	log "One or more updates failed"
	exit 1
fi
