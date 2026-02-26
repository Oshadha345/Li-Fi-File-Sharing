/*
* LiFi Transmitter - Slow Speed Test
* Hardware: Arduino Uno/Nano + 1W LED Driver
* Pin: Pin 1 (TX) -> Connect to Transistor Base
*/

void setup() {
// 1. Initialize Serial at 1200 Baud (Slow & Stable)
// This makes the pulses ~8x longer than 9600 baud,
// giving your 1W LED plenty of time to fully turn on/off.
Serial.begin(300);
}

void loop() {
// 2. Send the character 'A'
Serial.write('A');

// 3. Wait a bit so you don't flood the receiver screen
// sending 4 characters per second is easy to read.
delay(250);
}