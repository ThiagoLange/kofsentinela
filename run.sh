#!/usr/bin/env bash
# KofSentinela — ./run.sh once | poll | status
set -e
cd "$(dirname "$0")"

if ! command -v kof >/dev/null 2>&1; then
  export PATH="$HOME/.kof/bin:$PATH"
fi
command -v kof >/dev/null 2>&1 || { echo "ERRO: 'kof' não encontrado." >&2; exit 1; }

INTERVAL="${INTERVAL:-30}"

case "${1:-once}" in
  once)
    cd poller && exec kof run Main.kf
    ;;
  poll)
    cd poller
    while true; do
      kof run Main.kf || true
      sleep "$INTERVAL"
    done
    ;;
  status)
    cd status && exec kof run Main.kf
    ;;
  ui-build)
    cd ui && exec kof build Dashboard.kf --target js --output ui-dist
    ;;
  *)
    echo "uso: ./run.sh once | poll | status | ui-build" >&2; exit 1
    ;;
esac
