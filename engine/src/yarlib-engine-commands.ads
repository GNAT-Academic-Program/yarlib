--  The engine's console commands. Register once at startup; then any
--  console line (a -c argument, a test) can say:
--
--     scene load arena.scene      replace the world with the file
--     scene save out.scene        write the world
--     scene watch arena.scene     hot reload on change (off: scene unwatch)
--     spawn NAME X Y [W H]        entity with transform + white sprite
--     kill NAME                   destroy
--     set NAME COMPONENT FIELDS   same line grammar as the scene file
--     entities                    list names and positions
--     texture NAME                (milestone 3) load a file and register it

with Yarlib.Console;

package Yarlib.Engine.Commands is

   procedure Register_All;

   procedure Cmd_Scene (Args : String; R : out Console.Response);
   procedure Cmd_Spawn (Args : String; R : out Console.Response);
   procedure Cmd_Kill (Args : String; R : out Console.Response);
   procedure Cmd_Set (Args : String; R : out Console.Response);
   procedure Cmd_Entities (Args : String; R : out Console.Response);

end Yarlib.Engine.Commands;
