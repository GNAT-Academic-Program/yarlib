--  Shapes: solid-colour primitives. raylib's rshapes. Every one is a
--  quad (or a few) on the white texture, pushed through Core.Submit.
--  Each has a Context form and a flat form over Core.Default.

with Bedrock; use Bedrock;
with Yarlib.Core; use Yarlib.Core;

package Yarlib.Shapes is

   procedure Draw_Rectangle (Ctx : in out Context; X, Y, Width, Height : Integer; C : Color);
   procedure Draw_Rectangle_Rec (Ctx : in out Context; R : Rectangle; C : Color);
   procedure Draw_Rectangle_Pro
     (Ctx : in out Context; R : Rectangle; Origin : Vector2; Rotation : Degrees; C : Color);
   --  Rotation clockwise about R's position + Origin.
   procedure Draw_Rectangle_Lines
     (Ctx : in out Context; X, Y, Width, Height : Integer; C : Color);
   procedure Draw_Line (Ctx : in out Context; X1, Y1, X2, Y2 : Integer; C : Color);
   procedure Draw_Line_Ex
     (Ctx : in out Context; Start, Stop : Vector2; Thick : Scalar; C : Color);

   procedure Draw_Rectangle (X, Y, Width, Height : Integer; C : Color);
   procedure Draw_Rectangle_Rec (R : Rectangle; C : Color);
   procedure Draw_Rectangle_Pro (R : Rectangle; Origin : Vector2; Rotation : Degrees; C : Color);
   procedure Draw_Rectangle_Lines (X, Y, Width, Height : Integer; C : Color);
   procedure Draw_Line (X1, Y1, X2, Y2 : Integer; C : Color);
   procedure Draw_Line_Ex (Start, Stop : Vector2; Thick : Scalar; C : Color);

   --  Circles, triangles, polygons: milestone 4. Fans of triangles;
   --  add them here, never in a game.

end Yarlib.Shapes;
