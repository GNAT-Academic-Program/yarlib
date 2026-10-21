--  The frame loop, done right once so no game does it wrong.
--
--  Fixed timestep with interpolation ("Fix Your Timestep"): Update runs
--  zero or more times per frame with a constant Dt, Draw runs once
--  with Alpha in 0 .. 1 saying how far the next step is, for smooth
--  rendering of fixed-rate physics. Frame time is clamped so a stall
--  (a breakpoint, a window drag) does not produce a spiral of updates.
--
--  A game is three procedures. Immediate mode inside each; structure
--  between them. The editor, the replay system and the headless tests
--  all depend on this split, which is why it is a generic and not a
--  suggestion.
--
--     procedure Update (Dt : Scalar);     --  simulation, reads input
--     procedure Draw (Alpha : Scalar);    --  between Begin/End_Drawing
--
--  Headless: Run with Max_Frames > 0 uses exactly one step per frame
--  and simulated time, so a test or a replay produces the same result
--  on any machine at any speed.

with Bedrock; use Bedrock;
with Yarlib.Core;
with Yarlib.Replay;

generic
   with procedure Update (Dt : Scalar);
   with procedure Draw (Alpha : Scalar);
package Yarlib.Game_Loop is

   procedure Run
     (Ctx : in out Core.Context; Session : in out Replay.Session;
      Fixed_Dt            :    Scalar := 1.0 / 60.0; Max_Frames : Natural := 0;
      Max_Steps_Per_Frame :        Positive := 5);
   --  Until Window_Should_Close, or Max_Frames frames (0 = no limit).
   --  Steps per frame come from the clock, or from the replay file, or
   --  are exactly 1 when Max_Frames > 0 (headless, deterministic).

   procedure Run (Fixed_Dt : Scalar := 1.0 / 60.0; Max_Frames : Natural := 0);
   --  Flat form: Core.Default, no recording.

end Yarlib.Game_Loop;
