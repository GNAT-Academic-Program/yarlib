--  Software rasterizer: draws a batch into a Bedrock image, on the
--  CPU. This is the "null" GPU port's engine, so the tests can read
--  pixels back with no display and no driver, and it is the renderer
--  for a platform without a GPU (portal on a bare framebuffer).
--  Nearest-neighbour texture sampling, straight-alpha blend, no
--  anti-aliasing. Correct, not fast.
--
--  Triangle fill is the classic half-space test: for every pixel in
--  the triangle's bounding box, the three edge functions say inside or
--  out; barycentric weights interpolate UV and colour.

with Bedrock; use Bedrock;
with Bedrock.Buffers;

package Yarlib.Raster is

   subtype Framebuffer is Bedrock.Buffers.Image;

   type Image_Access is access Bedrock.Buffers.Image;
   type Image_Table is array (Texture_Id) of Image_Access;
   --  Textures the rasterizer can sample; the port fills it.

   function Sample (T : Bedrock.Buffers.Image; U, V : Scalar) return Color;
   --  Nearest neighbour, coordinates clamped to 0 .. 1.

   type Vertex is record
      X, Y, U, V : Scalar := 0.0;
      C : Color := White;
   end record;

   procedure Fill_Triangle (F : in out Framebuffer; A, B, C : Vertex; T : Image_Access);
   --  T = null: untextured. Colour is vertex colour times texel,
   --  blended over the framebuffer by its alpha.

end Yarlib.Raster;
