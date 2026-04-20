#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
CLI=$BASE/CORE/trikos

mkdir -p $BASE/{REL/memory,AGENTS/models,REL/graph/nodes}

echo "[*] Installing mutation + memory + agent models..."

# -----------------------
# MUTATION MODEL
# -----------------------
cat > $BASE/AGENTS/models/mutate << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"

# enkel mutation: shuffle + slice
MUT=$(echo "$INPUT" | rev | cut -c1-10)
echo " [$MUT]"
EOM

# -----------------------
# MEMORY SCORE
# -----------------------
cat > $BASE/AGENTS/models/score_mem << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"

LEN=${#INPUT}
COUNT=$(grep -c "$INPUT" ~/trikos/REL/memory/history.log 2>/dev/null)

# belöna nytt, straffa repetition
echo $((1000 - LEN - (COUNT * 50)))
EOM

# -----------------------
# AGENT AI (placeholder)
# -----------------------
cat > $BASE/AGENTS/models/agent_ai << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"

# placeholder för riktig AI
echo " [ai:$(echo "$INPUT" | tr 'a-z' 'n-za-m' | cut -c1-20)]"
EOM

chmod +x $BASE/AGENTS/models/*

# -----------------------
# FULL CLI
# -----------------------

cat > $CLI << 'EOC'
#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
DATA="$BASE/DATA"
REL="$BASE/REL"
MODELS="$BASE/AGENTS/models"

hash(){ echo -n "$1" | sha256sum | cut -d' ' -f1; }

remember(){
  echo "$1" >> "$REL/memory/history.log"
}

cmd="$1"; shift

case "$cmd" in

state)
  S="$*"
  ID=$(hash "$S")
  echo "$S" > "$DATA/states/$ID"
  echo "$ID" > "$REL/latest"
  remember "$S"
  ;;

# -----------------------
# MULTI + SELECTION
# -----------------------
multi)
  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA/states/$PREV")

  BEST_SCORE=-999999
  BEST_STATE=""

  for m in "$MODELS"/*; do
    NAME=$(basename "$m")

    DELTA=$("$m" "$STATE")
    NEW="$STATE$DELTA"

    SCORE=$("$MODELS/score_mem" "$NEW")

    echo "$NAME → $SCORE"

    if [ "$SCORE" -gt "$BEST_SCORE" ]; then
      BEST_SCORE=$SCORE
      BEST_STATE="$NEW"
    fi
  done

  ID=$(hash "$BEST_STATE")
  echo "$BEST_STATE" > "$DATA/states/$ID"
  echo "$ID" > "$REL/latest"

  remember "$BEST_STATE"

  echo "BEST: $BEST_SCORE"
  ;;

# -----------------------
# EVOLVE LOOP
# -----------------------
evolve)
  STEPS=${1:-5}

  for i in $(seq 1 $STEPS); do
    echo "STEP $i"
    "$0" multi
  done
  ;;

# -----------------------
# MUTATION BURST
# -----------------------
mutate)
  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA/states/$PREV")

  for i in {1..5}; do
    DELTA=$("$MODELS/mutate" "$STATE")
    echo "$STATE$DELTA"
  done
  ;;

# -----------------------
# MEMORY VIEW
# -----------------------
memory)
  tail -n 20 "$REL/memory/history.log"
  ;;

show)
  cat "$DATA/states/$(cat "$REL/latest")"
  echo
  ;;

*)
  echo "Commands:"
  echo "  trikos state 'data'"
  echo "  trikos evolve [n]"
  echo "  trikos mutate"
  echo "  trikos memory"
  echo "  trikos show"
  ;;
esac
EOC

chmod +x $CLI
cp $CLI $PREFIX/bin/trikos

echo "[✓] ULTIMATE SYSTEM READY"
