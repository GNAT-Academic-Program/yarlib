package body Yarlib.Console is

   type Entry_Record is record
      Name        : String (1 .. Max_Name) := [others => ' '];
      Length      : Natural                := 0;
      H           : Handler                := null;
      Help        : String (1 .. 80)       := [others => ' '];
      Help_Length : Natural                := 0;
   end record;

   Table : array (1 .. Max_Commands) of Entry_Record;
   N     : Natural := 0;

   function Find (Name : String) return Natural;

   function Find (Name : String) return Natural is
   begin
      for I in 1 .. N loop
         if Table (I).Length = Name'Length
           and then Table (I).Name (1 .. Table (I).Length) = Name
         then
            return I;
         end if;
      end loop;
      return 0;
   end Find;

   procedure Register (Name : String; H : Handler; Help : String := "") is
      I  : Natural          := Find (Name);
      HL : constant Natural := Natural'Min (Help'Length, 80);
   begin
      if I = 0 then
         if N = Max_Commands then
            raise Program_Error with "console: command table full";
         end if;
         N := N + 1;
         I := N;
      end if;
      Table (I).Name                    := [others => ' '];
      Table (I).Name (1 .. Name'Length) := Name;
      Table (I).Length                  := Name'Length;
      Table (I).H                       := H;
      Table (I).Help                    := [others => ' '];
      Table (I).Help (1 .. HL) := Help (Help'First .. Help'First + HL - 1);
      Table (I).Help_Length             := HL;
   end Register;

   procedure Execute (Line : String; R : out Response) is
      First : Natural := Line'First;
      Last  : Natural;
   begin
      while First <= Line'Last and then Line (First) = ' ' loop
         First := First + 1;
      end loop;
      if First > Line'Last or else Line (First) = '#' then
         Set (R, True, "ok");
         return;
      end if;
      Last := First;
      while Last <= Line'Last and then Line (Last) /= ' ' loop
         Last := Last + 1;
      end loop;
      declare
         Name : constant String := Line (First .. Last - 1);
         A0   : Natural         := Last;
      begin
         while A0 <= Line'Last and then Line (A0) = ' ' loop
            A0 := A0 + 1;
         end loop;
         if Name = "help" then
            Set (R, True, "ok");
            for I in 1 .. N loop
               Append (R, " " & Table (I).Name (1 .. Table (I).Length));
               if Table (I).Help_Length > 0 then
                  Append
                    (R,
                     " (" & Table (I).Help (1 .. Table (I).Help_Length) & ")");
               end if;
            end loop;
            return;
         end if;
         declare
            I : constant Natural := Find (Name);
         begin
            if I = 0 then
               Set (R, False, "err unknown command " & Name);
            else
               Table (I).H (Line (A0 .. Line'Last), R);
            end if;
         end;
      end;
   end Execute;

   function Count return Natural is (N);

end Yarlib.Console;
