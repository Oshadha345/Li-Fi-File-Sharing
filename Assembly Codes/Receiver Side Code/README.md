# LiFi UART Receiver with SSD1306 OLED Display (AVR Assembly)

This repository contains the bare-metal AVR Assembly source code for a **LiFi (Light Fidelity) Receiver**. It uses an ATmega328P microcontroller to decode light pulses sent by a LiFi transmitter into standard UART serial data. The received characters are buffered in SRAM and actively rendered onto a 128x32 I2C OLED display (SSD1306) using a custom font stored in Flash memory.

## 🚀 Features

* **Hardware TWI (I2C):** Implements low-level I2C protocol drivers to communicate with the OLED display at 100 kHz.
* **SRAM Message Buffering:** Safely stores up to 21 incoming characters in Data Memory (SRAM) using indirect pointer addressing before rendering them.
* **Custom Flash Memory Font:** Utilizes a custom 5x7 bitmap font stored in Program Memory (Flash). Entries are 6 bytes wide to perfectly align memory and provide automatic character spacing.
* **Hardware Multiplication:** Uses the AVR `mul` instruction for fast 16-bit pointer arithmetic during font lookups.
* **Screen Management:** Automatically clears the screen and resets the buffer when a Newline (`\n`) or Carriage Return (`\r`) is received.
* **Horizontal Addressing Mode:** Configures the SSD1306 GDDRAM to automatically wrap columns, allowing for continuous data streaming without repositioning the cursor for every byte.

---

## 🛠 Hardware Requirements

* **Microcontroller:** ATmega328P (e.g., Arduino Uno).
* **Clock Speed:** 16 MHz (Standard external crystal).
* **Display:** 128x32 I2C OLED Display (SSD1306 Controller, Address `0x3C`).
* **Input:** A LiFi receiver circuit (e.g., a photodiode or LDR paired with an op-amp/comparator) connected to the RX pin to convert light pulses back into clean 0V/5V digital logic.

## 📌 Pin Configuration

| Component | ATmega328P Pin | Arduino Uno Pin | I/O Type | Description |
| --- | --- | --- | --- | --- |
| **UART RX** | PD0 | D0 | Input | Connect to LiFi Receiver Circuit |
| **I2C SDA** | PC4 | A4 | In/Out | I2C Data Line (requires pull-up) |
| **I2C SCL** | PC5 | A5 | Output | I2C Clock Line (requires pull-up) |

---

## 🧠 How It Works Under the Hood

### 1. UART Asynchronous Reception

The LiFi receiver circuit translates flashes of light back into electrical HIGH/LOW signals. The ATmega's hardware UART is configured to 300 Baud (8N1).

The code continuously polls the `RXC0` (Receive Complete) flag. When a full 8-bit character is successfully sampled and reassembled, the code extracts it from the `UDR0` register.

### 2. Dynamic SRAM Buffering

Because a screen must be refreshed with the entire message, characters cannot be displayed and immediately forgotten.

* The code reserves a block of SRAM starting at address `0x0100`.
* It uses the 16-bit `X` pointer register (`XH:XL`) to keep track of where to store the next byte.
* The message length is tracked in register `r2`. When a carriage return (`\r`) or line feed (`\n`) is detected, `r2` is reset to 0, clearing the display for the next message.

### 3. TWI (I2C) Communication

To talk to the SSD1306, the code configures the Two-Wire Interface (TWI) peripheral.

The clock speed is calculated for 100 kHz using the formula:


$$TWBR = \frac{(\frac{F_{CPU}}{TWI\_FREQ}) - 16}{2}$$


The code uses dedicated subroutines to send `START` conditions, transmit the device address (`0x3C << 1`), send `Control Bytes` (`0x00` for commands, `0x40` for data), and issue `STOP` conditions.

### 4. Font Rendering and Pointer Math

When a character is ready to be drawn:

1. **Offset:** The ASCII value is subtracted by 32 (since the font table starts at the space character).
2. **Multiply:** The AVR's hardware multiplier multiplies this offset by 6 (since each character is 6 bytes wide: 5 bytes for the glyph, 1 for the gap).
3. **Fetch & Draw:** This 16-bit offset is added to the `Z` pointer base address. The code fetches the 6 bytes from Flash memory using `lpm` and streams them sequentially over I2C to the OLED.

Because the OLED is configured in **Horizontal Addressing Mode**, streaming 6 bytes automatically paints the character and moves the internal screen cursor over by 6 pixels, perfectly setting up the next letter!

---

## ⚙️ Compilation and Flashing

Standard AVR GCC toolchains can be used to compile this project:

```bash
# Compile the assembly file
avr-gcc -mmcu=atmega328p -Wall -Os -o lifi_rx.elf lifi_rx.S

# Convert the ELF output to a HEX file
avr-objcopy -j .text -j .data -O ihex lifi_rx.elf lifi_rx.hex

# Upload to the microcontroller using avrdude
avrdude -c arduino -p m328p -P /dev/ttyACM0 -b 115200 -U flash:w:lifi_rx.hex:i

```

*(Note: Be sure to change `/dev/ttyACM0` to the actual port your board is connected to).*

