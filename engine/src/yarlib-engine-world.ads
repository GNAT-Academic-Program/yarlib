--  The engine's escape assembly: one world, six pools, desktop backing
--  (unbounded sequences, paged sparse maps). A game that wants more
--  component kinds makes its own assembly with a bigger enumeration and
--  instantiates the engine's systems against it (milestone: make the
--  systems generic over the assembly; today they name this one).
--
--  Boilerplate per pool is escape's price for no tagged types and no
--  byte blobs: three instantiations. Copy a block, rename, done.

with ECS;
with ECS.Worlds;
with ECS.Pools;
with ECS.Sequences;
with ECS.Sparse_Maps;
with ECS.Unbounded_Sequences;
with ECS.Paged_Sparse_Maps;
with Yarlib.Engine.Components;

package Yarlib.Engine.World is

   Max_Entities : constant := 4_096;

   subtype Entity is ECS.Entity;
   No_Entity : constant Entity := ECS.No_Entity;

   package W is new ECS.Worlds
     (Component_Kind => Components.Component_Kind, Max_Entities => Max_Entities);

   package Owner_Store is new ECS.Unbounded_Sequences (ECS.Entity_Index);
   package Owner_Seq is new ECS.Sequences
     (Element => ECS.Entity_Index, Sequence => Owner_Store.Sequence,
      Clear   => Owner_Store.Clear,   Length      => Owner_Store.Length,
      Item    => Owner_Store.Item,    Replace     => Owner_Store.Replace,
      Append  => Owner_Store.Append,  Swap_Remove => Owner_Store.Swap_Remove);

   package Sparse_Store is new ECS.Paged_Sparse_Maps (Page_Size => 1024);
   package Sparse_Map is new ECS.Sparse_Maps
     (Map => Sparse_Store.Map, Clear => Sparse_Store.Clear,
      Lookup => Sparse_Store.Lookup, Assign => Sparse_Store.Assign);

   generic
      type Component is private;
      Kind : Components.Component_Kind;
   package Pool_Of is
      package Store is new ECS.Unbounded_Sequences (Component);
      package Seq is new ECS.Sequences
        (Element => Component, Sequence => Store.Sequence,
         Clear   => Store.Clear,   Length      => Store.Length,
         Item    => Store.Item,    Replace     => Store.Replace,
         Append  => Store.Append,  Swap_Remove => Store.Swap_Remove);
      package P is new ECS.Pools
        (W => W, Component => Component, Kind => Kind,
         Values => Seq, Owners => Owner_Seq, Sparse => Sparse_Map);
   end Pool_Of;

   package Name_Pool      is new Pool_Of (Components.Name_Data, Components.Name);
   package Transform_Pool is new Pool_Of (Components.Transform_Data, Components.Transform);
   package Velocity_Pool  is new Pool_Of (Components.Velocity_Data, Components.Velocity);
   package Sprite_Pool    is new Pool_Of (Components.Sprite_Data, Components.Sprite);
   package Collider_Pool  is new Pool_Of (Components.Collider_Data, Components.Collider);
   package Lifetime_Pool  is new Pool_Of (Components.Lifetime_Data, Components.Lifetime);

   package Names      renames Name_Pool.P;
   package Transforms renames Transform_Pool.P;
   package Velocities renames Velocity_Pool.P;
   package Sprites    renames Sprite_Pool.P;
   package Colliders  renames Collider_Pool.P;
   package Lifetimes  renames Lifetime_Pool.P;

   function Find (Name : String) return Entity;
   --  First entity whose Name component matches; No_Entity if none.

end Yarlib.Engine.World;
