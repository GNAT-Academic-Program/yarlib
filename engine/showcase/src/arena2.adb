--  arena2: the arena again, as a scene file on the engine layer.
--
--     arena2 [arena.scene] [--frames N] [--record F] [--replay F] [-c LINE]...
--
--  Compare with ../../showcase/src/arena_game.adb: the blocks, their
--  bouncing, the spinner and the ship are now data in arena.scene and
--  three engine systems. What is left here is the ship's control and
--  the spinner's rotation: the two things that are this game's own.
--
--  Edit arena.scene while it runs. It reloads.
--
--  Until escape's milestone 1 (pools) lands, entities cannot hold
--  components and "scene load" reports it. Until yarlib's milestone 1
--  (batcher) lands, nothing draws. Both teams see the same window.

with Bedrock;         use Bedrock;
with Bedrock.Colors;  use Bedrock.Colors;
with Ada.Command_Line;  use Ada.Command_Line;
with Ada.Text_IO;       use Ada.Text_IO;
with Bedrock.Input;     use Bedrock.Input;
with ECS;
with Yarlib;            use Yarlib;
with Yarlib.Console;
with Yarlib.Core;       use Yarlib.Core;
with Yarlib.Game_Loop;
with Yarlib.Replay;
with Yarlib.Shapes;     use Yarlib.Shapes;
with Yarlib.Engine.Commands;
with Yarlib.Engine.Components; use Yarlib.Engine.Components;
with Yarlib.Engine.Scene;
with Yarlib.Engine.Systems;
with Yarlib.Engine.World;      use Yarlib.Engine.World;

procedure Arena2 is

   use type ECS.Entity;

   W : constant := 800;
   H : constant := 450;
   Speed : constant Scalar := 260.0;

   procedure Update (Dt : Scalar);
   procedure Draw (Alpha : Scalar);

   procedure Update (Dt : Scalar) is
      Ship : constant Entity := Find ("ship");
      Spin : constant Entity := Find ("spinner");
      Ok   : Boolean;
   begin
      if Ship /= No_Entity and then Velocities.Has (Ship) then
         declare
            V : Velocity_Data;
         begin
            V.V.X := (if Is_Key_Down (Key_Left) or Is_Key_Down (Key_A) then -Speed
                      elsif Is_Key_Down (Key_Right) or Is_Key_Down (Key_D) then Speed else 0.0);
            V.V.Y := (if Is_Key_Down (Key_Up) or Is_Key_Down (Key_W) then -Speed
                      elsif Is_Key_Down (Key_Down) or Is_Key_Down (Key_S) then Speed else 0.0);
            Velocities.Set (Ship, V, Ok);
         end;
      end if;
      if Spin /= No_Entity and then Transforms.Has (Spin) then
         declare
            T : Transform_Data := Transforms.Get (Spin);
         begin
            T.Rotation := T.Rotation + Degrees (90.0 * Dt);
            Transforms.Set (Spin, T, Ok);
         end;
      end if;
      Yarlib.Engine.Systems.Update (Dt);
   end Update;

   procedure Draw (Alpha : Scalar) is
      pragma Unreferenced (Alpha);
      Reloaded : Boolean;
   begin
      Yarlib.Engine.Scene.Poll (Reloaded);
      if Reloaded then
         Put_Line ("arena2: scene reloaded," & Yarlib.Engine.World.W.Live_Count'Image
                   & " entities");
      end if;
      Clear_Background (Dark_Gray);
      Draw_Rectangle_Lines (8, 8, W - 16, H - 16, Light_Gray);
      Yarlib.Engine.Systems.Render;
   end Draw;

   package Game is new Yarlib.Game_Loop (Update, Draw);

   Session : Replay.Session;
   Frames  : Natural := 0;
   Ok      : Boolean;
   Err     : String (1 .. 160);
   Last    : Natural;
   I       : Positive := 1;
   Scene_File : String (1 .. 256) := "arena.scene" & [12 .. 256 => ' '];
   Scene_Len  : Natural := 11;
begin
   Init_Window (W, H, "yarlib arena2");
   Yarlib.Engine.Systems.Arena := (8.0, 8.0, Scalar (W) - 16.0, Scalar (H) - 16.0);
   Yarlib.Engine.Commands.Register_All;

   while I <= Argument_Count loop
      if Argument (I) = "--frames" and then I < Argument_Count then
         Frames := Natural'Value (Argument (I + 1));
         I := I + 2;
      elsif Argument (I) = "--record" and then I < Argument_Count then
         Replay.Start_Recording (Session, Argument (I + 1), Ok);
         I := I + 2;
      elsif Argument (I) = "--replay" and then I < Argument_Count then
         Replay.Start_Replay (Session, Default.all, Argument (I + 1), Ok);
         I := I + 2;
      elsif Argument (I) = "-c" and then I < Argument_Count then
         I := I + 2;   --  run after the scene is loaded, below
      elsif Argument (I)'Length > 0 and then Argument (I) (1) /= '-' then
         Scene_Len := Argument (I)'Length;
         Scene_File (1 .. Scene_Len) := Argument (I);
         I := I + 1;
      else
         Put_Line ("arena2: unknown argument " & Argument (I));
         I := I + 1;
      end if;
   end loop;

   Yarlib.Engine.Scene.Load (Scene_File (1 .. Scene_Len), Ok, Err, Last);
   if Ok then
      Put_Line ("arena2: loaded" & Yarlib.Engine.World.W.Live_Count'Image & " entities");
      Yarlib.Engine.Scene.Watch (Scene_File (1 .. Scene_Len));
   else
      Put_Line ("arena2: " & Err (1 .. Last));
   end if;

   I := 1;
   while I < Argument_Count loop
      if Argument (I) = "-c" then
         declare
            R : Console.Response;
         begin
            Console.Execute (Argument (I + 1), R);
            Put_Line (Console.Image (R));
         end;
      end if;
      I := I + 1;
   end loop;

   Game.Run (Default.all, Session, Max_Frames => Frames);
   Replay.Stop (Session, Default.all);

   declare
      R : Console.Response;
   begin
      Console.Execute ("entities", R);
      Put_Line ("arena2: " & Console.Image (R));
   end;
   Close_Window;
end Arena2;
