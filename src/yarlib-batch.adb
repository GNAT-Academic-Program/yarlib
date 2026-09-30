package body Yarlib.Batch with SPARK_Mode is

   -----------
   -- Reset --
   -----------

   procedure Reset (B : in out Batch) is
   begin
      B.Vertex_Count := 0;
      B.Call_Count := 0;
   end Reset;

   ---------------
   -- Push_Quad --
   ---------------

   --  PLACEHOLDER. The algorithm is in the spec header. Milestone 1.

   procedure Push_Quad
     (B : in out Batch; Tex : Texture_Id; P, UV : Quad_Corners; C : Color; Ok : out Boolean)
   is
      pragma Unreferenced (Tex, P, UV, C);
   begin
      if Dropped < Natural'Last then
         Dropped := Dropped + 1;
      end if;
      Ok := False;
   end Push_Quad;

end Yarlib.Batch;
