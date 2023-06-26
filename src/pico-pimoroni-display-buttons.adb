
package body Pico.Pimoroni.Display.Buttons
with SPARK_Mode,
  Refined_State => (State => (Current_Buttons_State, Previous_Buttons_State))
is

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

   procedure Buttons_State
     (State : out Unsigned_4)
   is
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

      State := Buttons;
   end Buttons_State;

   -------------
   -- Pressed --
   -------------

   procedure Pressed (Button : Button_Kind;
                        Result : out Boolean) is
   begin
      Pressed (Button'Enum_Rep, Result);
   end Pressed;

   -------------
   -- Pressed --
   -------------

   procedure Pressed (Button_Mask : Unsigned_4;
                        Result : out Boolean) is
      State : Unsigned_4;
   begin
      Buttons_State (State);
      Result := (State and Button_Mask) = Button_Mask;
   end Pressed;

   ------------------
   -- Poll_Buttons --
   ------------------

   procedure Poll_Buttons is
   State : Unsigned_4;
   begin

      Previous_Buttons_State := Current_Buttons_State;
      Buttons_State (State);
      Current_Buttons_State := State;
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
