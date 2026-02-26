;==========================================================================
; LiFi UART Receiver with SSD1306 OLED Display
; ATmega328P (Arduino Uno) — 300 Baud, 8N1
; I2C OLED: 128x32, Address 0x3C
;==========================================================================

.include "m328pdef.inc"

;---------- Constants ----------
.equ F_CPU       = 16000000
.equ BAUD        = 300
.equ UBRR_VAL    = (F_CPU / (16 * BAUD)) - 1   ; = 3332 = 0x0D04

; I2C / TWI
.equ TWI_FREQ    = 100000                         ; 100 kHz I2C
.equ TWBR_VAL    = ((F_CPU / TWI_FREQ) - 16) / 2 ; = 72

; SSD1306
.equ SSD1306_ADDR = 0x3C        ; 7-bit I2C address
.equ SSD1306_CMD  = 0x00        ; Control byte: command mode
.equ SSD1306_DATA = 0x40        ; Control byte: data mode

; Display geometry
.equ DISP_WIDTH   = 128
.equ DISP_HEIGHT  = 32
.equ MAX_CHARS    = 21          ; 128 / 6 = 21 chars per line (5px + 1 gap)
.equ FONT_WIDTH   = 5           ; 5 bytes per character glyph
.equ CHAR_SPACING = 6           ; 5 pixel + 1 gap

; SRAM Buffer for received message
.equ MSG_BUF      = 0x0100      ; Start of SRAM message buffer
.equ MSG_BUF_END  = 0x0115      ; 21 chars max

;---------- Register Aliases (global) ----------
; r2  = message length (saved across calls)
; r16 = general working register
; r17 = secondary working register

;==========================================================================
; Interrupt Vector Table
;==========================================================================
.org 0x0000
    rjmp RESET

;==========================================================================
; RESET: Main Entry
;==========================================================================
.org 0x0034
RESET:
    ; --- Stack Pointer ---
    ldi   r16, high(RAMEND)
    out   SPH, r16
    ldi   r16, low(RAMEND)
    out   SPL, r16

    ; --- Clear message length ---
    clr   r2

    ; --- Init Peripherals ---
    rcall TWI_INIT
    rcall SSD1306_INIT
    rcall USART_INIT

    ; --- Show "Waiting..." on startup ---
    rcall SSD1306_CLEAR
    ldi   ZL, low(2 * STR_WAITING)
    ldi   ZH, high(2 * STR_WAITING)
    rcall SSD1306_PRINT_FLASH_STRING

;==========================================================================
; MAIN LOOP
;==========================================================================
MAIN_LOOP:
    ; Poll USART for received byte
    lds   r16, UCSR0A
    sbrs  r16, RXC0
    rjmp  MAIN_LOOP            ; No data yet — keep polling

    ; --- Read received character ---
    lds   r16, UDR0

    ; --- Check for newline (CR or LF) ---
    cpi   r16, 0x0A            ; '\n'
    breq  CLEAR_MSG
    cpi   r16, 0x0D            ; '\r'
    breq  CLEAR_MSG

    ; --- Append character to buffer ---
    mov   r17, r2              ; Current length
    cpi   r17, MAX_CHARS       ; Buffer full?
    brsh  MAIN_LOOP            ; Use brsh (unsigned)

    ; Store char in SRAM buffer
    ldi   XL, low(MSG_BUF)
    ldi   XH, high(MSG_BUF)
    add   XL, r2
    clr   r17
    adc   XH, r17
    st    X, r16               ; Store character
    inc   r2                   ; Increment length

    ; --- Redraw display ---
    rcall DISPLAY_MESSAGE
    rjmp  MAIN_LOOP

CLEAR_MSG:
    clr   r2                   ; Reset message length
    rcall SSD1306_CLEAR        ; Clear screen
    rjmp  MAIN_LOOP

;==========================================================================
; DISPLAY_MESSAGE: Draw message buffer to OLED
;==========================================================================
DISPLAY_MESSAGE:
    push  r16
    push  r17
    push  r18

    rcall SSD1306_CLEAR

    ; Set cursor to page 1, column 0 (skip damaged first line)
    rcall SSD1306_SET_CURSOR_HOME

    ; Start I2C data stream
    rcall TWI_START
    ldi   r16, (SSD1306_ADDR << 1) | 0  ; Write mode
    rcall TWI_WRITE
    ldi   r16, SSD1306_DATA              ; Data mode
    rcall TWI_WRITE

    ; Loop through each character in the buffer
    clr   r18                  ; Character index
