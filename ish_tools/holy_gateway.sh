#!/bin/sh

PASS=0
FAIL=0

ok() {
  echo "OK"
  PASS=$((PASS + 1))
}

bad() {
  echo "FAILED"
  FAIL=$((FAIL + 1))
}

check() {
  NAME="$1"
  shift

  echo ""
  echo "[$NAME]"
  if "$@"; then
    ok
  else
    bad
  fi
}

echo "======================================"
echo "        HOLY-CLUSTER GATEWAY"
echo "======================================"

echo ""
echo "[LOCAL SSH MODE]"
if [ -f "$HOME/holy-cluster/.holy_mode" ]; then
  echo "holy_mode=$(cat "$HOME/holy-cluster/.holy_mode")"
else
  echo "holy_mode=NORMAL"
fi

echo ""
echo "[SSH CONFIG TARGETS]"
grep -A5 -E "^Host archive09$|^Host cortex11$" ~/.ssh/config 2>/dev/null || echo "No archive09/cortex11 blocks found."

check "iSH -> ARCHIVE-09 over current SSH config" \
  ssh -o ConnectTimeout=8 archive09 'hostname; whoami; date'

check "ARCHIVE-09 Tailscale identity" \
  ssh -o ConnectTimeout=8 archive09 'tailscale ip -4; tailscale status | head -10'

check "ARCHIVE-09 can see CORTEX-11 on home LAN" \
  ssh -o ConnectTimeout=8 archive09 'ping -c 2 -W 2 10.0.0.75'

check "iSH -> CORTEX-11 through configured route" \
  ssh -o ConnectTimeout=12 cortex11 'hostname; whoami; date'

check "CORTEX-11 HolyOps folder exists" \
  ssh -o ConnectTimeout=12 cortex11 'test -d ~/holy-cluster && ls ~/holy-cluster | head -5'

check "CORTEX-11 queue database reachable" \
  ssh -o ConnectTimeout=12 cortex11 'test -f ~/holy-cluster/queue/holy_queue.db || test -x ~/holy-cluster/holy_queue.py'

check "CORTEX-11 artifact registry reachable" \
  ssh -o ConnectTimeout=12 cortex11 'test -f ~/holy-cluster/artifacts/artifacts.db || test -x ~/holy-cluster/holy_artifact.py'

echo ""
echo "======================================"
echo "PASS=$PASS"
echo "FAIL=$FAIL"
echo "======================================"

if [ "$FAIL" -eq 0 ]; then
  echo "GATEWAY STATE: HEALTHY"
  exit 0
else
  echo "GATEWAY STATE: NEEDS ATTENTION"
  exit 1
fi
