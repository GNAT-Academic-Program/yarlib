--  The engine's component set. Small on purpose: what a 2D game needs
--  to exist on screen and move. A game adds its own kinds in its own
--  world assembly; these are the ones the engine's systems know.
--
--  Every component is a plain record with defaults, so a scene line
--  can omit fields and a Set never needs a constructor.

with Bedrock; use Bedrock;
with Bedrock.Names;

package Yarlib.Engine.Components is

   type Component_Kind is (Name, Transform, Velocity, Sprite, Collider, Lifetime);

   Max_Name : constant := Bedrock.Names.Max_Name;
   subtype Name_Data is Bedrock.Names.Name;
   function To_Name (S : String) return Name_Data renames Bedrock.Names.To_Name;
   function Image (N : Name_Data) return String renames Bedrock.Names.Image;

   type Transform_Data is record
      Pos      : Vector2 := (0.0, 0.0);      --  world, top-left
      Size     : Vector2 := (16.0, 16.0);
      Rotation : Degrees := 0.0;             --  about the centre
   end record;

   type Velocity_Data is record
      V : Vector2 := (0.0, 0.0);             --  units per second
   end record;

   Max_Texture_Name : constant := 32;
   type Sprite_Data is record
      Tex_Len : Natural range 0 .. Max_Texture_Name := 5;
      Tex     : String (1 .. Max_Texture_Name) := "white" & [6 .. Max_Texture_Name => ' '];
      Tint    : Color := White;
      Layer   : Integer := 0;                --  draw order, low first
   end record;

   type Collider_Data is record
      Size   : Vector2 := (16.0, 16.0);      --  AABB, at Transform.Pos
      Bounce : Boolean := True;              --  reflect Velocity on the arena edge
   end record;

   type Lifetime_Data is record
      Seconds_Left : Scalar := 1.0;          --  destroyed at 0
   end record;

end Yarlib.Engine.Components;
