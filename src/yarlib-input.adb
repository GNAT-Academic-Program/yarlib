package body Yarlib.Input with SPARK_Mode is

   procedure Begin_Frame (S : in out State) is
   begin
      S.Pressed := [others => False];
      S.Released := [others => False];
      S.Button_Pressed := [others => False];
      S.Button_Released := [others => False];
   end Begin_Frame;

   procedure Apply (S : in out State; E : Event) is
   begin
      case E.Kind is
         when Quit | Window_Close =>
            S.Quit_Requested := True;
         when Key_Down =>
            if not E.Repeat then
               if not S.Down (E.Key) then
                  S.Pressed (E.Key) := True;
               end if;
               S.Down (E.Key) := True;
            end if;
         when Key_Up =>
            S.Down (E.Key) := False;
            S.Released (E.Key) := True;
         when Mouse_Move =>
            S.Mouse_X := Integer (E.At_Pos.X);
            S.Mouse_Y := Integer (E.At_Pos.Y);
         when Mouse_Down =>
            S.Button_Pressed (E.Button) := True;
            S.Button_Down (E.Button) := True;
            S.Mouse_X := Integer (E.Where.X);
            S.Mouse_Y := Integer (E.Where.Y);
         when Mouse_Up =>
            S.Button_Down (E.Button) := False;
            S.Button_Released (E.Button) := True;
         when others =>
            null;
      end case;
   end Apply;

end Yarlib.Input;
