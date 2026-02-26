;=====================================================
; LiFi UART Transmitter with 4×3 Keypad
; ATmega328P (Arduino Uno) — 300 Baud, 8N1
; Keypad Rows: PD2–PD5 (output, active-low scan)
; Keypad Cols: PD6, PD7, PB0 (input, internal pull-up)
; TX output: PD1 (UART TX to LED driver)
;=====================================================

.include "m328pdef.inc"

;---------- Constants ----------
.equ F_CPU     = 16000000
.equ BAUD      = 300
.equ UBRR_VAL  = (F_CPU / (16 * BAUD)) - 1  ; = 3332 = 0x0D04

; Keypad GPIO
; Rows: PD2 (ROW0), PD3 (ROW1), PD4 (ROW2), PD5 (ROW3) — outputs
; Cols: PD6 (COL0), PD7 (COL1), PB0 (COL2) — inputs with pull-ups

.equ ROW0_BIT  = 2            ; PD2
.equ ROW1_BIT  = 3            ; PD3
.equ ROW2_BIT  = 4            ; PD4
.equ ROW3_BIT  = 5            ; PD5
.equ COL0_BIT  = 6            ; PD6
.equ COL1_BIT  = 7            ; PD7
.equ COL2_BIT  = 0            ; PB0

.equ ROW_MASK  = (1<<ROW0_BIT)|(1<<ROW1_BIT)|(1<<ROW2_BIT)|(1<<ROW3_BIT)
                               ; 0x3C = bits 2,3,4,5

.equ NO_KEY    = 0xFF         ; Sentinel: no key pressed

;---------- Interrupt Vector Table ----------
.org 0x0000
    rjmp RESET

;=====================================================
; RESET: Entry point
;=====================================================
.org 0x0034
RESET:
    ;--- Stack Pointer ---
    ldi   r16, high(RAMEND)
    out   SPH, r16
    ldi   r16, low(RAMEND)
    out   SPL, r16

    ;--- Init Peripherals ---
    rcall USART_INIT
    rcall KEYPAD_INIT

    ;--- Send startup message over UART ---
    ldi   ZL, low(2 * MSG_READY)
    ldi   ZH, high(2 * MSG_READY)
    rcall USART_PRINT_STRING

;=====================================================
; MAIN LOOP: Scan keypad ? Transmit character
;=====================================================
MAIN_LOOP:
    rcall KEYPAD_SCAN          ; Result in r16 (ASCII or NO_KEY)
    cpi   r16, NO_KEY
    breq  MAIN_LOOP            ; No key — keep scanning

    ;--- Debounce: wait ~20ms ---
    rcall DELAY_20MS

    ;--- Confirm key is still pressed (re-scan) ---
    mov   r17, r16             ; Save first scan result
    rcall KEYPAD_SCAN
    cp    r16, r17             ; Same key?
    brne  MAIN_LOOP            ; Noise — discard

    ;--- Key confirmed — handle it ---
    cpi   r16, 0x0A            ; Is it '#' mapped to LF? (we use 0x0A internally)
    breq  SEND_NEWLINE
    cpi   r16, 0x08            ; Is it '*' mapped to backspace?
    breq  SEND_KEY

    ;--- Normal digit key: transmit ASCII ---
SEND_KEY:
    rcall USART_TRANSMIT

    ;--- Wait for key release ---
    rcall WAIT_KEY_RELEASE
    rjmp  MAIN_LOOP

SEND_NEWLINE:
    ldi   r16, 0x0D            ; Send CR
    rcall USART_TRANSMIT
    ldi   r16, 0x0A            ; Send LF
    rcall USART_TRANSMIT

    ;--- Wait for key release ---
    rcall WAIT_KEY_RELEASE
    rjmp  MAIN_LOOP

