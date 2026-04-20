#!/data/data/com.termux/files/usr/bin/bash

INPUT="$1"

LEN=${#INPUT}
UNIQ=$(echo -n "$INPUT" | fold -w1 | sort -u | wc -l)

echo $(( (UNIQ * 20) - LEN ))
