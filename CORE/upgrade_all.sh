#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
CLI=$BASE/CORE/trikos

echo "[*] Upgrading Trikos → full system"

mkdir -p $BASE/{REL/graph,AGENTS/models}

# -----------------------
# MODELS
# -----------------------

cat > $BASE/AGENTS/models/score_len << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"
LEN=${#INPUT}
echo $((1000 - LEN))
EOM

cat > $BASE/AGENTS/models/echo << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
echo " [echo:$1]"
EOM

cat > $BASE/AGENTS/models/reverse << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
echo " $(echo "$1" | rev)"
EOM

chmod +x $BASE/AGENTS/models/*

# -----------------------
# REWRITE CLI CLEAN
# -----------------------

cat > $CLI << 'EOC'
#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
DATA_STATES="$BASE/DATA/states"
DATA_DELTAS="$BASE/DATA/deltas"
REL="$BASE/REL"
MODELS="$BASE/AGENTS/models"

cmd="$1"
shift

hash() { echo -n "$1" | sha256sum | cut -d' ' -f1; }

case "$cmd" in

state)
  DATA="$*"
  ID=$(hash "$DATA")
  echo "$DATA" > "$DATA_STATES/$ID"
  echo "$ID" > "$REL/latest"
  echo "STATE: $ID"
  ;;

add)
  DELTA="$*"
  PREV=$(cat "$REL/latest")
  BASE_STATE=$(cat "$DATA_STATES/$PREV")

  NEW="$BASE_STATE$DELTA"
  NEW_ID=$(hash "$NEW")
  DELTA_ID=$(hash "$DELTA")

  echo "$DELTA" > "$DATA_DELTAS/$DELTA_ID"
  echo "$NEW" > "$DATA_STATES/$NEW_ID"

  echo "$PREV -> $DELTA_ID -> $NEW_ID" >> "$REL/chain.log"
  echo "$NEW_ID" > "$REL/latest"

  echo "STATE: $NEW_ID"
  ;;

show)
  cat "$DATA_STATES/$(cat "$REL/latest")"
  echo
  ;;

# -----------------------
# SCORE GRAPH
# -----------------------

score)
  MODEL="$1"
  SCORE_MODEL="$2"

  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA_STATES/$PREV")

  DELTA=$("$MODELS/$MODEL" "$STATE")
  NEW="$STATE$DELTA"

  SCORE=$("$MODELS/$SCORE_MODEL" "$NEW")

  NEW_ID=$(hash "$NEW")
  DELTA_ID=$(hash "$DELTA")

  echo "$NEW" > "$DATA_STATES/$NEW_ID"
  echo "$DELTA" > "$DATA_DELTAS/$DELTA_ID"

  echo "$PREV -> $DELTA_ID -> $NEW_ID | score=$SCORE" >> "$REL/graph/graph.log"

  echo "$NEW_ID $SCORE"
  ;;

# -----------------------
# PREDICT (NO COMMIT)
# -----------------------

predict)
  MODEL="$1"
  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA_STATES/$PREV")

  DELTA=$("$MODELS/$MODEL" "$STATE")
  echo "PREDICT:"
  echo "$STATE$DELTA"
  ;;

# -----------------------
# BEST SELECTION
# -----------------------

best)
  sort -t= -k2 -nr "$REL/graph/graph.log" | head -n1
  ;;

# -----------------------
# MULTI-PREDICT
# -----------------------

multi)
  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA_STATES/$PREV")

  for m in "$MODELS"/*; do
    NAME=$(basename "$m")
    DELTA=$("$m" "$STATE")
    NEW="$STATE$DELTA"
    LEN=${#NEW}
    SCORE=$((1000 - LEN))
    echo "$NAME → score=$SCORE → $NEW"
  done
  ;;

*)
  echo "Commands:"
  echo "  trikos state 'data'"
  echo "  trikos add 'delta'"
  echo "  trikos show"
  echo "  trikos score model score_model"
  echo "  trikos predict model"
  echo "  trikos multi"
  echo "  trikos best"
  ;;
esac
EOC

chmod +x $CLI
cp $CLI $PREFIX/bin/trikos

echo "[✓] FULL SYSTEM READY"
