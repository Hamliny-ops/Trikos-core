#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
CLI=$BASE/CORE/trikos

mkdir -p $BASE/REL/graph/nodes
mkdir -p $BASE/AGENTS/models

echo "[*] Installing OBJ score model..."

cat > $BASE/AGENTS/models/score_obj << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"

LEN=${#INPUT}
UNIQ=$(echo -n "$INPUT" | fold -w1 | sort -u | wc -l)

# balans mellan komplexitet + kompression
echo $(( (UNIQ * 20) - LEN ))
EOM

chmod +x $BASE/AGENTS/models/score_obj

echo "[*] Rewriting CLI with evolve + graph..."

cat > $CLI << 'EOC'
#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
DATA="$BASE/DATA"
REL="$BASE/REL"
MODELS="$BASE/AGENTS/models"

hash(){ echo -n "$1" | sha256sum | cut -d' ' -f1; }

save_node(){
  ID="$1"
  STATE="$2"
  SCORE="$3"

  FILE="$REL/graph/nodes/$ID.json"

  echo "{
  \"id\":\"$ID\",
  \"score\":$SCORE,
  \"len\":${#STATE}
}" > "$FILE"
}

cmd="$1"; shift

case "$cmd" in

state)
  DATA_IN="$*"
  ID=$(hash "$DATA_IN")
  echo "$DATA_IN" > "$DATA/states/$ID"
  echo "$ID" > "$REL/latest"
  echo "STATE: $ID"
  ;;

score)
  MODEL="$1"
  SCORE_MODEL="$2"

  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA/states/$PREV")

  DELTA=$("$MODELS/$MODEL" "$STATE")
  NEW="$STATE$DELTA"

  SCORE=$("$MODELS/$SCORE_MODEL" "$NEW")

  ID=$(hash "$NEW")
  DID=$(hash "$DELTA")

  echo "$NEW" > "$DATA/states/$ID"
  echo "$DELTA" > "$DATA/deltas/$DID"

  echo "$PREV -> $DID -> $ID | score=$SCORE" >> "$REL/graph/graph.log"

  save_node "$ID" "$NEW" "$SCORE"

  echo "$ID $SCORE"
  ;;

multi)
  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA/states/$PREV")

  BEST_SCORE=-999999
  BEST_ID=""

  for m in "$MODELS"/*; do
    NAME=$(basename "$m")
    DELTA=$("$m" "$STATE")
    NEW="$STATE$DELTA"

    SCORE=$("$MODELS/score_obj" "$NEW")

    ID=$(hash "$NEW")

    echo "$NAME → score=$SCORE"

    if [ "$SCORE" -gt "$BEST_SCORE" ]; then
      BEST_SCORE=$SCORE
      BEST_ID=$ID
      BEST_STATE="$NEW"
    fi
  done

  echo "BEST: $BEST_SCORE"
  echo "$BEST_STATE" > "$DATA/states/$BEST_ID"
  echo "$BEST_ID" > "$REL/latest"
  ;;

evolve)
  STEPS=${1:-5}

  for i in $(seq 1 $STEPS); do
    echo "STEP $i"
    "$0" multi
  done
  ;;

best)
  sort -t= -k2 -nr "$REL/graph/graph.log" | head -n1
  ;;

show)
  cat "$DATA/states/$(cat "$REL/latest")"
  echo
  ;;

*)
  echo "Commands:"
  echo "  trikos state 'data'"
  echo "  trikos score model score_model"
  echo "  trikos multi"
  echo "  trikos evolve [steps]"
  echo "  trikos best"
  echo "  trikos show"
  ;;
esac
EOC

chmod +x $CLI
cp $CLI $PREFIX/bin/trikos

echo "[✓] EVOLVE SYSTEM READY"
