package Pico.Pimoroni.Display.Buttons
with SPARK_Mode,
  Elaborate_Body,
  Abstract_State => State,
Initializes => State is

   --  type Button_State is private;

   type Unsigned_4 is mod 2 ** 4
     with Size => 4;

   type Button_Kind is (Y, X, B, A);

   procedure Initialize;

   function Pressed (Button : Button_Kind) return Boolean;

   function Pressed (Button_Mask : Unsigned_4) return Boolean;

   procedure Poll_Buttons;

   function Just_Pressed (Button : Button_Kind) return Boolean;

   function Just_Released (Button : Button_Kind) return Boolean;

private
   --
   --  type Button_State is new Unsigned_4;

   for Button_Kind use (
                        Y => 2#0001#,
                        X => 2#0010#,
                        B => 2#0100#,
                        A => 2#1000#
                       );

end Pico.Pimoroni.Display.Buttons;
