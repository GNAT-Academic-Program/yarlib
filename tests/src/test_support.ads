--  Library-level handlers for the console tests (access-to-subprogram
--  values must not be deeper than the access type).
with Yarlib.Console;
package Test_Support is
   Echoed : Natural := 0;
   procedure Echo (Args : String; R : out Yarlib.Console.Response);
end Test_Support;
