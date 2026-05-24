#!/bin/sh

TEXT="$1"
FRAMES="${2:-96}"

[ -z "$TEXT" ] && TEXT="HOLY-CLUSTER ONLINE"

printf '%s' "$TEXT" | ssh cortex11 'cat > ~/holy-cluster/title_text.txt'
printf '%s' "$FRAMES" | ssh cortex11 'cat > ~/holy-cluster/title_frames.txt'

ssh cortex11 'cd ~/holy-cluster && ./title_head.sh'
ssh cortex11 'LATEST=$(ls -td ~/holy-cluster/title_renders/title_*/index.html 2>/dev/null | head -1); echo "$LATEST"; open "$LATEST"'
