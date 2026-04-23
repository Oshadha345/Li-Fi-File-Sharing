; LiFi IR Receiver (38kHz Modulated with XOR Decryption)
.include "m328pdef.inc"

; --- System and UART Configuration ---
.equ F_CPU       = 16000000         ; 16 MHz external crystal
.equ BAUD        = 2400            
.equ UBRR_VAL    = (F_CPU / (16 * BAUD)) - 1

; --- I2C (TWI) Configuration ---
.equ TWI_FREQ    = 100000           ; Standard 100 kHz I2C speed
.equ TWBR_VAL    = ((F_CPU / TWI_FREQ) - 16) / 2 

; --- OLED SSD1306 Configuration & Encryption ---
.equ SECRET_KEY   = 0x5A            ; NEW: Must match the transmitter exactly!
.equ SSD1306_ADDR = 0x3C            ; Standard 7-bit I2C address
.equ SSD1306_CMD  = 0x00            ; Command byte prefix
.equ SSD1306_DATA = 0x40            ; Data byte prefix

.equ DISP_WIDTH   = 128
.equ DISP_HEIGHT  = 32
.equ MAX_CHARS    = 21              ; Max letters per line
.equ FONT_WIDTH   = 5
.equ CHAR_SPACING = 6               

; --- SRAM Memory Pointers ---
.equ MSG_BUF      = 0x0100          ; Start storing received text here
.equ MSG_BUF_END  = 0x0115          

.org 0x0000
    rjmp RESET                      

.org 0x0034
RESET:
    ; Initialize Stack Pointer
    ldi   r16, high(RAMEND)
    out   SPH, r16
    ldi   r16, low(RAMEND)
    out   SPL, r16

    clr   r2                        ; r2 tracks the current string length

    rcall TWI_INIT                  ; Start hardware I2C 
    rcall SSD1306_INIT              ; Initialize OLED
    rcall USART_INIT                ; Start listening on RX pin

    ; Print Startup Screen 
    rcall SSD1306_CLEAR
    ldi   ZL, low(2 * STR_WAITING)
    ldi   ZH, high(2 * STR_WAITING)
    rcall SSD1306_PRINT_FLASH_STRING

; --- Main Listening Loop ---
MAIN_LOOP:
    lds   r16, UCSR0A
    sbrs  r16, RXC0                 ; Wait for data from the VS1838B
    rjmp  MAIN_LOOP                 

    lds   r16, UDR0                 ; Grab the received encrypted byte

    ; --- NEW: DECRYPTION STAGE ---
    push  r17
    ldi   r17, SECRET_KEY           ; Load the secret key
    eor   r16, r17                  ; Un-garble it back into readable ASCII!
    pop   r17
    ; -----------------------------

    ; Check for Enter/Newline keys (from your Keypad '#' key)
    cpi   r16, 0x0A                 ; Line Feed (\n)
    breq  CLEAR_MSG
    cpi   r16, 0x0D                 ; Carriage Return (\r)
    breq  CLEAR_MSG

    ; Check for Backspace (from your Keypad '*' key)
    cpi   r16, 0x08                 ; Backspace
    breq  HANDLE_BACKSPACE

    ; Prevent SRAM Buffer Overflow
    mov   r17, r2                   
    cpi   r17, MAX_CHARS            
    brsh  MAIN_LOOP                 ; If screen is full, ignore new typing

    ; Save character to SRAM
    ldi   XL, low(MSG_BUF)          
    ldi   XH, high(MSG_BUF)
    add   XL, r2                    
    clr   r17
    adc   XH, r17
    st    X, r16                    
    inc   r2                        

    rcall DISPLAY_MESSAGE           ; Update the OLED screen
    rjmp  MAIN_LOOP

CLEAR_MSG:
    clr   r2                        ; Reset string length to 0
    rcall SSD1306_CLEAR
    rjmp  MAIN_LOOP

HANDLE_BACKSPACE:
    tst   r2                        ; Check if length is already 0
    breq  MAIN_LOOP                 ; Nothing to delete
    dec   r2                        ; Reduce length by 1
    rcall DISPLAY_MESSAGE           ; Redraw screen without the last letter
    rjmp  MAIN_LOOP

