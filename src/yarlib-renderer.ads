--  The GPU seam: textures in, batches out. One spec, one body per
--  port, selected by YARLIB_RENDERER:
--
--     null    Yarlib.Raster into a framebuffer in memory; tests read it
--     opengl  OpenGL 1.x client arrays (ports/gpu/opengl); needs a
--             context, which the sdl3 platform port creates
--
--  The port is deliberately dumb: no matrices, no sorting, no state
--  beyond "which texture is bound". Everything clever happens in
--  Yarlib.Batch, on the CPU, where it is portable and provable.

with Yarlib.Batch;

package Yarlib.Renderer is

   procedure Init (Width, Height : Positive);
   --  After Platform.Open. Sets the viewport and creates texture 0.

   procedure Resize (Width, Height : Positive);

   procedure Clear (C : Color);

   procedure Create_Texture (Img : Bitmap; T : out Texture; Ok : out Boolean);
   --  Ok = False: table full.

   procedure Draw (B : Batch.Batch)
     with Pre => Batch.Well_Formed (B);
   --  Draws every call, in order, with its texture.

   function Read_Pixel (X, Y : Natural) return Color;
   --  One pixel back, y down from the top. For tests. On opengl this
   --  is a round trip to the driver: never call it per pixel of a frame.

   procedure Read_Frame (Img : out Bitmap);
   --  The whole frame, one call. Img must be Make (Width, Height) of
   --  the current size. This is what screenshots use.

   procedure Shutdown;

end Yarlib.Renderer;