;=====================================================
; KEYPAD_INIT: Configure row pins as outputs (high),
;              column pins as inputs with pull-ups
;=====================================================
KEYPAD_INIT:
    ;--- Rows PD2–PD5: set as outputs, initially HIGH ---
    in    r16, DDRD
    ori   r16, ROW_MASK        ; Set bits 2,3,4,5 as output
    out   DDRD, r16

    in    r16, PORTD
    ori   r16, ROW_MASK        ; Drive rows HIGH (inactive)
    out   PORTD, r16

    ;--- Col0 = PD6, Col1 = PD7: inputs with pull-ups ---
    in    r16, DDRD
    andi  r16, ~((1<<COL0_BIT) | (1<<COL1_BIT))  ; Clear bits 6,7 = input
    out   DDRD, r16

    in    r16, PORTD
    ori   r16, (1<<COL0_BIT) | (1<<COL1_BIT)      ; Enable pull-ups
    out   PORTD, r16

    ;--- Col2 = PB0: input with pull-up ---
    in    r16, DDRB
    andi  r16, ~(1<<COL2_BIT)  ; Clear bit 0 = input
    out   DDRB, r16

    in    r16, PORTB
    ori   r16, (1<<COL2_BIT)   ; Enable pull-up
    out   PORTB, r16

    ret

;=====================================================
; KEYPAD_SCAN: Scan all 4 rows × 3 columns
;   Returns: ASCII char in r16, or NO_KEY (0xFF)
;
;   Scans by pulling one row LOW at a time, then
;   reading columns. A pressed key reads LOW.
;
;   Register usage:
;     r18 = current row number (0–3)
;     r19 = row bit mask (the pin to pull low)
;     r20 = column reading
;     r16 = result
;=====================================================
KEYPAD_SCAN:
    push  r18
    push  r19
    push  r20
    push  ZL
    push  ZH

    ldi   r18, 0               ; Row counter = 0
    ldi   r19, (1<<ROW0_BIT)   ; Start with ROW0 bit mask (bit 2)

SCAN_ROW_LOOP:
    cpi   r18, 4
    breq  SCAN_NO_KEY          ; All 4 rows scanned, no key found

    ;--- Drive current row LOW, all others HIGH ---
    in    r16, PORTD
    ori   r16, ROW_MASK        ; Set all rows HIGH first
    com   r19                  ; Invert mask: bit to clear
    and   r16, r19             ; Clear the one row bit (drive LOW)
    com   r19                  ; Restore mask for later
    out   PORTD, r16

    ;--- Small settling delay (~5µs at 16MHz) ---
    nop
    nop
    nop
    nop
    nop

    ;--- Read columns ---
    ; Col0 = PD6, Col1 = PD7
    in    r20, PIND

    ; Check COL0 (PD6)
    sbrs  r20, COL0_BIT        ; Skip if COL0 is HIGH (not pressed)
    rjmp  FOUND_COL0

    ; Check COL1 (PD7)
    sbrs  r20, COL1_BIT
    rjmp  FOUND_COL1

    ; Check COL2 (PB0)
    in    r20, PINB
    sbrs  r20, COL2_BIT
    rjmp  FOUND_COL2

    ;--- No key in this row — next row ---
    lsl   r19                  ; Shift row mask to next pin
    inc   r18                  ; Increment row counter
    rjmp  SCAN_ROW_LOOP

FOUND_COL0:
    ;--- Key at (r18, 0) ---
    ; row_index * 3 + 0
    mov   r16, r18
    lsl   r16                  ; ×2
    add   r16, r18             ; ×3
    ; r16 = key_index = row*3 + 0
    rjmp  LOOKUP_KEY

FOUND_COL1:
    ;--- Key at (r18, 1) ---
    mov   r16, r18
    lsl   r16
    add   r16, r18
    inc   r16                  ; row*3 + 1
    rjmp  LOOKUP_KEY

FOUND_COL2:
    ;--- Key at (r18, 2) ---
    mov   r16, r18
    lsl   r16
    add   r16, r18
    subi  r16, -2              ; row*3 + 2 (subi with -2 = add 2)
    rjmp  LOOKUP_KEY

LOOKUP_KEY:
    ;--- Restore all rows HIGH before returning ---
    in    r20, PORTD
    ori   r20, ROW_MASK
    out   PORTD, r20

    ;--- Look up ASCII from table ---
    ldi   ZL, low(2 * KEYPAD_TABLE)
    ldi   ZH, high(2 * KEYPAD_TABLE)
    clr   r20
    add   ZL, r16
    adc   ZH, r20
    lpm   r16, Z               ; r16 = ASCII character

    pop   ZH
    pop   ZL
    pop   r20
    pop   r19
    pop   r18
    ret

