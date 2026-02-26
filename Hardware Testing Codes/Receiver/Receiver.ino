/*
* LiFi Receiver - 1200 Baud (Slow Speed)
* Hardware: ATmega328P (16MHz Crystal) + SSD1306 OLED
* Connect: Op-Amp Output -> Pin 2 (RX)
*/

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Volatile variables for interrupt data
volatile char receivedChar = 0;
volatile bool newData = false;
String messageBuffer = "";

void setup() {
// 1. Initialize OLED
if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
for(;;); // Halt if display fails
}
display.clearDisplay();
display.setTextSize(2);
display.setTextColor(SSD1306_WHITE);
display.setCursor(0, 0);
display.println(F("Waiting..."));
display.display();
delay(1000);

// 2. Setup UART Registers for 1200 Baud (16MHz Clock)
// Calculation: 16,000,000 / (16 * 1200) - 1 = 832
// 832 converted to High/Low Bytes:

cli(); // Disable interrupts during setup

UBRR0H = 13; // High Byte (0x03)
UBRR0L = 4; // Low Byte (0x40)

// Enable Receiver and Receiver Interrupt
UCSR0B = (1 << RXCIE0) | (1 << RXEN0);

// Set Frame Format: 8 data bits, 1 stop bit (Default)
UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);

sei(); // Enable interrupts globally
}

void loop() {
if (newData == true) {
// Add character to buffer
messageBuffer += receivedChar;

// Keep only the last 10 characters to fit on screen
if (messageBuffer.length() > 10) {
messageBuffer = messageBuffer.substring(1);
}

// Update Screen
display.clearDisplay();
display.setCursor(0, 0);
display.println(messageBuffer);
display.display();

newData = false;
}
}

// =========================================================
// INTERRUPT SERVICE ROUTINE (ISR)
// =========================================================
ISR(USART_RX_vect) {
receivedChar = UDR0; // Read the data from the register
newData = true; // Flag main loop to update screen
}