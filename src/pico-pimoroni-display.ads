with HAL;
with HAL.SPI; use HAL.SPI;
with Interfaces; use Interfaces;

package Pico.Pimoroni.Display with SPARK_Mode is

   type Bitmap_Color is record
      Red   : HAL.UInt8;
      Green : HAL.UInt8;
      Blue  : HAL.UInt8;
   end record with Size => 24;

      for Bitmap_Color use record
      Blue  at 0 range 0 .. 7;
      Green at 1 range 0 .. 7;
      Red   at 2 range 0 .. 7;
   end record;

      Screen_Width : constant := 240;
   Screen_Height : constant := 135;
   Nbr_Of_Pixels : constant := Screen_Width * Screen_Height;
   type Pixel is range 0 .. Nbr_Of_Pixels - 1;
   subtype Natural_Width is Natural range 0 .. Screen_Width;
   subtype Natural_Height is Natural range 0 .. Screen_Height;

   type Point is record
      X : Natural_Width;
      Y : Natural_Height;
   end record;

   type Rect is record
      Position : Point;
      Width    : Natural_Width;
      Height   : Natural_Height;
   end record
     with Dynamic_Predicate => Position.X <= Screen_Width - Width
   and then Position.Y <= Screen_Height - Height;

   procedure Initialize;

      procedure Command (Cmd : HAL.UInt8;
                         Data : SPI_Data_8b := (1 .. 0 => 0));

   procedure Set_Pixel (Pt : Point; On : Boolean := True)
     with Pre => Pt.X <= Screen_Width - 1 and then Pt.Y <= Screen_Height - 1
   ;
   procedure Set_Color (Color_Name : Bitmap_Color);
   procedure Set_Color (R : HAL.UInt8; G : HAL.UInt8; B : HAL.UInt8);

   --  procedure Get (Pxl          :     Pixel;
   --                 R, G, B    : out HAL.UInt8);

   function To_RGB565 (R, G, B    : HAL.UInt8)
                       return HAL.UInt16;

   procedure Update (Clear : Boolean := False);

   procedure Draw_Line
     (Start, Stop : Point;
      Thickness   : Natural := 1;
      Fast        : Boolean := True)
     with Pre => Check_Thickness(Start, Stop, Thickness);

   procedure Draw_Horizontal_Line (X, Y : Integer; Width : Natural)
    with Pre => Width <= Screen_Width;

   procedure Draw_Vertical_Line (X, Y : Integer; Height : Natural)
     with Pre => Height <= Screen_Height;

   procedure Fill_Circle
     (Center : Point;
      Radius : Natural)
     with Pre => Radius < 2 ** 30
     and then Center.X - Radius >= 0
       and then Center.X + Radius <= Screen_Width
     and then Center.Y - Radius >= 0
   and then Center.Y + Radius <= Screen_Height;

   procedure Fill_Rect
     (Area   : Rect);

   subtype Char_Size is Natural range 1 .. 16;
      procedure Draw_Char (Pt   : Point;
                        C    : Character;
                        On   : Boolean := True;
                           Size : Char_Size := 1)
     with Pre => Pt.X + Char_Width >= 0
     and then Pt.X + Char_Width <= Screen_Width
   and then Pt.Y + Char_Height <= Screen_Height;

   procedure Put (Str : String);
   procedure Put (C : Character);
   procedure Put (I : Interfaces.Integer_32);
   procedure New_Line;
   procedure Set_Text_Cursor (X, Y : Natural)
     with Pre => X <= Screen_Width
     and then Y <= Screen_Height;

      function Check_Thickness
     (Start, Stop : Point;
      Thickness   : Natural)
      return Boolean
     with Ghost;

   Brown               : constant Bitmap_Color := (165, 042, 042);
   Red                 : constant Bitmap_Color := (255, 000, 000);
   Orange              : constant Bitmap_Color := (255, 165, 000);
   Gold                : constant Bitmap_Color := (255, 215, 000);
   Yellow              : constant Bitmap_Color := (255, 255, 000);
   Green               : constant Bitmap_Color := (000, 255, 000);
   Cyan                : constant Bitmap_Color := (000, 255, 255);
   Turquoise           : constant Bitmap_Color := (064, 224, 208);
   Navy                : constant Bitmap_Color := (000, 000, 128);
   Blue                : constant Bitmap_Color := (000, 000, 255);
   Purple              : constant Bitmap_Color := (128, 000, 128);
   Magenta             : constant Bitmap_Color := (255, 000, 255);
   Pink                : constant Bitmap_Color := (255, 192, 203);
   Black               : constant Bitmap_Color := (000, 000, 000);
   White               : constant Bitmap_Color := (255, 255, 255);

   --  Font constant
   Char_Width       : constant := 5;
   Char_Height      : constant := 8;
   Char_Spacing     : constant := 1;
   Line_Spacing     : constant := 0;
   Full_Char_Width  : constant := Char_Width + Char_Spacing;
   Full_Char_Height : constant := Char_Height + Line_Spacing;
   private



   type Array_of_Car is array (Natural range 0 .. Char_Width * Char_Height - 1) of Natural;

   A : constant Array_of_Car := (0, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 1, 1, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 0, 0, 0, 0);

   B : constant Array_of_Car := (1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);

   CC : constant Array_of_Car := (0, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 1,
                                 0, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);

   D : constant Array_of_Car := (1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);

   E : constant Array_of_Car := (1, 1, 1, 1, 1,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 1, 1, 1, 1,
                                 0, 0, 0, 0, 0);

   F : constant Array_of_Car := (1, 1, 1, 1, 1,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 0, 0, 0, 0, 0);

   G : constant Array_of_Car := (0, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 1, 1,
                                 1, 0, 0, 0, 1,
                                 0, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);

   H : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 1, 1, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 0, 0, 0, 0);

   I : constant Array_of_Car := (0, 1, 1, 1, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);

   J : constant Array_of_Car := (0, 0, 1, 1, 1,
                                 0, 0, 0, 1, 0,
                                 0, 0, 0, 1, 0,
                                 0, 0, 0, 1, 0,
                                 0, 0, 0, 1, 0,
                                 1, 0, 0, 1, 0,
                                 0, 1, 1, 0, 0,
                                 0, 0, 0, 0, 0);

   K : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 1, 0,
                                 1, 0, 1, 0, 0,
                                 1, 1, 0, 0, 0,
                                 1, 0, 1, 0, 0,
                                 1, 0, 0, 1, 0,
                                 1, 0, 0, 0, 1,
                                 0, 0, 0, 0, 0);

   L : constant Array_of_Car := (1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 1, 1, 1, 1,
                                 0, 0, 0, 0, 0);

   M : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 1, 0, 1, 1,
                                 1, 0, 1, 0, 1,
                                 1, 0, 1, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 0, 0, 0, 0);

   N : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 0, 0, 1,
                                 1, 0, 1, 0, 1,
                                 1, 0, 0, 1, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 0, 0, 0, 0);

   O : constant Array_of_Car := (0, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);

   P : constant Array_of_Car := (1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 0, 0, 0, 0, 0);

   Q : constant Array_of_Car := (0, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 1, 0, 1,
                                 1, 0, 0, 1, 0,
                                 0, 1, 1, 0, 1,
                                 0, 0, 0, 0, 0);

   R : constant Array_of_Car := (1, 1, 1, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 1, 1, 1, 0,
                                 1, 0, 1, 0, 0,
                                 1, 0, 0, 1, 0,
                                 1, 0, 0, 0, 1,
                                 0, 0, 0, 0, 0);

   S : constant Array_of_Car := (0, 1, 1, 1, 1,
                                 1, 0, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 0, 1, 1, 1, 0,
                                 0, 0, 0, 0, 1,
                                 0, 0, 0, 0, 1,
                                 1, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);
   T : constant Array_of_Car := (1, 1, 1, 1, 1,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 0, 0, 0);

   U : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 1, 1, 1, 0,
                                 0, 0, 0, 0, 0);
   V : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 1, 0, 1, 0,
                                 0, 1, 0, 1, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 0, 0, 0);

   W : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 1, 0, 1, 0, 1,
                                 1, 0, 1, 0, 1,
                                 1, 0, 1, 0, 1,
                                 0, 1, 0, 1, 0,
                                 0, 0, 0, 0, 0);

   X : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 1, 0, 1, 0,
                                 0, 0, 1, 0, 0,
                                 0, 1, 0, 1, 0,
                                 1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 0, 0, 0, 0);

   Y : constant Array_of_Car := (1, 0, 0, 0, 1,
                                 1, 0, 0, 0, 1,
                                 0, 1, 0, 1, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 1, 0, 0,
                                 0, 0, 0, 0, 0);

   Z : constant Array_of_Car := (1, 1, 1, 1, 1,
                                 0, 0, 0, 0, 1,
                                 0, 0, 0, 1, 0,
                                 0, 0, 1, 0, 0,
                                 0, 1, 0, 0, 0,
                                 1, 0, 0, 0, 0,
                                 1, 1, 1, 1, 1,
                                 0, 0, 0, 0, 0);

   N0 : constant Array_of_Car := (0, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  0, 1, 1, 1, 0,
                                  0, 0, 0, 0, 0);

   N1 : constant Array_of_Car := (0, 0, 1, 0, 0,
                                  1, 1, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  1, 1, 1, 1, 1,
                                  0, 0, 0, 0, 0);

   N2 : constant Array_of_Car := (0, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  0, 0, 0, 1, 0,
                                  0, 0, 1, 0, 0,
                                  0, 1, 0, 0, 0,
                                  1, 0, 0, 0, 0,
                                  1, 1, 1, 1, 1,
                                  0, 0, 0, 0, 0);

   N3 : constant Array_of_Car := (0, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  0, 0, 0, 0, 1,
                                  0, 0, 1, 1, 0,
                                  0, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  0, 1, 1, 1, 0,
                                  0, 0, 0, 0, 0);

   N4 : constant Array_of_Car := (1, 0, 0, 0, 0,
                                  1, 0, 0, 0, 0,
                                  1, 0, 0, 0, 0,
                                  1, 0, 1, 0, 0,
                                  1, 1, 1, 1, 1,
                                  0, 0, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 0, 0);

   N5 : constant Array_of_Car := (1, 1, 1, 1, 1,
                                  1, 0, 0, 0, 0,
                                  1, 0, 0, 0, 0,
                                  1, 1, 1, 1, 0,
                                  0, 0, 0, 0, 1,
                                  0, 0, 0, 0, 1,
                                  1, 1, 1, 1, 0,
                                  0, 0, 0, 0, 0);

   N6 : constant Array_of_Car := (0, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 0,
                                  1, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  0, 1, 1, 1, 0,
                                  0, 0, 0, 0, 0);

   N7 : constant Array_of_Car := (1, 1, 1, 1, 1,
                                  0, 0, 0, 0, 1,
                                  0, 0, 0, 1, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 1, 0, 0,
                                  0, 0, 0, 0, 0);

   N8 : constant Array_of_Car := (0, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  0, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  0, 1, 1, 1, 0,
                                  0, 0, 0, 0, 0);

   N9 : constant Array_of_Car := (0, 1, 1, 1, 0,
                                  1, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  0, 1, 1, 1, 1,
                                  0, 0, 0, 0, 1,
                                  1, 0, 0, 0, 1,
                                  0, 1, 1, 1, 0,
                                  0, 0, 0, 0, 0);

end Pico.Pimoroni.Display;
