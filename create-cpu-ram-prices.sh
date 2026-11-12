#!/bin/bash

MORPHEUS="https://"
TOKEN=""

create_price() {

    NAME="$1"
    CODE="$2"
    UNIT="$3"
    TYPE="$4"
    ADDITIONAL="$5"

    TMPFILE="/tmp/price-$$.json"

    cat > "$TMPFILE" <<EOF
{
  "price": {
    "name": "$NAME",
    "code": "$CODE",
    "active": true,
    "priceType": "$TYPE",
    "priceUnit": "$UNIT",
    "additionalPriceUnit": "$ADDITIONAL",
    "price": 0,
    "cost": 0,
    "currency": "CZK",
    "incurCharges": "running"
  }
}
EOF

    echo ""
    echo "Creating: $NAME"

    RESPONSE=$(curl -sk \
      -X POST \
      -H "Authorization: BEARER $TOKEN" \
      -H "Content-Type: application/json" \
      "$MORPHEUS/api/prices" \
      -d @"$TMPFILE")

    echo "$RESPONSE" | jq .

    rm -f "$TMPFILE"
}

#########################################
# CPU - Cores Only
#########################################

create_price \
  "Master CPU Hourly" \
  "MCH" \
  "hour" \
  "cores" \
  "#"

create_price \
  "Master CPU Monthly" \
  "MCM" \
  "month" \
  "cores" \
  "#"

#########################################
# Memory - Memory Only
#########################################

create_price \
  "Master Mem Hourly" \
  "MMH" \
  "hour" \
  "memory" \
  "MB"

create_price \
  "Master Mem Monthly" \
  "MMM" \
  "month" \
  "memory" \
  "MB"

echo ""
echo "=================================="
echo "CPU and Memory Prices Created"
echo "=================================="
