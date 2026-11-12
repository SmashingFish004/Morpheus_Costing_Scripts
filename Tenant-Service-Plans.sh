#!/bin/bash

set -e

MORPHEUS="https://x.x.x.x"
TOKEN=""

TENANT_ID="<%= customOptions.tenantId %>"
PLAN_FAMILY=$(echo "<%= customOptions.storageplan %>" | tr '[:upper:]' '[:lower:]')
BILLING=$(echo "<%= customOptions.storagebilling %>" | tr '[:upper:]' '[:lower:]')

echo "Tenant ID      : $TENANT_ID"
echo "Plan Family    : $PLAN_FAMILY"
echo "Billing Model  : $BILLING"

########################################
# Resolve Tenant Name
########################################

TENANT_NAME=$(curl -sk \
  -H "Authorization: BEARER $TOKEN" \
  "$MORPHEUS/api/accounts?max=500" | \
  jq -r --argjson ID "$TENANT_ID" \
  '.accounts[] | select(.id == $ID) | .name')

if [ -z "$TENANT_NAME" ]; then
  echo "ERROR: Unable to determine tenant name"
  exit 1
fi

echo "Tenant Name : $TENANT_NAME"

########################################
# Find KVM Provision Type
########################################

KVM_ID=$(curl -sk \
  -H "Authorization: BEARER $TOKEN" \
  "$MORPHEUS/api/provision-types?max=500" | \
  jq -r '.provisionTypes[] | select(.code=="kvm") | .id' | \
  head -1)

if [ -z "$KVM_ID" ]; then
  echo "ERROR: Unable to locate KVM Provision Type"
  exit 1
fi

echo "KVM Provision Type ID : $KVM_ID"

########################################
# Price Set Lookup
########################################

get_priceset_id() {

  local NAME="$1"

  curl -sk \
    -H "Authorization: BEARER $TOKEN" \
    "$MORPHEUS/api/price-sets?max=500" | \
  jq -r --arg NAME "$NAME" '
    .priceSets[]
    | select(.name==$NAME)
    | .id
  ' | head -1
}

########################################
# PLAN DEFINITIONS
########################################

PLANS=()

case "$PLAN_FAMILY" in

  standard)

    if [ "$BILLING" = "hourly" ] || [ "$BILLING" = "both" ]; then
      PLANS+=(
        "Archive Standard Hourly|Archive-Hourly-Standard"
        "Bronze Standard Hourly|Bronze-Hourly-Standard"
        "Silver Standard Hourly|Silver-Hourly-Standard"
        "Gold Standard Hourly|Gold-Hourly-Standard"
        "Platinum Standard Hourly|Platinum-Hourly-Standard"
        "Diamond Standard Hourly|Diamond-Hourly-Standard"
      )
    fi

    if [ "$BILLING" = "monthly" ] || [ "$BILLING" = "both" ]; then
      PLANS+=(
        "Archive Standard Monthly|Archive-Monthly-Standard"
        "Bronze Standard Monthly|Bronze-Monthly-Standard"
        "Silver Standard Monthly|Silver-Monthly-Standard"
        "Gold Standard Monthly|Gold-Monthly-Standard"
        "Platinum Standard Monthly|Platinum-Monthly-Standard"
        "Diamond Standard Monthly|Diamond-Monthly-Standard"
      )
    fi
    ;;

  enterprise)

    if [ "$BILLING" = "hourly" ] || [ "$BILLING" = "both" ]; then
      PLANS+=(
        "Archive Enterprise Hourly|Archive-Hourly-Enterprise"
        "Bronze Enterprise Hourly|Bronze-Hourly-Enterprise"
        "Silver Enterprise Hourly|Silver-Hourly-Enterprise"
        "Gold Enterprise Hourly|Gold-Hourly-Enterprise"
        "Platinum Enterprise Hourly|Platinum-Hourly-Enterprise"
        "Diamond Enterprise Hourly|Diamond-Hourly-Enterprise"
      )
    fi

    if [ "$BILLING" = "monthly" ] || [ "$BILLING" = "both" ]; then
      PLANS+=(
        "Archive Enterprise Monthly|Archive-Monthly-Enterprise"
        "Bronze Enterprise Monthly|Bronze-Monthly-Enterprise"
        "Silver Enterprise Monthly|Silver-Monthly-Enterprise"
        "Gold Enterprise Monthly|Gold-Monthly-Enterprise"
        "Platinum Enterprise Monthly|Platinum-Monthly-Enterprise"
        "Diamond Enterprise Monthly|Diamond-Monthly-Enterprise"
      )
    fi
    ;;

  partner)

    if [ "$BILLING" = "hourly" ] || [ "$BILLING" = "both" ]; then
      PLANS+=(
        "Archive Partner Hourly|Archive-Hourly-Partner"
        "Bronze Partner Hourly|Bronze-Hourly-Partner"
        "Silver Partner Hourly|Silver-Hourly-Partner"
        "Gold Partner Hourly|Gold-Hourly-Partner"
        "Platinum Partner Hourly|Platinum-Hourly-Partner"
        "Diamond Partner Hourly|Diamond-Hourly-Partner"
      )
    fi

    if [ "$BILLING" = "monthly" ] || [ "$BILLING" = "both" ]; then
      PLANS+=(
        "Archive Partner Monthly|Archive-Monthly-Partner"
        "Bronze Partner Monthly|Bronze-Monthly-Partner"
        "Silver Partner Monthly|Silver-Monthly-Partner"
        "Gold Partner Monthly|Gold-Monthly-Partner"
        "Platinum Partner Monthly|Platinum-Monthly-Partner"
        "Diamond Partner Monthly|Diamond-Monthly-Partner"
      )
    fi
    ;;

  *)
    echo "Unknown Plan Family: $PLAN_FAMILY"
    exit 1
    ;;
