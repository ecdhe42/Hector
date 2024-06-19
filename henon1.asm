RCHRAD  equ 5FE3h
SETSCR  equ 0D30h
CHRCOL  equ 062Eh
PUTC    equ 0C62h
DELAY   equ 07F6h
PUTSTR  equ 0D0Ch
CLS     equ 0D2Fh
SETCOLS equ 19E0h
COLORS  equ 0BD3h

IF K7
    org 4C00h
ELSE
    org 4200h
ENDIF
    ld sp, 0C000h

start:
    call CLS        ; Clears screen
    ld bc, 0FFFh    ; Delay
    call DELAY      ; Wait

; ##########################################################################
; # Splash screen
; ##########################################################################
    ld a, 0h
    call SETSCR     ; Screen color = 0 (black)
    ld c, 1h
    CALL CHRCOL     ; Text color = 1 (red)

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
;    ld (hl), 18h    ; color0 = 0 (black), color2 = 3 (yellow)
    ld (hl), 20h    ; color0 = 0 (black), color2 = 1 (red)
    ld hl, 01800h
    ld (hl), 39h    ; color1 = 4 (blue), color3 = 7 (white)

    ld de, 3859h    ; X and Y positions
    ld bc, title    ; Text
    call PUTSTR     ; Displays text on screen
    ld de, 1869h    ; X and Y positions
    ld bc, subtitle ; Text
    call PUTSTR     ; Displays text on screen
    ld c, 3h        ; 
    CALL CHRCOL     ; Text color = 3 (white)
    ld de, 289Ch    ; X and Y positions
    ld bc, author   ; Text
    call PUTSTR     ; Displays text on screen
    ld de, 18A9h    ; X and Y positions
    ld bc, author2  ; Text
    call PUTSTR     ; Displays text on screen

    ld hl, bitmap_title
    ld de, 0D000h
    ld bc, 00580h
    ldir

splash_loop:
    ld hl, 03800h
    ld a, (hl)
    cp $ff
    jp z, splash_loop
splash_end
    ld a, (hl)
    cp $ff
    jp nz, splash_end

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
;    ld (hl), 18h    ; color0 = 0 (black), color2 = 3 (yellow)
    ld (hl), 20h    ; color0 = 0 (black), color2 = 1 (red)
    ld hl, 01800h
    ld (hl), 39h    ; color1 = 4 (blue), color3 = 7 (white)

    ; Copy the bitmap to the frame buffer
    ld hl, bitmap
    ld de, 0C000h
    ld bc, 039C0h
    ldir

    ; Display the sprite
    ld de, variables
    ld ix, sprites
    ld iy, 0C220h
    call display_sprite

loop:
    call joystick
    call joystick

    ld hl, 03800h
    ld a, (hl)
    cp $ff
    jp z, loop

    call move_down_with_scroll
    call scroll
    jp loop

joystick:
    ld hl, 03807h
    ld a, (hl)
    cp $ff
    jp z, joystick_end
    bit 3, a
    jp z, move_down
    bit 2, a
    jp z, move_up
    bit 0, a
    jp z, move_left
    bit 1, a
    jp z, move_right
joystick_end:
    ret

move_down_with_scroll:
    call clear_sprite

    ld bc, 64
    add iy, bc      ; Move the pointer to the next line
    call display_sprite
    ld hl, 03808h
    ld (hl), 0
move_down_with_scroll_end:
    ret

move_down:
    ld a, (variables)   ; If we're too low, stop
    cp 200
    jp z, joystick_end

    call clear_sprite
    ld bc, 64
    add iy, bc      ; Move the pointer to the next line
    ld a, (variables)
    inc a
    ld (variables), a      ; Increase the line
    call display_sprite
    ld hl, 03808h
    ld (hl), 0
    jp joystick_end

move_up:
    ld a, (variables)      ; a = Y
    cp 0
    jp z, joystick_end

    call clear_sprite

    ld bc, 0FFC0h
    add iy, bc
    ld a, (variables)
    dec a
    ld (variables), a      ; Increase the line
    call display_sprite
    ld hl, 03808h
    ld (hl), 0
    jp joystick_end

move_left:
    ld a, (variables+1)    ; a = X
    cp 0
    jp z, joystick_end  ; if a == 0, stop

    call clear_sprite
    ld a, (variables+2)    ; a = pixel shift
    cp 0
    jp nz, pixel_shift_left  ; if pixel shift != 0
reset_pixel_shift_left:
    ld a, 3
    ld (variables+2), a
    ld ix, sprites+9
;    call clear_right_sprite
    dec iy
    jp move_left_x
pixel_shift_left:
    dec a
    ld (variables+2), a      ; X pixel--
    dec ix
    dec ix
    dec ix
move_left_x:
    ld a, (variables+1)
    dec a
    ld (variables+1), a      ; X--

    call display_sprite
    ld hl, 03808h
    ld (hl), 0
    jp joystick_end

move_right:
    ld a, (variables+1)    ; a = X
    cp 230
    jp z, joystick_end  ; if a == 240, stop

    call clear_sprite
    ld a, (variables+2)    ; a = pixel shift
    cp 3
    jp nz, pixel_shift_right  ; if pixel shift != 3
reset_pixel_shift_right:
    ld a, 0
    ld (variables+2), a     ; X pixel = 0
    ld ix, sprites
;    call clear_left_sprite
    inc iy
    jp move_right_x
pixel_shift_right:
    inc a
    ld (variables+2), a      ; X pixel++
    inc ix
    inc ix
    inc ix
