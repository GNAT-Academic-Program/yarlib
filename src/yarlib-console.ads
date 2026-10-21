--  The console: a table of command names and handlers. Execute takes
--  one line, finds the handler for its first word, and hands it the
--  rest of the line. The handler answers one Response whose text
--  starts with "ok" or "err".
--
--  Who registers what:
--     the game            its own verbs, in Init (arena: spawn, clear, ship, list)
--     Yarlib.Engine       scene, spawn, kill, set, entities (Commands.Register_All)
--
--  How lines reach it in the seed: the showcases take -c "LINE" on
--  the command line, repeatable, and run each before the loop starts:
--
--     arena  -c "spawn 100 100 20" -c "list"
--     arena2 arena.scene -c "set ship velocity 0 80" -c "scene save out.scene"
--
--  There is no on-screen console and no stdin reader yet; drawing the
--  console needs text, which is milestone 2.
--
--  Why it exists: one line per command means a test, a CI step or a
--  shell script can poke the game without a GUI, and the engine's
--  scene grammar and console grammar can be the same parser.

with Bedrock.Responses;

package Yarlib.Console is

   Max_Response : constant := 1_024;

   package Responses is new Bedrock.Responses (Max_Response);
   subtype Response is Responses.Response;
   function Image (R : Response) return String renames Responses.Image;
   procedure Set (R : out Response; Ok : Boolean; Msg : String) renames
     Responses.Set;
   procedure Append (R : in out Response; Msg : String) renames
     Responses.Append;

   type Handler is access procedure (Args : String; R : out Response);
   --  Args is everything after the command name, trimmed.

   Max_Commands : constant := 128;
   Max_Name     : constant := 32;

   procedure Register (Name : String; H : Handler; Help : String := "") with
     Pre => Name'Length in 1 .. Max_Name;
   --  Replaces an existing Name. Raises Program_Error when full.

   procedure Execute (Line : String; R : out Response);
   --  Empty lines and '#' lines answer ok. Unknown names answer
   --  "err unknown command NAME". "help" is built in.

   function Count return Natural;

end Yarlib.Console;
