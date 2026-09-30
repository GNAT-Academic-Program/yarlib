--  Record and replay. A play session is a text file: one line per
--  frame that had events or a non-default step count.
--
--     # yarlib replay v1
--     0 1
--     12 1 k+Key_D
--     40 1 k-Key_D m 300 120
--     41 2 b+Mouse_Left
--     200 1 q
--     end 201
--
--  FRAME STEPS [events...]   STEPS = fixed updates run that frame
--  A frame with no line is the default: one step, no events.
--  "end N" closes the session at frame N; replay quits there.
--     k+KEY  k-KEY           key down / up, Bedrock.Input.Key'Image (repeats dropped)
--     m X Y                  mouse move
--     b+B X Y   b-B X Y      mouse button, Bedrock.Input.Mouse_Button'Image, at X Y
--     r W H                  window resized
--     q                      quit
--  Other event kinds (focus, wheel, gamepads, text) are not recorded
--  yet; add them here and in Image/Value when a game needs them.
--
--  Because Yarlib.Game_Loop drives Update from this file's step counts
--  and injects exactly these events at exactly these frames, with the
--  platform muted, a replayed game reaches the same state as the
--  recorded one. So a .rec attached to a bug report reproduces the
--  bug, and a .rec plus an assertion is a gameplay test (tests.adb
--  does exactly that).
--
--  What makes it deterministic: the game's Update must depend only on
--  Dt, the input state, and its own state. Wall-clock reads and
--  unseeded random numbers break replay; that is a feature, it tells
--  you where your game is not a function.

with Yarlib.Core;
with Yarlib.Input;

package Yarlib.Replay is

   type Mode is (Off, Recording, Replaying);

   type Session is limited private;

   function Current_Mode (S : Session) return Mode;

   procedure Start_Recording (S : in out Session; File : String; Ok : out Boolean);
   procedure Start_Replay (S : in out Session; Ctx : in out Core.Context; File : String;
                           Ok : out Boolean);
   --  Mutes the platform for Ctx. Ok = False: cannot open or bad header.
   procedure Stop (S : in out Session; Ctx : in out Core.Context);
   --  Unmutes the platform.

   ---------------------------------------------------------------------
   --  Called by Yarlib.Game_Loop once per frame. A game does not.
   ---------------------------------------------------------------------

   procedure Before_Frame (S : in out Session; Ctx : in out Core.Context; Steps : in out Natural);
   --  Replaying: injects this frame's events into Ctx and overrides
   --  Steps with the recorded count (0 for a frame with no line). At end
   --  of file, stops and requests quit.

   procedure After_Frame (S : in out Session; Ctx : Core.Context; Steps : Natural);
   --  Recording: writes the line for the frame just ended.

   function Image (E : Input.Event) return String;
   procedure Value (Tok : String; E : out Input.Event; Ok : out Boolean);

private

   Max_Line : constant := 4096;

   type Session is limited record
      M          : Mode := Off;
      Opened     : Boolean := False;
      --  next recorded line, parsed
      Have_Next  : Boolean := False;
      Next_Frame : Natural := 0;
      Next_Steps : Natural := 0;
      Next_Line  : String (1 .. Max_Line);
      Next_Last  : Natural := 0;
      Handle     : Natural := 0;   --  index into the body's file table
      End_Frame  : Natural := Natural'Last;
      Last_Frame : Natural := 0;   --  recording: frame number to write at Stop
   end record;

end Yarlib.Replay;
