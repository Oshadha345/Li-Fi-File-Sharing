# LiFi IR Transmitter with 4x3 Keypad, 38kHz Carrier & XOR Encryption (AVR Assembly)

This repository contains bare-metal AVR Assembly code for a **secure LiFi/IR Transmitter** using an **ATmega328P**.  
The system scans a **4x3 matrix keypad**, maps key presses to ASCII, **encrypts each byte with XOR**, and transmits data over UART while generating a **continuous 38kHz carrier** for IR-based optical transmission.

---

## 🚀 Features

* **Bare-Metal AVR Assembly:** Fully written in low-level assembly for tight hardware control and deterministic timing.
* **4x3 Matrix Keypad Scanning:** Reads 12 keys using only 7 GPIO pins (4 rows + 3 columns).
* **Software Debounce + Release Detection:** ~20ms debounce and wait-for-release logic to avoid repeated/false triggers.
* **Flash Lookup Table (`lpm`):** Key index → ASCII mapping stored in program memory to save SRAM.
* **Secure Byte Transmission:** XOR encryption using a shared key (`SECRET_KEY = 0x5A`) before UART transmission.
* **UART @ 2400 Baud (8N1):** Configured transmitter on PD1/TX.
* **38kHz IR Carrier Generation:** Timer2 CTC toggles **PB3 (OC2A)** continuously for IR modulation support.
* **Special Key Mapping:**
  * `*` → Backspace (`0x08`)
  * `#` → Line Feed (`0x0A`), with transmit routine sending **CR + LF** sequence.

---

## 🛠 Hardware Requirements

* **Microcontroller:** ATmega328P (e.g., Arduino Uno)
* **Clock:** 16 MHz external crystal
* **Input:** Standard 4x3 matrix keypad
* **Outputs:**
  * **UART TX (PD1):** serial data output stream
  * **38kHz Carrier Output (PB3 / OC2A):** connect to IR LED driver stage (transistor + resistor)

> Recommended: drive IR LED through a transistor (e.g., 2N2222) instead of directly from MCU pin.

---

## 📌 Pin Configuration

| Function | ATmega328P Pin | Arduino Uno Pin | Direction | Description |
|---|---|---|---|---|
| Row 0 | PD2 | D2 | Output | Active-low row scan |
| Row 1 | PD3 | D3 | Output | Active-low row scan |
| Row 2 | PD4 | D4 | Output | Active-low row scan |
| Row 3 | PD5 | D5 | Output | Active-low row scan |
| Col 0 | PD6 | D6 | Input | Pull-up enabled |
| Col 1 | PD7 | D7 | Input | Pull-up enabled |
| Col 2 | PB0 | D8 | Input | Pull-up enabled |
| UART TX | PD1 | D1 | Output | Encrypted serial data |
| Carrier Out (OC2A) | PB3 | D11 | Output | Continuous 38kHz square wave |

---

## 🔐 Encryption Details

Before any byte is sent, it is encrypted in `USART_TRANSMIT_SECURE`:

- `cipher_byte = plain_byte XOR 0x5A`

This applies to:

- keypad characters
- CR/LF on Enter
- startup message (`"LiFi Ready"`)

So the receiver must XOR incoming bytes with the same key (`0x5A`) to recover plaintext.

---

## 🧠 How It Works

### 1) Initialization (`RESET`)

The firmware initializes:

1. Stack pointer
2. USART (`USART_INIT`)
3. Keypad GPIO (`KEYPAD_INIT`)
4. 38kHz carrier generator (`CARRIER_INIT`)
5. Sends encrypted startup string (`USART_PRINT_STRING`)

---

### 2) Keypad Scanning (`KEYPAD_SCAN`)

The scanner:

1. Sets all rows high.
2. Pulls one row low at a time.
3. Reads 3 column inputs.
4. If a column is low, computes key index: `row * 3 + col`.
5. Looks up ASCII from `KEYPAD_TABLE` in flash using `lpm`.

If no key is pressed, returns `NO_KEY = 0xFF`.

---

### 3) Debounce and Validation

Main loop behavior:

1. Scan key.
2. If detected, wait ~20ms (`DELAY_20MS`).
3. Scan again and compare.
4. If stable, transmit.
5. Wait until key release (`WAIT_KEY_RELEASE`) before next key.

---

### 4) Newline Handling

If `#` is pressed (mapped to `0x0A`):

- firmware sends:
  - `0x0D` (CR)
  - `0x0A` (LF)

Both are encrypted before transmit.

---

### 5) 38kHz Carrier (`CARRIER_INIT`)

Timer2 in CTC mode toggles OC2A (PB3):

- Prescaler = 1
- `OCR2A = 210`
- Output compare toggle mode enabled (`COM2A0`)

This produces a continuous carrier around 38kHz suitable for typical IR receiver modules.

---

## ⌨️ Keypad Mapping

| R\C | Col 0 | Col 1 | Col 2 |
|---|---|---|---|
| Row 0 | 1 | 2 | 3 |
| Row 1 | 4 | 5 | 6 |
| Row 2 | 7 | 8 | 9 |
| Row 3 | `*` (Backspace) | 0 | `#` (Enter) |

Internal table:

- `*` → `0x08`
- `#` → `0x0A` (then code sends CR+LF sequence)

---

## ⚙️ UART Configuration

- CPU clock: **16 MHz**
- Baud rate: **2400**
- Frame format: **8 data bits, no parity, 1 stop bit (8N1)**
- UBRR value:
  \[
  UBRR = \left(\frac{F\_CPU}{16 \cdot BAUD}\right) - 1
  \]

With `F_CPU = 16,000,000` and `BAUD = 2400`, firmware uses the computed `UBRR_VAL`.

---

## 🧪 Build & Flash

Example AVR-GCC / AVRDUDE flow:

```bash
# Assemble/compile
avr-gcc -mmcu=atmega328p -Wall -Os -o lifi_tx.elf main.asm

# Convert ELF to HEX
avr-objcopy -j .text -j .data -O ihex lifi_tx.elf lifi_tx.hex

# Flash to ATmega328P (Arduino Uno bootloader example)
avrdude -c arduino -p m328p -P /dev/ttyACM0 -b 115200 -U flash:w:lifi_tx.hex:i
```

Replace `/dev/ttyACM0` with your actual serial port (`COMx` on Windows).

---

## 📡 Receiver Requirement (Important)

Because transmitter output is XOR-encrypted, the receiver must do:

```text
plaintext = received_byte XOR 0x5A
```

If receiver decryption key does not match, output text will appear as garbage.

---

## 📝 Notes

- Current code sends an encrypted startup message: `"LiFi Ready"`.
- `NO_KEY` sentinel is `0xFF`.
- Carrier and UART are both active continuously after initialization.
- Ensure common ground and proper IR LED drive current limits in hardware.
