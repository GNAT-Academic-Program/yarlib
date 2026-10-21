--  yarlib: yet another raylib, except for the parts raylib gets wrong.
--  A flat, immediate-mode 2D game library in Ada, with the platform and
--  the GPU behind two seams, and an engine layer over it.
--
--     Init_Window (800, 450, "hello");
--     while not Window_Should_Close loop
--        Begin_Drawing;
--        Clear_Background (Ray_White);
--        Draw_Rectangle (100, 100, 200, 80, Red);
--        End_Drawing;
--     end loop;
--     Close_Window;
--
--  Root package. The vocabulary (Scalar, Degrees, Vector2, Rectangle,
--  Color and the palette, Image, Key, Mouse_Button) is bedrock's and
--  is not re-declared here: a game withs Bedrock, Bedrock.Colors and
--  Bedrock.Input alongside Yarlib, and every Yarlib child that needs
--  those types says so with its own with/use. Texture is yarlib's own:
--  a handle into the GPU.

with Bedrock;
with Bedrock.Buffers;
with Bedrock.Colors; use Bedrock.Colors;
with Bedrock.Input;  use Bedrock.Input;

package Yarlib with
  SPARK_Mode, Pure
is

   --  Only Color and Key are needed in this spec, hence the two use
   --  clauses above. Children with/use Bedrock themselves for the
   --  geometry types.

   subtype Bitmap is Bedrock.Buffers.Image;
   --  Called Bitmap here so the many Image functions (names, console
   --  responses) are not hidden by a type of the same name.

   ---------------------------------------------------------------------
   --  Textures: handles into the GPU. 0 is the built-in 1x1 white
   --  texture, so solid shapes are textured quads like everything else.
   ---------------------------------------------------------------------

   Max_Textures : constant := 256;
   type Texture_Id is range 0 .. Max_Textures;
   White_Texture : constant Texture_Id := 0;

   type Texture is record
      Id     : Texture_Id := White_Texture;
      Width  : Positive   := 1;
      Height : Positive   := 1;
   end record;

   No_Tint : Color renames White;
   --  Draw_Texture's default tint: the texture as it is.

   Quit_Key : constant Key := Key_Escape;
   --  Window_Should_Close is true after this key or a Quit event.

end Yarlib;
