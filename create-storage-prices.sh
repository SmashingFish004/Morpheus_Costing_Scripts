#!/bin/bash

MORPHEUS="https://"
TOKEN=""

create_price() {
    local NAME="$1"
    local CODE="$2"
    local UNIT="$3"
    local PRICE="$4"

    cat >/tmp/price.json <<EOF
{
  "price": {
    "name": "$NAME",
    "code": "$CODE",
    "active": true,
    "priceType": "storage",
    "priceUnit": "$UNIT",
    "additionalPriceUnit": "GB",
    "price": $PRICE,
    "cost": $PRICE,
    "currency": "CZK",
    "incurCharges": "always",
    "volumeType": {
      "id": 1
    }
  }
}
EOF

    echo "Creating: $NAME"

    curl -sk \
      -X POST \
      -H "Authorization: BEARER $TOKEN" \
      -H "Content-Type: application/json" \
      "$MORPHEUS/api/prices" \
      -d @/tmp/price.json | jq .
}

# =============================
# HOURLY - STANDARD
# =============================
create_price "Archive-Hourly-Standard"   "archive-hourly-standard"   "hour" 0.005
create_price "Bronze-Hourly-Standard"    "bronze-hourly-standard"    "hour" 0.008
create_price "Silver-Hourly-Standard"    "silver-hourly-standard"    "hour" 0.010
create_price "Gold-Hourly-Standard"      "gold-hourly-standard"      "hour" 0.012
create_price "Platinum-Hourly-Standard"  "platinum-hourly-standard"  "hour" 0.015
create_price "Diamond-Hourly-Standard"   "diamond-hourly-standard"   "hour" 0.020

# =============================
# HOURLY - ENTERPRISE
# =============================
create_price "Archive-Hourly-Enterprise"  "archive-hourly-enterprise"  "hour" 0.006
create_price "Bronze-Hourly-Enterprise"   "bronze-hourly-enterprise"   "hour" 0.009
create_price "Silver-Hourly-Enterprise"   "silver-hourly-enterprise"   "hour" 0.011
create_price "Gold-Hourly-Enterprise"     "gold-hourly-enterprise"     "hour" 0.013
create_price "Platinum-Hourly-Enterprise" "platinum-hourly-enterprise" "hour" 0.016
create_price "Diamond-Hourly-Enterprise"  "diamond-hourly-enterprise"  "hour" 0.021

# =============================
# HOURLY - PARTNER
# =============================
create_price "Archive-Hourly-Partner"  "archive-hourly-partner"  "hour" 0.004
create_price "Bronze-Hourly-Partner"   "bronze-hourly-partner"   "hour" 0.007
create_price "Silver-Hourly-Partner"   "silver-hourly-partner"   "hour" 0.009
create_price "Gold-Hourly-Partner"     "gold-hourly-partner"     "hour" 0.011
create_price "Platinum-Hourly-Partner" "platinum-hourly-partner" "hour" 0.014
create_price "Diamond-Hourly-Partner"  "diamond-hourly-partner"  "hour" 0.019

# =============================
# MONTHLY - STANDARD
# =============================
create_price "Archive-Monthly-Standard"   "archive-monthly-standard"   "month" 0.50
create_price "Bronze-Monthly-Standard"    "bronze-monthly-standard"    "month" 0.80
create_price "Silver-Monthly-Standard"    "silver-monthly-standard"    "month" 0.10
create_price "Gold-Monthly-Standard"      "gold-monthly-standard"      "month" 0.12
create_price "Platinum-Monthly-Standard"  "platinum-monthly-standard"  "month" 0.15
create_price "Diamond-Monthly-Standard"   "diamond-monthly-standard"   "month" 0.20

# =============================
# MONTHLY - ENTERPRISE
# =============================
create_price "Archive-Monthly-Enterprise"  "archive-monthly-enterprise"  "month" 0.60
create_price "Bronze-Monthly-Enterprise"   "bronze-monthly-enterprise"   "month" 0.90
create_price "Silver-Monthly-Enterprise"   "silver-monthly-enterprise"   "month" 0.11
create_price "Gold-Monthly-Enterprise"     "gold-monthly-enterprise"     "month" 0.13
create_price "Platinum-Monthly-Enterprise" "platinum-monthly-enterprise" "month" 0.16
create_price "Diamond-Monthly-Enterprise"  "diamond-monthly-enterprise"  "month" 0.21

# =============================
# MONTHLY - PARTNER
# =============================
create_price "Archive-Monthly-Partner"  "archive-monthly-partner"  "month" 0.40
create_price "Bronze-Monthly-Partner"   "bronze-monthly-partner"   "month" 0.70
create_price "Silver-Monthly-Partner"   "silver-monthly-partner"   "month" 0.90
create_price "Gold-Monthly-Partner"     "gold-monthly-partner"     "month" 0.11
create_price "Platinum-Monthly-Partner" "platinum-monthly-partner" "month" 0.14
create_price "Diamond-Monthly-Partner"  "diamond-monthly-partner"  "month" 0.19

echo "Completed."

