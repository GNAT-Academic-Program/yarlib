--  A scene is a text file: readable, diffable, hand-editable, and
--  reloaded live while the game runs.
--
--     # yarlib scene v1
--     entity ship
--       transform 384 209 32 32 0        x y w h rotation
--       velocity 0 0
--       sprite white 102 191 255 255     texture r g b a
--       collider 32 32
--     entity block
--       transform 60 37 14 14
--       velocity 40 -30
--       sprite checker
--       lifetime 12.5
--
--  One entity per "entity NAME" line, one component per indented line,
--  fields in declaration order, trailing fields optional (defaults
--  apply). Unknown component names are errors; unknown entities are
--  fine. Save writes exactly this, so Load (Save (world)) = world.
--
--  Hot reload: Watch (File) remembers the file's modification time;
--  Poll reloads when it changes. Edit the scene in any editor, alt-tab,
--  it is there. This is most of what a level editor is for, at the
--  cost of forty lines.

with Yarlib.Engine.World;

package Yarlib.Engine.Scene is

   procedure Load (File : String; Ok : out Boolean; Error : out String; Last : out Natural)
     with Pre => Error'Length >= 128;
   --  Clears the world first. On error the world is what the file
   --  built up to the bad line, and Error says "line N: reason".

   procedure Save (File : String; Ok : out Boolean);

   procedure Parse_Entity (Lines : String; Ok : out Boolean);
   --  Same grammar, from a string with LF separators, added to the
   --  world without clearing. The console's "spawn" uses it.

   procedure Parse_Entity_On (E : World.Entity; Line : String; Ok : out Boolean);
   --  One component line applied to an existing entity. "set" uses it.

   procedure Watch (File : String);
   procedure Unwatch;
   procedure Poll (Reloaded : out Boolean);
   --  Call once per frame. Reloaded = True when the file changed and
   --  was loaded again (errors are printed and the world is left as
   --  the partial load; fix the file and save again).

   function Watched return String;

end Yarlib.Engine.Scene;
