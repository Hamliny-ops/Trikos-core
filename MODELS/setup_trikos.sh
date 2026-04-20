#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos

echo "[*] Creating structure..."
mkdir -p $BASE/{A_states,B_deltas,AB_index,CORE,MODELS}

echo "[*] Creating CLI..."

cat > $BASE/CORE/trikos << 'EOC'
#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos

cmd="$1"
shift

case "$cmd" in

init)
  mkdir -p $BASE/{A_states,B_deltas,AB_index,CORE,MODELS}
  echo "Trikos initialized."
  ;;

state)
  DATA="$*"
  if [ -z "$DATA" ]; then
    read -p "Enter state: " DATA
  fi

  ID=$(echo -n "$DATA" | sha256sum | cut -d' ' -f1)
  echo "$DATA" > $BASE/A_states/$ID
  echo "$ID" > $BASE/AB_index/latest

  echo "STATE: $ID"
  ;;

add)
  DELTA="$*"
  if [ -z "$DELTA" ]; then
    read -p "Enter delta: " DELTA
  fi

  PREV=$(cat $BASE/AB_index/latest)
  BASE_STATE=$(cat $BASE/A_states/$PREV)

  NEW_DATA="$BASE_STATE$DELTA"

  NEW_ID=$(echo -n "$NEW_DATA" | sha256sum | cut -d' ' -f1)
  DELTA_ID=$(echo -n "$DELTA" | sha256sum | cut -d' ' -f1)

  echo "$DELTA" > $BASE/B_deltas/$DELTA_ID
  echo "$NEW_DATA" > $BASE/A_states/$NEW_ID

  echo "$PREV -> $DELTA_ID -> $NEW_ID" >> $BASE/AB_index/chain.log
  echo "$NEW_ID" > $BASE/AB_index/latest

  echo "DELTA: $DELTA_ID"
  echo "STATE: $NEW_ID"
  ;;

show)
  ID=$(cat $BASE/AB_index/latest)
  echo "STATE ($ID):"
  cat $BASE/A_states/$ID
  echo
  ;;

log)
  cat $BASE/AB_index/chain.log 2>/dev/null || echo "No chain yet"
  ;;

run)
  MODEL="$1"

  if [ -z "$MODEL" ]; then
    echo "Usage: trikos run model"
    exit 1
  fi

  PREV=$(cat $BASE/AB_index/latest)
  STATE=$(cat $BASE/A_states/$PREV)

  if [ ! -f "$BASE/MODELS/$MODEL" ]; then
    echo "Model not found: $MODEL"
    exit 1
  fi

  DELTA=$($BASE/MODELS/$MODEL "$STATE")

  $0 add "$DELTA"
  ;;

*)
  echo "Usage:"
  echo "  trikos init"
  echo "  trikos state 'data'"
  echo "  trikos add 'delta'"
  echo "  trikos show"
  echo "  trikos log"
  echo "  trikos run model"
  ;;
esac
EOC

chmod +x $BASE/CORE/trikos

echo "[*] Installing CLI globally..."
cp $BASE/CORE/trikos $PREFIX/bin/trikos

echo "[*] Creating models..."

cat > $BASE/MODELS/echo << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"
echo " [echo:$INPUT]"
EOM

cat > $BASE/MODELS/reverse << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"
echo " $(echo "$INPUT" | rev)"
EOM

chmod +x $BASE/MODELS/*

echo "[✓] DONE"
echo ""
echo "Try:"
echo "  trikos init"
echo "  trikos state \"hello\""
echo "  trikos run echo"
echo "  trikos run reverse"
echo "  trikos show"
