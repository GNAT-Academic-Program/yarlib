--  Null platform: no window, no events, a real clock. For tests and CI.

with Ada.Calendar;
with Bedrock.Input;

package body Yarlib.Platform is

   Epoch : Ada.Calendar.Time := Ada.Calendar.Clock;

   procedure Open (Width, Height : Positive; Title : String; Ok : out Boolean)
   is
      pragma Unreferenced (Width, Height, Title);
   begin
      Epoch := Ada.Calendar.Clock;
      Ok    := True;
   end Open;

   procedure Close is null;

   procedure Poll (E : out Event; Got : out Boolean) is
   begin
      E   := Bedrock.Input.Quit_Event;
      Got := False;
   end Poll;

   procedure Swap is null;

   function Now return Duration is
      use Ada.Calendar;
   begin
      return Clock - Epoch;
   end Now;

end Yarlib.Platform;