; --- OLED Drawing Subroutine ---
DISPLAY_MESSAGE:
    push  r16
    push  r17
    push  r18

    rcall SSD1306_CLEAR
    rcall SSD1306_SET_CURSOR_HOME   

    rcall TWI_START
    ldi   r16, (SSD1306_ADDR << 1) | 0 
    rcall TWI_WRITE
    ldi   r16, SSD1306_DATA             
    rcall TWI_WRITE

    clr   r18                       
DISP_CHAR_LOOP:
    cp    r18, r2                   
    brge  DISP_CHAR_DONE

    ldi   XL, low(MSG_BUF)
    ldi   XH, high(MSG_BUF)
    add   XL, r18
    clr   r17
    adc   XH, r17
    ld    r16, X                    

    rcall SSD1306_SEND_CHAR_GLYPH   

    inc   r18
    rjmp  DISP_CHAR_LOOP

DISP_CHAR_DONE:
    rcall TWI_STOP                  
    pop   r18
    pop   r17
    pop   r16
    ret

; --- Font Calculation Engine ---
SSD1306_SEND_CHAR_GLYPH:
    push  r0
    push  r1
    push  r16
    push  r17
    push  r18
    push  ZL
    push  ZH

    cpi   r16, 32
    brlo  GLYPH_DEFAULT
    cpi   r16, 127
    brlo  GLYPH_OK
GLYPH_DEFAULT:
    ldi   r16, 32                   
GLYPH_OK:
    subi  r16, 32                   

    ldi   ZL, low(2 * FONT_5x7)
    ldi   ZH, high(2 * FONT_5x7)

    ldi   r17, 6
    mul   r16, r17                  

    add   ZL, r0
    adc   ZH, r1

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

; --- Hardware Setup ---
USART_INIT:
    ldi   r16, high(UBRR_VAL)
    sts   UBRR0H, r16
    ldi   r16, low(UBRR_VAL)
    sts   UBRR0L, r16
    ldi   r16, (1 << RXEN0)         
    sts   UCSR0B, r16
    ldi   r16, (1 << UCSZ01) | (1 << UCSZ00) 
    sts   UCSR0C, r16
    ret

TWI_INIT:
    ldi   r16, TWBR_VAL             
    sts   TWBR, r16
    ldi   r16, 0x00                 
    sts   TWSR, r16
    ret

; --- I2C Low Level Drivers ---
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

TWI_WRITE:
    sts   TWDR, r16                 
    ldi   r16, (1 << TWINT) | (1 << TWEN)
    sts   TWCR, r16                 
TWI_WRITE_WAIT:
    lds   r16, TWCR
    sbrs  r16, TWINT                
    rjmp  TWI_WRITE_WAIT
    ret

; --- OLED Low Level Drivers ---
SSD1306_CMD_SEND:
    push  r16
    rcall TWI_START
    ldi   r16, (SSD1306_ADDR << 1) | 0
    rcall TWI_WRITE
    ldi   r16, SSD1306_CMD
    rcall TWI_WRITE
    pop   r16
    rcall TWI_WRITE
    rcall TWI_STOP
    ret

SSD1306_INIT:
    ldi   r16, 0xAE
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xD5
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x80
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA8
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x1F
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xD3
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x40
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x8D
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x14
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x20
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA1
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xC8
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xDA
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x02
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x81
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x8F
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xD9
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xF1
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xDB
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x40
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA4
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xA6
    rcall SSD1306_CMD_SEND
    ldi   r16, 0xAF
    rcall SSD1306_CMD_SEND
    ret

SSD1306_CLEAR:
    push  r16
    push  r17
    push  r18

    ldi   r16, 0x21
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x7F
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x22
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x03
    rcall SSD1306_CMD_SEND

    rcall TWI_START
    ldi   r16, (SSD1306_ADDR << 1) | 0
    rcall TWI_WRITE
    ldi   r16, SSD1306_DATA
    rcall TWI_WRITE

    ldi   r18, 2
CLEAR_OUTER:
    ldi   r17, 0
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

SSD1306_SET_CURSOR_HOME:
    ldi   r16, 0x21
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x00
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x7F
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x22
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x01
    rcall SSD1306_CMD_SEND
    ldi   r16, 0x03
    rcall SSD1306_CMD_SEND
    ret

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

; --- Flash Memory Data ---
STR_WAITING:
    .db "Waiting...", 0, 0

