#!/bin/sh

MODE="$1"

case "$MODE" in
  lan)
    cp ~/.ssh/config.holy-lan ~/.ssh/config
    chmod 600 ~/.ssh/config
    echo "holy-cluster SSH mode: LAN"
    ;;
  remote)
    cp ~/.ssh/config.holy-remote ~/.ssh/config
    chmod 600 ~/.ssh/config
    echo "holy-cluster SSH mode: REMOTE via Tailscale/ARCHIVE-09"
    ;;
  *)
    echo "Usage: holy_net.sh lan|remote"
    exit 1
    ;;
esac