DISP_CHAR_LOOP:
    cp    r18, r2              ; Reached end of message?
    brge  DISP_CHAR_DONE

    ; Load character from SRAM
    ldi   XL, low(MSG_BUF)
    ldi   XH, high(MSG_BUF)
    add   XL, r18
    clr   r17
    adc   XH, r17
    ld    r16, X               ; r16 = ASCII character

    ; Draw this character's 6 font bytes (5 glyph + 1 spacer)
    rcall SSD1306_SEND_CHAR_GLYPH

    inc   r18
    rjmp  DISP_CHAR_LOOP

DISP_CHAR_DONE:
    rcall TWI_STOP

    pop   r18
    pop   r17
    pop   r16
    ret

;==========================================================================
; SSD1306_SEND_CHAR_GLYPH: Send 6 font bytes for char in r16
;   (Called while I2C data stream is already open)
;   Each font entry is 6 bytes: 5 glyph columns + 1 blank spacer
;   Uses 16-bit multiply by 6 to find the correct glyph
;==========================================================================
SSD1306_SEND_CHAR_GLYPH:
    push  r0
    push  r1
    push  r16
    push  r17
    push  r18
    push  ZL
    push  ZH

    ; Clamp to printable ASCII range (32–126)
    cpi   r16, 32
    brlo  GLYPH_DEFAULT
    cpi   r16, 127
    brlo  GLYPH_OK
GLYPH_DEFAULT:
    ldi   r16, 32
GLYPH_OK:
    subi  r16, 32              ; Offset from space (font starts at ' ')

    ; Calculate font table byte address: (2 * FONT_5x7) + (char_index * 6)
    ldi   ZL, low(2 * FONT_5x7)
    ldi   ZH, high(2 * FONT_5x7)

    ; --- 16-bit multiply index by 6 using hardware multiplier ---
    ldi   r17, 6
    mul   r16, r17             ; r1:r0 = char_index * 6

    ; Add 16-bit offset to Z pointer
    add   ZL, r0
    adc   ZH, r1

    ; Send 6 font bytes (5 glyph + 1 spacer, all stored in flash)
    ldi   r18, 6
GLYPH_LOOP:
    lpm   r16, Z+
    rcall TWI_WRITE
    dec   r18
    brne  GLYPH_LOOP

    pop   ZH
    pop   ZL
    pop   r18
    pop   r17
    pop   r16
    pop   r1
    pop   r0
    ret

