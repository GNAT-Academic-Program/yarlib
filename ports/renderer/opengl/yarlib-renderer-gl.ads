--  Minimal OpenGL 1.1 binding: fixed-function, client-side vertex
--  arrays. Every entry point here is exported directly by libGL on
--  Linux/macOS and by opengl32.dll on Windows, so no loader is needed.
--  A modern-GL port (shaders, VBOs) is a milestone; it replaces this
--  file and the body next to it, and nothing else.

with Interfaces.C;
with System;

private package Yarlib.Renderer.GL is

   use Interfaces.C;

   subtype Enum is Interfaces.C.unsigned;
   subtype Sizei is Interfaces.C.int;
   subtype Bitfield is Interfaces.C.unsigned;

   GL_TRIANGLES        : constant Enum := 16#0004#;
   GL_TEXTURE_2D       : constant Enum := 16#0DE1#;
   GL_BLEND            : constant Enum := 16#0BE2#;
   GL_SRC_ALPHA        : constant Enum := 16#0302#;
   GL_ONE_MINUS_SRC_ALPHA : constant Enum := 16#0303#;
   GL_RGBA             : constant Enum := 16#1908#;
   GL_UNSIGNED_BYTE    : constant Enum := 16#1401#;
   GL_FLOAT            : constant Enum := 16#1406#;
   GL_NEAREST          : constant Enum := 16#2600#;
   GL_TEXTURE_MIN_FILTER : constant Enum := 16#2801#;
   GL_TEXTURE_MAG_FILTER : constant Enum := 16#2800#;
   GL_TEXTURE_WRAP_S   : constant Enum := 16#2802#;
   GL_TEXTURE_WRAP_T   : constant Enum := 16#2803#;
   GL_CLAMP            : constant Enum := 16#2900#;
   GL_COLOR_BUFFER_BIT : constant Bitfield := 16#4000#;
   GL_PROJECTION       : constant Enum := 16#1701#;
   GL_MODELVIEW        : constant Enum := 16#1700#;
   GL_VERTEX_ARRAY     : constant Enum := 16#8074#;
   GL_COLOR_ARRAY      : constant Enum := 16#8076#;
   GL_TEXTURE_COORD_ARRAY : constant Enum := 16#8078#;
   GL_PACK_ALIGNMENT   : constant Enum := 16#0D05#;
   GL_UNPACK_ALIGNMENT : constant Enum := 16#0CF5#;

   procedure glViewport (X, Y : int; W, H : Sizei)
     with Import, Convention => C, External_Name => "glViewport";
   procedure glClearColor (R, G, B, A : C_float)
     with Import, Convention => C, External_Name => "glClearColor";
   procedure glClear (Mask : Bitfield)
     with Import, Convention => C, External_Name => "glClear";
   procedure glEnable (Cap : Enum)
     with Import, Convention => C, External_Name => "glEnable";
   procedure glBlendFunc (S, D : Enum)
     with Import, Convention => C, External_Name => "glBlendFunc";
   procedure glMatrixMode (Mode : Enum)
     with Import, Convention => C, External_Name => "glMatrixMode";
   procedure glLoadIdentity
     with Import, Convention => C, External_Name => "glLoadIdentity";
   procedure glOrtho (L, R, B, T, N, F : double)
     with Import, Convention => C, External_Name => "glOrtho";
   procedure glGenTextures (N : Sizei; Ids : System.Address)
     with Import, Convention => C, External_Name => "glGenTextures";
   procedure glDeleteTextures (N : Sizei; Ids : System.Address)
     with Import, Convention => C, External_Name => "glDeleteTextures";
   procedure glBindTexture (Target : Enum; Id : unsigned)
     with Import, Convention => C, External_Name => "glBindTexture";
   procedure glTexImage2D
     (Target : Enum; Level : int; Internal : int; W, H : Sizei; Border : int;
      Format, Kind : Enum; Data : System.Address)
     with Import, Convention => C, External_Name => "glTexImage2D";
   procedure glTexParameteri (Target, Name : Enum; Value : int)
     with Import, Convention => C, External_Name => "glTexParameteri";
   procedure glPixelStorei (Name : Enum; Value : int)
     with Import, Convention => C, External_Name => "glPixelStorei";
   procedure glEnableClientState (Cap : Enum)
     with Import, Convention => C, External_Name => "glEnableClientState";
   procedure glVertexPointer (Size : int; Kind : Enum; Stride : Sizei; P : System.Address)
     with Import, Convention => C, External_Name => "glVertexPointer";



   procedure glTexCoordPointer (Size   : int; 
                                Kind   : Enum; 
                                Stride : Sizei; 
                                P      : System.Address)

     with Import, 
          Convention    => C, 
          External_Name => "glTexCoordPointer";




   procedure glColorPointer (Size : int; Kind : Enum; Stride : Sizei; P : System.Address)
     with Import, Convention => C, External_Name => "glColorPointer";
   procedure glDrawArrays (Mode : Enum; First : int; Count : Sizei)
     with Import, Convention => C, External_Name => "glDrawArrays";
   procedure glReadPixels
     (X, Y : int; W, H : Sizei; Format, Kind : Enum; Data : System.Address)
     with Import, Convention => C, External_Name => "glReadPixels";
   procedure glFinish
     with Import, Convention => C, External_Name => "glFinish";

end Yarlib.Renderer.GL;
