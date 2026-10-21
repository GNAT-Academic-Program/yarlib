--  Input state as a value: what one frame sees. Down (held), Pressed
--  (went down this frame), Released (went up this frame), mouse. Built
--  from Bedrock.Input.Event values, so a frame's input can be recorded,
--  replayed, injected by a test, or produced by a script. Nothing here
--  touches a device.

with Bedrock.Input;

package Yarlib.Input with
  SPARK_Mode
is

   subtype Event is Bedrock.Input.Event;
   subtype Event_Queue is Bedrock.Input.Event_Queue;

   type State is record
      Down, Pressed, Released : Key_Set      := [others => False];
      Button_Down, Button_Pressed, Button_Released : Button_State :=
        [others => False];
      Mouse_X, Mouse_Y                             : Integer      := 0;
      Quit_Requested                               : Boolean      := False;
   end record;

   procedure Begin_Frame (S : in out State) with
     Post =>
      (for all K in Key => not S.Pressed (K) and then not S.Released (K));
   --  Clears the per-frame edges; Down persists.

   procedure Apply (S : in out State; E : Event);
   --  Window and gamepad events are ignored here; Core handles resize.

end Yarlib.Input;
