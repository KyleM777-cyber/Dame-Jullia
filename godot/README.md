# Dame Julia — Godot 4 port

This is a Godot 4.3 port of `../index.html`, the original single-file HTML5
Canvas platformer. The HTML version is untouched; this is a full rewrite
using Godot's scene/node system, built to run on Godot 4.3+ (GL Compatibility
renderer, so it also runs on older/integrated GPUs).

## Opening it

Open Godot 4.3 (or later), "Import", and select `godot/project.godot`.
Press F5 (or the Play button) to run — `scenes/Main.tscn` is the entry point.

## How it maps to the original

- **`autoload/Game.gd`** — global state machine (`start / dialogue / playing /
  levelcomplete / gameover / victory`) plus all level layout data and dialogue
  text, transcribed from the `LEVELS` array and the various `*Dialogue()`
  functions in `index.html`.
- **`scripts/player.gd`** — ported 1:1 from `updatePlayer()`. Physics constants
  (speed, gravity, jump power, knockback, etc.) are the *exact same numbers*
  as the original per-frame model — Godot's physics tick is pinned to 60Hz in
  `project.godot`, so no unit conversion was needed.
- **`scripts/level.gd`** — the biggest file; ported from `moveAndCollide()`,
  `updateEnemies()`, `updatePlayerProjectiles()`, `updateJeb()`,
  `updateMiniBoss()`, `updateRocks()`, `updateMovingPlatforms()`, and the
  dialogue-chain functions (`jebIntroDialogue`, `jebFleeSequence`,
  `friarSlideDialogue`, `princeKyleDialogue`, `kingsFinaleDialogue`, etc).
  Collision uses a hand-rolled AABB resolver (not Godot's physics engine) to
  match the original's exact platformer feel.
- **`scripts/{chugger,mini_boss,brie,decor,hanging_rock,projectile,terrain,
  background}.gd`** — visuals ported from the corresponding `draw*()` canvas
  functions, using Godot's `_draw()` immediate-mode API (`draw_rect`,
  `draw_circle`, `draw_colored_polygon`, ...) as a close analog to
  `fillRect`/`arc`/`fill`.
- **`scenes/ui/`** — HUD, dialogue box, and a single reusable full-screen
  `Overlay` (the original's four separate start/level-complete/game-over/
  victory `<div>` overlays collapse into one, since only one is ever visible
  at a time).
- **Camera** — the original manually subtracted `camX` from every draw call.
  Here a `Camera2D` just follows the player (same clamping formula), so world
  objects are placed at their absolute level coordinates and Godot handles
  the scrolling.

## Known simplifications / things worth a look in-editor

- **Background art is simplified.** The original's parallax clouds/castle-
  silhouette bezier art was not ported stroke-for-stroke — `background.gd` is
  a reasonable approximation (theme-colored sky bands, a sun/moon, simple
  parallax silhouettes), not a pixel match.
- **The final boss is named "Brie" in dialogue but is called `jeb` throughout
  the original source** (`updateJeb()`, `spawnJeb()`, etc.) — a leftover
  internal name from before the game was reskinned. This port keeps the
  *visual* faithful to the active (cheese-wheel) `drawJeb()` override, but
  renamed the script/scene/class to `Brie` for clarity. Confusingly, the
  original file actually has *two* definitions of `drawJeb()` (and of
  `drawMiniBoss`/`drawChugger`/`drawSirSlime`) — an early "mobster bottle" /
  "winged dragon" version followed by a later reskin override that wins at
  runtime since JS uses the last function declaration. Only the winning
  (reskinned) versions were ported; the dead first drafts were left behind.
- **Unused legacy assets weren't ported.** The original embeds four large
  base64 JPEG portraits (`jeb`, `kings`, `sirslime`, `princess`) that no
  dialogue line actually references — leftovers from before the reskin.
  Skipped here.
- **The Up-arrow alternate jump binding** in `project.godot`'s input map
  uses `physical_keycode 4194320`, which should be Godot 4's `KEY_UP` — worth
  a quick check in Project Settings → Input Map after opening, since it
  wasn't possible to verify against a running Godot instance in this session.
- This was built and syntax-checked with `gdparse`/`gdlint` (via the
  `gdtoolkit` PyPI package) but **not run inside the actual Godot editor** —
  no Godot binary was available in this environment. Give it a run and a
  playthrough; scene wiring (node paths, signal connections) was checked by
  hand but a couple of names could still be off.
