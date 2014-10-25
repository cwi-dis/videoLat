/*
 Weird protocol to send and receive analog values.
 Each message and response is 2 bytes. First byte is one of
 0..128 Illegal, reserved for data bytes
 129..192 Sequence number. Echoed in response, so message and response can be matched.
 255 Filler, to resynchronise. The single byte is read and discarded.
 192..254 Errors (only used in response):
     254 No command received. Data: number of bytes in buffer (0 or 1, I guess)
     253 No data byte received. Data: number of bytes in buffer (0 or 1, I guess)
     252 Illegal sequence number read (not between 129 and 192)
     251 Illegal data byte read (not between 0 and 127) Data: the byte read.
     
   The data bytes are 7-bit values. The output values (in the message) are multiplied by
   two and sent to the LED as an 8-bit value. The input values are auto-scaled
   by keeping minimal and maximal value ever received and using those to scale
   the current value read.
 */

// These constants won't change.  They're used to give names
// to the pins used:
const int analogInPin = 3;  // Analog input pin that the potentiometer is attached to
const int analogOutPin = 4; // Analog output pin that the LED is attached to

int sensorValue = 0;        // value read from the pot
int outputValue;

void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600); 
}

void loop() {
  // Read all input, updating eventual output value.
  while (Serial.available() > 0) {
    outputValue = Serial.read();
  }
  
  // read the analog in value:
  sensorValue = analogRead(analogInPin);            
  analogWrite(analogOutPin, outputValue);

  // Send the report back
  Serial.write(sensorValue);
  // wait 2 milliseconds before the next loop
  // for the analog-to-digital converter to settle
  // after the last reading:
  delay(2);                     
  

}
