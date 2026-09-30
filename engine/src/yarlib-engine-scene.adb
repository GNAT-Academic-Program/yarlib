with Bedrock; use Bedrock;
with Ada.Calendar;
with Ada.Directories;
with Ada.Text_IO;
with ECS;
with Yarlib.Engine.Components; use Yarlib.Engine.Components;
with Yarlib.Engine.World;      use Yarlib.Engine.World;

package body Yarlib.Engine.Scene is

   use type ECS.Entity;

   ---------------------------------------------------------------------
   --  Tokenizer over one line
   ---------------------------------------------------------------------

   type Cursor is record
      P : Natural;
   end record;

   function Next_Token (L : String; C : in out Cursor) return String;
   function Next_Token (L : String; C : in out Cursor) return String is
      Start : Natural;
   begin
      while C.P <= L'Last and then (L (C.P) = ' ' or else L (C.P) = ASCII.HT) loop
         C.P := C.P + 1;
      end loop;
      Start := C.P;
      while C.P <= L'Last and then L (C.P) /= ' ' and then L (C.P) /= ASCII.HT loop
         C.P := C.P + 1;
      end loop;
      return L (Start .. C.P - 1);
   end Next_Token;

   --  Optional numeric field: Default when the token is missing.
   procedure Num (L : String; C : in out Cursor; V : in out Scalar; Ok : in out Boolean);
   procedure Num (L : String; C : in out Cursor; V : in out Scalar; Ok : in out Boolean) is
      T : constant String := Next_Token (L, C);
   begin
      if T'Length > 0 then
         V := Scalar'Value (T);
      end if;
   exception
      when Constraint_Error =>
         Ok := False;
   end Num;

   procedure Chan (L : String; C : in out Cursor; V : in out Channel; Ok : in out Boolean);
   procedure Chan (L : String; C : in out Cursor; V : in out Channel; Ok : in out Boolean) is
      T : constant String := Next_Token (L, C);
   begin
      if T'Length > 0 then
         V := Channel (Natural'Value (T));
      end if;
   exception
      when Constraint_Error =>
         Ok := False;
   end Chan;

   ---------------------------------------------------------------------
   --  One line into the world
   ---------------------------------------------------------------------

   Current : Entity := No_Entity;

   procedure Apply_Line (L : String; Ok : out Boolean; Why : out String; Why_Last : out Natural);
   procedure Apply_Line (L : String; Ok : out Boolean; Why : out String; Why_Last : out Natural)
   is
      C   : Cursor := (P => L'First);
      Set_Ok : Boolean;
      procedure Fail (Msg : String);
      procedure Fail (Msg : String) is
         N : constant Natural := Natural'Min (Msg'Length, Why'Length);
      begin
         Why (Why'First .. Why'First + N - 1) := Msg (Msg'First .. Msg'First + N - 1);
         Why_Last := N;
         Ok := False;
      end Fail;
   begin
      Ok := True;
      Why_Last := 0;
      declare
         Head : constant String := Next_Token (L, C);
      begin
         if Head'Length = 0 or else Head (Head'First) = '#' then
            return;
         elsif Head = "entity" then
            declare
               N : constant String := Next_Token (L, C);
            begin
               if N'Length = 0 or else N'Length > Max_Name then
                  Fail ("entity needs a name of 1 .. 32 characters");
                  return;
               end if;
               Current := W.Create;
               if Current = No_Entity then
                  Fail ("world full");
                  return;
               end if;
               Names.Set (Current, To_Name (N), Set_Ok);
               if not Set_Ok then
                  Fail ("cannot attach name (escape milestone 1?)");
               end if;
            end;
         elsif Current = No_Entity then
            Fail ("component before any entity");
         elsif Head = "transform" then
            declare
               D : Transform_Data;
               R : Scalar := 0.0;
            begin
               Num (L, C, D.Pos.X, Ok); Num (L, C, D.Pos.Y, Ok);
               Num (L, C, D.Size.X, Ok); Num (L, C, D.Size.Y, Ok);
               Num (L, C, R, Ok);
               D.Rotation := Degrees (R);
               if Ok then
                  Transforms.Set (Current, D, Set_Ok);
                  Ok := Set_Ok;
               end if;
               if not Ok then
                  Fail ("transform x y [w h rotation]");
               end if;
            end;
         elsif Head = "velocity" then
            declare
               D : Velocity_Data;
            begin
               Num (L, C, D.V.X, Ok); Num (L, C, D.V.Y, Ok);
               if Ok then
                  Velocities.Set (Current, D, Set_Ok);
                  Ok := Set_Ok;
               end if;
               if not Ok then
                  Fail ("velocity vx vy");
               end if;
            end;
         elsif Head = "sprite" then
            declare
               D : Sprite_Data;
               T : constant String := Next_Token (L, C);
               Layer : Scalar := 0.0;
            begin
               if T'Length in 1 .. Max_Texture_Name then
                  D.Tex := [others => ' '];
                  D.Tex (1 .. T'Length) := T;
                  D.Tex_Len := T'Length;
               end if;
               Chan (L, C, D.Tint.R, Ok); Chan (L, C, D.Tint.G, Ok);
               Chan (L, C, D.Tint.B, Ok); Chan (L, C, D.Tint.A, Ok);
               Num (L, C, Layer, Ok);
               D.Layer := Integer (Layer);
               if Ok then
                  Sprites.Set (Current, D, Set_Ok);
                  Ok := Set_Ok;
               end if;
               if not Ok then
                  Fail ("sprite TEXTURE [r g b a layer]");
               end if;
            end;
         elsif Head = "collider" then
            declare
               D : Collider_Data;
            begin
               Num (L, C, D.Size.X, Ok); Num (L, C, D.Size.Y, Ok);
               declare
                  B : constant String := Next_Token (L, C);
               begin
                  if B = "nobounce" then
                     D.Bounce := False;
                  elsif B'Length > 0 and then B /= "bounce" then
                     Ok := False;
                  end if;
               end;
               if Ok then
                  Colliders.Set (Current, D, Set_Ok);
                  Ok := Set_Ok;
               end if;
               if not Ok then
                  Fail ("collider w h [bounce|nobounce]");
               end if;
            end;
         elsif Head = "lifetime" then
            declare
               D : Lifetime_Data;
            begin
               Num (L, C, D.Seconds_Left, Ok);
               if Ok then
                  Lifetimes.Set (Current, D, Set_Ok);
                  Ok := Set_Ok;
               end if;
               if not Ok then
                  Fail ("lifetime seconds");
               end if;
            end;
         else
            Fail ("unknown component " & Head);
         end if;
      end;
   end Apply_Line;

   ----------
   -- Load --
   ----------

   procedure Load (File : String; Ok : out Boolean; Error : out String; Last : out Natural) is
      use Ada.Text_IO;
      F    : File_Type;
      N    : Natural := 0;
      Why  : String (1 .. 100);
      WL   : Natural;
      LOk  : Boolean;
   begin
      Error := [others => ' '];
      Last := 0;
      Ok := False;
      W.Clear;
      Current := No_Entity;
      Open (F, In_File, File);
      while not End_Of_File (F) loop
         N := N + 1;
         Apply_Line (Get_Line (F), LOk, Why, WL);
         if not LOk then
            declare
               Msg : constant String := "line" & N'Image & ": " & Why (1 .. WL);
            begin
               Last := Natural'Min (Msg'Length, Error'Length);
               Error (Error'First .. Error'First + Last - 1) := Msg (1 .. Last);
            end;
            Close (F);
            return;
         end if;
      end loop;
      Close (F);
      Ok := True;
   exception
      when others =>
         declare
            Msg : constant String := "cannot read " & File;
         begin
            Last := Natural'Min (Msg'Length, Error'Length);
            Error (Error'First .. Error'First + Last - 1) := Msg (1 .. Last);
         end;
   end Load;

   ------------------
   -- Parse_Entity --
   ------------------

   procedure Parse_Entity (Lines : String; Ok : out Boolean) is
      Start : Natural := Lines'First;
      Why   : String (1 .. 100);
      WL    : Natural;
      LOk   : Boolean;
   begin
      Ok := True;
      Current := No_Entity;
      for I in Lines'First .. Lines'Last + 1 loop
         if I > Lines'Last or else Lines (I) = ASCII.LF then
            Apply_Line (Lines (Start .. I - 1), LOk, Why, WL);
            Ok := Ok and LOk;
            Start := I + 1;
         end if;
      end loop;
   end Parse_Entity;

   procedure Parse_Entity_On (E : World.Entity; Line : String; Ok : out Boolean) is
      Why : String (1 .. 100);
      WL  : Natural;
   begin
      Current := E;
      Apply_Line (Line, Ok, Why, WL);
   end Parse_Entity_On;

   ----------
   -- Save --
   ----------

   function Img (S : Scalar) return String;
   function Img (S : Scalar) return String is
      I : constant Integer := Integer (S);
   begin
      if Scalar (I) = S then
         declare
            R : constant String := I'Image;
         begin
            return R (R'First + 1 .. R'Last);
         end;
      end if;
      declare
         R : constant String := S'Image;
      begin
         return (if R (R'First) = ' ' then R (R'First + 1 .. R'Last) else R);
      end;
   end Img;

   procedure Save (File : String; Ok : out Boolean) is
      use Ada.Text_IO;
      F : File_Type;
   begin
      Create (F, Out_File, File);
      Put_Line (F, "# yarlib scene v1");
      for I in 1 .. Names.Count loop
         declare
            E : constant Entity := Names.Owner (I);
         begin
            Put_Line (F, "entity " & Image (Names.Value (I)));
            if Transforms.Has (E) then
               declare
                  T : constant Transform_Data := Transforms.Get (E);
               begin
                  Put_Line (F, "  transform " & Img (T.Pos.X) & " " & Img (T.Pos.Y) & " "
                            & Img (T.Size.X) & " " & Img (T.Size.Y) & " "
                            & Img (Scalar (T.Rotation)));
               end;
            end if;
            if Velocities.Has (E) then
               declare
                  V : constant Velocity_Data := Velocities.Get (E);
               begin
                  Put_Line (F, "  velocity " & Img (V.V.X) & " " & Img (V.V.Y));
               end;
            end if;
            if Sprites.Has (E) then
               declare
                  S : constant Sprite_Data := Sprites.Get (E);
               begin
                  Put_Line (F, "  sprite " & S.Tex (1 .. S.Tex_Len) & S.Tint.R'Image
                            & S.Tint.G'Image & S.Tint.B'Image & S.Tint.A'Image & S.Layer'Image);
               end;
            end if;
            if Colliders.Has (E) then
               declare
                  Cd : constant Collider_Data := Colliders.Get (E);
               begin
                  Put_Line (F, "  collider " & Img (Cd.Size.X) & " " & Img (Cd.Size.Y)
                            & (if Cd.Bounce then "" else " nobounce"));
               end;
            end if;
            if Lifetimes.Has (E) then
               Put_Line (F, "  lifetime " & Img (Lifetimes.Get (E).Seconds_Left));
            end if;
         end;
      end loop;
      Close (F);
      Ok := True;
   exception
      when others =>
         Ok := False;
   end Save;

   ----------------
   -- Hot reload --
   ----------------

   Watch_File : String (1 .. 256) := [others => ' '];
   Watch_Len  : Natural := 0;
   Watch_Time : Ada.Calendar.Time;
   Watching   : Boolean := False;

   procedure Watch (File : String) is
   begin
      Watch_Len := Natural'Min (File'Length, Watch_File'Length);
      Watch_File (1 .. Watch_Len) := File (File'First .. File'First + Watch_Len - 1);
      Watching := True;
      begin
         Watch_Time := Ada.Directories.Modification_Time (File);
      exception
         when others =>
            Watch_Time := Ada.Calendar.Clock;
      end;
   end Watch;

   procedure Unwatch is
   begin
      Watching := False;
   end Unwatch;

   procedure Poll (Reloaded : out Boolean) is
      use type Ada.Calendar.Time;
      Now : Ada.Calendar.Time;
      Ok  : Boolean;
      Err : String (1 .. 160);
      Last : Natural;
   begin
      Reloaded := False;
      if not Watching then
         return;
      end if;
      begin
         Now := Ada.Directories.Modification_Time (Watched);
      exception
         when others =>
            return;   --  being written; try next frame
      end;
      if Now /= Watch_Time then
         Watch_Time := Now;
         Load (Watched, Ok, Err, Last);
         if not Ok then
            Ada.Text_IO.Put_Line ("scene: " & Err (1 .. Last));
         end if;
         Reloaded := True;
      end if;
   end Poll;

   function Watched return String is (Watch_File (1 .. Watch_Len));

end Yarlib.Engine.Scene;
