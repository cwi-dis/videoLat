/*
  Analog input, analog output, serial output
 
 Reads an analog input pin, maps the result to a range from 0 to 255
 and uses the result to set the pulsewidth modulation (PWM) of an output pin.
 Also prints the results to the serial monitor.
 
 The circuit:
 * potentiometer connected to pin 5.
   Center pin of the potentiometer goes to the pin.
   side pins of the potentiometer go to +3.3V and ground
 * LED connected from pin 3 to ground
 
 created 29 Dec. 2008
 modified 9 Apr 2012
 by Tom Igoe
 
 This example code is in the public domain.
 
 */

// These constants won't change.  They're used to give names
// to the pins used:
const int analogInPin = 3;  // Analog input pin that the potentiometer is attached to
const int analogOutPin = 4; // Analog output pin that the LED is attached to

int sensorValue = 0;        // value read from the pot
int minSensorValue = 255;
int maxSensorValue = 0;
int scaledValue;

int sequenceNumber;
int outputValue;

void setup() {
  // initialize serial communications at 9600 bps:
  Serial.begin(9600); 
}

void loop() {
  // Wait for the sequence number byte
  int nAvailable;
  while ((nAvailable = Serial.available()) < 2) delay(1);
  sequenceNumber = Serial.read();
  outputValue = Serial.read();
  if (sequenceNumber < 0) {
    Serial.write(254);
    Serial.write(nAvailable);
    delay(500);
    return;
  }
  if (outputValue < 0) {
    Serial.write(253);
    Serial.write(nAvailable);
    delay(500);
    return;
  }
  if (sequenceNumber < 128 || sequenceNumber > 192) {
    Serial.write(252);
    Serial.write(sequenceNumber);
    delay(500);
    return;
  }
  if (outputValue > 127) {
    Serial.write(251);
    Serial.write(outputValue);
    delay(500);
    return;
  }
  // wait 2 milliseconds before the next loop
  // for the analog-to-digital converter to settle
  // after the last reading:
  delay(2);                     
  
  // read the analog in value:
  sensorValue = analogRead(analogInPin);            
  // Keep min and max sensor values, and scale our result
  if (sensorValue < minSensorValue)
     minSensorValue = sensorValue;
  if (sensorValue > maxSensorValue)
     maxSensorValue = sensorValue;
  scaledValue = (sensorValue - minSensorValue) * (127 / (maxSensorValue - minSensorValue));
  
  // Set the LED output level
  analogWrite(analogOutPin, outputValue*2);

  // Send the report back
  Serial.write(sequenceNumber);
  Serial.write(scaledValue);
  

}
