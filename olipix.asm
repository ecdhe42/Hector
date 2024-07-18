RCHRAD  equ 5FE3h
SETSCR  equ 0D30h
CHRCOL  equ 062Eh
PUTC    equ 0C62h
DELAY   equ 07F6h
PUTSTR  equ 0D0Ch
CLS     equ 0D2Fh
SETCOLS equ 19E0h
COLORS  equ 0BD3h
BITMAP  equ 6000h

    org 4200h
    ld sp, 0C000h

debut:
    call CLS        ; Clear screen
    ld bc, 0FFFh    ; Delay value
    call DELAY      ; Call the delay function in ROM

    ; Set color palette
    ; 0=black
    ; 1=red
    ; 2=green
    ; 3=yellow
    ; 4=blue
    ; 5=magenta
    ; 6=cyan
    ; 7=white
    ; <half-tone first color><half-tone second color><second color><first color>
    ld hl, 01000h
    ld (hl), 18h    ; color0 = 0, color2 = 3
    ld hl, 01800h
    ld (hl), 3Ch    ; color1 = 4, color3 = 7

    ; Copy the bitmap to the frame buffer
    ld hl, BITMAP
    ld de, 0C000h
    ld bc, 039C0h
    ldir

; This is far from being the most efficient method, but it is the fastest to write
; Possible improvements:
; - Instead of using a temp buffer, copy it straight from the original image in BITMAP
; - Instead of using LDIR (which consumes 21 cycles/byte) use LDI (16 cycles/byte) or
;   POP/PUSH
scroll:
    ; Copy the top line to a temp buffer
    ld hl, 0C000h
    ld de, buffer
    ld bc, 00080h
    ldir

    ; Move the whole screen up one line
    ld hl, 0C080h
    ld de, 0C000h
    ld bc, 03940h
    ldir

    ; Copy the line stored in the temp buffer at the bottom of the screen
    ld hl, buffer
    ld de, 0F940h
    ld bc, 00080h
    ldir

    jp scroll

buffer:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

    org 06000h
include "rsc_olipix.asm"

    END
