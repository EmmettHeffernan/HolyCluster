#!/bin/sh

PASS=0
FAIL=0

check() {
  NAME="$1"
  shift

  echo ""
  echo "[$NAME]"
  if "$@"; then
    echo "OK"
    PASS=$((PASS + 1))
  else
    echo "FAILED"
    FAIL=$((FAIL + 1))
  fi
}

echo "======================================"
echo "          HOLY-CLUSTER DOCTOR"
echo "======================================"

check "iSH holy command" command -v holy

check "iSH -> ARCHIVE-09 SSH" \
  ssh archive09 'hostname; whoami; python3 --version'

check "iSH -> CORTEX-11 SSH" \
  ssh cortex11 'hostname; whoami; /usr/local/bin/python3 --version'

check "CORTEX-11 -> ARCHIVE-09 SSH" \
  ssh cortex11 'ssh archive09 "hostname; whoami"'

check "CORTEX optimized scheduler exists" \
  ssh cortex11 'test -x ~/holy-cluster/optimized_head.sh'

check "CORTEX multicore worker exists" \
  ssh cortex11 'test -x ~/holy-cluster/mc_worker.py'

check "ARCHIVE multicore worker exists" \
  ssh archive09 'test -x ~/holy-cluster/mc_worker.py'

check "CORTEX render script exists" \
  ssh cortex11 'test -x ~/holy-cluster/render_mini.sh'

check "Entity UI files exist" \
  ssh cortex11 'test -f ~/holy-cluster/entity_ui/index.html && test -f ~/holy-cluster/entity_ui/style.css && test -f ~/holy-cluster/entity_ui/app.js && test -f ~/holy-cluster/entity_ui/state.json'

check "CORTEX Git checkpoint exists" \
  ssh cortex11 'cd ~/holy-cluster && git log --oneline -1'

echo ""
echo "======================================"
echo "PASS=$PASS"
echo "FAIL=$FAIL"
echo "======================================"

if [ "$FAIL" -eq 0 ]; then
  echo "HOLY-CLUSTER STATE: HEALTHY"
  exit 0
else
  echo "HOLY-CLUSTER STATE: NEEDS ATTENTION"
  exit 1
fi
