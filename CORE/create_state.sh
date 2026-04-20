#!/data/data/com.termux/files/usr/bin/bash

DATA="$1"

if [ -z "$DATA" ]; then
  read -p "Enter state data: " DATA
fi

ID=$(echo -n "$DATA" | sha256sum | cut -d' ' -f1)

echo "$DATA" > ../A_states/$ID
echo "$ID" > ../AB_index/latest

echo "STATE CREATED: $ID"
