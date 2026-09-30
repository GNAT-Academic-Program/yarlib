with Yarlib.Textures;          use Yarlib.Textures;
with Yarlib.Engine.Components; use Yarlib.Engine.Components;
with Yarlib.Engine.World;      use Yarlib.Engine.World;

package body Yarlib.Engine.Systems is

   --------------
   -- Lifetime --
   --------------

   procedure Lifetime (Dt : Scalar) is
   begin
      for I in reverse 1 .. Lifetimes.Count loop
         declare
            L : Lifetime_Data := Lifetimes.Value (I);
         begin
            L.Seconds_Left := L.Seconds_Left - Dt;
            if L.Seconds_Left <= 0.0 then
               W.Destroy (Lifetimes.Owner (I));
            else
               Lifetimes.Update (I, L);
            end if;
         end;
      end loop;
   end Lifetime;

   --------------
   -- Movement --
   --------------

   procedure Movement (Dt : Scalar) is
   begin
      for I in 1 .. Velocities.Count loop
         declare
            E : constant Entity := Velocities.Owner (I);
         begin
            if Transforms.Has (E) then
               declare
                  T : Transform_Data := Transforms.Get (E);
                  Ok : Boolean;
               begin
                  T.Pos := T.Pos + Velocities.Value (I).V * Dt;
                  Transforms.Set (E, T, Ok);
               end;
            end if;
         end;
      end loop;
   end Movement;

   ------------
   -- Bounce --
   ------------

   procedure Bounce is
   begin
      for I in 1 .. Colliders.Count loop
         declare
            E : constant Entity := Colliders.Owner (I);
            C : constant Collider_Data := Colliders.Value (I);
         begin
            if C.Bounce and then Transforms.Has (E) and then Velocities.Has (E) then
               declare
                  T  : constant Transform_Data := Transforms.Get (E);
                  V  : Velocity_Data := Velocities.Get (E);
                  Ok : Boolean;
               begin
                  if (T.Pos.X < Arena.X and then V.V.X < 0.0)
                    or else (T.Pos.X + C.Size.X > Arena.X + Arena.Width and then V.V.X > 0.0)
                  then
                     V.V.X := -V.V.X;
                  end if;
                  if (T.Pos.Y < Arena.Y and then V.V.Y < 0.0)
                    or else (T.Pos.Y + C.Size.Y > Arena.Y + Arena.Height and then V.V.Y > 0.0)
                  then
                     V.V.Y := -V.V.Y;
                  end if;
                  Velocities.Set (E, V, Ok);
               end;
            end if;
         end;
      end loop;
   end Bounce;

   procedure Update (Dt : Scalar) is
   begin
      Lifetime (Dt);
      Movement (Dt);
      Bounce;
   end Update;

   ------------
   -- Render --
   ------------

   Max_Named : constant := 64;
   type Named_Texture is record
      Name : String (1 .. 32) := [others => ' '];
      Len  : Natural := 0;
      T    : Texture;
   end record;
   Named   : array (1 .. Max_Named) of Named_Texture;
   Named_N : Natural := 0;
   Checker : Texture;
   Have_Checker : Boolean := False;

   procedure Register_Texture (Name : String; T : Texture) is
   begin
      for I in 1 .. Named_N loop
         if Named (I).Name (1 .. Named (I).Len) = Name then
            Named (I).T := T;
            return;
         end if;
      end loop;
      if Named_N < Max_Named then
         Named_N := Named_N + 1;
         Named (Named_N).Name (1 .. Name'Length) := Name;
         Named (Named_N).Len := Name'Length;
         Named (Named_N).T := T;
      end if;
   end Register_Texture;

   function Lookup (Name : String) return Texture;
   function Lookup (Name : String) return Texture is
   begin
      if Name = "checker" then
         if not Have_Checker then
            Checker := Checkerboard (32, 32, 8, Orange, Purple);
            Have_Checker := True;
         end if;
         return Checker;
      end if;
      for I in 1 .. Named_N loop
         if Named (I).Name (1 .. Named (I).Len) = Name then
            return Named (I).T;
         end if;
      end loop;
      return (Id => White_Texture, Width => 1, Height => 1);
   end Lookup;

   procedure Render is
      --  Layers: draw the lowest first. Sprites are few; a pass per
      --  distinct layer is fine for a seed, a sort is milestone work.
      Lo : Integer := Integer'Last;
      Hi : Integer := Integer'First;
   begin
      for I in 1 .. Sprites.Count loop
         Lo := Integer'Min (Lo, Sprites.Value (I).Layer);
         Hi := Integer'Max (Hi, Sprites.Value (I).Layer);
      end loop;
      if Sprites.Count = 0 then
         return;
      end if;
      for Layer in Lo .. Hi loop
         for I in 1 .. Sprites.Count loop
            declare
               S : constant Sprite_Data := Sprites.Value (I);
               E : constant Entity := Sprites.Owner (I);
            begin
               if S.Layer = Layer and then Transforms.Has (E) then
                  declare
                     T  : constant Transform_Data := Transforms.Get (E);
                     Tx : constant Texture := Lookup (S.Tex (1 .. S.Tex_Len));
                  begin
                     Draw_Texture_Pro
                       (Tx,
                        Source => (0.0, 0.0, Scalar (Tx.Width), Scalar (Tx.Height)),
                        Dest   => (T.Pos.X + T.Size.X / 2.0, T.Pos.Y + T.Size.Y / 2.0,
                                   T.Size.X, T.Size.Y),
                        Origin => (T.Size.X / 2.0, T.Size.Y / 2.0),
                        Rotation => T.Rotation, Tint => S.Tint);
                  end;
               end if;
            end;
         end loop;
      end loop;
   end Render;

end Yarlib.Engine.Systems;
