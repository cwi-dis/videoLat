
// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
  // initialize A1 as analog input
  pinMode(A1, INPUT);
  Serial.begin(115200);
}

unsigned long lastWrite = 0;
char ledStatus = '0';

// the loop function runs over and over again forever
void loop() {
  while (Serial.available()) {
    char ch = Serial.read();
    if (ch == '1') {
      ledStatus = ch;
      digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
    } else if (ch == '0') {
      ledStatus = ch;
      digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (HIGH is the voltage level)
    }
  }
  if (millis() > lastWrite + 1) {
    int lightLevel = analogRead(A1);
      Serial.println(lightLevel / 4);
      lastWrite = millis();
  }
}
