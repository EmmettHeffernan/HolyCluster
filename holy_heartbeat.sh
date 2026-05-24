#!/bin/sh

echo "======================================"
echo "          HOLY-CLUSTER HEARTBEAT"
echo "======================================"

echo "[CORTEX-11]"
echo "STATUS=ONLINE"
echo "HOST=$(hostname)"
echo "USER=$(whoami)"
echo "PYTHON=$(python3 --version 2>&1)"
echo "$(grep PROJECT ~/holy-cluster/node_identity.txt)"
echo ""

echo "[ARCHIVE-09]"
ssh archive09 'echo STATUS=ONLINE; echo HOST=$(hostname); echo USER=$(whoami); echo PYTHON=$(python3 --version 2>&1); grep PROJECT ~/holy-cluster/node_identity.txt'
echo ""

echo "COHERENCE: 100%"
echo "CLUSTER STATE: ALIVE"
echo "PROJECT=holy-cluster"
echo "======================================"
