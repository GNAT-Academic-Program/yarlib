--  Yarlib.Engine: what a game engine adds on top of a game library,
--  kept to the things that pay for themselves.
--
--     Components   Name, Transform, Velocity, Sprite, Collider, Lifetime
--     World        the escape ECS, assembled for the desktop
--     Scene        a level is a text file; load, save, hot reload
--     Systems      movement, lifetime, render, collision
--     Commands     console commands: spawn, kill, entities, scene ...
--
--  A game that uses this layer is: a .scene file, a few systems of its
--  own, and a main that calls Engine.Init, then Game_Loop.Run with
--  Engine.Update and Engine.Draw (or its own that call them).
--
--  The line below this package is escape. The line above it is the
--  game. yarlib proper (Core, Shapes, Textures, Batch, ports) never
--  withs anything here.

package Yarlib.Engine is
   pragma Pure;
end Yarlib.Engine;
