; TRANSMITTER ( for 38KHz with XOR Encryption)
.include "m328pdef.inc"

; --- System and UART Configuration ---
.equ F_CPU      = 16000000          ; 16 MHz external crystal
.equ BAUD       = 2400             
.equ UBRR_VAL   = (F_CPU / (16 * BAUD)) - 1

; --- Keypad Matrix Pin Mapping & Encryption ---
.equ SECRET_KEY = 0x5A              ; NEW: The shared encryption key
.equ ROW0_BIT   = 2                 ; PD2 (Output)
.equ ROW1_BIT   = 3                 ; PD3 (Output)
.equ ROW2_BIT   = 4                 ; PD4 (Output)
.equ ROW3_BIT   = 5                 ; PD5 (Output)
.equ COL0_BIT   = 6                 ; PD6 (Input with pull-up)
.equ COL1_BIT   = 7                 ; PD7 (Input with pull-up)
.equ COL2_BIT   = 0                 ; PB0 (Input with pull-up)

.equ ROW_MASK   = (1<<ROW0_BIT)|(1<<ROW1_BIT)|(1<<ROW2_BIT)|(1<<ROW3_BIT)
.equ NO_KEY     = 0xFF              

.org 0x0000
    rjmp RESET                      

.org 0x0034
RESET:
    ; Initialize Stack Pointer 
    ldi   r16, high(RAMEND)
    out   SPH, r16
    ldi   r16, low(RAMEND)
    out   SPL, r16

    rcall USART_INIT
    rcall KEYPAD_INIT
    rcall CARRIER_INIT              ; START THE 38kHz BACKGROUND TIMER

    ; Send Startup String
    ldi   ZL, low(2 * MSG_READY)
    ldi   ZH, high(2 * MSG_READY)
    rcall USART_PRINT_STRING

; --- Main Execution Loop ---
MAIN_LOOP:
    rcall KEYPAD_SCAN               
    cpi   r16, NO_KEY
    breq  MAIN_LOOP                 

    rcall DELAY_20MS                

    mov   r17, r16
    rcall KEYPAD_SCAN               
    cp    r16, r17
    brne  MAIN_LOOP                 

    cpi   r16, 0x0A                 ; '#' = Line Feed
    breq  SEND_NEWLINE
    cpi   r16, 0x08                 ; '*' = Backspace
    breq  SEND_KEY

SEND_KEY:
    rcall USART_TRANSMIT_SECURE     ; Send encrypted keystroke
    rcall WAIT_KEY_RELEASE          
    rjmp  MAIN_LOOP

SEND_NEWLINE:
    ldi   r16, 0x0D                 ; Carriage Return (CR)
    rcall USART_TRANSMIT_SECURE     ; Send encrypted CR
    ldi   r16, 0x0A                 ; Line Feed (LF)
    rcall USART_TRANSMIT_SECURE     ; Send encrypted LF
    rcall WAIT_KEY_RELEASE
    rjmp  MAIN_LOOP

; --- Hardware Initialization ---
KEYPAD_INIT:
    in    r16, DDRD
    ori   r16, ROW_MASK
    out   DDRD, r16
    in    r16, PORTD
    ori   r16, ROW_MASK
    out   PORTD, r16

    in    r16, DDRD
    andi  r16, ~((1<<COL0_BIT) | (1<<COL1_BIT))
    out   DDRD, r16
    in    r16, PORTD
    ori   r16, (1<<COL0_BIT) | (1<<COL1_BIT)
    out   PORTD, r16
    in    r16, DDRB
    andi  r16, ~(1<<COL2_BIT)
    out   DDRB, r16
    in    r16, PORTB
    ori   r16, (1<<COL2_BIT)
    out   PORTB, r16
    ret

;==========================================================================
; CARRIER_INIT: Generates continuous 38kHz square wave on PB3 (Leg 17)
; Uses Timer2 in CTC Mode. Calculation: 16MHz / (2 * 1 * 38000) - 1 = 210
;==========================================================================
CARRIER_INIT:
    in    r16, DDRB
    ori   r16, (1<<3)               ; Set PB3 as Output
    out   DDRB, r16
    ldi   r16, 210
    sts   OCR2A, r16
    ldi   r16, (1<<COM2A0) | (1<<WGM21)
    sts   TCCR2A, r16
    ldi   r16, (1<<CS20)
    sts   TCCR2B, r16
    ret

