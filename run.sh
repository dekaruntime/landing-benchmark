#!/usr/bin/env bash
# Orchestration only -- every measurement is taken by oha, every server is a
# real runtime. Nothing here computes a result.
set -uo pipefail

DUR="${DUR:-10s}"
CONN="${CONN:-50}"
RUNS="${RUNS:-3}"
WARMUP="${WARMUP:-5s}"
MODE="${1:-default}"          # default | tuned | all
OHA="${OHA:-oha}"
DEKA="${DEKA:-deka}"
HERE="$(cd "$(dirname "$0")" && pwd)"

for tool in "$OHA" node bun; do
  command -v "$tool" >/dev/null 2>&1 || { echo "missing: $tool"; exit 1; }
done
command -v "$DEKA" >/dev/null 2>&1 || { echo "missing: deka (set DEKA=/path/to/deka)"; exit 1; }

CORES=$( (nproc 2>/dev/null) || sysctl -n hw.ncpu )
cleanup() { pkill -f "servers/node.mjs" 2>/dev/null; pkill -f "servers/node-cluster.mjs" 2>/dev/null
            pkill -f "servers/bun" 2>/dev/null; pkill -f "$DEKA serve" 2>/dev/null; }
trap cleanup EXIT
cleanup; sleep 1

# median of $RUNS x $DUR, after a warmup that is discarded
measure() {
  local name="$1" port="$2" cfg="$3" rps=()
  "$OHA" -z "$WARMUP" -c "$CONN" --no-tui "http://127.0.0.1:$port/" >/dev/null 2>&1
  for _ in $(seq 1 "$RUNS"); do
    rps+=("$("$OHA" -z "$DUR" -c "$CONN" --no-tui "http://127.0.0.1:$port/" 2>/dev/null \
           | awk '/Requests\/sec/ {print $2; exit}')")
  done
  local med
  med=$(printf '%s\n' "${rps[@]}" | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}')
  printf '| %-18s | %-24s | %14.0f | %s |\n' "$name" "$cfg" "$med" "$(printf '%.0f ' "${rps[@]}")"
}

echo "host   : $( (sysctl -n machdep.cpu.brand_string 2>/dev/null) || grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- ), ${CORES} cores"
echo "load   : $(uptime | sed 's/.*averages*: //')"
echo "node   : $(node --version)   bun: $(bun --version)   deka: $("$DEKA" --version 2>/dev/null | head -1)"
echo "oha    : $("$OHA" --version)"
echo "params : ${CONN} connections, ${DUR} per run, median of ${RUNS}, ${WARMUP} warmup discarded"
echo
echo "| runtime            | configuration            |          req/s | runs |"
echo "|--------------------|--------------------------|----------------|------|"

if [ "$MODE" = default ] || [ "$MODE" = all ]; then
  node "$HERE/servers/node.mjs" & sleep 3
  measure "Node"  3011 "one event loop (default)"; cleanup; sleep 1

  bun "$HERE/servers/bun.js" & sleep 3
  measure "Bun"   3012 "one event loop (default)"; cleanup; sleep 1

  ( cd "$HERE/.deka-project" && "$DEKA" serve --port 3010 >/dev/null 2>&1 ) & sleep 14
  measure "deka"  3010 "one loop per core (default)"; cleanup; sleep 1
fi

if [ "$MODE" = tuned ] || [ "$MODE" = all ]; then
  WORKERS="$CORES" node "$HERE/servers/node-cluster.mjs" & sleep 5
  measure "Node cluster" 3013 "${CORES} workers (opt-in)"; cleanup; sleep 1

  for _ in $(seq 1 "$CORES"); do bun "$HERE/servers/bun-reuseport.js" & done; sleep 4
  measure "Bun reusePort" 3014 "${CORES} processes (opt-in)"; cleanup; sleep 1
fi
