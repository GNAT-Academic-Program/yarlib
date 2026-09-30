with Ada.Streams.Stream_IO;
with Bedrock.Buffers; use Bedrock.Buffers;
with Interfaces;      use Interfaces;

package body Yarlib.PNG is

   use Ada.Streams;

   function CRC32 (Data : Stream_Element_Array) return Unsigned_32;
   function Adler32 (Data : Stream_Element_Array) return Unsigned_32;
   function Be32 (V : Unsigned_32) return Stream_Element_Array;

   Empty : constant Stream_Element_Array (1 .. 0) := [];

   --  CRC-32 (PNG chunks) and Adler-32 (zlib stream), both from the
   --  respective specs, table-free.

   function CRC32 (Data : Stream_Element_Array) return Unsigned_32 is
      C : Unsigned_32 := 16#FFFF_FFFF#;
   begin
      for B of Data loop
         C := C xor Unsigned_32 (B);
         for K in 1 .. 8 loop
            C := (if (C and 1) /= 0 then Shift_Right (C, 1) xor 16#EDB8_8320#
                  else Shift_Right (C, 1));
         end loop;
      end loop;
      return C xor 16#FFFF_FFFF#;
   end CRC32;

   function Adler32 (Data : Stream_Element_Array) return Unsigned_32 is
      A : Unsigned_32 := 1;
      B : Unsigned_32 := 0;
   begin
      for X of Data loop
         A := (A + Unsigned_32 (X)) mod 65_521;
         B := (B + A) mod 65_521;
      end loop;
      return Shift_Left (B, 16) or A;
   end Adler32;

   function Be32 (V : Unsigned_32) return Stream_Element_Array is
     [Stream_Element (Shift_Right (V, 24) and 255), Stream_Element (Shift_Right (V, 16) and 255),
      Stream_Element (Shift_Right (V, 8) and 255), Stream_Element (V and 255)];

   procedure Save (Img : Bitmap; File : String; Ok : out Boolean) is
      use Ada.Streams.Stream_IO;
      F : File_Type;
      W : constant Positive := Width (Img);
      H : constant Positive := Height (Img);
      Row_Bytes : constant Natural := 1 + 4 * W;   --  filter byte + RGBA
      Raw : Stream_Element_Array (1 .. Stream_Element_Offset (Row_Bytes * H));
      P : Stream_Element_Offset := 1;

      procedure Chunk (Kind : String; Data : Stream_Element_Array);
      procedure Chunk (Kind : String; Data : Stream_Element_Array) is
         Body_Bytes : Stream_Element_Array (1 .. Stream_Element_Offset (Kind'Length) + Data'Length);
      begin
         for I in Kind'Range loop
            Body_Bytes (Stream_Element_Offset (I - Kind'First + 1)) :=
              Stream_Element (Character'Pos (Kind (I)));
         end loop;
         Body_Bytes (Stream_Element_Offset (Kind'Length) + 1 .. Body_Bytes'Last) := Data;
         Write (F, Be32 (Unsigned_32 (Data'Length)));
         Write (F, Body_Bytes);
         Write (F, Be32 (CRC32 (Body_Bytes)));
      end Chunk;
   begin
      Ok := False;
      --  Scanlines: filter 0 then RGBA.
      for Y in 0 .. H - 1 loop
         Raw (P) := 0;
         P := P + 1;
         for X in 0 .. W - 1 loop
            declare
               C : constant Color := Get (Img, X, Y);
            begin
               Raw (P) := Stream_Element (C.R);
               Raw (P + 1) := Stream_Element (C.G);
               Raw (P + 2) := Stream_Element (C.B);
               Raw (P + 3) := Stream_Element (C.A);
               P := P + 4;
            end;
         end loop;
      end loop;

      Create (F, Out_File, File);
      Write (F, [137, 80, 78, 71, 13, 10, 26, 10]);
      Chunk ("IHDR", Be32 (Unsigned_32 (W)) & Be32 (Unsigned_32 (H))
                     & [8, 6, 0, 0, 0]);   --  8-bit RGBA, deflate, no filter, no interlace

      --  zlib stream: header, stored deflate blocks of at most 65535
      --  bytes, Adler-32 of the raw data.
      declare
         Max_Block : constant := 65_535;
         Total : constant Natural := Raw'Length;
         Blocks : constant Natural := (Total + Max_Block - 1) / Max_Block;
         Z : Stream_Element_Array
           (1 .. 2 + Stream_Element_Offset (Total + 5 * Blocks) + 4);
         Q : Stream_Element_Offset := 1;
         Done : Natural := 0;
      begin
         Z (1) := 16#78#;
         Z (2) := 16#01#;
         Q := 3;
         while Done < Total loop
            declare
               N : constant Natural := Natural'Min (Max_Block, Total - Done);
               Last : constant Boolean := Done + N = Total;
            begin
               Z (Q) := (if Last then 1 else 0);
               Z (Q + 1) := Stream_Element (N mod 256);
               Z (Q + 2) := Stream_Element (N / 256);
               Z (Q + 3) := Stream_Element ((not Unsigned_16 (N)) mod 256);
               Z (Q + 4) := Stream_Element ((not Unsigned_16 (N)) / 256);
               Z (Q + 5 .. Q + 4 + Stream_Element_Offset (N)) :=
                 Raw (Stream_Element_Offset (Done) + 1 .. Stream_Element_Offset (Done + N));
               Q := Q + 5 + Stream_Element_Offset (N);
               Done := Done + N;
            end;
         end loop;
         Z (Q .. Q + 3) := Be32 (Adler32 (Raw));
         Chunk ("IDAT", Z (1 .. Q + 3));
      end;
      Chunk ("IEND", Empty);
      Close (F);
      Ok := True;
   exception
      when others =>
         Ok := False;
   end Save;

end Yarlib.PNG;
