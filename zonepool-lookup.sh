#!/usr/bin/env bash
# zonepool-lookup.sh
# For each cloud (zone) ID, finds the resource pool ID to use as network.zonePool.id
# with the two methods HPE support described, and shows whether they agree.
#
#   Method 1 (cluster API):  GET /api/clusters?zoneId=<zone>
#                            GET /api/clusters/<clusterId>  -> .cluster.permissions.resourcePool.id
#   Method 2 (core options): GET /api/options/zonePools?zoneId=<zone>&provisionTypeCode=kvm
#                            -> .data[] entries that have an "id" (the group header row has none)
#
# Requires: curl, jq
#
# Usage:
#   read -rs -p "Token: " TOKEN; echo; export TOKEN
#   BASE=https://<appliance> ./zonepool-lookup.sh <zoneId> [<zoneId> ...]
# Example (O2 preprod):
#   BASE=https://t-portal.cloud.o2.cz ./zonepool-lookup.sh 3 65 66
#
# -k skips TLS certificate verification; remove it if the certificate is trusted.
set -uo pipefail

: "${BASE:?set BASE, e.g. https://t-portal.cloud.o2.cz}"
: "${TOKEN:?set TOKEN (export it, do not paste it into shared output)}"
[ $# -ge 1 ] || { echo "Usage: BASE=... $0 <zoneId> [<zoneId> ...]" >&2; exit 1; }

AUTH="Authorization: Bearer ${TOKEN}"
get() { curl -sk -H "$AUTH" -H 'accept: application/json' "$1"; }

printf '%-6s %-28s %-9s %-26s %s\n' "ZONE" "CLUSTER" "M1_POOL" "M2_POOL(S)" "RESULT"

for zone in "$@"; do
  # Method 2 once per zone: all numeric pool IDs with names, e.g. "56:T-CH-POD06"
  m2raw=$(get "${BASE}/api/options/zonePools?zoneId=${zone}&provisionTypeCode=kvm")
  m2list=$(echo "$m2raw" | jq -r '.data[]? | select(.id != null) | "\(.id):\(.name)"' 2>/dev/null)

  # Method 1: clusters for this zone
  clusters=$(get "${BASE}/api/clusters?zoneId=${zone}")
  rows=$(echo "$clusters" | jq -r '.clusters[]? | "\(.id)\t\(.name)"' 2>/dev/null)

  if [ -z "$rows" ]; then
    err=$(echo "$clusters" | head -c 100)
    printf '%-6s %-28s %-9s %-26s %s\n' "$zone" "-" "-" "$(echo "$m2list" | tr '\n' ' ')" "M1: no clusters returned ($err)"
    continue
  fi

  while IFS=$'\t' read -r cid cname; do
    detail=$(get "${BASE}/api/clusters/${cid}")
    m1=$(echo "$detail" | jq -r '.cluster.permissions.resourcePool.id // "-"' 2>/dev/null)
    ids_m2=$(echo "$m2list" | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')

    if echo "$m2list" | cut -d: -f1 | grep -qx "$m1" && [ "$m1" != "-" ]; then
      res="M1 pool $m1 is listed by M2"
    else
      res="CHECK: M1 pool $m1 not in M2 list"
    fi
    printf '%-6s %-28s %-9s %-26s %s\n' "$zone" "$cname" "$m1" "$ids_m2" "$res"
  done <<< "$rows"
done

echo
echo "Note: if M2 returns the same pools for every zone, zoneId is not filtering there;"
echo "rely on M1 (per-cluster) for the zone-to-pool mapping."