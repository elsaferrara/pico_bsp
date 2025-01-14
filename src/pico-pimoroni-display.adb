with HAL;      use HAL;
--  with HAL.SPI;  use HAL.SPI;
with RP.SPI;
with RP.Device;

with Pico.Pimoroni.Display.Buttons;
with Integer32_Parsing;

package body Pico.Pimoroni.Display
with SPARK_Mode,
  Refined_State => (State => (Color,
                              Pixel_Data,
                              Cursor_X,
                              Cursor_Y))
is

   SPI : RP.SPI.SPI_Port renames RP.Device.SPI_0;
   SPI_LCD_MOSI : RP.GPIO.GPIO_Point renames Pico.GP19;
   SPI_LCD_CLK : RP.GPIO.GPIO_Point renames Pico.GP18;
   SPI_LCD_CS : RP.GPIO.GPIO_Point renames Pico.GP17;
   SPI_LCD_DC : RP.GPIO.GPIO_Point renames Pico.GP16;

   BL_EN : RP.GPIO.GPIO_Point renames Pico.GP20;

   LED_R : RP.GPIO.GPIO_Point renames Pico.GP6;
   LED_G : RP.GPIO.GPIO_Point renames Pico.GP7;
   LED_B : RP.GPIO.GPIO_Point renames Pico.GP8;

   Pixel_Data : SPI_Data_8b (1 .. 4 + Nbr_Of_Pixels * 2 + 4) := [others => 0];
   Color : Bitmap_Color := (0, 0, 0);

   subtype Cursor_Width is Natural range 0 .. Screen_Width;
   Cursor_X : Cursor_Width := 0;
   subtype Cursor_Height is Natural range 0 .. Screen_Height;
   Cursor_Y : Cursor_Height := 0;
   Text_Size : constant Char_Size := 1;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is

   begin
      RP.SPI.Configure  (SPI, (
                  Role => RP.SPI.Master,
                  Baud => 20_000_000,
                  others => <>));

      SPI_LCD_CLK.Configure (Output, Floating, RP.GPIO.SPI);
      SPI_LCD_MOSI.Configure (Output, Floating, RP.GPIO.SPI);

      SPI_LCD_CS.Configure (Output);
      SPI_LCD_DC.Configure (Output);

      BL_EN.Set;

      Command (SWRESET);

      RP.Device.Timer.Delay_Milliseconds (150);

      Command (TEON);
      Command (COLMOD, [0 => 16#05#]);
      Command (PORCTRL, [16#0c#, 16#0c#, 16#00#, 16#33#, 16#33#]);
      Command (LCMCTRL, [0 => 16#2c#]);
      Command (VDVVRHEN, [0 => 16#01#]);
      Command (VRHS, [0 => 16#12#]);
      Command (VDVS, [0 => 16#20#]);
      Command (PWCTRL1, [16#a4#, 16#a1#]);
      Command (FRCTRL2, [0 => 16#0f#]);

      Command (VRHS, [0 => 16#00#]);
      Command (GCTRL, [0 => 16#75#]);
      Command (VCOMS, [0 => 16#3d#]);
      Command (16#d6#, [0 => 16#a1#]); -- ???
      Command (GMCTRP1, [16#70#, 16#04#, 16#08#, 16#09#, 16#09#, 16#05#, 16#2A#,
               16#33#, 16#41#, 16#07#, 16#13#, 16#13#, 16#29#, 16#2f#]);
      Command (GMCTRN1, [16#70#, 16#03#, 16#09#, 16#0A#, 16#09#, 16#06#, 16#2B#,
               16#34#, 16#41#, 16#07#, 16#12#, 16#14#, 16#28#, 16#2E#]);

      Command (INVON);
      Command (SLPOUT);
      Command (DISPON);

      RP.Device.Timer.Delay_Milliseconds (100);

      Command (CASET, [16#00#, 16#28#, 16#01#, 16#17#]);
      Command (RASET, [16#00#, 16#35#, 16#00#, 16#bb#]);
      Command (MADCTL, [0 => 16#70#]);

      Pico.Pimoroni.Display.Buttons.Initialize;

   end Initialize;

   procedure Command (Cmd : HAL.UInt8;
                      Data : SPI_Data_8b := [1 .. 0 => 0])
   is
      Status : SPI_Status;
      Cmd_Arr : constant SPI_Data_8b (0 .. 0) := [0 => Cmd];
   begin
      SPI_LCD_DC.Clear;
      SPI_LCD_CS.Clear;

      RP.SPI.Transmit (SPI, Cmd_Arr, Status);

      if Status /= Ok then
         return;
      end if;

      if Data'Length /= 0 then
         SPI_LCD_DC.Set;
         RP.SPI.Transmit (SPI, Data, Status);
         if Status /= Ok then
            return;
         end if;
      end if;

      SPI_LCD_CS.Set;
   end Command;

   ---------
   -- Set --
   ---------

   procedure Set_Pixel (Pt : Point; On : Boolean := True)
   is
      Index : Natural;
      pragma Warnings (Off, "no returning annotation available for ""Shift_Right""");
      pragma Warnings (Off, "no returning annotation available for ""Shift_Left""");
      Color_hi : constant HAL.UInt8 := HAL.UInt8 (Shift_Right (To_RGB565 (Color.Red, Color.Green, Color.Blue), 8));
      Color_lo : constant HAL.UInt8 := HAL.UInt8 (16#00ff# and To_RGB565 (Color.Red, Color.Green, Color.Blue));
      Data_hi : HAL.UInt8;
      Data_lo : HAL.UInt8;
   begin

      Index := Pixel_Data'First + 4 + (Pt.X + Pt.Y * Screen_Width) * 2;

      Data_hi := Pixel_Data (Index);
      Data_lo := Pixel_Data (Index + 1);

      if On then
         Data_hi := Data_hi or Color_hi;
         Data_lo := Data_lo or Color_lo;
      else
         Data_hi := Data_hi and not Color_hi;
         Data_lo := Data_lo and not Color_lo;
      end if;

      Pixel_Data (Index) := Data_hi;
      Pixel_Data (Index + 1) := Data_lo;

   end Set_Pixel;

   procedure Set_Color (Color_Name : Bitmap_Color) is
   begin
      Color := Color_Name;
   end Set_Color;

   procedure Set_Color (R : HAL.UInt8; G : HAL.UInt8; B : HAL.UInt8) is
   begin
      Color := (Red => R,
                Green => G,
                Blue => B);
   end Set_Color;

   function To_RGB565 (R, G, B    : HAL.UInt8)
                       return HAL.UInt16
   is (Shift_Left ((HAL.UInt16 (R) and 2#11111000#), 8) or
         Shift_Left ((HAL.UInt16 (G) and 2#11111100#), 3) or
         Shift_Right ((HAL.UInt16 (B) and 2#11111000#), 3));

   procedure Draw_Line
     (Start, Stop : Point)
   is
      D : Integer;
      Xmin : constant Natural_Width := (if Start.X <= Stop.X then Start.X else Stop.X);
      Xmax : constant Natural_Width := (if Start.X <= Stop.X then Stop.X else Start.X);
      Ymin : constant Natural_Width := (if Start.Y <= Stop.Y then Start.Y else Stop.Y);
      Ymax : constant Natural_Width := (if Start.Y <= Stop.Y then Stop.Y else Start.Y);
      X : Natural_Width := Xmin;
      Y : Natural_Height := Ymin;
      DX : constant Natural_Width := Xmax - Xmin;
      DY : constant Natural_Height := Ymax - Ymin;

      procedure Draw_Point (P : Point) with Inline,
      Pre => P.X <= Screen_Width - 1 and then P.Y <= Screen_Height - 1;
      procedure Draw_Point (P : Point) is
      begin
            Set_Pixel ((P.X, P.Y));
      end Draw_Point;

   begin
      if DX > DY then
         D := 2 * DY - DX;
         loop
            pragma Loop_Invariant (D = 2 * (X - Xmin + 1) * DY
                                   - (2 * (Y - Ymin) + 1) * DX);
            pragma Loop_Invariant (2 * (DY - DX) <= D and then D <= 2 * DY);
            pragma Loop_Invariant (X <= Xmax);
            pragma Loop_Invariant (Ymax - Y <= DY);
            pragma Loop_Invariant (Y <= Ymax);
            pragma Assert (if Y = Ymax then D = 2 * DY * (X - Xmax + 1) - DX);
            Draw_Point ((X, Y));
            exit when X = Xmax;
            if D > 0 then
               Y := Y + 1;
               D := D - 2 * DX;
            end if;
            D := D + 2 * DY;
            X := X + 1;
         end loop;
      else
         D := 2 * DX - DY;
         loop
            pragma Loop_Invariant (D = 2 * (Y - Ymin + 1) * DX - (2 * (X - Xmin) + 1) * DY);
            pragma Loop_Invariant (2 * (DX - DY) <= D and then D <= 2 * DX);
            pragma Loop_Invariant (Y <= Ymax);
            pragma Loop_Invariant (Xmax - X <= DX);
            pragma Loop_Invariant (X <= Xmax);
            pragma Assert (if X = Xmax then D = 2 * DX * (Y - Ymax + 1) - DY);
            Draw_Point ((X, Y));
            exit when Y = Ymax;
            if D > 0 then
               X := X + 1;
               D := D - 2 * DY;
            end if;
            D := D + 2 * DX;
            Y := Y + 1;
         end loop;
      end if;

   end Draw_Line;

   ---------------
   -- Fill_Rect --
   ---------------

   procedure Fill_Rect
     (Area   : Rect)
   is
   begin
      for Y0 in Area.Position.Y .. Area.Position.Y + Area.Height - 1 loop
         for X0 in Area.Position.X .. Area.Position.X + Area.Width - 1 loop
            Set_Pixel ((X0, Y0));
         end loop;
      end loop;
   end Fill_Rect;

   --------------------------
   -- Draw_Horizontal_Line --
   --------------------------

   procedure Draw_Horizontal_Line (X, Y : Integer; Width : Natural)
   is
      X1, W1 : Natural;
   begin
      if Width = 0 then
         return;

      elsif Y < 0 or else Y >= Screen_Height then
         return;

      elsif X >= Screen_Width or else X < -Width then
         return;
      end if;

      if X < 0 then
         X1 := 0;
         W1 := Width + X;
      else
         X1 := X;
         W1 := Width;
      end if;

      if W1 >= Screen_Width - X1 then
         W1 := Screen_Width - X1 - 1;
      end if;

      if W1 = 0 then
         return;
      end if;

      Fill_Rect (((X1, Y), W1, 1));
   end Draw_Horizontal_Line;

   ------------------------
   -- Draw_Vertical_Line --
   ------------------------

   procedure Draw_Vertical_Line (X, Y : Integer; Height : Natural)
   is
      Y1, H1 : Natural;
   begin
      if Height = 0 then
         return;

      elsif X < 0 or else X >= Screen_Width then
         return;

      elsif Y < -Height or else Y >= Screen_Height then
         return;
      end if;

      if Y < 0 then
         Y1 := 0;
         H1 := Height + Y;
      else
         Y1 := Y;
         H1 := Height;
      end if;

      if H1 >= Screen_Height - Y1 then
         H1 := Screen_Height - Y1 - 1;
      end if;

      if H1 = 0 then
         return;
      end if;

      Fill_Rect (((X, Y1), 1, H1));
   end Draw_Vertical_Line;

   procedure Fill_Circle
     (Center : Point;
      Radius : Natural)
   is

      F     : Integer := 1 - Radius;
      ddF_X : Integer := 1;
      ddF_Y : Integer := -(2 * Radius);
      X     : Integer := 0;
      Y     : Integer := Radius;
      Index : Natural := 0 with Ghost;
      Index_if : Natural := 0 with Ghost;
      ddF_X_Init : Integer with Ghost;
      ddF_Y_Init : Integer with Ghost;
      F_Init : Integer with Ghost;
   begin
      Draw_Vertical_Line
        (Center.X,
         Center.Y - Radius,
         2 * Radius);
      Draw_Horizontal_Line
        (Center.X - Radius,
         Center.Y,
         2 * Radius);

      ddF_X_Init := ddF_X;
      ddF_Y_Init := ddF_Y;
      F_Init := F;
      while X < Y loop
         pragma Loop_Invariant (X >= 0 and then X < Y and then Y <= Radius);
         pragma Loop_Invariant (Radius = Y - X + Index + Index_if);
         pragma Loop_Invariant (ddF_X = ddF_X_Init + 2 * Index);
         pragma Loop_Invariant (ddF_Y = ddF_Y_Init + 2 * Index_if);
         pragma Loop_Invariant (F <= F_Init + ddF_X * Index + ddF_Y * Index_if);
         if F >= 0 then
            Y := Y - 1;
            ddF_Y := ddF_Y + 2;
            F := F + ddF_Y;
            Index_if := Index_if + 1;
         end if;
         X := X + 1;
         ddF_X := ddF_X + 2;
         F := F + ddF_X;

         Draw_Horizontal_Line (Center.X - X, Center.Y + Y, 2 * X);
         Draw_Horizontal_Line (Center.X - X, Center.Y - Y, 2 * X);
         Draw_Horizontal_Line (Center.X - Y, Center.Y + X, 2 * Y);
         Draw_Horizontal_Line (Center.X - Y, Center.Y - X, 2 * Y);
         Index := Index + 1;
      end loop;
   end Fill_Circle;

   procedure Draw_Char (Pt   : Point;
                        Char    : Character;
                        On   : Boolean := True;
                        Size : Char_Size := 1)
   is
      pragma Unreferenced (Size);
      Data_Car : Array_of_Car := [others => 0];
   begin
      case Char is
         when 'a' | 'A' => Data_Car := A;
         when 'b' | 'B' => Data_Car := B;
         when 'c' | 'C' => Data_Car := C;
         when 'd' | 'D' => Data_Car := D;
         when 'e' | 'E' => Data_Car := E;
         when 'f' | 'F' => Data_Car := F;
         when 'g' | 'G' => Data_Car := G;
         when 'h' | 'H' => Data_Car := H;
         when 'i' | 'I' => Data_Car := I;
         when 'j' | 'J' => Data_Car := J;
         when 'k' | 'K' => Data_Car := K;
         when 'l' | 'L' => Data_Car := L;
         when 'm' | 'M' => Data_Car := M;
         when 'n' | 'N' => Data_Car := N;
         when 'o' | 'O' => Data_Car := O;
         when 'p' | 'P' => Data_Car := P;
         when 'q' | 'Q' => Data_Car := Q;
         when 'r' | 'R' => Data_Car := R;
         when 's' | 'S' => Data_Car := S;
         when 't' | 'T' => Data_Car := T;
         when 'u' | 'U' => Data_Car := U;
         when 'v' | 'V' => Data_Car := V;
         when 'w' | 'W' => Data_Car := W;
         when 'x' | 'X' => Data_Car := X;
         when 'y' | 'Y' => Data_Car := Y;
         when 'z' | 'Z' => Data_Car := Z;

         when '0' => Data_Car := N0;
         when '1' => Data_Car := N1;
         when '2' => Data_Car := N2;
         when '3' => Data_Car := N3;
         when '4' => Data_Car := N4;
         when '5' => Data_Car := N5;
         when '6' => Data_Car := N6;
         when '7' => Data_Car := N7;
         when '8' => Data_Car := N8;
         when '9' => Data_Car := N9;

         when others => null;
      end case;

      for J in Pt.Y .. Pt.Y + Char_Height - 1 loop
         for I in Pt.X .. Pt.X + Char_Width - 1 loop
            if Data_Car (I - Pt.X + (J - Pt.Y) * Char_Width) = 1 then
               Set_Pixel ((I, J), On);
            end if;
         end loop;
      end loop;

   end Draw_Char;

   procedure Put (Str : String) is
   begin
      for C of Str loop
         Put (C);
      end loop;
   end Put;

   procedure Put (C : Character) is
   begin
      if C = ASCII.CR or else Cursor_Y + Char_Height > Screen_Height then
         return;
      end if;

      if C = ASCII.LF or else Cursor_X + Full_Char_Width * Text_Size > Screen_Width then
         New_Line;
      else
         Draw_Char ((Cursor_X, Cursor_Y), C, Size => Text_Size);
         Cursor_X := Cursor_X + Full_Char_Width * Text_Size;
      end if;

   end Put;

   procedure Put (I : Interfaces.Integer_32)
     is
   begin
      Put (Integer32_Parsing.Print_Int_32 (I));
   end Put;

   procedure New_Line is
   begin
      Cursor_X := 0;
      if Cursor_Y + Char_Height * Text_Size > Screen_Height
      then
         Cursor_Y := 0;
      else
         Cursor_Y := Cursor_Y + Char_Height * Text_Size;
      end if;
   end New_Line;

   procedure Set_Text_Cursor (X, Y : Natural) is
   begin
      Cursor_X := X;
      Cursor_Y := Y;
   end Set_Text_Cursor;

   ------------
   -- Update --
   ------------

   procedure Update (Clear : Boolean := False) is
   begin

      Command (16#2c#, Pixel_Data);
      if Clear then
         Pixel_Data := [others => 0];
      end if;

   end Update;

end Pico.Pimoroni.Display;
