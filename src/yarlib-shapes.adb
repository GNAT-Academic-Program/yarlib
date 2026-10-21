with Ada.Numerics.Elementary_Functions;
with Yarlib.Batch;

package body Yarlib.Shapes is

   Unit_UV : constant Batch.Quad_Corners :=
     [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];

   procedure Draw_Rectangle
     (Ctx : in out Context; X, Y, Width, Height : Integer; C : Color)
   is
   begin
      Draw_Rectangle_Rec
        (Ctx, (Scalar (X), Scalar (Y), Scalar (Width), Scalar (Height)), C);
   end Draw_Rectangle;

   procedure Draw_Rectangle_Rec
     (Ctx : in out Context; R : Rectangle; C : Color)
   is
      P : constant Batch.Quad_Corners :=
        [(R.X, R.Y), (R.X + R.Width, R.Y), (R.X + R.Width, R.Y + R.Height),
        (R.X, R.Y + R.Height)];
   begin
      Submit (Ctx, White_Texture, P, Unit_UV, C);
   end Draw_Rectangle_Rec;

   procedure Draw_Rectangle_Pro
     (Ctx      : in out Context; R : Rectangle; Origin : Vector2;
      Rotation :        Degrees; C : Color)
   is
      use Ada.Numerics.Elementary_Functions;
      Rad : constant Float  := Float (Rotation) * Ada.Numerics.Pi / 180.0;
      Cs  : constant Scalar := Scalar (Cos (Rad));
      Sn  : constant Scalar := Scalar (Sin (Rad));
      function Rot (LX, LY : Scalar) return Vector2 is
        ((R.X + LX * Cs - LY * Sn, R.Y + LX * Sn + LY * Cs));
      P : constant Batch.Quad_Corners :=
        [Rot (-Origin.X, -Origin.Y), Rot (R.Width - Origin.X, -Origin.Y),
        Rot (R.Width - Origin.X, R.Height - Origin.Y),
        Rot (-Origin.X, R.Height - Origin.Y)];
   begin
      Submit (Ctx, White_Texture, P, Unit_UV, C);
   end Draw_Rectangle_Pro;

   procedure Draw_Rectangle_Lines
     (Ctx : in out Context; X, Y, Width, Height : Integer; C : Color)
   is
   begin
      Draw_Rectangle (Ctx, X, Y, Width, 1, C);
      Draw_Rectangle (Ctx, X, Y + Height - 1, Width, 1, C);
      Draw_Rectangle (Ctx, X, Y, 1, Height, C);
      Draw_Rectangle (Ctx, X + Width - 1, Y, 1, Height, C);
   end Draw_Rectangle_Lines;

   procedure Draw_Line
     (Ctx : in out Context; X1, Y1, X2, Y2 : Integer; C : Color)
   is
   begin
      Draw_Line_Ex
        (Ctx, (Scalar (X1), Scalar (Y1)), (Scalar (X2), Scalar (Y2)), 1.0, C);
   end Draw_Line;

   procedure Draw_Line_Ex
     (Ctx : in out Context; Start, Stop : Vector2; Thick : Scalar; C : Color)
   is
      use Ada.Numerics.Elementary_Functions;
      D   : constant Vector2 := Stop - Start;
      Len : constant Scalar  := Scalar (Sqrt (Float (D.X * D.X + D.Y * D.Y)));
   begin
      if Len <= 0.0 then
         return;
      end if;
      declare
         N : constant Vector2            :=
           (-D.Y / Len * Thick / 2.0, D.X / Len * Thick / 2.0);
         P : constant Batch.Quad_Corners :=
           [Start - N, Stop - N, Stop + N, Start + N];
      begin
         Submit (Ctx, White_Texture, P, Unit_UV, C);
      end;
   end Draw_Line_Ex;

   ----------
   -- Flat --
   ----------

   procedure Draw_Rectangle (X, Y, Width, Height : Integer; C : Color) is
   begin
      Draw_Rectangle (Default.all, X, Y, Width, Height, C);
   end Draw_Rectangle;
   procedure Draw_Rectangle_Rec (R : Rectangle; C : Color) is
   begin
      Draw_Rectangle_Rec (Default.all, R, C);
   end Draw_Rectangle_Rec;
   procedure Draw_Rectangle_Pro
     (R : Rectangle; Origin : Vector2; Rotation : Degrees; C : Color)
   is
   begin
      Draw_Rectangle_Pro (Default.all, R, Origin, Rotation, C);
   end Draw_Rectangle_Pro;
   procedure Draw_Rectangle_Lines (X, Y, Width, Height : Integer; C : Color) is
   begin
      Draw_Rectangle_Lines (Default.all, X, Y, Width, Height, C);
   end Draw_Rectangle_Lines;
   procedure Draw_Line (X1, Y1, X2, Y2 : Integer; C : Color) is
   begin
      Draw_Line (Default.all, X1, Y1, X2, Y2, C);
   end Draw_Line;
   procedure Draw_Line_Ex (Start, Stop : Vector2; Thick : Scalar; C : Color) is
   begin
      Draw_Line_Ex (Default.all, Start, Stop, Thick, C);
   end Draw_Line_Ex;

end Yarlib.Shapes;
