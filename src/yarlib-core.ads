--  Core: window, frame loop, time, input, camera. raylib's rcore, with
--  the one thing raylib gets wrong fixed: there is no hidden global.
--
--  A Context is the state of one game view: window size, the batch,
--  input, clock, camera. Every operation takes one. The flat overloads
--  without a Context use Default, so a beginner writes
--
--     Init_Window (800, 450, "hello");
--     Draw_Rectangle (10, 10, 20, 20, Red);
--
--  and never learns Context exists, while the tests, the editor, and a
--  split-screen game hold their own. Same names, one extra parameter.
--
--  A Context is bounded and lives where you declare it. No heap.

with Bedrock; use Bedrock;
with Yarlib.Batch;
with Yarlib.Input;

package Yarlib.Core is

   type Context is limited private;

   function Default return not null access Context;
   --  The context the flat API uses. Declared in the body, so a game
   --  that never uses the flat API never touches it.

   ---------------------------------------------------------------------
   --  Camera
   ---------------------------------------------------------------------

   type Camera2D is record
      Offset   : Vector2 := (0.0, 0.0);   --  where Target lands on screen
      Target   : Vector2 := (0.0, 0.0);   --  world point under Offset
      Rotation : Degrees := 0.0;
      Zoom     : Scalar  := 1.0;
   end record;

   function World_To_Screen (Cam : Camera2D; P : Vector2) return Vector2;
   function Screen_To_World (Cam : Camera2D; P : Vector2) return Vector2 with
     Pre => Cam.Zoom /= 0.0;

   ---------------------------------------------------------------------
   --  Window and frame
   ---------------------------------------------------------------------

   procedure Init_Window
     (Ctx : in out Context; Width, Height : Positive; Title : String);
   --  Raises Program_Error if the platform cannot open a window. One
   --  window per process on every port so far; a second Context on the
   --  same window (the editor's viewport) shares the platform and gets
   --  its own batch, camera and input.

   function Window_Is_Open (Ctx : Context) return Boolean;
   function Window_Should_Close (Ctx : Context) return Boolean;
   procedure Close_Window (Ctx : in out Context);

   function Screen_Width (Ctx : Context) return Positive;
   function Screen_Height (Ctx : Context) return Positive;

   procedure Begin_Drawing (Ctx : in out Context);
   procedure Clear_Background (Ctx : in out Context; C : Color);
   procedure End_Drawing (Ctx : in out Context);
   --  Flushes the batch, swaps, polls events, updates time.

   procedure Begin_Mode_2D (Ctx : in out Context; Cam : Camera2D);
   procedure End_Mode_2D (Ctx : in out Context);
   --  Between the two, coordinates are world coordinates.

   ---------------------------------------------------------------------
   --  Time
   ---------------------------------------------------------------------

   function Get_Frame_Time (Ctx : Context) return Scalar;   --  seconds
   function Get_Time
     (Ctx : Context) return Scalar;         --  since Init_Window
   function Get_FPS (Ctx : Context) return Natural;

   ---------------------------------------------------------------------
   --  Input
   ---------------------------------------------------------------------

   function Is_Key_Down (Ctx : Context; K : Key) return Boolean;
   function Is_Key_Pressed (Ctx : Context; K : Key) return Boolean;
   function Is_Key_Released (Ctx : Context; K : Key) return Boolean;
   function Is_Mouse_Button_Down
     (Ctx : Context; B : Mouse_Button) return Boolean;
   function Is_Mouse_Button_Pressed
     (Ctx : Context; B : Mouse_Button) return Boolean;
   function Get_Mouse_Position (Ctx : Context) return Vector2;   --  screen
   function Get_Mouse_World
     (Ctx : Context) return Vector2;      --  through the camera

   function Input_State (Ctx : Context) return Input.State;
   --  The whole frame's input as a value.

   function Frame_Events (Ctx : Context) return Input.Event_Queue;
   --  Every event applied at the last End_Drawing, injected or from
   --  the platform, in order. Yarlib.Replay writes these down.

   function Frame_Number (Ctx : Context) return Natural;
   --  Number of End_Drawing calls since Init_Window.

   procedure Inject (Ctx : in out Context; E : Input.Event);
   --  Delivered at the next End_Drawing, before the platform's events.
   --  Tests and Replay use it; a game does not.

   procedure Set_Input_Source
     (Ctx : in out Context; Platform_Events : Boolean);
   --  False: ignore the platform, only injected events count. Replay.

   ---------------------------------------------------------------------
   --  Screen readback
   ---------------------------------------------------------------------

   function Get_Screen_Pixel (Ctx : Context; X, Y : Natural) return Color with
     Pre => X < Screen_Width (Ctx) and then Y < Screen_Height (Ctx);
   --  One pixel of the last frame. For tests. On a GPU this is a driver
   --  round trip; do not loop over a frame with it.

   function Screenshot (Ctx : Context) return Bitmap;
   --  The whole last frame, one readback. Yarlib.PNG.Save writes it.

   ---------------------------------------------------------------------
   --  For Shapes and Textures only. A game never calls this.
   ---------------------------------------------------------------------

   procedure Submit
     (Ctx : in out Context; Tex : Texture_Id; P, UV : Batch.Quad_Corners;
      C   :        Color);
   --  Applies the camera if one is active, pushes the quad, flushes
   --  and retries if the batch is full.

   ---------------------------------------------------------------------
   --  Flat API over Default. Same names, no Context.
   ---------------------------------------------------------------------

   procedure Init_Window (Width, Height : Positive; Title : String);
   function Window_Is_Open return Boolean;
   function Window_Should_Close return Boolean;
   procedure Close_Window;
   function Screen_Width return Positive;
   function Screen_Height return Positive;
   procedure Begin_Drawing;
   procedure Clear_Background (C : Color);
   procedure End_Drawing;
   procedure Begin_Mode_2D (Cam : Camera2D);
   procedure End_Mode_2D;
   function Get_Frame_Time return Scalar;
   function Get_Time return Scalar;
   function Get_FPS return Natural;
   function Is_Key_Down (K : Key) return Boolean;
   function Is_Key_Pressed (K : Key) return Boolean;
   function Is_Key_Released (K : Key) return Boolean;
   function Is_Mouse_Button_Down (B : Mouse_Button) return Boolean;
   function Is_Mouse_Button_Pressed (B : Mouse_Button) return Boolean;
   function Get_Mouse_Position return Vector2;
   function Get_Mouse_World return Vector2;
   function Get_Screen_Pixel (X, Y : Natural) return Color;
   function Screenshot return Bitmap;
   procedure Inject (E : Input.Event);

private

   type Context is limited record
      Open          : Boolean  := False;
      Width         : Positive := 1;
      Height        : Positive := 1;
      B             : Batch.Batch;
      In_State      : Input.State;
      Pending       : Input.Event_Queue;
      From_Platform : Boolean  := True;
      Applied       : Input.Event_Queue;
      Frames        : Natural  := 0;
      Cam           : Camera2D;
      Cam_Active    : Boolean  := False;
      Frame_Time    : Scalar   := 0.0;
      Last_Tick     : Duration := 0.0;
      FPS_Count     : Natural  := 0;
      FPS_Value     : Natural  := 0;
      FPS_Since     : Duration := 0.0;
   end record;

   type Context_Access is not null access all Context;

end Yarlib.Core;
