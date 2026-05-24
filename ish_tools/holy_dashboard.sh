#!/bin/sh

CMD="${1:-open}"

case "$CMD" in
  start)
    ssh cortex11 'pkill -f "holy_dashboard.py" 2>/dev/null || true'
    ssh cortex11 'cd ~/holy-cluster && /usr/local/bin/python3 holy_dashboard.py >/tmp/holy_dashboard.log 2>&1 &'
    echo "Dashboard started."
    ;;
  open)
    ssh cortex11 'cd ~/holy-cluster && /usr/local/bin/python3 holy_dashboard.py >/tmp/holy_dashboard.log 2>&1 &'
    ssh cortex11 'open http://127.0.0.1:8790'
    echo "Dashboard opened."
    ;;
  stop)
    ssh cortex11 'pkill -f "holy_dashboard.py" 2>/dev/null || true'
    echo "Dashboard stopped."
    ;;
  log)
    ssh cortex11 'tail -n 80 /tmp/holy_dashboard.log 2>/dev/null || echo "No dashboard log."'
    ;;
  *)
    echo "Usage: holy_dashboard.sh start|open|stop|log"
    exit 1
    ;;
esac
