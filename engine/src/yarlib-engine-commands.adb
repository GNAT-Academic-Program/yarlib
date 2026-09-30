with ECS;
with Yarlib.Engine.Components; use Yarlib.Engine.Components;
with Yarlib.Engine.Scene;
with Yarlib.Engine.World;      use Yarlib.Engine.World;

package body Yarlib.Engine.Commands is

   use type ECS.Entity;

   procedure Split (S : String; Head : out Natural; Rest : out Natural);
   --  Head = last index of the first word; Rest = first index after the
   --  spaces that follow it (S'Last + 1 if none).
   procedure Split (S : String; Head : out Natural; Rest : out Natural) is
      P : Natural := S'First;
   begin
      while P <= S'Last and then S (P) = ' ' loop
         P := P + 1;
      end loop;
      while P <= S'Last and then S (P) /= ' ' loop
         P := P + 1;
      end loop;
      Head := P - 1;
      while P <= S'Last and then S (P) = ' ' loop
         P := P + 1;
      end loop;
      Rest := P;
   end Split;

   procedure Register_All is
   begin
      Console.Register ("scene", Cmd_Scene'Access, "load|save|watch|unwatch FILE");
      Console.Register ("spawn", Cmd_Spawn'Access, "NAME X Y [W H]");
      Console.Register ("kill", Cmd_Kill'Access, "NAME");
      Console.Register ("set", Cmd_Set'Access, "NAME COMPONENT FIELDS...");
      Console.Register ("entities", Cmd_Entities'Access);
   end Register_All;

   procedure Cmd_Scene (Args : String; R : out Console.Response) is
      H, Rest : Natural;
      Ok   : Boolean;
      Err  : String (1 .. 160);
      Last : Natural;
   begin
      Split (Args, H, Rest);
      declare
         Verb : constant String := Args (Args'First .. H);
         File : constant String := Args (Rest .. Args'Last);
      begin
         if Verb = "load" and then File'Length > 0 then
            Scene.Load (File, Ok, Err, Last);
            if Ok then
               Console.Set (R, True, "ok" & W.Live_Count'Image & " entities");
            else
               Console.Set (R, False, "err " & Err (1 .. Last));
            end if;
         elsif Verb = "save" and then File'Length > 0 then
            Scene.Save (File, Ok);
            Console.Set (R, Ok, (if Ok then "ok saved " & File else "err cannot write " & File));
         elsif Verb = "watch" and then File'Length > 0 then
            Scene.Watch (File);
            Console.Set (R, True, "ok watching " & File);
         elsif Verb = "unwatch" then
            Scene.Unwatch;
            Console.Set (R, True, "ok");
         else
            Console.Set (R, False, "err scene load|save|watch|unwatch FILE");
         end if;
      end;
   end Cmd_Scene;

   procedure Cmd_Spawn (Args : String; R : out Console.Response) is
      H, Rest : Natural;
      Ok : Boolean;
   begin
      Split (Args, H, Rest);
      declare
         Name   : constant String := Args (Args'First .. H);
         Fields : constant String := Args (Rest .. Args'Last);
      begin
         if Name'Length = 0 or else Fields'Length = 0 then
            Console.Set (R, False, "err spawn NAME X Y [W H]");
            return;
         end if;
         Scene.Parse_Entity
           ("entity " & Name & ASCII.LF & "transform " & Fields & ASCII.LF & "sprite white", Ok);
         Console.Set (R, Ok, (if Ok then "ok " & Name
                              else "err cannot spawn (escape milestone 1?)"));
      end;
   end Cmd_Spawn;

   procedure Cmd_Kill (Args : String; R : out Console.Response) is
      E : constant Entity := Find (Args);
   begin
      if E = No_Entity then
         Console.Set (R, False, "err no entity named " & Args);
      else
         W.Destroy (E);
         Console.Set (R, True, "ok");
      end if;
   end Cmd_Kill;

   procedure Cmd_Set (Args : String; R : out Console.Response) is
      H, Rest : Natural;
      Ok : Boolean;
   begin
      Split (Args, H, Rest);
      declare
         Name : constant String := Args (Args'First .. H);
         Line : constant String := Args (Rest .. Args'Last);
      begin
         if Find (Name) = No_Entity then
            Console.Set (R, False, "err no entity named " & Name);
            return;
         end if;
         --  Re-select the entity, then apply one component line to it.
         Scene.Parse_Entity_On (Find (Name), Line, Ok);
         Console.Set (R, Ok, (if Ok then "ok" else "err bad component line"));
      end;
   end Cmd_Set;

   procedure Cmd_Entities (Args : String; R : out Console.Response) is
      pragma Unreferenced (Args);
   begin
      Console.Set (R, True, "ok" & W.Live_Count'Image);
      for I in 1 .. Names.Count loop
         declare
            E : constant Entity := Names.Owner (I);
         begin
            Console.Append (R, " " & Components.Image (Names.Value (I)));
            if Transforms.Has (E) then
               Console.Append (R, "@" & Integer (Transforms.Get (E).Pos.X)'Image
                               & Integer (Transforms.Get (E).Pos.Y)'Image);
            end if;
         end;
      end loop;
   end Cmd_Entities;

end Yarlib.Engine.Commands;
