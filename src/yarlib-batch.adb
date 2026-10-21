package body Yarlib.Batch with
  SPARK_Mode
is

   -----------
   -- Reset --
   -----------

   procedure Reset (B : in out Batch) is
   begin
      B.Vertex_Count := 0;
      B.Call_Count   := 0;
   end Reset;

   ---------------
   -- Push_Quad --
   ---------------

   --  PLACEHOLDER. The algorithm is in the spec header. Milestone 1.

   procedure Push_Quad
     (B  : in out Batch; Tex : Texture_Id; P, UV : Quad_Corners; C : Color;
      Ok :    out Boolean)
   is
   --  pragma Unreferenced (Tex, P, UV, C);
   begin

      --  Step 1
      --  we are adding vertices as 6 at a time, so if we are at the limit, we cannot add any more
      if B.Vertex_Count + 6 > Max_Vertices then
         Ok := False;
         return;
      end if;

      --  step 2
      --  if we have no calls yet, or the last call has a
      --  different texture, we need to add a new call
      if B.Call_Count = 0 or else B.Calls (B.Call_Count).Tex /= Tex then
         --  max draw calls, return out
         if B.Call_Count = Max_Calls then
            Ok := False;
            return;
         else
            --  add a new draw call and append to the draw call array
            B.Call_Count           := B.Call_Count + 1;
            B.Calls (B.Call_Count) :=
              (Tex, First => B.Vertex_Count + 1, Count => 0);
         end if;
      end if;

      --  step 3
      --  add 6 vertices -> p1, p2 ,p3 | p1, p3, p4
      B.Vertices (B.Vertex_Count + 1) :=
        (P (1).X, P (1).Y, UV (1).X, UV (1).Y, C);
      B.Vertices (B.Vertex_Count + 2) :=
        (P (2).X, P (2).Y, UV (2).X, UV (2).Y, C);
      B.Vertices (B.Vertex_Count + 3) :=
        (P (3).X, P (3).Y, UV (3).X, UV (3).Y, C);
      B.Vertices (B.Vertex_Count + 4) :=
        (P (1).X, P (1).Y, UV (1).X, UV (1).Y, C);
      B.Vertices (B.Vertex_Count + 5) :=
        (P (3).X, P (3).Y, UV (3).X, UV (3).Y, C);
      B.Vertices (B.Vertex_Count + 6) :=
        (P (4).X, P (4).Y, UV (4).X, UV (4).Y, C);
      B.Vertex_Count                  := B.Vertex_Count + 6;
      B.Calls (B.Call_Count).Count    := B.Calls (B.Call_Count).Count + 6;

      --  step 4
      Ok := True;

      --  if Dropped < Natural'Last then
      --  Dropped := Dropped + 1;
      --  end if;
      --  Ok := False;

      --  take screenshot:
      --  .\showcase\bin\arena.exe --frames 60

   end Push_Quad;

end Yarlib.Batch;
