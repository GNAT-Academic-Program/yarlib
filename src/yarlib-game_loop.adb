
package body Yarlib.Game_Loop is

   use Yarlib.Core;

   procedure Run
     (Ctx        : in out Core.Context;
      Session    : in out Replay.Session;
      Fixed_Dt   : Scalar := 1.0 / 60.0;
      Max_Frames : Natural := 0;
      Max_Steps_Per_Frame : Positive := 5)
   is
      Accumulator : Scalar := 0.0;
      Steps       : Natural;
      Frames      : Natural := 0;
      Headless    : constant Boolean := Max_Frames > 0;
   begin
      while not Window_Should_Close (Ctx) loop
         if Headless then
            Steps := 1;
         else
            Accumulator := Accumulator + Scalar'Min (Get_Frame_Time (Ctx), 0.25);
            Steps := 0;
            while Accumulator >= Fixed_Dt and then Steps < Max_Steps_Per_Frame loop
               Accumulator := Accumulator - Fixed_Dt;
               Steps := Steps + 1;
            end loop;
            if Steps = Max_Steps_Per_Frame then
               Accumulator := 0.0;   --  we fell behind; drop the rest
            end if;
         end if;
         Replay.Before_Frame (Session, Ctx, Steps);

         for I in 1 .. Steps loop
            Update (Fixed_Dt);
         end loop;

         Begin_Drawing (Ctx);
         Draw ((if Headless then 0.0 else Accumulator / Fixed_Dt));
         End_Drawing (Ctx);

         Replay.After_Frame (Session, Ctx, Steps);
         Frames := Frames + 1;
         exit when Headless and then Frames >= Max_Frames;
      end loop;
   end Run;

   procedure Run (Fixed_Dt : Scalar := 1.0 / 60.0; Max_Frames : Natural := 0) is
      S : Replay.Session;
   begin
      Run (Default.all, S, Fixed_Dt, Max_Frames);
   end Run;

end Yarlib.Game_Loop;
