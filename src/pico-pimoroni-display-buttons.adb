
package body Pico.Pimoroni.Display.Buttons is

   Current_Buttons_State : Unsigned_4 := 0;
   Previous_Buttons_State : Unsigned_4 := 0;

   SW_A : RP.GPIO.GPIO_Point renames Pico.GP12;
   SW_B : RP.GPIO.GPIO_Point renames Pico.GP13;
   SW_X : RP.GPIO.GPIO_Point renames Pico.GP14;
   SW_Y : RP.GPIO.GPIO_Point renames Pico.GP15;

   procedure Initialize is
   begin
      SW_A.Configure (Input, Pull_Up);
      SW_B.Configure (Input, Pull_Up);
      SW_X.Configure (Input, Pull_Up);
      SW_Y.Configure (Input, Pull_Up);
   end Initialize;

   function Buttons_State return Unsigned_4 is
      Buttons : Unsigned_4 := 2#0000#;
      Result : Boolean;
   begin

      SW_A.Get (Result);
      if not Result then
         Buttons := Buttons or A'Enum_Rep;
      end if;

      SW_B.Get (Result);
      if not Result then
         Buttons := Buttons or B'Enum_Rep;
      end if;

      SW_X.Get (Result);
      if not Result then
         Buttons := Buttons or X'Enum_Rep;
      end if;

      SW_Y.Get (Result);
      if not Result then
         Buttons := Buttons or Y'Enum_Rep;
      end if;

      return Buttons;
   end Buttons_State;

   -------------
   -- Pressed --
   -------------

   function Pressed (Button : Button_Kind) return Boolean is
   begin
      return Pressed (Button'Enum_Rep);
   end Pressed;

   -------------
   -- Pressed --
   -------------

   function Pressed (Button_Mask : Unsigned_4) return Boolean is
   begin
      return (Buttons_State and Button_Mask) = Button_Mask;
   end Pressed;

   ------------------
   -- Poll_Buttons --
   ------------------

   procedure Poll_Buttons is
   begin
      Previous_Buttons_State := Current_Buttons_State;
      Current_Buttons_State := Buttons_State;
   end Poll_Buttons;

   ------------------
   -- Just_Pressed --
   ------------------

   function Just_Pressed (Button : Button_Kind) return Boolean
   is (((Previous_Buttons_State and Button'Enum_Rep) = 0)
       and then
         ((Current_Buttons_State and Button'Enum_Rep) /= 0));

   -------------------
   -- Just_Released --
   -------------------

   function Just_Released (Button : Button_Kind) return Boolean
   is (((Previous_Buttons_State and Button'Enum_Rep) /= 0)
       and then
         ((Current_Buttons_State and Button'Enum_Rep) = 0));

end Pico.Pimoroni.Display.Buttons;
