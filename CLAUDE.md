# optioncommand (WheelLauncher) — agent notes
## Talk to the user
- User: Oğuzhan. Reply in **simple Turkish**, short updates, no step-by-step recaps.
- Routine work: keep going. Real decisions (new feature scope, breaking config changes): ask first.

## What this is
A free radial launcher for macOS. No app of our own: a Hammerspoon Spoon (Lua 5.4).
- `WheelLauncher.spoon/geometry.lua` — pure math (slot picking, slice polygon). No `hs` calls.
- `WheelLauncher.spoon/init.lua` — trigger (modifier eventtap), drawing (`hs.canvas`), actions.
- `WheelLauncher.spoon/settings.lua` + `settings.html` — settings window (`hs.webview`); page ↔ Lua via `postMessage` / `WL.*`. Saves `wheel.json`, which overrides the Lua config (keys in `SAVED`).
- `wheel.example.lua` — user config template (comments in Turkish). `install.sh` — copies into `~/.hammerspoon`.
- `tests/run.lua` — math tests + a fake `hs` that walks open → point → release.

## Commands
- Test: `lua5.4 tests/run.lua` (must print `ok`). Linux has no Hammerspoon: drawing can only be checked by the user on the Mac — say so, never claim it was seen working.

## Rules
- Logic changes: test first in `tests/run.lua`. New math goes in `geometry.lua`, not `init.lua`.
- New config keys: add to `DEFAULTS` in `init.lua`, to `wheel.example.lua`, to the README table, and (if user-editable) to `SAVED` + `settings.html`. Old configs must keep working.
- Network: only site-icon download (`fetchSiteIcon`, off with `favicons = false`). No telemetry, no extra dependencies. MIT only.
- `settings.html` can be checked on Linux: open it with Playwright and call `WL.init({...})`.
- Small commits. Tell the user what will be pushed before pushing. No force push.

## Context & token rules
- The whole project is ~900 lines: `grep -n` first, then read only the function you need.
- Pipe test output through `tail`. Do not paste whole files back into chat.
- Hammerspoon API unsure? Check the one doc page (hammerspoon.org/docs/hs.<module>.html), do not browse broadly.
- `/clear` between unrelated tasks; write lasting notes into this file, not only into chat.
