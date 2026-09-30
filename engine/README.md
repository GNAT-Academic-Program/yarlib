# engine

The engine layer: `Yarlib.Engine.*`. A separate crate so that a game
which wants only the library pays nothing for it, and so that the one
outside dependency of the whole project is isolated here.

## The escape dependency

`Yarlib.Engine.World` is an assembly of
[escape](https://github.com/GNAT-Academic-Program/escape), the ECS
capstone's seed, pinned by URL in `alire.toml`. escape's pools
(`Has`, `Get`, `Set`, `Unset`, `Detach`) are that team's milestone 1,
placeholders until they land it (October). Until then:

- `arena2` loads a scene and reports `cannot attach name (escape
  milestone 1?)` on line 3; entities exist but hold nothing.
- `engine/tests` prints eight TODO lines and passes.
- Everything in this crate compiles and runs; it just has nothing to
  operate on.

When escape lands, set `Escape_Milestone := 1` in
`engine/tests/src/engine_tests.adb` and the TODOs must pass. Both
teams see the same window until both milestones land; that is the
point of the program.

Fallback if escape slips past December: pin a fork with the reference
pools body (the coordinator has it) and carry on.

## Layout

```
src/yarlib-engine-components.ads   Name, Transform, Velocity, Sprite, Collider, Lifetime
src/yarlib-engine-world.ads        the escape assembly; Find (name)
src/yarlib-engine-scene.ads        .scene grammar, Load, Save, hot reload
src/yarlib-engine-systems.ads      Lifetime, Movement, Bounce, Render; Register_Texture
src/yarlib-engine-commands.ads     scene, spawn, kill, set, entities
showcase/arena.scene               the arena as data
showcase/src/arena2.adb            the game: ship control and a spinner; the rest is data
tests/                             grammar and console now; behaviour when escape lands
```
