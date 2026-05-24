#!/bin/sh

TYPE="$1"

case "$TYPE" in
  title)
    ssh cortex11 'LATEST=$(ls -td ~/holy-cluster/title_renders/title_*/index.html 2>/dev/null | head -1); echo "$LATEST"; [ -n "$LATEST" ] && open "$LATEST"'
    ;;
  render|entity-render)
    ssh cortex11 'LATEST=$(ls -td ~/holy-cluster/renders/mini_*/index.html 2>/dev/null | head -1); echo "$LATEST"; [ -n "$LATEST" ] && open "$LATEST"'
    ;;
  face)
    ssh cortex11 'cd ~/holy-cluster/entity_ui && python3 -m http.server 8788 >/tmp/holy_entity_server.log 2>&1 & open http://localhost:8788'
    ;;
  compute)
    ssh cortex11 'LATEST=$(ls -t ~/holy-cluster/optimized_*.txt 2>/dev/null | head -1); echo "$LATEST"; [ -n "$LATEST" ] && open "$LATEST"'
    ;;
  folder)
    ssh cortex11 'open ~/holy-cluster'
    ;;
  *)
    echo "Usage:"
    echo "  holy open title"
    echo "  holy open render"
    echo "  holy open face"
    echo "  holy open compute"
    echo "  holy open folder"
    exit 1
    ;;
esac
