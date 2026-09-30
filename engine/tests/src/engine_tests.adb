--  Engine tests. Checks tagged with a milestone print TODO until it
--  lands. "escape 1" is the ECS team's pools milestone: until then no
--  entity can hold a component, and every scene loads empty.

with Bedrock;         use Bedrock;
with Ada.Command_Line;
with Ada.Text_IO;      use Ada.Text_IO;
with ECS;
with Yarlib;           use Yarlib;
with Yarlib.Console;
with Yarlib.Core;      use Yarlib.Core;
with Yarlib.Engine.Commands;
with Yarlib.Engine.Scene;
with Yarlib.Engine.Systems;
with Yarlib.Engine.World;      use Yarlib.Engine.World;

procedure Engine_Tests is

   Escape_Milestone : constant Natural := 0;
   --  0: escape pools are the placeholder. 1: they work.

   use type ECS.Entity;

   Failures : Natural := 0;
   Todos    : Natural := 0;

   procedure Check (Name : String; Cond : Boolean; Needs_Escape : Natural := 0);
   procedure Check (Name : String; Cond : Boolean; Needs_Escape : Natural := 0) is
   begin
      if Cond then
         Put_Line ("PASS  " & Name);
      elsif Needs_Escape > Escape_Milestone then
         Put_Line ("TODO  " & Name & "  (escape milestone" & Needs_Escape'Image & ")");
         Todos := Todos + 1;
      else
         Put_Line ("FAIL  " & Name);
         Failures := Failures + 1;
      end if;
   end Check;

   Ok   : Boolean;
   Err  : String (1 .. 160);
   Last : Natural;
   R    : Console.Response;

begin
   Init_Window (64, 64, "engine tests");
   Yarlib.Engine.Commands.Register_All;
   Yarlib.Engine.Systems.Arena := (0.0, 0.0, 64.0, 64.0);

   --  Scene grammar, independent of escape: errors are reported by line.
   declare
      F : File_Type;
   begin
      Create (F, Out_File, "bad.scene");
      Put_Line (F, "# yarlib scene v1");
      Put_Line (F, "  transform 1 2");
      Close (F);
   end;
   Yarlib.Engine.Scene.Load ("bad.scene", Ok, Err, Last);
   Check ("component before entity is line 2",
          not Ok and Err (1 .. Last) = "line 2: component before any entity");
   Yarlib.Engine.Scene.Load ("missing.scene", Ok, Err, Last);
   Check ("missing file reported", not Ok);
   Yarlib.Engine.Scene.Save ("empty.scene", Ok);
   Check ("save empty world", Ok);

   --  Console wiring.
   Console.Execute ("scene load bad.scene", R);
   Check ("console scene load reports the error", not R.Ok);
   Console.Execute ("kill nobody", R);
   Check ("kill unknown", not R.Ok);
   Console.Execute ("entities", R);
   Check ("entities answers", R.Ok);

   --  With working pools (escape milestone 1): a real scene.
   declare
      F : File_Type;
   begin
      Create (F, Out_File, "two.scene");
      Put_Line (F, "entity a");
      Put_Line (F, "  transform 10 10 8 8");
      Put_Line (F, "  velocity 60 0");
      Put_Line (F, "  sprite white");
      Put_Line (F, "  collider 8 8");
      Put_Line (F, "entity b");
      Put_Line (F, "  transform 40 40");
      Put_Line (F, "  lifetime 0.5");
      Close (F);
   end;
   Yarlib.Engine.Scene.Load ("two.scene", Ok, Err, Last);
   Check ("scene with two entities loads", Ok and W.Live_Count = 2, Needs_Escape => 1);
   Check ("find by name", Find ("b") /= No_Entity, Needs_Escape => 1);
   Yarlib.Engine.Systems.Update (0.5);
   Check ("movement: a moved 30", Find ("a") /= No_Entity and then Transforms.Has (Find ("a"))
          and then Transforms.Get (Find ("a")).Pos.X = 40.0, Needs_Escape => 1);
   Yarlib.Engine.Systems.Update (0.5);
   Check ("bounce: a reflected at the edge", Find ("a") /= No_Entity
          and then Velocities.Has (Find ("a"))
          and then Velocities.Get (Find ("a")).V.X < 0.0, Needs_Escape => 1);
   Check ("lifetime: b is gone", Find ("b") = No_Entity, Needs_Escape => 1);
   Yarlib.Engine.Scene.Save ("rt.scene", Ok);
   Yarlib.Engine.Scene.Load ("rt.scene", Ok, Err, Last);
   Check ("save/load round trip keeps a", Ok and Find ("a") /= No_Entity and W.Live_Count = 1,
          Needs_Escape => 1);
   Console.Execute ("spawn c 1 2 3 4", R);
   Check ("spawn via console", R.Ok and Find ("c") /= No_Entity, Needs_Escape => 1);
   Console.Execute ("set c velocity 5 5", R);
   Check ("set via console", R.Ok and then Velocities.Has (Find ("c")), Needs_Escape => 1);
   Console.Execute ("kill c", R);
   Check ("kill via console", R.Ok and Find ("c") = No_Entity, Needs_Escape => 1);

   Close_Window;
   New_Line;
   if Todos > 0 then
      Put_Line (Todos'Image & " TODO (waiting on escape milestone" & Escape_Milestone'Image & ")");
   end if;
   if Failures = 0 then
      Put_Line ("all tests passed");
   else
      Put_Line (Failures'Image & " failure(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Engine_Tests;