esac

########################################
# CREATE SERVICE PLANS
########################################

for PLAN in "${PLANS[@]}"
do

  PLAN_NAME=$(echo "$PLAN" | cut -d'|' -f1)
  PRICESET_NAME=$(echo "$PLAN" | cut -d'|' -f2)

  PRICESET_ID=$(get_priceset_id "$PRICESET_NAME")

  if [ -z "$PRICESET_ID" ]; then
    echo "ERROR: Could not locate Price Set: $PRICESET_NAME"
    continue
  fi

  NEW_NAME="$TENANT_NAME $PLAN_NAME"

  NEW_CODE=$(echo "$NEW_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/ /-/g' \
    | sed 's/[^a-zA-Z0-9-]//g')

  echo ""
  echo "Creating $NEW_NAME"
  echo "Price Set    : $PRICESET_NAME"
  echo "Price Set ID : $PRICESET_ID"

  cat >/opt/morpheus/.local/serviceplan.json <<EOF
{
  "servicePlan": {
    "name": "$NEW_NAME",
    "code": "$NEW_CODE",
    "active": true,
    "description": "$NEW_NAME",
    "maxStorage": 0,
    "maxMemory": 0,
    "maxCpu": 0,
    "maxCores": 1,
    "maxDisks": 10,
    "customCores": true,
    "customMaxMemory": true,
    "customMaxStorage": true,
    "customMaxDataStorage": true,
    "addVolumes": true,
    "visibility": "private",
    "provisionType": {
      "id": $KVM_ID
    },
    "priceSets": [
      {
        "id": $PRICESET_ID
      }
    ],
    "zones": [
      {
        "id": 1
      }
    ]
  }
}
EOF

  RESULT=$(curl -sk \
    -X POST \
    -H "Authorization: BEARER $TOKEN" \
    -H "Content-Type: application/json" \
    "$MORPHEUS/api/service-plans" \
    -d @/opt/morpheus/.local/serviceplan.json)

  PLAN_ID=$(echo "$RESULT" | jq -r '.id')

  echo "Created Plan ID: $PLAN_ID"

  cat >/opt/morpheus/.local/perm.json <<EOF
{
  "servicePlan": {
    "permissions": {
      "tenantPermissions": {
        "accounts": [
          $TENANT_ID
        ]
      }
    }
  }
}
EOF

  curl -sk \
    -X PUT \
    -H "Authorization: BEARER $TOKEN" \
    -H "Content-Type: application/json" \
    "$MORPHEUS/api/service-plans/$PLAN_ID" \
    -d @/opt/morpheus/.local/perm.json >/dev/null

  echo "Permissions Applied"

done

echo ""
echo "Completed Successfully"