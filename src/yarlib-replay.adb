with Ada.Text_IO;

with Bedrock.Screen; use Bedrock.Screen;

package body Yarlib.Replay is

   use Ada.Text_IO;

   --  A Session is limited but not controlled, so file handles live in
   --  the body. One recording and one replay at a time is plenty.
   Files : array (1 .. 2) of File_Type;

   procedure Read_Next (S : in out Session);

   function Current_Mode (S : Session) return Mode is (S.M);

   -----------
   -- Image --
   -----------

   function Image (E : Input.Event) return String is
   begin
      case E.Kind is
         when Quit | Window_Close =>
            return "q";
         when Key_Down =>
            return (if E.Repeat then "" else "k+" & E.Key'Image);
         when Key_Up =>
            return "k-" & E.Key'Image;
         when Mouse_Move =>
            return "m" & E.At_Pos.X'Image & E.At_Pos.Y'Image;
         when Mouse_Down =>
            return "b+" & E.Button'Image & E.Where.X'Image & E.Where.Y'Image;
         when Mouse_Up =>
            return "b-" & E.Button'Image & E.Where.X'Image & E.Where.Y'Image;
         when Window_Resized =>
            return "r" & E.Size.Width'Image & E.Size.Height'Image;
         when others =>
            return "";   --  not replayed
      end case;
   end Image;

   -----------
   -- Value --
   -----------

   procedure Value (Tok : String; E : out Input.Event; Ok : out Boolean) is
   begin
      Ok := True;
      if Tok = "q" then
         E := Quit_Event;
      elsif Tok'Length > 2 and then Tok (Tok'First) = 'k' then
         E :=
           Key_Event
             (Key'Value (Tok (Tok'First + 2 .. Tok'Last)),
              Down => Tok (Tok'First + 1) = '+');
      elsif Tok'Length > 2 and then Tok (Tok'First) = 'b' then
         E :=
           Button_Event
             (Mouse_Button'Value (Tok (Tok'First + 2 .. Tok'Last)),
              Down => Tok (Tok'First + 1) = '+');
      else
         E  := Quit_Event;
         Ok := False;
      end if;
   exception
      when Constraint_Error =>
         E  := Quit_Event;
         Ok := False;
   end Value;

   ---------------------------------------------------------------------
   --  Line parsing for replay: "FRAME STEPS tok tok ..."
   ---------------------------------------------------------------------

   procedure Read_Next (S : in out Session) is
      F : File_Type renames Files (S.Handle);
   begin
      S.Have_Next := False;
      while not End_Of_File (F) loop
         declare
            L : constant String := Get_Line (F);
            P : Natural         := L'First;
            function Next_Token return String;
            function Next_Token return String is
               Start : Natural;
            begin
               while P <= L'Last and then L (P) = ' ' loop
                  P := P + 1;
               end loop;
               Start := P;
               while P <= L'Last and then L (P) /= ' ' loop
                  P := P + 1;
               end loop;
               return L (Start .. P - 1);
            end Next_Token;
         begin
            if L'Length > 0 and then L (L'First) /= '#' then
               declare
                  T1 : constant String := Next_Token;
                  T2 : constant String := Next_Token;
               begin
                  if T1 = "end" and then T2'Length > 0 then
                     S.End_Frame := Natural'Value (T2);
                     return;
                  elsif T1'Length > 0 and then T2'Length > 0 then
                     S.Next_Frame                   := Natural'Value (T1);
                     S.Next_Steps                   := Natural'Value (T2);
                     S.Next_Last := Natural'Min (Max_Line, L'Last - P + 1);
                     S.Next_Line (1 .. S.Next_Last) :=
                       L (P .. P + S.Next_Last - 1);
                     S.Have_Next                    := True;
                     return;
                  end if;
               end;
            end if;
         end;
      end loop;
   exception
      when Constraint_Error =>
         S.Have_Next := False;
   end Read_Next;

   ---------------------
   -- Start_Recording --
   ---------------------

   procedure Start_Recording
     (S : in out Session; File : String; Ok : out Boolean)
   is
   begin
      Ok := False;
      if S.M /= Off then
         return;
      end if;
      S.Handle := 1;
      Create (Files (1), Out_File, File);
      Put_Line (Files (1), "# yarlib replay v1");
      S.M      := Recording;
      S.Opened := True;
      Ok       := True;
   exception
      when others =>
         Ok := False;
   end Start_Recording;

   ------------------
   -- Start_Replay --
   ------------------

   procedure Start_Replay
     (S  : in out Session; Ctx : in out Core.Context; File : String;
      Ok :    out Boolean)
   is
   begin
      Ok := False;
      if S.M /= Off then
         return;
      end if;
      S.Handle := 2;
      Open (Files (2), In_File, File);
      declare
         Header : constant String := Get_Line (Files (2));
      begin
         if Header /= "# yarlib replay v1" then
            Close (Files (2));
            return;
         end if;
      end;
      S.M      := Replaying;
      S.Opened := True;
      Core.Set_Input_Source (Ctx, Platform_Events => False);
      Read_Next (S);
      Ok := True;
   exception
      when others =>
         Ok := False;
   end Start_Replay;

   ----------
   -- Stop --
   ----------

   procedure Stop (S : in out Session; Ctx : in out Core.Context) is
   begin
      if S.Opened then
         if S.M = Recording then
            Put_Line (Files (S.Handle), "end" & S.Last_Frame'Image);
         end if;
         Close (Files (S.Handle));
         S.Opened := False;
      end if;
      if S.M = Replaying then
         Core.Set_Input_Source (Ctx, Platform_Events => True);
      end if;
      S.M := Off;
   end Stop;

   ------------------
   -- Before_Frame --
   ------------------

   procedure Before_Frame
     (S : in out Session; Ctx : in out Core.Context; Steps : in out Natural)
   is
   begin
      if S.M /= Replaying then
         return;
      end if;
      if Core.Frame_Number (Ctx) >= S.End_Frame then
         Stop (S, Ctx);
         Core.Inject (Ctx, Quit_Event);
         Steps := 0;
         return;
      end if;
      if not S.Have_Next or else Core.Frame_Number (Ctx) < S.Next_Frame then
         Steps := 1;   --  the default line
         return;
      end if;
      Steps := S.Next_Steps;
      declare
         L : constant String := S.Next_Line (1 .. S.Next_Last);
         P : Natural         := L'First;
         function Next_Token return String;
         function Next_Token return String is
            Start : Natural;
         begin
            while P <= L'Last and then L (P) = ' ' loop
               P := P + 1;
            end loop;
            Start := P;
            while P <= L'Last and then L (P) /= ' ' loop
               P := P + 1;
            end loop;
            return L (Start .. P - 1);
         end Next_Token;
         E  : Input.Event;
         Ok : Boolean;
      begin
         loop
            declare
               T : constant String := Next_Token;
            begin
               exit when T'Length = 0;
               if T = "m" then
                  declare
                     X : constant String := Next_Token;
                     Y : constant String := Next_Token;
                  begin
                     Core.Inject
                       (Ctx, Move_Event (Pixels'Value (X), Pixels'Value (Y)));
                  end;
               elsif T = "r" then
                  declare
                     W : constant String := Next_Token;
                     H : constant String := Next_Token;
                  begin
                     Core.Inject
                       (Ctx,
                        Resize_Event (Extent'Value (W), Extent'Value (H)));
                  end;
               elsif T'Length > 2 and then T (T'First) = 'b' then
                  declare
                     X : constant String := Next_Token;
                     Y : constant String := Next_Token;
                  begin
                     Core.Inject
                       (Ctx,
                        Button_Event
                          (Mouse_Button'Value (T (T'First + 2 .. T'Last)),
                           Down => T (T'First + 1) = '+',
                           X    => Pixels'Value (X), Y => Pixels'Value (Y)));
                  end;
               else
                  Value (T, E, Ok);
                  if Ok then
                     Core.Inject (Ctx, E);
                  end if;
               end if;
            end;
         end loop;
      exception
         when Constraint_Error =>
            null;   --  a bad token ends this frame's events
      end;
      Read_Next (S);
   end Before_Frame;

   -----------------
   -- After_Frame --
   -----------------

   procedure After_Frame
     (S : in out Session; Ctx : Core.Context; Steps : Natural)
   is
      Q : constant Input.Event_Queue := Core.Frame_Events (Ctx);
   begin
      if S.M /= Recording then
         return;
      end if;
      S.Last_Frame := Core.Frame_Number (Ctx);
      if Q.Count = 0 and then Steps = 1 then
         return;   --  the default line; omitted to keep files short
      end if;
      declare
         F : File_Type renames Files (S.Handle);
      begin
         Put (F, Natural'Image (Core.Frame_Number (Ctx) - 1) & Steps'Image);
         for I in 1 .. Q.Count loop
            declare
               Img : constant String := Image (Q.Events (I));
            begin
               if Img'Length > 0 then
                  Put (F, " " & Img);
               end if;
            end;
         end loop;
         New_Line (F);
      end;
   end After_Frame;

end Yarlib.Replay;
