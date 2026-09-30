--  Write a Bitmap to a PNG file: screenshots now, Load at milestone 3.
--  blocks), so it needs no zlib and is ~70 lines; files are large but
--  every viewer on every OS opens them. Compression is a milestone if
--  anyone cares; the format is the same.
--
--     Yarlib.PNG.Save (Screenshot, "shot.png");

package Yarlib.PNG is

   procedure Save (Img : Bitmap; File : String; Ok : out Boolean);

end Yarlib.PNG;
