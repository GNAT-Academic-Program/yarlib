# editor: the contract

Not built yet (milestone 7). By then, `scene watch` plus the console
will have given you most of what an editor is for; build it when a
thing you do daily is still slower than it should be.

When it is built, it is its own crate here, depends on `yarlib`,
`yarlib_engine` and `adi2`, and obeys three rules:

1. **The library does not know the editor exists.** Nothing in `src/`,
   `ports/` or `engine/` withs adi2 or the editor. CI greps for it.
2. **The game runs unchanged inside the editor.** The editor owns a
   second `Core.Context` whose renderer target is a texture (the one
   renderer-side feature the editor may add to the seam: render to
   texture), calls the game's `Update` and `Draw` itself, and shows
   the texture in an adi2 texture view. The game is `Init / Update /
   Draw` already, because `Yarlib.Game_Loop` demanded it, so the
   editor is just another driver of the same three procedures. No
   `if In_Editor` anywhere in a game.
3. **Editor panels read and write the scene, not yarlib.** The entity
   list, the inspector and save/load are `Yarlib.Engine.World` and
   `Scene`; every edit the inspector makes is a console line (`set
   ship velocity 0 80`) shown in the editor's command bar, so using
   the editor teaches the console.

## Suggested stack

- adi2 window with a dock layout: viewport (texture view), console,
  entity list, inspector.
- Input forwarded to the game's context through `Core.Inject`, so the
  game sees ordinary events.
- Play / pause / step: the editor decides when `Update` runs; `Draw`
  runs every editor frame. Step = one `Update` at `Fixed_Dt`.
- Record / replay buttons over `Yarlib.Replay`.

## Acceptance

Open the editor, load `arena.scene`, see it running in a panel, pause,
step one frame, change `b1`'s velocity in the inspector and read the
bar: `set b1 velocity -55 30`. Resume, watch it go the other way. Save;
close the editor; `arena2 arena.scene` shows the same. Then hit Record,
play ten seconds, stop, and replay the `.rec` in `arena2` headless.
