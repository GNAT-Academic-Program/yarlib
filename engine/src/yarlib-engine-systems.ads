--  Systems: procedures over pools. Each one is a loop over one pool
--  with lookups into others; that is the whole ECS idea, and it is why
--  a new behaviour is a new procedure here and not a new class.
--
--  Order matters and is fixed in Update: Lifetime (may destroy) ->
--  Movement -> Bounce. Render is separate because it runs once a frame
--  while Update may run several times.
--
--  Iterate in reverse when a system may Unset or Destroy: escape moves
--  the tail into the hole.
--
--  Milestones: Collide (AABB pairs, spatial hash when N > a few
--  hundred), Animate (sprite sheet frames), Follow (camera), Emit
--  (particles). Each is one more procedure with the same shape.

with Bedrock; use Bedrock;

package Yarlib.Engine.Systems is

   Arena : Rectangle := (0.0, 0.0, 800.0, 450.0);
   --  Bounce reflects velocities at these edges. The game sets it.

   procedure Lifetime (Dt : Scalar);
   --  Seconds_Left -= Dt; destroy at 0.

   procedure Movement (Dt : Scalar);
   --  Transform.Pos += Velocity * Dt for every entity with both.

   procedure Bounce;
   --  Entities with Transform, Velocity and a bouncing Collider reflect
   --  off Arena's edges.

   procedure Update (Dt : Scalar);
   --  Lifetime, Movement, Bounce, in that order.

   procedure Render;
   --  Every entity with Transform and Sprite, lowest Layer first.
   --  Texture names: "white", "checker", or one registered with
   --  Register_Texture.

   procedure Register_Texture (Name : String; T : Texture)
     with Pre => Name'Length in 1 .. 32;
   --  Milestone 3 loads these from files by scene reference.

end Yarlib.Engine.Systems;
