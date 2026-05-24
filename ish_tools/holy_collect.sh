#!/bin/sh

echo "======================================"
echo "          HOLY-CLUSTER COLLECT"
echo "======================================"

echo ""
echo "[LATEST TITLE RENDER]"
ssh cortex11 'ls -td ~/holy-cluster/title_renders/title_* 2>/dev/null | head -1 || echo "none"'

echo ""
echo "[LATEST ENTITY RENDER]"
ssh cortex11 'ls -td ~/holy-cluster/renders/mini_* 2>/dev/null | head -1 || echo "none"'

echo ""
echo "[LATEST COMPUTE REPORT]"
ssh cortex11 'ls -t ~/holy-cluster/optimized_*.txt 2>/dev/null | head -1 || echo "none"'

echo ""
echo "[LATEST CHECKPOINT TAR]"
ssh cortex11 'ls -t ~/holy-cluster-checkpoint-*.tar.gz 2>/dev/null | head -1 || echo "none"'

echo ""
echo "[LATEST GIT COMMIT]"
ssh cortex11 'cd ~/holy-cluster && git log --oneline -1 2>/dev/null || echo "none"'

echo ""
echo "======================================"
