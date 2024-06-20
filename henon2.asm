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
    ld de, 3069h    ; X and Y positions
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

    ; Copy the bitmap to the frame buffer
    ld hl, bitmap
    ld de, 0C000h
    ld bc, 039C0h
    ldir

    ; Display the sprite
    ld de, variables
    ld ix, sprites
    ld iy, 0C260h
    call display_sprite

; ##########################################################################
; # MAIN LOOP
; ##########################################################################

loop:
    call animate_missiles
    call animate_boss_missiles
    call animate_missiles
    call animate_boss_missiles
    call animate_missiles
    call animate_boss_missiles
    call animate_missiles
    call animate_boss_missiles
    call joystick

    ld a, (variables+5)
    cp 0
    call nz, collide_with_playfield

    ld bc, 0FFFh    ; Delay value
    call DELAY      ; Wait

    call boss_shoot

    ld hl, 03800h   ; Check if the player pushed the trigger button
    ld a, (hl)
    cp $ff
    jp z, loop

    call player_shoot
    jp loop
; ##########################################################################

DispHL:
    ld de, score
	ld	bc,-100
	call	Num1
	ld	c,-10
	call	Num1
	ld	c,-1
Num1:	ld	a,'0'-1
Num2:	inc	a
	add	hl,bc
	jr	c,Num2
	sbc	hl,bc
    ld (de), a
    inc de
	ret 

player_shoot:
    ; missiles: missile Y position (0 if no missile)
    ; missiles+1: high screen ptr of the missile
    ; missiles+2: low screen ptr of the missile
    ; missiles+3: shape/mask of the missile 
    ld a, (missiles)    ; If a missile is already shot
    cp 0
    jp nz, shoot_end    ; Then skip
    ld a, 20            ; Sets the vertical position
    ld (missiles), a
    ld a, (ix-12)        ; Sets the shape of the missile
    ld (missiles+3), a
    push iy
    ld a, (ix-11)
    cp 0
    jp z, missile_no_shift
    ld bc,$401
    jp missile_set_pointer
missile_no_shift
    ld bc, $400
missile_set_pointer
    add iy, bc
    ld (missiles+1), iy
    pop iy
shoot_end:
    ret

boss_shoot:
    ; missiles+4: missile Y position (0 if no missile)
    ; missiles+5: high screen ptr of the missile
    ; missiles+6: low screen ptr of the missile
    ; missiles+7: shape/mask of the missile 
    ld a, (missiles+4)    ; If a missile is already shot
    cp 0
    jp nz,shoot_end    ; Then skip
    ld a, 141           ; Sets the vertical position
    ld (missiles+4),a
    ld a, $3C           ; Sets the missile shape/mask
    ld (missiles+7),a
    ld (missiles+5),iy  ; Sets the missile address. Use the ship address
    ld a,(missiles+5)   ; For the lower bytes,
    and $3F             ; Keep the lower 5 bits (horizontal line pos)
    inc a
    ld (missiles+5),a
    ld a,$e3            ; Sets the higher address to 0xE3__
    ld (missiles+6), a
    ret

animate_missiles:
    ld a, (missiles)        ; If there is already a missile shot
    cp 0
    jp z, animate_missiles_end  ; Then skip

    cp 230
    jp nz, move_missile_down
    ld a, 0                 ; Reset missile position
    ld (missiles), a
    ret
move_missile_down:
    ld a,(missiles+3)       ; Download the missile shape and mask
    ld e,a                  ; e=missile shape
    cpl
    ld d,a                  ; d=missile mask

    ld hl, missiles         ; Increment the line
    inc (hl)

    ld hl, (missiles+1)
    ld a, (hl)              ; Remove previous position
    and d
    ld (hl), a
    ld bc, $40              ; Move the missile pointer down one line
    add hl, bc

    ld a, (hl)              ; Check for any collision
    and e
    cp 0
    jp nz, missile_boom
    ld a, (hl)              ; If there is no collision, draw the missile
    or e
    ld (hl), a
    ld (missiles+1), hl
    ret
missile_boom:
    ld a, (hl)              ; Remove previous position
    and d
    ld (hl), a
    ld a, 0                 ; Reset missile position
    ld (missiles), a

    ld a, h
    cp $EB
    jp nz, animate_missiles_end
    ld a, l
    cp $20
    jp nz, animate_missiles_end