FONT_5x7:
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Space
.db 0x00, 0x00, 0x5F, 0x00, 0x00, 0x00 ; !
.db 0x00, 0x07, 0x00, 0x07, 0x00, 0x00 ; "
.db 0x14, 0x7F, 0x14, 0x7F, 0x14, 0x00 ; #
.db 0x24, 0x2A, 0x7F, 0x2A, 0x12, 0x00 ; $
.db 0x23, 0x13, 0x08, 0x64, 0x62, 0x00 ; %
.db 0x36, 0x49, 0x55, 0x22, 0x50, 0x00 ; &
.db 0x00, 0x05, 0x03, 0x00, 0x00, 0x00 ; '
.db 0x00, 0x1C, 0x22, 0x41, 0x00, 0x00 ; (
.db 0x00, 0x41, 0x22, 0x1C, 0x00, 0x00 ; )
.db 0x08, 0x2A, 0x1C, 0x2A, 0x08, 0x00 ; *
.db 0x08, 0x08, 0x3E, 0x08, 0x08, 0x00 ; +
.db 0x00, 0x50, 0x30, 0x00, 0x00, 0x00 ; ,
.db 0x08, 0x08, 0x08, 0x08, 0x08, 0x00 ; -
.db 0x00, 0x60, 0x60, 0x00, 0x00, 0x00 ; .
.db 0x20, 0x10, 0x08, 0x04, 0x02, 0x00 ; /
.db 0x3E, 0x51, 0x49, 0x45, 0x3E, 0x00 ; 0
.db 0x00, 0x42, 0x7F, 0x40, 0x00, 0x00 ; 1
.db 0x42, 0x61, 0x51, 0x49, 0x46, 0x00 ; 2
.db 0x21, 0x41, 0x45, 0x4B, 0x31, 0x00 ; 3
.db 0x18, 0x14, 0x12, 0x7F, 0x10, 0x00 ; 4
.db 0x27, 0x45, 0x45, 0x45, 0x39, 0x00 ; 5
.db 0x3C, 0x4A, 0x49, 0x49, 0x30, 0x00 ; 6
.db 0x01, 0x71, 0x09, 0x05, 0x03, 0x00 ; 7
.db 0x36, 0x49, 0x49, 0x49, 0x36, 0x00 ; 8
.db 0x06, 0x49, 0x49, 0x29, 0x1E, 0x00 ; 9
.db 0x00, 0x36, 0x36, 0x00, 0x00, 0x00 ; :
.db 0x00, 0x56, 0x36, 0x00, 0x00, 0x00 ; ;
.db 0x00, 0x08, 0x14, 0x22, 0x41, 0x00 ; <
.db 0x14, 0x14, 0x14, 0x14, 0x14, 0x00 ; =
.db 0x41, 0x22, 0x14, 0x08, 0x00, 0x00 ; >
.db 0x02, 0x01, 0x51, 0x09, 0x06, 0x00 ; ?
.db 0x32, 0x49, 0x79, 0x41, 0x3E, 0x00 ; @
.db 0x7E, 0x11, 0x11, 0x11, 0x7E, 0x00 ; A
.db 0x7F, 0x49, 0x49, 0x49, 0x36, 0x00 ; B
.db 0x3E, 0x41, 0x41, 0x41, 0x22, 0x00 ; C
.db 0x7F, 0x41, 0x41, 0x22, 0x1C, 0x00 ; D
.db 0x7F, 0x49, 0x49, 0x49, 0x41, 0x00 ; E
.db 0x7F, 0x09, 0x09, 0x01, 0x01, 0x00 ; F
.db 0x3E, 0x41, 0x41, 0x51, 0x32, 0x00 ; G
.db 0x7F, 0x08, 0x08, 0x08, 0x7F, 0x00 ; H
.db 0x00, 0x41, 0x7F, 0x41, 0x00, 0x00 ; I
.db 0x20, 0x40, 0x41, 0x3F, 0x01, 0x00 ; J
.db 0x7F, 0x08, 0x14, 0x22, 0x41, 0x00 ; K
.db 0x7F, 0x40, 0x40, 0x40, 0x40, 0x00 ; L
.db 0x7F, 0x02, 0x04, 0x02, 0x7F, 0x00 ; M
.db 0x7F, 0x04, 0x08, 0x10, 0x7F, 0x00 ; N
.db 0x3E, 0x41, 0x41, 0x41, 0x3E, 0x00 ; O
.db 0x7F, 0x09, 0x09, 0x09, 0x06, 0x00 ; P
.db 0x3E, 0x41, 0x51, 0x21, 0x5E, 0x00 ; Q
.db 0x7F, 0x09, 0x19, 0x29, 0x46, 0x00 ; R
.db 0x46, 0x49, 0x49, 0x49, 0x31, 0x00 ; S
.db 0x01, 0x01, 0x7F, 0x01, 0x01, 0x00 ; T
.db 0x3F, 0x40, 0x40, 0x40, 0x3F, 0x00 ; U
.db 0x1F, 0x20, 0x40, 0x20, 0x1F, 0x00 ; V
.db 0x3F, 0x40, 0x38, 0x40, 0x3F, 0x00 ; W
.db 0x63, 0x14, 0x08, 0x14, 0x63, 0x00 ; X
.db 0x07, 0x08, 0x70, 0x08, 0x07, 0x00 ; Y
.db 0x61, 0x51, 0x49, 0x45, 0x43, 0x00 ; Z
.db 0x00, 0x7F, 0x41, 0x41, 0x00, 0x00 ; [
.db 0x02, 0x04, 0x08, 0x10, 0x20, 0x00 ; \
.db 0x00, 0x41, 0x41, 0x7F, 0x00, 0x00 ; ]
.db 0x04, 0x02, 0x01, 0x02, 0x04, 0x00 ; ^
.db 0x40, 0x40, 0x40, 0x40, 0x40, 0x00 ; _
.db 0x00, 0x01, 0x02, 0x04, 0x00, 0x00 ; `
.db 0x20, 0x54, 0x54, 0x54, 0x78, 0x00 ; a
.db 0x7F, 0x48, 0x44, 0x44, 0x38, 0x00 ; b
.db 0x38, 0x44, 0x44, 0x44, 0x20, 0x00 ; c
.db 0x38, 0x44, 0x44, 0x48, 0x7F, 0x00 ; d
.db 0x38, 0x54, 0x54, 0x54, 0x18, 0x00 ; e
.db 0x08, 0x7E, 0x09, 0x01, 0x02, 0x00 ; f
.db 0x08, 0x14, 0x54, 0x54, 0x3C, 0x00 ; g
.db 0x7F, 0x08, 0x04, 0x04, 0x78, 0x00 ; h
.db 0x00, 0x44, 0x7D, 0x40, 0x00, 0x00 ; i
.db 0x20, 0x40, 0x44, 0x3D, 0x00, 0x00 ; j
.db 0x00, 0x7F, 0x10, 0x28, 0x44, 0x00 ; k
.db 0x00, 0x41, 0x7F, 0x40, 0x00, 0x00 ; l
.db 0x7C, 0x04, 0x18, 0x04, 0x78, 0x00 ; m
.db 0x7C, 0x08, 0x04, 0x04, 0x78, 0x00 ; n
.db 0x38, 0x44, 0x44, 0x44, 0x38, 0x00 ; o
.db 0x7C, 0x14, 0x14, 0x14, 0x08, 0x00 ; p
.db 0x08, 0x14, 0x14, 0x18, 0x7C, 0x00 ; q
.db 0x7C, 0x08, 0x04, 0x04, 0x08, 0x00 ; r
.db 0x48, 0x54, 0x54, 0x54, 0x20, 0x00 ; s
.db 0x04, 0x3F, 0x44, 0x40, 0x20, 0x00 ; t
.db 0x3C, 0x40, 0x40, 0x20, 0x7C, 0x00 ; u
.db 0x1C, 0x20, 0x40, 0x20, 0x1C, 0x00 ; v
.db 0x3C, 0x40, 0x30, 0x40, 0x3C, 0x00 ; w
.db 0x44, 0x28, 0x10, 0x28, 0x44, 0x00 ; x
.db 0x0C, 0x50, 0x50, 0x50, 0x3C, 0x00 ; y
.db 0x44, 0x64, 0x54, 0x4C, 0x44, 0x00 ; z
.db 0x00, 0x08, 0x36, 0x41, 0x00, 0x00 ; {
.db 0x00, 0x00, 0x7F, 0x00, 0x00, 0x00 ; |
.db 0x00, 0x41, 0x36, 0x08, 0x00, 0x00 ; }
.db 0x08, 0x04, 0x08, 0x10, 0x08, 0x00 ; ~
