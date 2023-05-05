with HAL;
with HAL.SPI; use HAL.SPI;

package Pico.Pimoroni.Display is

   type Pixel is range 0 .. 32_399;
   procedure Initialize;

      procedure Command (Cmd : HAL.UInt8;
                         Data : SPI_Data_8b := (1 .. 0 => 0));

   procedure Set (Pxl          : Pixel;
                  R, G, B    : HAL.UInt8);

   procedure Get (Pxl          :     Pixel;
                  R, G, B    : out HAL.UInt8);

   function To_RGB565 (R, G, B    : HAL.UInt8)
     return HAL.UInt16;

   procedure Update;

      procedure Rectangle (Pxl          :     Pixel;
                        x : Natural;
                        y : Natural;
                       R,G,B : HAL.UInt8);

end Pico.Pimoroni.Display;
