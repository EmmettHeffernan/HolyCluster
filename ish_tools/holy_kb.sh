#!/bin/sh

python3 - "$@" <<'PY' | ssh cortex11 'cd ~/holy-cluster && /usr/local/bin/python3 holy_kb.py rpc'
import json, sys
print(json.dumps({"args": sys.argv[1:]}))
PY
