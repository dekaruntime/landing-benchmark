#!/usr/bin/env bash
# Creates the deka project the benchmark serves. Separate from run.sh because it
# touches the network and only needs doing once.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEKA="${DEKA:-deka}"
rm -rf "$HERE/.deka-project"
mkdir -p "$HERE/.deka-project"
cd "$HERE/.deka-project"
"$DEKA" init >/dev/null
cp "$HERE/servers/main.ds" app/main.ds
echo "ready: $HERE/.deka-project"
