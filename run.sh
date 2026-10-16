#!/usr/bin/env bash
# KofSentinela — ./run.sh once | poll | serve | all | status-legacy | ui-build
set -e
cd "$(dirname "$0")"

if ! command -v kof >/dev/null 2>&1; then
  export PATH="$HOME/.kof/bin:$PATH"
fi
command -v kof >/dev/null 2>&1 || { echo "ERRO: 'kof' não encontrado." >&2; exit 1; }

INTERVAL="${INTERVAL:-30}"

case "${1:-once}" in
  once)
    cd app && SENTINELA_MODE=once exec kof run Main.kf
    ;;
  poll)
    cd app
    while true; do
      SENTINELA_MODE=once kof run Main.kf || true
      sleep "$INTERVAL"
    done
    ;;
  serve)
    cd app && SENTINELA_MODE=serve exec kof run Main.kf
    ;;
  all)
    cd app && SENTINELA_MODE=all exec kof run Main.kf
    ;;
  ui-build)
    cd ui && exec kof build Dashboard.kf --target js --output ui-dist
    ;;
  *)
    echo "uso: ./run.sh once | poll | serve | all | ui-build" >&2; exit 1
    ;;
esac
