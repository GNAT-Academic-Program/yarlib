--  OpenGL 1.1 port: the batch's vertex array is handed to GL as is.
--  Yarlib.Batch.Vertex is X, Y, U, V (Float) then RGBA (4 bytes), so
--  one interleaved array feeds glVertexPointer, glTexCoordPointer and
--  glColorPointer with a stride of Vertex'Size / 8. The GPU does the
--  rest; this file has no logic worth proving.

with Bedrock.Buffers;
with Interfaces.C;
with System.Storage_Elements;
with Yarlib.Renderer.GL; use Yarlib.Renderer.GL;

package body Yarlib.Renderer is

   use Interfaces.C;

   type GL_Ids is array (Texture_Id) of unsigned;
   Ids      : GL_Ids := [others => 0];
   Next_Tex : Natural := 1;
   Height_Now : Positive := 1;

   Stride : constant Sizei := Sizei (Batch.Vertex'Size / 8);
   --  4 floats + 4 bytes = 20; the record has no padding because Color
   --  is 32 bits and every component is 32-bit aligned.

   procedure Init (Width, Height : Positive) is
      White : aliased Color := Bedrock.Colors.White;
   begin
      glEnable (GL_TEXTURE_2D);
      glEnable (GL_BLEND);
      glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      glEnableClientState (GL_VERTEX_ARRAY);
      glEnableClientState (GL_TEXTURE_COORD_ARRAY);
      glEnableClientState (GL_COLOR_ARRAY);
      glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
      glPixelStorei (GL_PACK_ALIGNMENT, 1);
      Resize (Width, Height);
      --  Texture 0: 1x1 white.
      glGenTextures (1, Ids (White_Texture)'Address);
      glBindTexture (GL_TEXTURE_2D, Ids (White_Texture));
      glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, int (GL_NEAREST));
      glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, int (GL_NEAREST));
      glTexImage2D (GL_TEXTURE_2D, 0, int (GL_RGBA), 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE,
                    White'Address);
   end Init;

   procedure Resize (Width, Height : Positive) is
   begin
      Height_Now := Height;
      glViewport (0, 0, Sizei (Width), Sizei (Height));
      glMatrixMode (GL_PROJECTION);
      glLoadIdentity;
      --  Screen space: origin top-left, y down, like the rasterizer.
      glOrtho (0.0, double (Width), double (Height), 0.0, -1.0, 1.0);
      glMatrixMode (GL_MODELVIEW);
      glLoadIdentity;
   end Resize;

   procedure Clear (C : Color) is
   begin
      glClearColor (C_float (C.R) / 255.0, C_float (C.G) / 255.0,
                    C_float (C.B) / 255.0, C_float (C.A) / 255.0);
      glClear (GL_COLOR_BUFFER_BIT);
   end Clear;

   procedure Create_Texture (Img : Bitmap; T : out Texture; Ok : out Boolean) is
      Width  : constant Positive := Bedrock.Buffers.Width (Img);
      Height : constant Positive := Bedrock.Buffers.Height (Img);
   begin
      if Next_Tex > Natural (Texture_Id'Last) then
         T := (others => <>);
         Ok := False;
         return;
      end if;
      declare
         Id : constant Texture_Id := Texture_Id (Next_Tex);
      begin
         glGenTextures (1, Ids (Id)'Address);
         glBindTexture (GL_TEXTURE_2D, Ids (Id));
         glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, int (GL_NEAREST));
         glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, int (GL_NEAREST));
         glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, int (GL_CLAMP));
         glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, int (GL_CLAMP));
         glTexImage2D (GL_TEXTURE_2D, 0, int (GL_RGBA), Sizei (Width), Sizei (Height), 0,
                       GL_RGBA, GL_UNSIGNED_BYTE, Img.Data (0, 0)'Address);
         T := (Id => Id, Width => Width, Height => Height);
      end;
      Next_Tex := Next_Tex + 1;
      Ok := True;
   end Create_Texture;

   procedure Draw (B : Batch.Batch) is
      Base : constant System.Address := B.Vertices (1)'Address;
      use type System.Address;
      use System.Storage_Elements;
   begin
      glVertexPointer (2, GL_FLOAT, Stride, Base);
      glTexCoordPointer (2, GL_FLOAT, Stride, Base + 8);

      glColorPointer (4, GL_UNSIGNED_BYTE, Stride, Base + 16);
      for I in 1 .. B.Call_Count loop
         glBindTexture (GL_TEXTURE_2D, Ids (B.Calls (I).Tex));
         glDrawArrays (GL_TRIANGLES, int (B.Calls (I).First) - 1, Sizei (B.Calls (I).Count));
      end loop;
   end Draw;

   function Read_Pixel (X, Y : Natural) return Color is
      P : aliased Color;
   begin
      glFinish;
      --  GL's origin is bottom-left.
      glReadPixels (int (X), int (Height_Now - 1 - Y), 1, 1, GL_RGBA, GL_UNSIGNED_BYTE,
                    P'Address);
      return P;
   end Read_Pixel;

   procedure Read_Frame (Img : out Bitmap) is
      use Bedrock.Buffers;
      W : constant Positive := Width (Img);
      H : constant Positive := Height (Img);
      Tmp : Bitmap := Make (W, H);
   begin
      glFinish;
      --  One call for the whole frame, bottom-up as GL stores it, then
      --  flipped into Img's top-down rows.
      glReadPixels (0, 0, Sizei (W), Sizei (H), GL_RGBA, GL_UNSIGNED_BYTE, Tmp.Data (0, 0)'Address);
      for Y in 0 .. H - 1 loop
         for X in 0 .. W - 1 loop
            Set (Img, X, Y, Get (Tmp, X, H - 1 - Y));
         end loop;
      end loop;
   end Read_Frame;

   procedure Shutdown is
   begin
      for T in Texture_Id range 0 .. Texture_Id (Next_Tex - 1) loop
         if Ids (T) /= 0 then
            glDeleteTextures (1, Ids (T)'Address);
            Ids (T) := 0;
         end if;
      end loop;
      Next_Tex := 1;
   end Shutdown;

end Yarlib.Renderer;
