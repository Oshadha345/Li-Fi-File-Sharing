
# LiFi UART Transmitter with 4x3 Keypad (AVR Assembly)

This repository contains the bare-metal AVR Assembly source code for a **LiFi (Light Fidelity) Transmitter**. The system uses an ATmega328P microcontroller to scan a 4x3 matrix keypad and transmit the pressed keys as ASCII characters over a UART interface. Instead of a standard serial cable, the UART TX pin is intended to drive an LED circuit, transmitting data via visible light pulses at 300 Baud.

## 🚀 Features

* **Bare-Metal Assembly:** Written entirely in AVR assembly for precise timing and minimal memory footprint.
* **Matrix Keypad Scanning:** Efficiently reads a 12-button (4x3) keypad using only 7 GPIO pins.
* **Software Debouncing:** Implements a ~20ms delay routine to prevent false mechanical triggers.
* **Flash Memory Lookup:** Uses the microcontroller's Program Memory (Flash) to store the keypad-to-ASCII translation table, saving SRAM.
* **LiFi Ready:** Configured for a slow 300 Baud rate (8N1 frame format) to accommodate the slower response times of basic light sensors (like LDRs) on the receiver end.
* **Custom Key Mapping:** Maps the `*` key to Backspace (`0x08`) and the `#` key to Newline/Enter (`CR` + `LF`).

---

## 🛠 Hardware Requirements

* **Microcontroller:** ATmega328P (commonly found on the Arduino Uno).
* **Clock Speed:** 16 MHz (Standard Arduino Uno external crystal).
* **Input:** Standard 4x3 Matrix Keypad.
* **Output:** LED with an appropriate driver circuit (e.g., a 2N2222 transistor and resistors) connected to the TX pin.

## 📌 Pin Configuration

| Component | ATmega328P Pin | Arduino Uno Pin | I/O Type | Description |
| --- | --- | --- | --- | --- |
| **Row 0** | PD2 | D2 | Output | Active-Low Scan |
| **Row 1** | PD3 | D3 | Output | Active-Low Scan |
| **Row 2** | PD4 | D4 | Output | Active-Low Scan |
| **Row 3** | PD5 | D5 | Output | Active-Low Scan |
| **Col 0** | PD6 | D6 | Input | Internal Pull-up Enabled |
| **Col 1** | PD7 | D7 | Input | Internal Pull-up Enabled |
| **Col 2** | PB0 | D8 | Input | Internal Pull-up Enabled |
| **UART TX** | PD1 | D1 | Output | Connect to LED LiFi Driver |

---

## 🧠 How It Works Under the Hood

### 1. Keypad Scanning Algorithm

The 4x3 keypad is wired in a matrix. To detect a keypress without using 12 separate pins, the microcontroller uses a scanning algorithm:

1. The 4 Row pins are configured as outputs and set `HIGH`.
2. The 3 Column pins are configured as inputs with internal pull-up resistors enabled (so they also read `HIGH` by default).
3. The code drives **one row `LOW` at a time**.
4. It then reads the column pins. If a button is pressed, the physical switch connects the `LOW` row to the column, causing the column input to drop to `LOW`.
5. The code calculates a 1D index using `(Row * 3) + Column` to identify the exact button.

### 2. Switch Debouncing

Mechanical switches "bounce" when pressed, creating rapid on/off spikes that the fast microcontroller might interpret as multiple presses. When a `LOW` signal is detected, the code waits for **~20ms**, then checks the pins again. If the signal is still `LOW`, the keypress is verified as genuine.

### 3. Flash Memory Lookup Table

Because the AVR architecture uses separate memory spaces for code and data (Harvard architecture), constant values like the ASCII character map are stored in Flash memory. The `lpm` (Load Program Memory) instruction and the `Z` register pair are used to fetch the correct ASCII character based on the keypad index.

### 4. UART Transmission (LiFi)

Once a valid ASCII character is retrieved, it is sent to the `UDR0` (USART Data Register).

The hardware peripheral automatically wraps the 8-bit character in a Start bit and a Stop bit, transmitting it out of `PD1` at 300 bits per second. A `HIGH` bit turns the transmitting LED on, and a `LOW` bit turns it off, effectively broadcasting the data as light. The code uses polling (`UDRE0` flag) to wait until the transmitter is ready before sending the next character.

---

## ⌨️ Keypad Mapping

| R\C | Col 0 | Col 1 | Col 2 |
| --- | --- | --- | --- |
| **Row 0** | 1 | 2 | 3 |
| **Row 1** | 4 | 5 | 6 |
| **Row 2** | 7 | 8 | 9 |
| **Row 3** | `*` *(Backspace)* | 0 | `#` *(Enter/Newline)* |

---

## ⚙️ Compilation and Flashing

This code can be compiled and uploaded using standard AVR toolchains (like `avr-gcc` and `avrdude`) or IDEs like Microchip Studio.

If using a Makefile / CLI:

```bash
# Example compilation step
avr-gcc -mmcu=atmega328p -Wall -Os -o lifi_tx.elf lifi_tx.S
# Convert to hex
avr-objcopy -j .text -j .data -O ihex lifi_tx.elf lifi_tx.hex
# Flash to Arduino Uno via avrdude
avrdude -c arduino -p m328p -P /dev/ttyACM0 -b 115200 -U flash:w:lifi_tx.hex:i

```

*(Note: Replace `/dev/ttyACM0` with your actual COM port).*

---
