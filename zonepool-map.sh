#!/usr/bin/env bash
# zonepool-map.sh
# Maps each Morpheus network server to the resource pool value returned by the
# HVM "hvm-resource-pool" option source (the value the UI sends as network.zonePool.id).
#
# Requires: curl, jq
#
# Usage:
#   BASE=https://<appliance> TOKEN=<api-token> ./zonepool-map.sh            # try to list servers
#   BASE=https://<appliance> TOKEN=<api-token> ./zonepool-map.sh 1 2 3 4    # explicit server IDs
#
# Tip: avoid leaving the token in shell history:
#   read -rs -p "Token: " TOKEN; echo; export TOKEN
#   BASE=https://<appliance> ./zonepool-map.sh 1 2 3 4
#
# Note: -k skips TLS certificate verification. Remove it if the appliance
# certificate is trusted.
set -uo pipefail

: "${BASE:?set BASE, e.g. https://t-portal.cloud.o2.cz}"
: "${TOKEN:?set TOKEN}"

AUTH="Authorization: Bearer ${TOKEN}"
POOL_URL="${BASE}/api/options/com.hpe.morpheus.hvm/hvm-resource-pool"

declare -A NAMES ZONES
ids=("$@")

# If no IDs were given, try to list the network servers
if [ ${#ids[@]} -eq 0 ]; then
  raw=$(curl -sk -H "$AUTH" -H 'accept: application/json' "${BASE}/api/networks/servers?max=100")
  if echo "$raw" | jq -e '.networkServers | length > 0' >/dev/null 2>&1; then
    while IFS=$'\t' read -r sid sname zid; do
      ids+=("$sid"); NAMES[$sid]="$sname"; ZONES[$sid]="$zid"
    done < <(echo "$raw" | jq -r '.networkServers[] | [.id, .name, (.zoneId // .zone.id // "")] | @tsv')
    echo "Listed ${#ids[@]} network servers via /api/networks/servers" >&2
  else
    echo "No usable server list from /api/networks/servers. Raw response (first 300 chars):" >&2
    echo "$raw" | head -c 300 >&2; echo >&2
    echo "Re-run with explicit IDs, e.g.: ./zonepool-map.sh 1 2 3 4" >&2
    exit 1
  fi
fi

printf '%-6s %-40s %-8s %-9s %s\n' "SRV_ID" "SERVER_NAME" "ZONE_ID" "POOL_VAL" "POOL_NAME"

for sid in "${ids[@]}"; do
  resp=$(curl -sk -X POST -H "$AUTH" "$POOL_URL" -d "network.networkServer.id=${sid}")
  sname="${NAMES[$sid]:-}"; zid="${ZONES[$sid]:-}"

  if [ "$(echo "$resp" | jq -r '.success // false' 2>/dev/null)" = "true" ] && \
     [ "$(echo "$resp" | jq -r '.data | length' 2>/dev/null)" != "0" ]; then
    echo "$resp" | jq -r '.data[] | [(.value|tostring), .name] | @tsv' |
    while IFS=$'\t' read -r val pname; do
      printf '%-6s %-40s %-8s %-9s %s\n' "$sid" "$sname" "$zid" "$val" "$pname"
    done
  else
    printf '%-6s %-40s %-8s %-9s %s\n' "$sid" "$sname" "$zid" "-" "no pool / error: $(echo "$resp" | head -c 80)"
  fi
done