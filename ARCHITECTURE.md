# Architecture

## Layers

```
editor/ (adi2)      engine/showcase (arena2)      showcase/ (arena)       a game
        \                    |                        |                    /
         Yarlib.Engine.*   Scene, Components, World, Systems, Commands    engine/ crate, on escape
                  \                  |
          Yarlib.Game_Loop   Yarlib.Replay   Yarlib.Console               structure: Init/Update/Draw, sessions as text
                  \                  |
          Yarlib.Core   Yarlib.Shapes   Yarlib.Textures                   the raylib-shaped API; Context, Camera2D
                  |
          Yarlib.Batch          Yarlib.Input                              CPU side: quads in, calls out; input as values   SPARK
                  |                    |
          Yarlib.Renderer (seam)     Yarlib.Platform (seam)
           /        \             /          \
    software     opengl       null        sdl3                          one body per port, gpr externals
         |
    Yarlib.Raster    software triangles, for the software renderer
```

Dependencies point down only. `src/` names no library but bedrock;
`ports/` name SDL and GL; `engine/` names escape; nothing names adi2
but the editor.

## bedrock

The root package `Yarlib` declares `Texture` and a `Bitmap` subtype
and nothing else; everything a game would call a type comes from
bedrock and is made visible to all of Yarlib's children by the use
clauses in `yarlib.ads`. That is deliberate: `Bedrock.Colors.Color`
is what the software rasterizer writes, what the GL port uploads,
what portal's framebuffer holds and what adi2's texture view will
receive, one type end to end. `Bedrock.Input.Event` is what the sdl3
port produces, what a `.rec` file records, what a test injects, and
what portal's ports will produce, so the portal platform port is a
pass-through.

## Context, not globals

raylib keeps one window, one batch and one input table in C statics.
That is why it cannot be embedded, cannot be tested without a display,
and cannot run two views. `Yarlib.Core.Context` is that state as a
limited record: window size, batch, input state, pending injected
events, camera, clock. Every operation takes one. The flat overloads
take none and use `Core.Default`, a context declared in the body, so
the six-line hello world stays six lines and the editor holds its own.

A Context is bounded (the batch is the big part, about 1 MB) and
lives where it is declared. No heap anywhere in `src/` except the
software renderer's frame.

## The two seams

`Yarlib.Platform` (open, close, poll, swap, now) and `Yarlib.Renderer`
(init, resize, clear, create texture, draw, read pixel, shutdown) are
ordinary packages whose bodies live in `ports/`; the gpr picks a
directory per external. A game binary contains exactly one platform
and one renderer, statically. No tagged types, no dispatching.

`Yarlib.Renderer` (init, resize, clear, create texture, draw, read
pixel, read frame, shutdown) has two bodies: `software`, which draws
into a Bedrock image with `Yarlib.Raster` and is complete without any
GPU, and `opengl`. The software one is not a stub: it is the oracle
the GL port must agree with pixel for pixel, the renderer for a
platform with no GPU (portal on a plain framebuffer), and what tests
and CI use. The `null` platform is the stub: no window, no events.

## The funnel

Every visible thing is a quad: four corners in screen space, four
UVs, one colour, one texture id. Shapes builds them on the white
texture, Textures on a real one, `Core.Submit` transforms them
through the camera if one is active and pushes them into
`Yarlib.Batch`. `End_Drawing` hands the batch to `Renderer.Draw`. One
path, so every clever thing (camera, atlas, layers, later culling)
happens once, on the CPU, portably, and the renderer ports stay at "bind,
draw arrays" forever.

`Batch.Vertex` is X, Y, U, V, RGBA: 20 bytes, no padding. The opengl
port hands the array to GL with a stride; the null port reads the
same array. No copying.

## Batch: the project

`Push_Quad` is the placeholder. `Well_Formed` is the invariant: draw
calls are non-empty, whole quads, contiguous, tile the vertex array,
adjacent calls differ in texture. Proof target for `gnatprove
--mode=all`.

## Input as values

`Input.Event` is what a platform delivers; `Input.State` is what a
frame sees. Both are plain records. `Core.Inject` queues events that
`End_Drawing` applies before the platform's own; `Frame_Events`
returns everything applied that frame. That is the whole mechanism
behind tests that press keys with no window, and behind Replay.

## Game_Loop and Replay

`Game_Loop` is generic over `Update (Dt)` and `Draw (Alpha)`. Fixed
step: an accumulator turns wall time into zero or more `Update`
calls per frame at a constant `Dt`, clamped so a stall cannot
spiral; `Draw` runs once with the fraction of a step left over.
Headless (`Max_Frames > 0`) uses one step per frame and no clock.

`Replay` records, per frame, the step count and the events applied,
as one text line, and omits the default line (one step, no events).
Replaying mutes the platform, injects the recorded events at the
recorded frames, and overrides the step counts. Since `Update` is a
function of `Dt`, input and its own state, the replayed game reaches
the recorded state. The tests record eight frames with two key
presses and replay them into a fresh world and compare counters.

## Console

A table of names and handlers. `Execute (Line, Response)`; the first
word of a response is `ok` or `err`. The game registers its verbs,
the engine registers scene and entity verbs. In the seed, lines come
from `-c "LINE"` arguments and from the tests; an on-screen console
is milestone 2.

## Engine

`Components`: Name, Transform, Velocity, Sprite, Collider, Lifetime.
Plain records with defaults, so scene lines can be short.

`World`: the escape assembly, one world of 4096 entities, one pool
per component through a local `Pool_Of` generic that hides escape's
three-instantiation ritual. `Find (name)` is the console's handle on
an entity.

`Scene`: the grammar in the spec header, a line-by-line loader with
"line N: reason" errors, a saver that produces the same grammar
(`Load (Save (w)) = w`), and hot reload by modification time.

`Systems`: Lifetime, Movement, Bounce, then Render by layer. Each is
a loop over one pool with lookups into others; reverse iteration
where an entity may be destroyed, because escape moves the tail into
the hole.

`Commands`: `scene`, `spawn`, `kill`, `set`, `entities`. `spawn` and
`set` reuse the scene grammar, so there is one parser.

## Ports

`sdl3`: a private child with the ten SDL calls used, and an
`SDL_Event` as tag plus 124 bytes overlaid by the specific record.
It requests GL 2.1 explicitly: SDL's default context on some
platforms is core or GLES, where the fixed-function port errors out
silently. That cost an afternoon; it is in a comment now.

`opengl`: GL 1.1 only, exported directly by every driver, no loader.
A modern-GL port with shaders is a new directory when someone wants
one.

`software` renderer: `Raster` into a heap image. Compiled without
`-gnatVa` on the rasterizer file only: validity checks on every float
in the inner loop made a full-screen fill 25x slower (measured).

## What is deliberately not here

- A scene graph or GameObject tree. The ECS is the composition model;
  a `Parent` component is one system when a game needs it.
- A scripting language. The console and scene files are the
  scripting, in Ada's own text.
- Full physics, 2D lighting, 3D, networking, a job system, an asset
  pipeline. Each a project of its own.
- An event bus. Systems reading components is the message.
- A GUI toolkit. That is adi2, in the editor, above the line.

## Screenshots

`Core.Screenshot` reads the whole frame back in one call
(`Renderer.Read_Frame`; on opengl a single `glReadPixels` and a row
flip). `Yarlib.PNG.Save` writes it as an uncompressed PNG (stored
deflate blocks, CRC-32 and Adler-32 by hand, no zlib), which every
viewer opens. An earlier version read the frame one `glReadPixels` at
a time; on a real driver that is minutes and an unresponsive window.
