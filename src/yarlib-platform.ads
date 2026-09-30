--  The platform seam: window, events, buffer swap, clock. One spec,
--  one body per port, selected by the gpr scenario variable
--  YARLIB_PLATFORM:
--
--     null   no window; Poll never returns an event; for tests and CI
--     sdl3   SDL3 with an OpenGL context (ports/platform/sdl3)
--     portal the GAP portal library, when it lands (milestone 6)
--
--  Nothing above this package names SDL, X11, Win32 or portal. A game
--  compiled against the null port runs headless to completion, which
--  is how the tests drive Core.

with Yarlib.Input;

package Yarlib.Platform is

   subtype Event is Input.Event;

   procedure Open (Width, Height : Positive; Title : String; Ok : out Boolean);
   --  Creates the window and, on GPU ports, the graphics context.

   procedure Close;

   procedure Poll (E : out Event; Got : out Boolean);
   --  One event, oldest first. Got = False when the queue is empty.

   procedure Swap;
   --  Present the back buffer. May block for vsync.

   function Now return Duration;
   --  Seconds since Open, monotonic.

end Yarlib.Platform;