move_right_x:
    ld a, (variables+1)
    inc a
    ld (variables+1), a      ; X++

    call display_sprite
    ld hl, 03808h
    ld (hl), 0
    jp joystick_end


clear_sprite:
    push iy
    push ix
    ld bc, 64
    ld d, 16
clear_sprite_loop:
    ld a, (ix+12)
    and (iy)
    ld (iy), a

    ld a, (ix+13)
    and (iy+1)
    ld (iy+1), a

    ld a, (ix+14)
    and (iy+2)
    ld (iy+2), a

    ld bc, 64
    add iy, bc
    ld bc, 24
    add ix, bc
    dec d
    ld a, d
    cp 0
    jp nz, clear_sprite_loop
    pop ix
    pop iy
    ret


display_sprite:
    push iy
    push ix
    ld bc, 64
    ld d, 16
    ld hl, $F900
    ld a, 0
    ld (hl), a
sprite_loop:
    ; First byte
    ld a, (ix+12)   ; Load the mask
    cpl
    and (iy)        ; Compare with the screen
    cp 0            ; If there is nothing in common
    jp z, nocoll1   ; Then there is no collision
    ld e, $FF
    ld (hl), e
nocoll1
    ld a, (ix+12)   ; Load the mask
    and (iy)        ; Compare with the screen
    ld (iy), a      ; Draws the mask
    ld a, (ix)      ; Loads the bitmap
    or (iy)         ; Merges with the screen
    ld (iy), a      ; Draws the result

    ; Second byte
    ld a, (ix+13)
    cpl
    and (iy+1)
    cp 0
    jp z, nocoll2
    ld e, $FF
    ld (hl), e
nocoll2
    ld a, (ix+13)
    and (iy+1)
    ld (iy+1), a
    ld a, (ix+1)
    or (iy+1)
    ld (iy+1), a

    ; Third byte
    ld a, (ix+14)
    cpl
    and (iy+2)
    cp 0
    jp z, nocoll3
    ld a, $FF
    ld (hl), a
nocoll3
    ld a, (ix+14)
    and (iy+2)
    ld a, (ix+14)
    and (iy+2)
    ld (iy+2), a
    ld a, (ix+2)
    or (iy+2)
    ld (iy+2), a

    ld bc, 64
    add iy, bc
    ld bc, 24
    add ix, bc
    dec d
    ld a, d
    cp 0
    jp nz, sprite_loop

    pop ix
    pop iy
    ret

scroll:
    ld hl, 0C000h
    ld de, buffer
    ld bc, 00040h
    ldir

    ld hl, 0C040h
    ld de, 0C000h
    ld bc, 03980h
    ldir

    ld hl, buffer
    ld de, 0F940h
    ld bc, 00040h
    ldir

    ld bc, 0FFC0h
    add iy, bc
    ret

title:
    db 20h, 20h, 20h
    db "HENON - Part 1", 0
subtitle:
    db "\"Cherie, je descend a la cave!\"", 0
author:
    db "By the Bitmap Fils Unique", 0
author2
    db "Copyleft Laurent Poulain 2024", 0

variables:
    db 8        ; Sprite Y
    db 128      ; Sprite X
    db 0        ; Sprite X pixel shift

sprites:
    ; Sprites (pre-shifted)
    db 128,2,0,0,10,0,0,40,0,0,160,0
    db 63,252,255,255,240,255,255,195,255,255,15,255
    db 128,2,0,0,10,0,0,40,0,0,160,0
    db 63,252,255,255,240,255,255,195,255,255,15,255
    db 160,10,0,128,42,0,0,170,0,0,168,2
    db 15,240,255,63,192,255,255,0,255,255,3,252
    db 160,10,0,128,42,0,0,170,0,0,168,2
    db 15,240,255,63,192,255,255,0,255,255,3,252
    db 160,10,0,128,42,0,0,170,0,0,168,2
    db 15,240,255,63,192,255,255,0,255,255,3,252
    db 168,42,0,160,170,0,128,170,2,0,170,10
    db 3,192,255,15,0,255,63,0,252,255,0,240
    db 168,42,0,160,170,0,128,170,2,0,170,10
    db 3,192,255,15,0,255,63,0,252,255,0,240
    db 184,46,0,224,186,0,128,235,2,0,174,11
    db 3,192,255,15,0,255,63,0,252,255,0,240
    db 186,174,0,232,186,2,160,235,10,128,174,43
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 186,174,0,232,186,2,160,235,10,128,174,43
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 186,174,0,232,186,2,160,235,10,128,174,43
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 170,170,0,168,170,2,160,170,10,128,170,42
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 170,170,0,168,170,2,160,170,10,128,170,42
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 21,84,0,84,80,1,80,65,5,64,5,21
    db 192,3,255,3,15,252,15,60,240,63,240,192
    db 20,20,0,80,80,0,64,65,1,0,5,5
    db 195,195,255,15,15,255,63,60,252,255,240,240
    db 4,16,0,16,64,0,64,0,1,0,1,4
    db 243,207,255,207,63,255,63,255,252,255,252,243

    db $40, $01, $0D, $07, $F0, $0F, $0C, $03
    db $29, $29, $AA, $AA, $A2, $92, $A2, $92
    db $A0, $0A, $50, $05, $54, $15, $14, $14
    db $14, $14, $14, $14, $14, $14, $15, $54

    db 3

buffer:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

bitmap_title:
include "rsc_henon_title.asm"

    org 06000h
bitmap:
IF K7 = 0
include "rsc_henon1.asm"
ENDIF
    END
