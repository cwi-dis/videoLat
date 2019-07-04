A very simple output-only hardware assist.

- Buy an Arduino/Genuino micro.
- Connect to USB.
- Download the Arduino IDE.
- Build and flash LedWriter.

- To test: open serial monitor, 115200 baud.
  Send a line containing only a 1. The onboard   LED will light and the board 
  will reply a line with 1 every second. Send a line containing only a 0. The 
  LED will go off and the board will reply a line with 0 every second. 
  Repeat until bored.
  
- To use: calibrate the hardware, delay should be very low, probably 0 ms.
  Then use it to hardware-calibrate your camera by pointing it at the onboard
  LED.