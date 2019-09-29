An input-output hardware assist using an Arduino and a photo-transistor.

- Buy an Arduino/Genuino micro.
- Connect phototransistor (NPN type) between 5V and Analog Input 1.
- Connect resistor (1K-50K, depends on transistor) between Analog Input 1 and GND.
- Connect to USB.
- Download the Arduino IDE.
- Build and flash LedWriterAnalogReader.

- To test: open serial monitor, 115200 baud.
  You should be getting lines with numbers between 0 and 255, representing the light
  level detected by the phototransistor. Check this is reasonable (by changing
  the light level).
  If you send a line containa only a 0 or a 1 this will turn the Arduino on-board
  LED off or on.
  Point the phototransistor at the LED and check this works.
  
- To use: calibrate the hardware by pointing the phototransistor at the on-board
  LED, delay should be low, probably a few milliseconds.
  
  Then use it to hardware-calibrate your camera by pointing it at the onboard
  LED.
  
  Or use it to hardware-calibrate your screen by pointing the phototransistor at
  the screen.