killed_boss:
    ld iy, $EA1C
    call draw_explosion

    ld a, 80
boss_dying:
    call move_boss_up
    call move_boss_down
    push af
    ld bc, 0FFFh    ; Valeur du delai
    call DELAY      ; Attente
    pop af
    dec a
    cp 75
    jp nz, boss_dying1
    ld iy, $EE10
    push af
    call draw_explosion
    pop af
    jp boss_dying
boss_dying1:
    cp 70
    jp nz, boss_dying2
    ld iy, $E828
    push af
    call draw_explosion
    pop af
    jp boss_dying
boss_dying2:
    cp 65
    jp nz, boss_dying3
    ld iy, $E415
    push af
    call draw_explosion
    pop af
    jp boss_dying
boss_dying3:
    cp 0
    jp nz, boss_dying

    ld hl, (lives)
    call DispHL
    ld de, 3089h    ; X and Y positions
    ld bc, game_won  ; Text
    call PUTSTR     ; Displays text on screen

happy_ending
    jp happy_ending
animate_missiles_end
    ret

animate_boss_missiles:
    ld a, (missiles+4)        ; If there no missile shot
    cp 0
    jp z, animate_missiles_end  ; Then skip

move_boss_missile_up:
    ld a,(missiles+7)       ; Download the missile shape and mask
    ld e,a                  ; e=missile shape
    cpl
    ld d,a                  ; d=missile mask

    ld hl, missiles+4       ; Decrement the line
    dec (hl)

    ld hl, (missiles+5)
    ld a, (hl)              ; Remove previous position
    and d
    ld (hl), a

    ld a, (missiles+4)      ; If the missile hit the top of the screen
    dec a
    cp 0
    jp z, boss_missile_reset    ; Then reset

    ld bc, $FFC0            ; Move the missile pointer up one line
    add hl, bc

    ld a, (hl)              ; Check for any collision
    and e
    cp 0
    jp nz, boss_missile_collision
    ld a, (hl)              ; If there is no collision, draw the missile
    or e
    ld (hl), a
    ld (missiles+5), hl
    ret
boss_missile_reset
    ld a, 0                 ; Reset missile position
    ld (missiles+4), a
    ret
boss_missile_collision:
    ld a, (variables+4)     ; If the high byte of the missile pointer
    cp h                    ; is different than the sprite lower pointer
    jp nz, boss_missile_hit_playfield ; high byte, we know it missed

    ld a, (variables+3)
    cp l
    jp nz, boss_missile_check_second_byte
    jp boss_missile_hit
boss_missile_check_second_byte:
    inc a
    cp l
    jp nz, boss_missile_check_second_byte
    jp boss_missile_hit
boss_missile_check_third_byte
    inc a
    cp l
    jp nz, boss_missile_hit_playfield
    jp boss_missile_hit
boss_missile_hit_playfield:
    ld a, (hl)              ; Remove previous position
    and d
    ld (hl), a
    ld a, 0                 ; Reset missile position
    ld (missiles+4), a
    ret

boss_missile_hit:
    push iy
    ld bc, $FDBC
    add iy, bc
    call draw_explosion
    pop iy
    ld a, (lives)
    inc a
    ld (lives), a

    ld bc, 0FFFFh    ; Delay
    call DELAY      ; Wait
    call reset_player

    jp boss_missile_hit_playfield

reset_player:
    ; Copy the bitmap to the frame buffer
    ld hl, bitmap
    ld de, 0C000h
    ld bc, 02000h
    ldir

    ld a, 9
    ld (variables), a
    ld a, 128
    ld (variables+1), a
    ld a, 0
    ld (variables+2), a
    ld (variables+5), a
    ld a, $10
    ld (variables+3), a
    ld a, $C6
    ld (variables+4), a

    ; Display the sprite
    ld de, variables
    ld ix, sprites
    ld iy, 0C260h
    call display_sprite
    ret

; ##############################################################################

move_boss_up:
    ld hl, 0E200h
    ld de, 0E1C0h
    ld bc, 01740h
    ldir
    ret

move_boss_down:
    push af
    ld hl, 0F940h
    ld de, 0F9C0h
move_boss_down_loop:
    ld bc, 00080h
    ldir

    dec h
    dec d

    ld a, h
    cp $E1
    jp nz, move_boss_down_loop
    ld a, l
    cp $C0
    jp nz, move_boss_down_loop
    pop af
    ret

