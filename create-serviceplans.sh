#!/bin/bash

####################################################
# Morpheus Configuration
####################################################

MORPHEUS="https://x.x.x.x"
TOKEN="YOUR_TOKEN"

####################################################
# API Helper
####################################################

api_get() {

    curl -sk \
        -H "Authorization: BEARER $TOKEN" \
        "$1"
}

####################################################
# Lookup Functions
####################################################

get_kvm_id() {

    api_get "$MORPHEUS/api/provision-types?max=500" | \
    jq -r '
      .provisionTypes[]
      | select(.code=="kvm")
      | .id
    ' | head -1
}

get_priceset_id() {

    local NAME="$1"

    api_get "$MORPHEUS/api/price-sets?max=500" | \
    jq -r --arg NAME "$NAME" '
      .priceSets[]
      | select(.name==$NAME)
      | .id
    ' | head -1
}

serviceplan_exists() {

    local CODE="$1"

    api_get "$MORPHEUS/api/service-plans?max=500" | \
    jq -r --arg CODE "$CODE" '
      .servicePlans[]
      | select(.code==$CODE)
      | .id
    ' | head -1
}

####################################################
# Validation
####################################################

PROVISION_TYPE_ID=$(get_kvm_id)

if [ -z "$PROVISION_TYPE_ID" ]; then
    echo "ERROR: KVM Provision Type not found"
    exit 1
fi

echo "KVM Provision Type ID = $PROVISION_TYPE_ID"
echo

####################################################
# Create Service Plan
####################################################

create_serviceplan() {

    local PLAN_NAME="$1"
    local PLAN_CODE="$2"
    local PRICESET_NAME="$3"

    EXISTING_ID=$(serviceplan_exists "$PLAN_CODE")

    if [ -n "$EXISTING_ID" ]; then

        echo "Skipping Existing Service Plan"
        echo "  Name : $PLAN_NAME"
        echo "  Code : $PLAN_CODE"
        echo "  ID   : $EXISTING_ID"
        echo

        return
    fi

    PRICESET_ID=$(get_priceset_id "$PRICESET_NAME")

    if [ -z "$PRICESET_ID" ]; then

        echo "ERROR: Price Set Not Found"
        echo "  Name : $PRICESET_NAME"
        echo

        return
    fi

    echo "Creating Service Plan"
    echo "  Name         : $PLAN_NAME"
    echo "  Code         : $PLAN_CODE"
    echo "  Price Set    : $PRICESET_NAME"
    echo "  Price Set ID : $PRICESET_ID"
    echo

cat >/tmp/serviceplan.json <<EOF
{
  "servicePlan": {
    "name": "$PLAN_NAME",
    "code": "$PLAN_CODE",
    "active": true,
    "visibility": "private",

    "maxStorage": 0,
    "maxMemory": 0,
    "maxCpu": null,
    "maxCores": 1,

    "customCpu": false,
    "customCores": true,
    "customMaxStorage": true,
    "customMaxDataStorage": true,
    "customMaxMemory": true,

    "addVolumes": true,

    "provisionType": {
      "id": $PROVISION_TYPE_ID
    },

    "priceSets": [
      {
        "id": $PRICESET_ID
      }
    ]
  }
}
EOF

    curl -sk \
        -X POST \
        -H "Authorization: BEARER $TOKEN" \
        -H "Content-Type: application/json" \
        "$MORPHEUS/api/service-plans" \
        -d @/tmp/serviceplan.json | jq .

    rm -f /tmp/serviceplan.json

    echo
}

####################################################
# HOURLY STANDARD
####################################################

create_serviceplan "Archive Standard Hourly"  "ASH" "Archive-Hourly-Standard"
create_serviceplan "Bronze Standard Hourly"   "BSH" "Bronze-Hourly-Standard"
create_serviceplan "Silver Standard Hourly"   "SSH" "Silver-Hourly-Standard"
create_serviceplan "Gold Standard Hourly"     "GSH" "Gold-Hourly-Standard"
create_serviceplan "Platinum Standard Hourly" "PSH" "Platinum-Hourly-Standard"
create_serviceplan "Diamond Standard Hourly"  "DSH" "Diamond-Hourly-Standard"

