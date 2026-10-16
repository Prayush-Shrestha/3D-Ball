# Rolling Realms — test checklist

How to run the automated tests (Godot 4.7.2, Windows PowerShell):

```powershell
$godot = "<path-to>\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --import
& $godot --headless --script res://tests/validate_scenes.gd
& $godot --headless --script res://tests/runtime_test.gd
```

## Automated results (2026-10-16, this machine)

- [x] `--headless --import`: clean, no script errors (one type-inference error
      found and fixed during development).
- [x] `validate_scenes.gd`: 3 autoloads + 18 scenes instantiate cleanly.
- [x] `runtime_test.gd`: 11/11 PASS —
  moved forward 8.06 m in 1 s, no fall-through, jump +1.78 m, gem counted once,
  checkpoint moved spawn (dist 0.00), fall respawned (y 3.0), pause froze tree,
  resume unfroze, level completed, save recorded completion, save file exists.
- [x] Windows export: `RollingRealms.exe` (109 MB) + `.pck` built, exit 0.
- [x] Exported exe: still running after 10 s with no crash (main menu scene live).
- [x] Android export: `RollingRealms-debug.apk` (28.5 MB) signed debug, exit 0
      (needed JDK path set in Editor Settings; documented in README).
- [ ] Web export: NOT built (Web templates not installed). Preset ships untested.
- [ ] Physical-device touch playtest: NOT done (no device in this session).

## Manual playtest checklist (for the developer)

- [ ] Main menu opens; Play starts highest unlocked unfinished level.
- [ ] Ball moves all directions; rolls visually; camera follows smoothly.
- [ ] Jump works; coyote time forgiving near edges; no double jump.
- [ ] Ball cannot pass through platforms; slopes and ramp climb cleanly.
- [ ] Gems increment once; sparkle + sound play; counter shows x / total.
- [ ] Checkpoint flag turns green; death respawns there with zero velocity.
- [ ] Fall below world respawns; R restarts at checkpoint.
- [ ] Pause (Esc / II) freezes physics; Resume/Restart/Menu all work.
- [ ] Finish pad shows stats, best time, New Best on record; Next unlocks level.
- [ ] Quit button visible on desktop, hidden on mobile/web.
- [ ] Restart PC game → unlocked levels, gems, best times persist.
- [ ] Touch: joystick moves ball; JUMP jumps; layout sane in landscape.
- [ ] Resize window → HUD adapts, 3D view expands.
