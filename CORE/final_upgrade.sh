#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
CLI=$BASE/CORE/trikos

mkdir -p $BASE/{REL/goals,REL/memory,AGENTS/models}

echo "[*] Installing goal + probability + real-ai..."

# -----------------------
# GOAL
# -----------------------
cat > $BASE/REL/goals/goal.txt << 'EOM'
optimize
EOM

# -----------------------
# PROBABILISTIC SCORE
# -----------------------
cat > $BASE/AGENTS/models/score_prob << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"

LEN=${#INPUT}
RAND=$((RANDOM % 100))

echo $((1000 - LEN + RAND))
EOM

# -----------------------
# REAL AI HOOK (API-ready)
# -----------------------
cat > $BASE/AGENTS/models/agent_real << 'EOM'
#!/data/data/com.termux/files/usr/bin/bash
INPUT="$1"

# placeholder – byt till curl/API senare
echo " [real_ai:$INPUT]"
EOM

chmod +x $BASE/AGENTS/models/*

# -----------------------
# FINAL CLI
# -----------------------

cat > $CLI << 'EOC'
#!/data/data/com.termux/files/usr/bin/bash

BASE=~/trikos
DATA="$BASE/DATA"
REL="$BASE/REL"
MODELS="$BASE/AGENTS/models"

hash(){ echo -n "$1" | sha256sum | cut -d' ' -f1; }

goal(){ cat "$REL/goals/goal.txt"; }

remember(){ echo "$1" >> "$REL/memory/history.log"; }

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
# PROBABILISTIC EVOLVE
# -----------------------
evolve)
  STEPS=${1:-5}

  for i in $(seq 1 $STEPS); do
    echo "STEP $i (goal: $(goal))"

    PREV=$(cat "$REL/latest")
    STATE=$(cat "$DATA/states/$PREV")

    BEST_SCORE=-999999
    BEST_STATE=""

    for m in "$MODELS"/*; do
      NAME=$(basename "$m")

      DELTA=$("$m" "$STATE")
      NEW="$STATE$DELTA"

      SCORE=$("$MODELS/score_prob" "$NEW")

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
  done
  ;;

# -----------------------
# REAL AI CALL
# -----------------------
ai)
  PREV=$(cat "$REL/latest")
  STATE=$(cat "$DATA/states/$PREV")

  "$MODELS/agent_real" "$STATE"
  ;;

# -----------------------
# SET GOAL
# -----------------------
goal)
  echo "$*" > "$REL/goals/goal.txt"
  ;;

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
  echo "  trikos goal 'text'"
  echo "  trikos ai"
  echo "  trikos memory"
  echo "  trikos show"
  ;;
esac
EOC

chmod +x $CLI
cp $CLI $PREFIX/bin/trikos

echo "[✓] FINAL SYSTEM READY"
