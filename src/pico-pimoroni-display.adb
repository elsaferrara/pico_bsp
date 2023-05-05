with HAL;      use HAL;
with HAL.SPI;  use HAL.SPI;

with RP.SPI;
with RP.Device;

package body Pico.Pimoroni.Display is
   
   SPI : RP.SPI.SPI_Port renames RP.Device.SPI_0;
   SPI_LCD_MOSI : RP.GPIO.GPIO_Point renames Pico.GP19;
   SPI_LCD_CLK : RP.GPIO.GPIO_Point renames Pico.GP18;
   SPI_LCD_CS : RP.GPIO.GPIO_Point renames Pico.GP17;
   SPI_LCD_DC : RP.GPIO.GPIO_Point renames Pico.GP16;
   
   BL_EN : RP.GPIO.GPIO_Point renames Pico.GP20;

   LED_R : RP.GPIO.GPIO_Point renames Pico.GP6;
   LED_G : RP.GPIO.GPIO_Point renames Pico.GP7;
   LED_B : RP.GPIO.GPIO_Point renames Pico.GP8;
   
   SW_A : RP.GPIO.GPIO_Point renames Pico.GP12;
   SW_B : RP.GPIO.GPIO_Point renames Pico.GP13;
   SW_X : RP.GPIO.GPIO_Point renames Pico.GP14;
   SW_Y : RP.GPIO.GPIO_Point renames Pico.GP15;
   
   
   Width : constant := 240;
   Height : constant := 135;
   Nbr_Of_Pixels : constant := Width * Height;
   
   Pixel_Data : SPI_Data_8b (1 .. 4 + Nbr_Of_Pixels * 2 + 4) := (others => 0);
   
   ----------------
   -- Initialize --
   ----------------
   
   procedure Initialize is 
 begin
      SPI.Configure
        ((Role => RP.SPI.Master,
          Baud => 20_000_000,
          others => <>));

      SPI_LCD_CLK.Configure (Output, Floating, RP.GPIO.SPI);
      SPI_LCD_MOSI.Configure (Output, Floating, RP.GPIO.SPI);
      
      SPI_LCD_CS.Configure (Output);
      SPI_LCD_DC.Configure (Output);
      
      BL_EN.Set;
      
      Command (16#01#); -- SWRESET
      
      RP.Device.Timer.Delay_Milliseconds (150);
      
      Command (16#35#); -- TEON
      Command (16#3a#, (0 => 16#05#)); -- COLMOD
      Command (16#b2#, (16#0c#,16#0c#,16#00#,16#33#,16#33#)); -- PORCTRL
      Command (16#c0#, (0 => 16#2c#)); -- LCMCTRL
      Command (16#c2#, (0 => 16#01#)); -- VDVVRHEN
      Command (16#c3#, (0 => 16#12#)); -- VRHS
      Command (16#c4#, (0 => 16#20#)); -- VDVS
      Command (16#d0#, (16#a4#,16#a1#)); -- PWCTRL1
      Command (16#c6#, (0 => 16#0f#)); -- FRCTRL2
      
      Command (16#c3#, (0 => 16#00#)); -- VRHS
      Command (16#b7#, (0 => 16#75#)); -- GCTRL
      Command (16#bb#, (0 => 16#3d#)); -- VCOMS
      Command (16#d6#, (0 => 16#a1#)); -- ???
      Command (16#e0#, (16#70#,16#04#,16#08#,16#09#,16#09#,16#05#,16#2A#,
                        16#33#,16#41#,16#07#,16#13#,16#13#,16#29#,16#2f#)); -- GMCTRP1
      Command (16#e1#, (16#70#,16#03#,16#09#,16#0A#,16#09#,16#06#,16#2B#,
               16#34#,16#41#,16#07#,16#12#,16#14#,16#28#,16#2E#)); -- GMCTRN1
      
      Command (16#21#); -- INVON
      Command (16#11#); -- SLPOUT
      Command (16#29#); -- DISPON
      
      RP.Device.Timer.Delay_Milliseconds (100);
      
      -- TODO : add rotation
      Command (16#2a#, (16#00#,16#28#,16#01#,16#17#)); -- CASET
      Command (16#2b#, (16#00#,16#35#,16#00#,16#bb#)); -- RASET
      Command (16#36#, (0 => 16#70#)); -- MADCTL
      
   end Initialize;
      
   
   procedure Command (Cmd : HAL.UInt8;
                      Data : SPI_Data_8b := (1 .. 0 => 0))
   is
      Status : SPI_Status;
      Cmd_Arr : SPI_Data_8b (0 .. 0):= (0 => Cmd);
   begin
      SPI_LCD_DC.Clear;
      SPI_LCD_CS.Clear;
      
      SPI.Transmit (Cmd_Arr, Status);
      
      if Data'Length /= 0 then
         SPI_LCD_DC.Set;
         SPI.Transmit (Data, Status);
      end if;
      
      SPI_LCD_CS.Set;
   end Command;
   
   ---------
   -- Set --
   ---------

   procedure Set (Pxl          : Pixel;
                  R, G, B    : HAL.UInt8)
   is
      Index : constant Natural := Pixel_Data'First + 4 + Natural (Pxl) * 2;
      Color_hi : HAL.UInt8 := HAL.UInt8 (Shift_Right (To_RGB565 (R, G, B), 8));
      Color_lo : HAL.UInt8 := HAL.UInt8 (16#00ff# and To_RGB565 (R, G, B));
   begin
      Pixel_Data (Index) := Color_hi;
      Pixel_Data (Index + 1) := Color_lo;
   end Set;
      
   ---------
   -- Get --
   ---------

   procedure Get (Pxl          :     Pixel;
                  R, G, B    : out HAL.UInt8)
   is
      Index : constant Natural := Pixel_Data'First + 4 + Natural (Pxl) * 3;
   begin

      B := Pixel_Data (Index);
      G := Pixel_Data (Index + 1);
      R := Pixel_Data (Index + 2);
   end Get;
   
      function To_RGB565 (R, G, B    : HAL.UInt8)
                          return HAL.UInt16
   is (Shift_Left((HAL.UInt16(R) and 2#11111000#),8) or 
         Shift_Left ((HAL.UInt16(G) and 2#11111100#), 3) or 
         Shift_Right((HAL.UInt16(B) and 2#11111000#), 3));
   
   procedure Rectangle (Pxl          :     Pixel;
                        x : Natural;
                        y : Natural;
                       R,G,B : HAL.UInt8)
   is
      a : Pixel := Pxl;
      begin
      while a <= Pxl + Pixel (y) * Width loop
         for c in a .. a + Pixel(x) loop
            Set(a + c, R, G, B);
            end loop;
         a := a + Width;
         end loop;
      end Rectangle;
   
   ------------
   -- Update --
   ------------

   procedure Update is
   begin

      Command (16#2c#,Pixel_Data);
      
   end Update;
   
end Pico.Pimoroni.Display;