draw_explosion:
    push ix
    push iy
    ld d, 10
    ld e, 34
    ld ix, explosion
draw_explosion_y:
    ld d, 10
draw_explosion_x:
    ld a, (ix+10)   ; Draws the mask
    and (iy)
    ld (iy), a
    ld a, (ix)      ; Draws the bitmap
    or (iy)
    ld (iy), a

    inc ix          ; Move to next byte
    inc iy
    dec d           ; col = col - 1
    ld a, d
    cp 0
    jp nz, draw_explosion_x
    ld bc, 54
    add iy, bc
    ld bc, 10
    add ix, bc
    dec e           ; row = row - 1
    ld a, e
    cp 0
    jp nz, draw_explosion_y

    pop iy
    pop ix
    ret

; ##############################################################################

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

move_down:
    ld a, (variables)   ; If we're too low, stop
    cp 110
    jp z, joystick_end

    call clear_sprite
    ld bc, 64
    add iy, bc              ; Move the pointer to the next line
    ld a, (variables)
    inc a
    ld (variables), a       ; Increase the line
    ld hl, (variables+3)    ; Increase the sprite bottom ptr
    ld bc, 64
    add hl, bc
    ld (variables+3), hl
    call display_sprite     ; Displays the sprite
    ld hl, 03808h
    ld (hl), 0
    jp joystick_end

move_up:
    ld a, (variables)      ; a = Y
    cp 9
    jp z, joystick_end

    call clear_sprite

    ld bc, 0FFC0h
    add iy, bc
    ld a, (variables)
    dec a
    ld (variables), a       ; Decrease the line
    ld hl, (variables+3)    ; Decreases the sprite bottom ptr
    ld bc, $FFC0
    add hl, bc
    ld (variables+3), hl
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
    dec iy                  ; Moves the top sprite pointer left
    ld hl, (variables+3)    ; Moves sprite bottom ptr left
    ld bc, $FFFF
    add hl, bc
    ld (variables+3), hl
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
    jp z, joystick_end  ; if a == 230, stop

    call clear_sprite
    ld a, (variables+2)    ; a = pixel shift
    cp 3
    jp nz, pixel_shift_right  ; if pixel shift != 3
reset_pixel_shift_right:
    ld a, 0
    ld (variables+2), a     ; X pixel = 0
    ld ix, sprites
    inc iy                  ; Moves the top sprite pointer right
    ld hl, (variables+3)    ; Moves sprite bottom ptr right
    ld bc, 00001h
    add hl, bc
    ld (variables+3), hl
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
    ld a, 0
    ld (variables+5), a
sprite_loop:
    ; First byte
    ld a, (ix+12)   ; Load the mask
    cpl
    and (iy)        ; Compare with the screen
    cp 0            ; If there is nothing in common
    jp z, nocoll1   ; Then there is no collision
    ld a, $FF
    ld (variables+5), a
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
    ld a, $FF
    ld (variables+5), a
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
    ld (variables+5), a
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

collide_with_playfield:
    push iy
    ld bc, $FDBC
    add iy, bc
    call draw_explosion
    pop iy
    ld a, (lives)
    inc a
    ld (lives), a

    ld bc, 0FFFFh    ; Delay
    call DELAY      ; Wait
    call reset_player
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
    db "HENON - Part 2", 0
subtitle:
    db "\"Merde! C'est Quoi Ca?\"", 0
author:
    db "By the Bitmap Fils Unique", 0
author2:
    db "Copyleft Laurent Poulain 2024", 0
game_won:
    db "Vous avez gagne en "
score:
    db 0, 0, 0
    db " vies",0

variables:
    db 9        ; Sprite Y
    db 128      ; Sprite X
    db 0        ; Sprite X pixel shift
    db $10, $C6 ; Sprite bottom position
    db 0        ; Collision
lives:
    db 0, 0    ; Number of lives spent
missiles:
    ; Byte 0: position (0 if not fired)
    ; Byte 1-2: address on screen
    ; Byte 3: missile shape/mask
    db 0, 0, 0, 0, 0, 0, 0, 0

    ; Missile shape (depending of the sprite)
    db $F0,0,0,$0F,1,0,$3C,1,0,$F0,1,0
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
    db 66,129,0,8,5,2,32,20,8,128,80,32
    db 60,60,255,243,240,252,207,195,243,63,15,207
    db 114,141,0,200,53,2,32,215,8,128,92,35
    db 12,48,255,51,192,252,207,0,243,63,3,204
    db 98,137,0,136,37,2,32,150,8,128,88,34
    db 12,48,255,51,192,252,207,0,243,63,3,204

