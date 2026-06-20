#!/usr/bin/env bash
set -Eeuo pipefail

TARGET="/usr/local/bin/doctorjack"

if [[ -e "$TARGET" ]]; then
    sudo rm -f "$TARGET"
    echo "[OK] Removed $TARGET"
else
    echo "[INFO] Doctorjack global command is not installed at $TARGET"
fi

echo "[INFO] Dependencies were not removed: httpx, gf, Gxss, qsreplace, uro, Go, Python."
echo "[INFO] Generated recon directories were not removed."
