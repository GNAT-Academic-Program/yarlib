package body Test_Support is
   procedure Echo (Args : String; R : out Yarlib.Console.Response) is
   begin
      Echoed := Echoed + 1;
      Yarlib.Console.Set (R, True, "ok " & Args);
   end Echo;
end Test_Support;