;==========================================================================
; USART_INIT: 300 Baud, 8N1
;==========================================================================
USART_INIT:
    ldi   r16, high(UBRR_VAL)
    sts   UBRR0H, r16
    ldi   r16, low(UBRR_VAL)
    sts   UBRR0L, r16

    ; Enable receiver only (we don't TX on the receiver side)
    ldi   r16, (1 << RXEN0)
    sts   UCSR0B, r16

    ; 8N1 frame format
    ldi   r16, (1 << UCSZ01) | (1 << UCSZ00)
    sts   UCSR0C, r16
    ret

;==========================================================================
; TWI (I2C) LOW-LEVEL DRIVERS
;==========================================================================
TWI_INIT:
    ldi   r16, TWBR_VAL       ; Set bit rate (100 kHz)
    sts   TWBR, r16
    ldi   r16, 0x00            ; Prescaler = 1
    sts   TWSR, r16
    ret

TWI_START:
    ldi   r16, (1 << TWINT) | (1 << TWSTA) | (1 << TWEN)
    sts   TWCR, r16
TWI_START_WAIT:
    lds   r16, TWCR
    sbrs  r16, TWINT
    rjmp  TWI_START_WAIT
    ret

TWI_STOP:
    ldi   r16, (1 << TWINT) | (1 << TWSTO) | (1 << TWEN)
    sts   TWCR, r16
    ret

TWI_WRITE:                     ; Send byte in r16
    sts   TWDR, r16
    ldi   r16, (1 << TWINT) | (1 << TWEN)
    sts   TWCR, r16
TWI_WRITE_WAIT:
    lds   r16, TWCR
    sbrs  r16, TWINT
    rjmp  TWI_WRITE_WAIT
    ret

;==========================================================================
; SSD1306 DISPLAY DRIVERS
;==========================================================================

; Send a single command byte (in r16) to SSD1306
SSD1306_CMD_SEND:
    push  r16
    rcall TWI_START
    ldi   r16, (SSD1306_ADDR << 1) | 0
    rcall TWI_WRITE
    ldi   r16, SSD1306_CMD     ; 0x00 = command mode
    rcall TWI_WRITE
    pop   r16
    rcall TWI_WRITE
    rcall TWI_STOP
    ret

; Full SSD1306 initialization sequence for 128x32
SSD1306_INIT:
    ldi   r16, 0xAE            ; Display OFF
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xD5            ; Set display clock divider
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x80            ;   Suggested ratio
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA8            ; Set multiplex ratio
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x1F            ;   1/32 duty (32 rows - 1)
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xD3            ; Set display offset
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00            ;   No offset
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x40            ; Set start line = 0
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x8D            ; Charge pump setting
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x14            ;   Enable charge pump
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x20            ; Memory addressing mode
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00            ;   Horizontal addressing mode
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA1            ; Segment re-map (col 127 = SEG0)
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xC8            ; COM scan direction: remapped
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xDA            ; COM pins configuration
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x02            ;   Sequential, no remap (for 128x32)
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x81            ; Set contrast
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x8F            ;   Medium-high contrast
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xD9            ; Set pre-charge period
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xF1            ;   Phase1=1, Phase2=15
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xDB            ; Set VCOMH deselect level
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x40            ;   ~0.77 × Vcc
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA4            ; Entire display ON (follow RAM)
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA6            ; Normal display (not inverted)
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xAF            ; Display ON
    rcall SSD1306_CMD_SEND
    ret

; Clear entire display (write 0x00 to all 512 bytes: 128x32/8)
SSD1306_CLEAR:
    push  r16
    push  r17
    push  r18

    ; Reset cursor to page 0 col 0 for full clear
    ldi   r16, 0x21            ; Set column address
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00            ;   Start column = 0
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x7F            ;   End column = 127
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x22            ; Set page address
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00            ;   Start page = 0
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x03            ;   End page = 3
    rcall SSD1306_CMD_SEND

    rcall TWI_START
    ldi   r16, (SSD1306_ADDR << 1) | 0
    rcall TWI_WRITE
    ldi   r16, SSD1306_DATA
    rcall TWI_WRITE

    ; 128 x 4 pages = 512 bytes
    ldi   r18, 2               ; Outer loop: 2 iterations
CLEAR_OUTER:
    ldi   r17, 0               ; Inner loop: 256 iterations (0 wraps)
CLEAR_INNER:
    ldi   r16, 0x00
    rcall TWI_WRITE
    dec   r17
    brne  CLEAR_INNER
    dec   r18
    brne  CLEAR_OUTER

    rcall TWI_STOP

    pop   r18
    pop   r17
    pop   r16
    ret

; Set column and page address for text rendering
; Start at page 1 to skip damaged first row of pixels (8px)
SSD1306_SET_CURSOR_HOME:
    ldi   r16, 0x21            ; Set column address
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00            ;   Start column = 0
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x7F            ;   End column = 127
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x22            ; Set page address
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x01            ;   Start page = 1 (skip damaged first line)
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x03            ;   End page = 3
    rcall SSD1306_CMD_SEND
    ret

; Print a null-terminated string from Flash to OLED
SSD1306_PRINT_FLASH_STRING:
    push  r16
    push  r18

    rcall SSD1306_SET_CURSOR_HOME
    rcall TWI_START
    ldi   r16, (SSD1306_ADDR << 1) | 0
    rcall TWI_WRITE
    ldi   r16, SSD1306_DATA
    rcall TWI_WRITE

PRINT_FLASH_LOOP:
    lpm   r16, Z+
    cpi   r16, 0
    breq  PRINT_FLASH_DONE
    rcall SSD1306_SEND_CHAR_GLYPH
    rjmp  PRINT_FLASH_LOOP

PRINT_FLASH_DONE:
    rcall TWI_STOP
    pop   r18
    pop   r16
    ret

;==========================================================================
; DATA: Strings
;==========================================================================
STR_WAITING:
    .db "Waiting...", 0, 0     ; Pad to even byte count

;==========================================================================
; DATA: 5x7 Font Table (ASCII 32–126)
; Each character is 6 bytes: 5 glyph columns + 1 blank spacer (0x00)
; The 6th byte eliminates AVR assembler word-alignment padding issues
; and is also the inter-character gap sent directly to the display.
;==========================================================================
FONT_5x7:
; Space (32)
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; ! (33)
.db 0x00, 0x00, 0x5F, 0x00, 0x00, 0x00
; " (34)
.db 0x00, 0x07, 0x00, 0x07, 0x00, 0x00
; # (35)
.db 0x14, 0x7F, 0x14, 0x7F, 0x14, 0x00
; $ (36)
.db 0x24, 0x2A, 0x7F, 0x2A, 0x12, 0x00
; % (37)
.db 0x23, 0x13, 0x08, 0x64, 0x62, 0x00
; & (38)
.db 0x36, 0x49, 0x55, 0x22, 0x50, 0x00
; ' (39)
.db 0x00, 0x05, 0x03, 0x00, 0x00, 0x00
; ( (40)
.db 0x00, 0x1C, 0x22, 0x41, 0x00, 0x00
; ) (41)
.db 0x00, 0x41, 0x22, 0x1C, 0x00, 0x00
; * (42)
.db 0x08, 0x2A, 0x1C, 0x2A, 0x08, 0x00
; + (43)
.db 0x08, 0x08, 0x3E, 0x08, 0x08, 0x00
; , (44)
.db 0x00, 0x50, 0x30, 0x00, 0x00, 0x00
; - (45)
.db 0x08, 0x08, 0x08, 0x08, 0x08, 0x00
; . (46)
.db 0x00, 0x60, 0x60, 0x00, 0x00, 0x00
; / (47)
.db 0x20, 0x10, 0x08, 0x04, 0x02, 0x00
; 0 (48)
.db 0x3E, 0x51, 0x49, 0x45, 0x3E, 0x00
; 1 (49)
.db 0x00, 0x42, 0x7F, 0x40, 0x00, 0x00
; 2 (50)
.db 0x42, 0x61, 0x51, 0x49, 0x46, 0x00
; 3 (51)
.db 0x21, 0x41, 0x45, 0x4B, 0x31, 0x00
; 4 (52)
.db 0x18, 0x14, 0x12, 0x7F, 0x10, 0x00
; 5 (53)
.db 0x27, 0x45, 0x45, 0x45, 0x39, 0x00
; 6 (54)
.db 0x3C, 0x4A, 0x49, 0x49, 0x30, 0x00
; 7 (55)
.db 0x01, 0x71, 0x09, 0x05, 0x03, 0x00
; 8 (56)
.db 0x36, 0x49, 0x49, 0x49, 0x36, 0x00
; 9 (57)
.db 0x06, 0x49, 0x49, 0x29, 0x1E, 0x00
; : (58)
.db 0x00, 0x36, 0x36, 0x00, 0x00, 0x00
; ; (59)
.db 0x00, 0x56, 0x36, 0x00, 0x00, 0x00
; < (60)
.db 0x00, 0x08, 0x14, 0x22, 0x41, 0x00
; = (61)
.db 0x14, 0x14, 0x14, 0x14, 0x14, 0x00
; > (62)
.db 0x41, 0x22, 0x14, 0x08, 0x00, 0x00
; ? (63)
.db 0x02, 0x01, 0x51, 0x09, 0x06, 0x00
; @ (64)
.db 0x32, 0x49, 0x79, 0x41, 0x3E, 0x00
; A (65)
.db 0x7E, 0x11, 0x11, 0x11, 0x7E, 0x00
; B (66)
.db 0x7F, 0x49, 0x49, 0x49, 0x36, 0x00
; C (67)
.db 0x3E, 0x41, 0x41, 0x41, 0x22, 0x00
; D (68)
.db 0x7F, 0x41, 0x41, 0x22, 0x1C, 0x00
; E (69)
.db 0x7F, 0x49, 0x49, 0x49, 0x41, 0x00
; F (70)
.db 0x7F, 0x09, 0x09, 0x01, 0x01, 0x00
; G (71)
.db 0x3E, 0x41, 0x41, 0x51, 0x32, 0x00
; H (72)
.db 0x7F, 0x08, 0x08, 0x08, 0x7F, 0x00
; I (73)
.db 0x00, 0x41, 0x7F, 0x41, 0x00, 0x00
; J (74)
.db 0x20, 0x40, 0x41, 0x3F, 0x01, 0x00
; K (75)
.db 0x7F, 0x08, 0x14, 0x22, 0x41, 0x00
; L (76)
.db 0x7F, 0x40, 0x40, 0x40, 0x40, 0x00
; M (77)
.db 0x7F, 0x02, 0x04, 0x02, 0x7F, 0x00
; N (78)
.db 0x7F, 0x04, 0x08, 0x10, 0x7F, 0x00
; O (79)
.db 0x3E, 0x41, 0x41, 0x41, 0x3E, 0x00
; P (80)
.db 0x7F, 0x09, 0x09, 0x09, 0x06, 0x00
; Q (81)
.db 0x3E, 0x41, 0x51, 0x21, 0x5E, 0x00
; R (82)
.db 0x7F, 0x09, 0x19, 0x29, 0x46, 0x00
; S (83)
.db 0x46, 0x49, 0x49, 0x49, 0x31, 0x00
; T (84)
.db 0x01, 0x01, 0x7F, 0x01, 0x01, 0x00
; U (85)
.db 0x3F, 0x40, 0x40, 0x40, 0x3F, 0x00
; V (86)
.db 0x1F, 0x20, 0x40, 0x20, 0x1F, 0x00
; W (87)
.db 0x3F, 0x40, 0x38, 0x40, 0x3F, 0x00
; X (88)
.db 0x63, 0x14, 0x08, 0x14, 0x63, 0x00
; Y (89)
.db 0x07, 0x08, 0x70, 0x08, 0x07, 0x00
; Z (90)
.db 0x61, 0x51, 0x49, 0x45, 0x43, 0x00
; [ (91)
.db 0x00, 0x7F, 0x41, 0x41, 0x00, 0x00
; \ (92)
.db 0x02, 0x04, 0x08, 0x10, 0x20, 0x00
; ] (93)
.db 0x00, 0x41, 0x41, 0x7F, 0x00, 0x00
; ^ (94)
.db 0x04, 0x02, 0x01, 0x02, 0x04, 0x00
; _ (95)
.db 0x40, 0x40, 0x40, 0x40, 0x40, 0x00
; ` (96)
.db 0x00, 0x01, 0x02, 0x04, 0x00, 0x00
; a (97)
.db 0x20, 0x54, 0x54, 0x54, 0x78, 0x00
; b (98)
.db 0x7F, 0x48, 0x44, 0x44, 0x38, 0x00
; c (99)
.db 0x38, 0x44, 0x44, 0x44, 0x20, 0x00
; d (100)
.db 0x38, 0x44, 0x44, 0x48, 0x7F, 0x00
; e (101)
.db 0x38, 0x54, 0x54, 0x54, 0x18, 0x00
; f (102)
.db 0x08, 0x7E, 0x09, 0x01, 0x02, 0x00
; g (103)
.db 0x08, 0x14, 0x54, 0x54, 0x3C, 0x00
; h (104)
.db 0x7F, 0x08, 0x04, 0x04, 0x78, 0x00
; i (105)
.db 0x00, 0x44, 0x7D, 0x40, 0x00, 0x00
; j (106)
.db 0x20, 0x40, 0x44, 0x3D, 0x00, 0x00
; k (107)
.db 0x00, 0x7F, 0x10, 0x28, 0x44, 0x00
; l (108)
.db 0x00, 0x41, 0x7F, 0x40, 0x00, 0x00
; m (109)
.db 0x7C, 0x04, 0x18, 0x04, 0x78, 0x00
; n (110)
.db 0x7C, 0x08, 0x04, 0x04, 0x78, 0x00
; o (111)
.db 0x38, 0x44, 0x44, 0x44, 0x38, 0x00
; p (112)
.db 0x7C, 0x14, 0x14, 0x14, 0x08, 0x00
; q (113)
.db 0x08, 0x14, 0x14, 0x18, 0x7C, 0x00
; r (114)
.db 0x7C, 0x08, 0x04, 0x04, 0x08, 0x00
; s (115)
.db 0x48, 0x54, 0x54, 0x54, 0x20, 0x00
; t (116)
.db 0x04, 0x3F, 0x44, 0x40, 0x20, 0x00
; u (117)
.db 0x3C, 0x40, 0x40, 0x20, 0x7C, 0x00
; v (118)
.db 0x1C, 0x20, 0x40, 0x20, 0x1C, 0x00
; w (119)
.db 0x3C, 0x40, 0x30, 0x40, 0x3C, 0x00
; x (120)
.db 0x44, 0x28, 0x10, 0x28, 0x44, 0x00
; y (121)
.db 0x0C, 0x50, 0x50, 0x50, 0x3C, 0x00
; z (122)
.db 0x44, 0x64, 0x54, 0x4C, 0x44, 0x00
; { (123)
.db 0x00, 0x08, 0x36, 0x41, 0x00, 0x00
; | (124)
.db 0x00, 0x00, 0x7F, 0x00, 0x00, 0x00
; } (125)
.db 0x00, 0x41, 0x36, 0x08, 0x00, 0x00
; ~ (126)
.db 0x08, 0x04, 0x08, 0x10, 0x08, 0x00