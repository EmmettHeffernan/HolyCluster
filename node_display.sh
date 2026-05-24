#!/bin/sh

BASE="$HOME/holy-cluster"
FEED="$BASE/terminal_feed.txt"

mkdir -p "$BASE"
touch "$FEED"

while true; do
  clear

  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                    HOLY-CLUSTER NODE                     ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  echo " NODE:      CORTEX-11"
  echo " ROLE:      CORTEX / CONTROL / GENERATION NODE"
  echo " PROJECT:   holy-cluster"
  echo " HOST:      $(hostname)"
  echo " USER:      $(whoami)"
  echo " TIME:      $(date)"
  echo " STATE:     ONLINE"
  echo ""
  echo "────────────────────────────────────────────────────────────"
  echo " ACTIVE DISPLAY BUFFER"
  echo "────────────────────────────────────────────────────────────"
  echo ""

  cat "$FEED"

  echo ""
  echo "────────────────────────────────────────────────────────────"
  echo " Refreshing display once per second..."
  echo " Press Ctrl+C to close this display."
  echo "────────────────────────────────────────────────────────────"

  sleep 1
done
