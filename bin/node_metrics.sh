#!/bin/sh

OS="$(uname -s)"
HOST="$(hostname)"
USER_NAME="$(whoami)"
KERNEL="$(uname -r)"
if [ -x /usr/local/bin/python3 ]; then
  PYTHON_VERSION="20 20 12 61 79 80 81 98 701 33 100 204 250 395 398 399 400/usr/local/bin/python3 --version 2>&1)"
elif [ -x /Library/Frameworks/Python.framework/Versions/3.11/bin/python3 ]; then
  PYTHON_VERSION="20 20 12 61 79 80 81 98 701 33 100 204 250 395 398 399 400/Library/Frameworks/Python.framework/Versions/3.11/bin/python3 --version 2>&1)"
else
  PYTHON_VERSION="20 20 12 61 79 80 81 98 701 33 100 204 250 395 398 399 400python3 --version 2>&1)"
fi
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

echo "NODE_METRICS_BEGIN"
echo "time=$NOW"
echo "host=$HOST"
echo "user=$USER_NAME"
echo "os=$OS"
echo "kernel=$KERNEL"
echo "python=$PYTHON_VERSION"

if [ "$OS" = "Linux" ]; then
  CPU_MODEL="$(grep -m 1 'model name' /proc/cpuinfo 2>/dev/null | cut -d ':' -f 2- | sed 's/^ //')"
  CPU_CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
  LOAD_AVG="$(cat /proc/loadavg 2>/dev/null | awk '{print $1","$2","$3}')"

  MEM_TOTAL_KB="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null)"
  MEM_AVAIL_KB="$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null)"

  if [ -n "$MEM_TOTAL_KB" ] && [ -n "$MEM_AVAIL_KB" ]; then
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
    MEM_USED_PCT=$((MEM_USED_KB * 100 / MEM_TOTAL_KB))
  else
    MEM_TOTAL_KB=unknown
    MEM_AVAIL_KB=unknown
    MEM_USED_PCT=unknown
  fi

  echo "cpu_model=$CPU_MODEL"
  echo "cpu_cores=$CPU_CORES"
  echo "load_avg_1_5_15=$LOAD_AVG"
  echo "mem_total_kb=$MEM_TOTAL_KB"
  echo "mem_available_kb=$MEM_AVAIL_KB"
  echo "mem_used_pct=$MEM_USED_PCT"
  df -h / 2>/dev/null | awk 'NR==2 {print "disk_total="$2; print "disk_used="$3; print "disk_avail="$4; print "disk_used_pct="$5}'
  echo "uptime=$(uptime -p 2>/dev/null || uptime)"
  echo "temp_c=unknown"

elif [ "$OS" = "Darwin" ]; then
  CPU_MODEL="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
  CPU_CORES="$(sysctl -n hw.ncpu 2>/dev/null || echo unknown)"
  MEM_TOTAL_BYTES="$(sysctl -n hw.memsize 2>/dev/null || echo unknown)"
  LOAD_AVG="$(sysctl -n vm.loadavg 2>/dev/null | tr -d '{}')"

  echo "cpu_model=$CPU_MODEL"
  echo "cpu_cores=$CPU_CORES"
  echo "load_avg_1_5_15=$LOAD_AVG"
  echo "mem_total_bytes=$MEM_TOTAL_BYTES"
  df -h / 2>/dev/null | awk 'NR==2 {print "disk_total="$2; print "disk_used="$3; print "disk_avail="$4; print "disk_used_pct="$5}'
  echo "uptime=$(uptime)"
  echo "temp_c=unavailable_without_extra_tools"

else
  echo "cpu_model=unknown"
  echo "cpu_cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
  echo "uptime=$(uptime 2>/dev/null || echo unknown)"
fi

echo "NODE_METRICS_END"
