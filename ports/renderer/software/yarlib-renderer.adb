--  Software renderer: Yarlib.Raster into a Bedrock image on the heap.
--  Complete without a GPU: tests read the frame back, and a platform
--  port can present it to a window (portal, milestone 6).

with Ada.Unchecked_Deallocation;
with Bedrock.Buffers; use Bedrock.Buffers;
with Yarlib.Raster;

package body Yarlib.Renderer is

   use type Raster.Image_Access;
   use type Batch.Vertex_Index;

   procedure Free is new Ada.Unchecked_Deallocation (Bedrock.Buffers.Image, Raster.Image_Access);

   FB       : Raster.Image_Access;
   Images   : Raster.Image_Table := [others => null];
   Next_Tex : Natural := 1;

   procedure Init (Width, Height : Positive) is
   begin
      Resize (Width, Height);
      --  Texture 0: 1x1 white.
      if Images (White_Texture) = null then
         Images (White_Texture) := new Bedrock.Buffers.Image'(Make (1, 1, White));
      end if;
   end Init;

   procedure Resize (Width, Height : Positive) is
   begin
      if FB /= null then
         Free (FB);
      end if;
      FB := new Bedrock.Buffers.Image'(Make (Width, Height, Black));
   end Resize;

   procedure Clear (C : Color) is
   begin
      Fill (FB.all, C);
   end Clear;

   procedure Create_Texture (Img : Bitmap; T : out Texture; Ok : out Boolean) is
   begin
      if Next_Tex > Natural (Texture_Id'Last) then
         T := (others => <>);
         Ok := False;
         return;
      end if;
      Images (Texture_Id (Next_Tex)) := new Bedrock.Buffers.Image'(Img);
      T := (Id => Texture_Id (Next_Tex), Width => Width (Img), Height => Height (Img));
      Next_Tex := Next_Tex + 1;
      Ok := True;
   end Create_Texture;

   procedure Draw (B : Batch.Batch) is
      function RV (V : Batch.Vertex) return Raster.Vertex is
        ((V.X, V.Y, V.U, V.V, V.C));
   begin
      for I in 1 .. B.Call_Count loop
         declare
            Call : Batch.Draw_Call renames B.Calls (I);
            Img  : constant Raster.Image_Access :=
              (if Call.Tex = White_Texture then null else Images (Call.Tex));
            J    : Batch.Vertex_Index := Call.First;
         begin
            while J + 2 <= Call.First + Call.Count - 1 loop
               Raster.Fill_Triangle
                 (FB.all, RV (B.Vertices (J)), RV (B.Vertices (J + 1)),
                  RV (B.Vertices (J + 2)), Img);
               J := J + 3;
            end loop;
         end;
      end loop;
   end Draw;

   function Read_Pixel (X, Y : Natural) return Color is (Get (FB.all, X, Y));

   procedure Read_Frame (Img : out Bitmap) is
   begin
      Img := FB.all;
   end Read_Frame;

   procedure Shutdown is
   begin
      if FB /= null then
         Free (FB);
      end if;
      for T in Images'Range loop
         if Images (T) /= null then
            Free (Images (T));
         end if;
      end loop;
      Next_Tex := 1;
   end Shutdown;

end Yarlib.Renderer;
