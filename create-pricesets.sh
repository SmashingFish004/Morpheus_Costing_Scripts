#!/bin/bash

MORPHEUS="https://x.x.x.x"
TOKEN=""
ACCOUNT_ID=1

###########################################
# API Helper
###########################################

api_get() {

    curl -sk \
      -H "Authorization: BEARER $TOKEN" \
      "$1"
}

###########################################
# Price Lookup
###########################################

get_price_id() {

    local NAME="$1"

    api_get "$MORPHEUS/api/prices?max=1000" | \
    jq -r --arg NAME "$NAME" '
      .prices[]
      | select(.name==$NAME)
      | .id
    ' | head -1
}

###########################################
# Create Price Set
###########################################

create_priceset() {

    local NAME="$1"
    local CODE="$2"
    local UNIT="$3"
    local CPU="$4"
    local MEM="$5"
    local STORAGE="$6"

    cat >/tmp/priceset.json <<EOF
{
  "priceSet": {
    "name": "$NAME",
    "code": "$CODE",
    "active": true,
    "priceUnit": "$UNIT",
    "type": "component",
    "account": {
      "id": $ACCOUNT_ID
    },
    "prices": [
      { "id": $CPU },
      { "id": $MEM },
      { "id": $STORAGE }
    ]
  }
}
EOF

    echo "Creating: $NAME"
    echo "  CPU     : $CPU"
    echo "  MEM     : $MEM"
    echo "  STORAGE : $STORAGE"

    curl -sk \
      -X POST \
      -H "Authorization: BEARER $TOKEN" \
      -H "Content-Type: application/json" \
      "$MORPHEUS/api/price-sets" \
      -d @/tmp/priceset.json | jq .

    echo
}

###########################################
# Resolve Master CPU / Memory IDs
###########################################

CPU_HOURLY=$(get_price_id "Master CPU Hourly")
CPU_MONTHLY=$(get_price_id "Master CPU Monthly")

MEM_HOURLY=$(get_price_id "Master Mem Hourly")
MEM_MONTHLY=$(get_price_id "Master Mem Monthly")

if [ -z "$CPU_HOURLY" ] || \
   [ -z "$CPU_MONTHLY" ] || \
   [ -z "$MEM_HOURLY" ] || \
   [ -z "$MEM_MONTHLY" ]; then

    echo "ERROR: Failed to resolve CPU/Memory Prices"
    exit 1
fi

echo "CPU Hourly : $CPU_HOURLY"
echo "CPU Monthly: $CPU_MONTHLY"
echo "MEM Hourly : $MEM_HOURLY"
echo "MEM Monthly: $MEM_MONTHLY"
echo

###########################################
# Storage Price Set Helper
###########################################

create_storage_priceset() {

    local NAME="$1"
    local CODE="$2"
    local UNIT="$3"

    STORAGE_ID=$(get_price_id "$NAME")

    if [ -z "$STORAGE_ID" ]; then
        echo "ERROR: Storage Price Not Found: $NAME"
        return
    fi

    if [ "$UNIT" = "hour" ]; then
        CPU_ID="$CPU_HOURLY"
        MEM_ID="$MEM_HOURLY"
    else
        CPU_ID="$CPU_MONTHLY"
        MEM_ID="$MEM_MONTHLY"
    fi

    create_priceset \
        "$NAME" \
        "$CODE" \
        "$UNIT" \
        "$CPU_ID" \
        "$MEM_ID" \
        "$STORAGE_ID"
}

###########################################
# HOURLY STANDARD
###########################################

create_storage_priceset "Archive-Hourly-Standard"  "archive-hourly-standard"  "hour"
create_storage_priceset "Bronze-Hourly-Standard"   "bronze-hourly-standard"   "hour"
create_storage_priceset "Silver-Hourly-Standard"   "silver-hourly-standard"   "hour"
create_storage_priceset "Gold-Hourly-Standard"     "gold-hourly-standard"     "hour"
create_storage_priceset "Platinum-Hourly-Standard" "platinum-hourly-standard" "hour"
create_storage_priceset "Diamond-Hourly-Standard"  "diamond-hourly-standard"  "hour"

###########################################
# HOURLY ENTERPRISE
###########################################

create_storage_priceset "Archive-Hourly-Enterprise"  "archive-hourly-enterprise"  "hour"
create_storage_priceset "Bronze-Hourly-Enterprise"   "bronze-hourly-enterprise"   "hour"
create_storage_priceset "Silver-Hourly-Enterprise"   "silver-hourly-enterprise"   "hour"
create_storage_priceset "Gold-Hourly-Enterprise"     "gold-hourly-enterprise"     "hour"
create_storage_priceset "Platinum-Hourly-Enterprise" "platinum-hourly-enterprise" "hour"
create_storage_priceset "Diamond-Hourly-Enterprise"  "diamond-hourly-enterprise"  "hour"

###########################################
# HOURLY PARTNER
###########################################

create_storage_priceset "Archive-Hourly-Partner"  "archive-hourly-partner"  "hour"
create_storage_priceset "Bronze-Hourly-Partner"   "bronze-hourly-partner"   "hour"
create_storage_priceset "Silver-Hourly-Partner"   "silver-hourly-partner"   "hour"
create_storage_priceset "Gold-Hourly-Partner"     "gold-hourly-partner"     "hour"
create_storage_priceset "Platinum-Hourly-Partner" "platinum-hourly-partner" "hour"
create_storage_priceset "Diamond-Hourly-Partner"  "diamond-hourly-partner"  "hour"

###########################################
# MONTHLY STANDARD
###########################################

create_storage_priceset "Archive-Monthly-Standard"  "archive-monthly-standard"  "month"
create_storage_priceset "Bronze-Monthly-Standard"   "bronze-monthly-standard"   "month"
create_storage_priceset "Silver-Monthly-Standard"   "silver-monthly-standard"   "month"
create_storage_priceset "Gold-Monthly-Standard"     "gold-monthly-standard"     "month"
create_storage_priceset "Platinum-Monthly-Standard" "platinum-monthly-standard" "month"
create_storage_priceset "Diamond-Monthly-Standard"  "diamond-monthly-standard"  "month"

###########################################
# MONTHLY ENTERPRISE
###########################################

create_storage_priceset "Archive-Monthly-Enterprise"  "archive-monthly-enterprise"  "month"
create_storage_priceset "Bronze-Monthly-Enterprise"   "bronze-monthly-enterprise"   "month"
create_storage_priceset "Silver-Monthly-Enterprise"   "silver-monthly-enterprise"   "month"
create_storage_priceset "Gold-Monthly-Enterprise"     "gold-monthly-enterprise"     "month"
create_storage_priceset "Platinum-Monthly-Enterprise" "platinum-monthly-enterprise" "month"
create_storage_priceset "Diamond-Monthly-Enterprise"  "diamond-monthly-enterprise"  "month"

###########################################
# MONTHLY PARTNER
###########################################

create_storage_priceset "Archive-Monthly-Partner"  "archive-monthly-partner"  "month"
create_storage_priceset "Bronze-Monthly-Partner"   "bronze-monthly-partner"   "month"
create_storage_priceset "Silver-Monthly-Partner"   "silver-monthly-partner"   "month"
create_storage_priceset "Gold-Monthly-Partner"     "gold-monthly-partner"     "month"
create_storage_priceset "Platinum-Monthly-Partner" "platinum-monthly-partner" "month"
create_storage_priceset "Diamond-Monthly-Partner"  "diamond-monthly-partner"  "month"

echo "========================================="
echo "All Price Sets Created"
echo "========================================="