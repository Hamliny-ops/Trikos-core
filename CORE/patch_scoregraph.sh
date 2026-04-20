#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
CLI=$BASE/CORE/trikos

echo "[*] Installing scoregraph clean..."

mkdir -p $BASE/REL/graph
mkdir -p $BASE/AGENTS/models

cat > $BASE/AGENTS/models/score_len << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"
LEN=${#INPUT}
echo $((1000 - LEN))
EOM

chmod +x $BASE/AGENTS/models/score_len

# Append command safely instead of awk injection
cat >> $CLI << 'EOC'

score_run)
  MODEL="$1"
  SCORE_MODEL="$2"

  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA_STATES/$PREV")

  DELTA=$("$MODELS/$MODEL" "$STATE")
  NEW_STATE="$STATE$DELTA"

  SCORE=$("$MODELS/$SCORE_MODEL" "$NEW_STATE")

  NEW_ID=$(echo -n "$NEW_STATE" | sha256sum | cut -d' ' -f1)
  DELTA_ID=$(echo -n "$DELTA" | sha256sum | cut -d' ' -f1)

  echo "$DELTA" > "$DATA_DELTAS/$DELTA_ID"
  echo "$NEW_STATE" > "$DATA_STATES/$NEW_ID"

  echo "$PREV -> $DELTA_ID -> $NEW_ID | score=$SCORE" >> "$REL/graph/graph.log"

  echo "DELTA: $DELTA_ID"
  echo "STATE: $NEW_ID"
  echo "SCORE: $SCORE"
  ;;
EOC

chmod +x $CLI

echo "[✓] Scoregraph ready"
