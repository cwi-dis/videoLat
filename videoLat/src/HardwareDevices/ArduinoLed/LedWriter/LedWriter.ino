
// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(115200);
}

unsigned long lastWrite;
char ledStatus = '0';

// the loop function runs over and over again forever
void loop() {
  while (Serial.available()) {
    char ch = Serial.read();
    if (ch == '1') {
      ledStatus = ch;
      digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
      lastWrite = 0;
    } else if (ch == '0') {
      ledStatus = ch;
      digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (HIGH is the voltage level)
      lastWrite = 0;
    }
  }
  if (millis() > lastWrite + 1000) {
      Serial.write(ledStatus);
      Serial.write('\n');
      lastWrite = millis();
  }
}