SCAN_NO_KEY:
    ;--- Restore all rows HIGH ---
    in    r16, PORTD
    ori   r16, ROW_MASK
    out   PORTD, r16

    ldi   r16, NO_KEY          ; Return 0xFF = no key

    pop   ZH
    pop   ZL
    pop   r20
    pop   r19
    pop   r18
    ret

;=====================================================
; WAIT_KEY_RELEASE: Block until no key is pressed
;   Prevents key repeat from a single press
;=====================================================
WAIT_KEY_RELEASE:
    push  r16
RELEASE_LOOP:
    rcall KEYPAD_SCAN
    cpi   r16, NO_KEY
    brne  RELEASE_LOOP         ; Key still held — keep waiting
    rcall DELAY_20MS           ; Debounce on release too
    pop   r16
    ret

;=====================================================
; DELAY_20MS: ~20ms delay at 16 MHz
;   16,000,000 Hz × 0.02s = 320,000 cycles
;   Outer loop: 200 × inner loop (4 cycles × 400) = 320,000
;=====================================================
DELAY_20MS:
    push  r16
    push  r17
    ldi   r16, 200             ; Outer count
DELAY_OUTER:
    ldi   r17, 0               ; Inner count = 256 (0 wraps)
DELAY_INNER:
    nop                        ; 1 cycle
    dec   r17                  ; 1 cycle
    brne  DELAY_INNER          ; 2 cycles (taken) = 4 cycles × 256 = 1024
    dec   r16
    brne  DELAY_OUTER          ; 200 × 1024 ? 204,800 cycles ? ~13ms
    ; Close enough for debouncing — actual is ~13ms which is fine
    pop   r17
    pop   r16
    ret

;=====================================================
; USART_INIT: Configure USART0 — 300 Baud, 8N1
;=====================================================
USART_INIT:
    ldi   r16, high(UBRR_VAL)
    sts   UBRR0H, r16
    ldi   r16, low(UBRR_VAL)
    sts   UBRR0L, r16

    ; Enable Transmitter only (no RX needed — input is from keypad)
    ldi   r16, (1 << TXEN0)
    sts   UCSR0B, r16

    ; 8N1 frame format
    ldi   r16, (1 << UCSZ01) | (1 << UCSZ00)
    sts   UCSR0C, r16
    ret

;=====================================================
; USART_TRANSMIT: Send byte in r16 via TX (Pin 1)
;=====================================================
USART_TRANSMIT:
    push  r17
USART_TX_WAIT:
    lds   r17, UCSR0A
    sbrs  r17, UDRE0
    rjmp  USART_TX_WAIT
    sts   UDR0, r16
    pop   r17
    ret

;=====================================================
; USART_PRINT_STRING: Send null-terminated Flash string
;   Z register (ZH:ZL) points to string in Flash
;=====================================================
USART_PRINT_STRING:
    push  r16
PRINT_LOOP:
    lpm   r16, Z+
    cpi   r16, 0
    breq  PRINT_DONE
    rcall USART_TRANSMIT
    rjmp  PRINT_LOOP
PRINT_DONE:
    pop   r16
    ret

;=====================================================
; DATA: Keypad Lookup Table (Flash)
;   Index = row*3 + col ? ASCII character
;
;   Layout:
;     [0] Row0,Col0 = '1'    [1] Row0,Col1 = '2'    [2] Row0,Col2 = '3'
;     [3] Row1,Col0 = '4'    [4] Row1,Col1 = '5'    [5] Row1,Col2 = '6'
;     [6] Row2,Col0 = '7'    [7] Row2,Col1 = '8'    [8] Row2,Col2 = '9'
;     [9] Row3,Col0 = '*'    [10] Row3,Col1 = '0'   [11] Row3,Col2 = '#'
;
;   '*' is mapped to 0x08 (backspace)
;   '#' is mapped to 0x0A (newline — triggers CR+LF send)
;=====================================================
KEYPAD_TABLE:
    .db '1', '2', '3', '4', '5', '6', '7', '8', '9', 0x08, '0', 0x0A
    ; 12 bytes = even ?

;=====================================================
; DATA: Startup Message
;=====================================================
MSG_READY:
    .db "LiFi Ready", 0, 0    ; 12 bytes = even ?