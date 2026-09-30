package body Yarlib.Engine.World is
   function Find (Name : String) return Entity is
   begin
      for I in 1 .. Names.Count loop
         if Components.Image (Names.Value (I)) = Name then
            return Names.Owner (I);
         end if;
      end loop;
      return No_Entity;
   end Find;
end Yarlib.Engine.World;
