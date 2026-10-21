with Bedrock.Buffers; use Bedrock.Buffers;

package body Yarlib.Raster is

   ------------
   -- Sample --
   ------------

   function Sample (T : Bedrock.Buffers.Image; U, V : Scalar) return Color is
      CU : constant Scalar  := Clamp (U, 0.0, 1.0);
      CV : constant Scalar  := Clamp (V, 0.0, 1.0);
      X  : constant Natural :=
        Natural'Min
          (Width (T) - 1, Natural (Scalar'Floor (CU * Scalar (Width (T)))));
      Y  : constant Natural :=
        Natural'Min
          (Height (T) - 1, Natural (Scalar'Floor (CV * Scalar (Height (T)))));
   begin
      return Get (T, X, Y);
   end Sample;

   -------------------
   -- Fill_Triangle --
   -------------------

   procedure Fill_Triangle
     (F : in out Framebuffer; A, B, C : Vertex; T : Image_Access)
   is
      --  Edge function: twice the signed area of (P, Q, R).
      function Edge (PX, PY, QX, QY, RX, RY : Scalar) return Scalar is
        ((QX - PX) * (RY - PY) - (QY - PY) * (RX - PX));

      Area : constant Scalar := Edge (A.X, A.Y, B.X, B.Y, C.X, C.Y);

      function Clamp_X (V : Scalar) return Integer is
        (Integer'Max
           (0, Integer'Min (Width (F) - 1, Integer (Scalar'Floor (V)))));
      function Clamp_Y (V : Scalar) return Integer is
        (Integer'Max
           (0, Integer'Min (Height (F) - 1, Integer (Scalar'Floor (V)))));

      X0 : constant Integer :=
        Clamp_X (Scalar'Min (A.X, Scalar'Min (B.X, C.X)));
      X1 : constant Integer :=
        Clamp_X (Scalar'Max (A.X, Scalar'Max (B.X, C.X)));
      Y0 : constant Integer :=
        Clamp_Y (Scalar'Min (A.Y, Scalar'Min (B.Y, C.Y)));
      Y1 : constant Integer :=
        Clamp_Y (Scalar'Max (A.Y, Scalar'Max (B.Y, C.Y)));

      Sign : Scalar;

      function Lerp_Channel
        (CA, CB, CC : Channel; WA, WB, WC : Scalar) return Channel is
        (Channel
           (Clamp
              (Scalar (CA) * WA + Scalar (CB) * WB + Scalar (CC) * WC, 0.0,
               255.0)));
   begin
      if abs Area < 1.0E-6 then
         return;   --  degenerate
      end if;
      Sign := (if Area > 0.0 then Scalar (1.0) else Scalar (-1.0));
      for Y in Y0 .. Y1 loop
         for X in X0 .. X1 loop
            declare
               PX : constant Scalar := Scalar (X) + 0.5;   --  pixel centre
               PY : constant Scalar := Scalar (Y) + 0.5;
               W0 : constant Scalar :=
                 Edge (B.X, B.Y, C.X, C.Y, PX, PY) * Sign;
               W1 : constant Scalar :=
                 Edge (C.X, C.Y, A.X, A.Y, PX, PY) * Sign;
               W2 : constant Scalar :=
                 Edge (A.X, A.Y, B.X, B.Y, PX, PY) * Sign;
            begin
               if W0 >= 0.0 and then W1 >= 0.0 and then W2 >= 0.0 then
                  declare
                     Inv : constant Scalar := 1.0 / (abs Area);
                     WA  : constant Scalar := W0 * Inv;
                     WB  : constant Scalar := W1 * Inv;
                     WC  : constant Scalar := W2 * Inv;
                     Col : Color           :=
                       (Lerp_Channel (A.C.R, B.C.R, C.C.R, WA, WB, WC),
                        Lerp_Channel (A.C.G, B.C.G, C.C.G, WA, WB, WC),
                        Lerp_Channel (A.C.B, B.C.B, C.C.B, WA, WB, WC),
                        Lerp_Channel (A.C.A, B.C.A, C.C.A, WA, WB, WC));
                  begin
                     if T /= null then
                        Col :=
                          Modulate
                            (Col,
                             Sample
                               (T.all, A.U * WA + B.U * WB + C.U * WC,
                                A.V * WA + B.V * WB + C.V * WC));
                     end if;
                     F.Data (Row (Y), Column (X)) :=
                       Blend (Col, F.Data (Row (Y), Column (X)));
                  end;
               end if;
            end;
         end loop;
      end loop;
   end Fill_Triangle;

end Yarlib.Raster;
