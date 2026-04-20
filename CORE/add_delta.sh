#!/data/data/com.termux/files/usr/bin/bash

DELTA="$1"

if [ -z "$DELTA" ]; then
  read -p "Enter delta: " DELTA
fi

PREV=$(cat ../AB_index/latest)
BASE=$(cat ../A_states/$PREV)

NEW_DATA="$BASE$DELTA"

NEW_ID=$(echo -n "$NEW_DATA" | sha256sum | cut -d' ' -f1)
DELTA_ID=$(echo -n "$DELTA" | sha256sum | cut -d' ' -f1)

echo "$DELTA" > ../B_deltas/$DELTA_ID
echo "$NEW_DATA" > ../A_states/$NEW_ID

echo "$PREV -> $DELTA_ID -> $NEW_ID" >> ../AB_index/chain.log
echo "$NEW_ID" > ../AB_index/latest

echo "DELTA APPLIED: $DELTA_ID"
echo "NEW STATE: $NEW_ID"