explosion:
    db 0,0,0,16,0,16,0,0,0,0
    db 255,255,255,207,255,207,255,255,255,255
    db 0,0,0,84,0,80,0,0,4,0
    db 255,255,255,3,255,15,255,255,243,255
    db 0,0,0,116,1,84,1,64,5,0
    db 255,255,255,3,252,3,252,63,240,255
    db 0,0,0,117,1,84,1,84,0,0
    db 255,255,255,0,252,3,252,3,255,255
    db 0,0,0,221,69,85,5,21,4,0
    db 255,255,255,0,48,0,240,192,243,255
    db 0,80,80,245,85,125,85,21,1,0
    db 255,15,15,0,0,0,0,192,252,255
    db 0,80,85,253,255,255,85,85,1,0
    db 255,15,0,0,0,0,0,0,252,255
    db 0,208,87,253,255,255,85,85,1,0
    db 255,15,0,0,0,0,0,0,252,255
    db 0,64,215,255,255,255,247,127,1,0
    db 255,63,0,0,0,0,0,0,252,255
    db 0,64,245,255,255,255,255,255,85,0
    db 255,63,0,0,0,0,0,0,0,255
    db 0,64,253,255,255,255,255,255,117,1
    db 255,63,0,0,0,0,0,0,0,252
    db 80,80,255,255,255,255,255,255,213,21
    db 15,15,0,0,0,0,0,0,0,192
    db 64,85,253,255,255,255,255,255,85,1
    db 63,0,0,0,0,0,0,0,0,252
    db 64,93,255,255,255,255,255,127,21,0
    db 63,0,0,0,0,0,0,0,192,255
    db 0,125,253,255,255,255,255,127,5,0
    db 255,0,0,0,0,0,0,0,240,255
    db 0,117,245,255,255,255,255,95,1,0
    db 255,0,0,0,0,0,0,0,252,255
    db 0,84,245,255,255,255,255,95,1,0
    db 255,3,0,0,0,0,0,0,252,255
    db 0,80,253,255,255,255,255,127,5,0
    db 255,15,0,0,0,0,0,0,240,255
    db 0,84,255,255,255,255,255,255,21,0
    db 255,3,0,0,0,0,0,0,192,255
    db 64,85,255,255,255,255,255,255,69,0
    db 63,0,0,0,0,0,0,0,48,255
    db 64,81,255,255,255,255,255,255,5,0
    db 63,12,0,0,0,0,0,0,240,255
    db 80,80,255,255,255,255,255,255,21,1
    db 15,15,0,0,0,0,0,0,192,252
    db 84,84,255,255,255,255,255,95,85,5
    db 3,3,0,0,0,0,0,0,0,240
    db 0,80,253,255,255,255,127,85,85,0
    db 255,15,0,0,0,0,0,0,0,255
    db 0,64,245,255,245,255,127,85,5,0
    db 255,63,0,0,0,0,0,0,240,255
    db 0,64,85,85,213,255,95,93,1,0
    db 255,63,0,0,0,0,0,0,252,255
    db 0,80,85,85,85,255,87,125,0,0
    db 255,15,0,0,0,0,0,0,255,255
    db 0,80,85,213,87,85,85,125,0,0
    db 255,15,0,0,0,0,0,0,255,255
    db 0,80,69,245,85,85,85,85,1,0
    db 255,15,48,0,0,0,0,0,252,255
    db 0,84,0,117,85,95,85,85,1,0
    db 255,3,255,0,0,0,0,0,252,255
    db 0,20,0,85,65,93,1,64,1,0
    db 255,195,255,0,60,0,252,63,252,255
    db 0,0,0,84,0,85,1,0,0,0
    db 255,255,255,3,255,0,252,255,255,255
    db 0,0,0,20,0,84,0,0,0,0
    db 255,255,255,195,255,3,255,255,255,255
    db 0,0,0,0,0,80,0,0,0,0
    db 255,255,255,255,255,15,255,255,255,255

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
include "rsc_henon2.asm"
ENDIF

;    org 0F9C1h
;bitmap_title:
;include "rsc_henon_title.asm"

    END
