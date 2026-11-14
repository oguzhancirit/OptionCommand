#!/bin/bash
# Copies the Spoon into ~/.hammerspoon and wires it up. Safe to run again to update.
set -euo pipefail
cd "$(dirname "$0")"
H="$HOME/.hammerspoon"
mkdir -p "$H/Spoons/WheelLauncher.spoon"
cp WheelLauncher.spoon/*.lua "$H/Spoons/WheelLauncher.spoon/"
[ -f "$H/wheel.lua" ] || cp wheel.example.lua "$H/wheel.lua"
if ! grep -q WheelLauncher "$H/init.lua" 2>/dev/null; then
  cat >> "$H/init.lua" <<'EOF'

hs.loadSpoon("WheelLauncher")
spoon.WheelLauncher:start("~/.hammerspoon/wheel.lua")
EOF
fi
echo "Tamam. Hammerspoon menusunden 'Reload Config' sec. Ayarlar: $H/wheel.lua"