; --- Matrix Scanning Logic ---
KEYPAD_SCAN:
    push  r18                       
    push  r19
    push  r20
    push  ZL
    push  ZH

    ldi   r18, 0                    
    ldi   r19, (1<<ROW0_BIT)        

SCAN_ROW_LOOP:
    cpi   r18, 4
    breq  SCAN_NO_KEY               

    in    r16, PORTD
    ori   r16, ROW_MASK
    com   r19                       
    and   r16, r19
    com   r19                       
    out   PORTD, r16

    nop
    nop
    nop
    nop
    nop

    in    r20, PIND
    sbrs  r20, COL0_BIT             
    rjmp  FOUND_COL0
    sbrs  r20, COL1_BIT
    rjmp  FOUND_COL1
    in    r20, PINB
    sbrs  r20, COL2_BIT
    rjmp  FOUND_COL2

    lsl   r19                       
    inc   r18
    rjmp  SCAN_ROW_LOOP

FOUND_COL0:
    mov   r16, r18
    lsl   r16
    add   r16, r18                  
    rjmp  LOOKUP_KEY
FOUND_COL1:
    mov   r16, r18
    lsl   r16
    add   r16, r18
    inc   r16                       
    rjmp  LOOKUP_KEY
FOUND_COL2:
    mov   r16, r18
    lsl   r16
    add   r16, r18
    subi  r16, -2                   
    rjmp  LOOKUP_KEY

LOOKUP_KEY:
    in    r20, PORTD
    ori   r20, ROW_MASK
    out   PORTD, r20
    ldi   ZL, low(2 * KEYPAD_TABLE)
    ldi   ZH, high(2 * KEYPAD_TABLE)
    clr   r20
    add   ZL, r16
    adc   ZH, r20
    lpm   r16, Z                    
    pop   ZH                        
    pop   ZL
    pop   r20
    pop   r19
    pop   r18
    ret

SCAN_NO_KEY:
    in    r16, PORTD
    ori   r16, ROW_MASK
    out   PORTD, r16
    ldi   r16, NO_KEY
    pop   ZH
    pop   ZL
    pop   r20
    pop   r19
    pop   r18
    ret

WAIT_KEY_RELEASE:
    push  r16
RELEASE_LOOP:
    rcall KEYPAD_SCAN
    cpi   r16, NO_KEY
    brne  RELEASE_LOOP              
    rcall DELAY_20MS                
    pop   r16
    ret

DELAY_20MS:
    push  r16
    push  r17
    ldi   r16, 200                  
DELAY_OUTER:
    ldi   r17, 0                    
DELAY_INNER:
    nop
    dec   r17
    brne  DELAY_INNER
    dec   r16
    brne  DELAY_OUTER
    pop   r17
    pop   r16
    ret

USART_INIT:
    ldi   r16, high(UBRR_VAL)
    sts   UBRR0H, r16
    ldi   r16, low(UBRR_VAL)
    sts   UBRR0L, r16
    ldi   r16, (1 << TXEN0)
    sts   UCSR0B, r16
    ldi   r16, (1 << UCSZ01) | (1 << UCSZ00)
    sts   UCSR0C, r16
    ret

; --- NEW: Encryption Subroutine ---
USART_TRANSMIT_SECURE:
    push  r17
    ldi   r17, SECRET_KEY           ; Load the secret key
    eor   r16, r17                  ; Encrypt the character in r16
    rcall USART_TRANSMIT            ; Send the garbled byte over IR
    eor   r16, r17                  ; Restore r16 to its original value just in case
    pop   r17
    ret

USART_TRANSMIT:
    push  r17
USART_TX_WAIT:
    lds   r17, UCSR0A
    sbrs  r17, UDRE0                
    rjmp  USART_TX_WAIT
    sts   UDR0, r16                 
    pop   r17
    ret

USART_PRINT_STRING:
    push  r16
PRINT_LOOP:
    lpm   r16, Z+                   
    cpi   r16, 0                    
    breq  PRINT_DONE
    rcall USART_TRANSMIT_SECURE     ; Send string securely
    rjmp  PRINT_LOOP
PRINT_DONE:
    pop   r16
    ret

; --- Flash Memory Data ---
KEYPAD_TABLE:
    .db '1', '2', '3', '4', '5', '6', '7', '8', '9', 0x08, '0', 0x0A

MSG_READY:
    .db "LiFi Ready", 0, 0
