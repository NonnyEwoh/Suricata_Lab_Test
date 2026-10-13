#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-<SURICATA_IP>}"
PORT="${2:-4444}"

echo "[+] Sending authorized lab marker to ${TARGET}:${PORT}"
printf 'SURICATA-LAB-TEST\n' | nc -v -w 3 "$TARGET" "$PORT"
echo "[+] Traffic generation finished."