####################################################
# HOURLY ENTERPRISE
####################################################

create_serviceplan "Archive Enterprise Hourly"  "AEH" "Archive-Hourly-Enterprise"
create_serviceplan "Bronze Enterprise Hourly"   "BEH" "Bronze-Hourly-Enterprise"
create_serviceplan "Silver Enterprise Hourly"   "SEH" "Silver-Hourly-Enterprise"
create_serviceplan "Gold Enterprise Hourly"     "GEH" "Gold-Hourly-Enterprise"
create_serviceplan "Platinum Enterprise Hourly" "PEH" "Platinum-Hourly-Enterprise"
create_serviceplan "Diamond Enterprise Hourly"  "DEH" "Diamond-Hourly-Enterprise"

####################################################
# HOURLY PARTNER
####################################################

create_serviceplan "Archive Partner Hourly"  "APH" "Archive-Hourly-Partner"
create_serviceplan "Bronze Partner Hourly"   "BPH" "Bronze-Hourly-Partner"
create_serviceplan "Silver Partner Hourly"   "SPH" "Silver-Hourly-Partner"
create_serviceplan "Gold Partner Hourly"     "GPH" "Gold-Hourly-Partner"
create_serviceplan "Platinum Partner Hourly" "PPH" "Platinum-Hourly-Partner"
create_serviceplan "Diamond Partner Hourly"  "DPH" "Diamond-Hourly-Partner"

####################################################
# MONTHLY STANDARD
####################################################

create_serviceplan "Archive Standard Monthly"  "ASM" "Archive-Monthly-Standard"
create_serviceplan "Bronze Standard Monthly"   "BSM" "Bronze-Monthly-Standard"
create_serviceplan "Silver Standard Monthly"   "SSM" "Silver-Monthly-Standard"
create_serviceplan "Gold Standard Monthly"     "GSM" "Gold-Monthly-Standard"
create_serviceplan "Platinum Standard Monthly" "PSM" "Platinum-Monthly-Standard"
create_serviceplan "Diamond Standard Monthly"  "DSM" "Diamond-Monthly-Standard"

####################################################
# MONTHLY ENTERPRISE
####################################################

create_serviceplan "Archive Enterprise Monthly"  "AEM" "Archive-Monthly-Enterprise"
create_serviceplan "Bronze Enterprise Monthly"   "BEM" "Bronze-Monthly-Enterprise"
create_serviceplan "Silver Enterprise Monthly"   "SEM" "Silver-Monthly-Enterprise"
create_serviceplan "Gold Enterprise Monthly"     "GEM" "Gold-Monthly-Enterprise"
create_serviceplan "Platinum Enterprise Monthly" "PEM" "Platinum-Monthly-Enterprise"
create_serviceplan "Diamond Enterprise Monthly"  "DEM" "Diamond-Monthly-Enterprise"

####################################################
# MONTHLY PARTNER
####################################################

create_serviceplan "Archive Partner Monthly"  "APM" "Archive-Monthly-Partner"
create_serviceplan "Bronze Partner Monthly"   "BPM" "Bronze-Monthly-Partner"
create_serviceplan "Silver Partner Monthly"   "SPM" "Silver-Monthly-Partner"
create_serviceplan "Gold Partner Monthly"     "GPM" "Gold-Monthly-Partner"
create_serviceplan "Platinum Partner Monthly" "PPM" "Platinum-Monthly-Partner"
create_serviceplan "Diamond Partner Monthly"  "DPM" "Diamond-Monthly-Partner"

echo
echo "======================================"
echo "ALL SERVICE PLANS CREATED SUCCESSFULLY"
echo "======================================"