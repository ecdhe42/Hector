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

    ; Create the start screen
    call display_screen

    ; Display the sprite
    ld ix, sprites
    ld iy, 0C220h
    call display_sprite

; ##########################################################################
; # MAIN LOOP
; ##########################################################################

loop:
    call animate_missiles
    call animate_enemy_missiles
    call animate_missiles
    call animate_enemy_missiles
    call animate_missiles
    call animate_enemy_missiles
    call joystick
    call animate_missiles
    call animate_enemy_missiles
    call animate_missiles
    call animate_enemy_missiles
    call animate_missiles
    call animate_enemy_missiles
    call joystick

    call move_down_with_scroll
    call scroll

    ld a, (player_col)
    cp 0
    call nz, collide_with_playfield

    call enemy_shoot

    ld hl, 03800h   ; Check if the player pushed the trigger button
    ld a, (hl)
    cp $ff
    jp z, loop

    call player_shoot

    jp loop

; ##########################################################################

player_shoot:
    ; missiles: missile Y position (0 if no missile)
    ; missiles+1: high screen ptr of the missile
    ; missiles+2: low screen ptr of the missile
    ; missiles+3: shape/mask of the missile 
    ld a, (missiles)    ; If a missile is already shot
    cp 0
    jp nz, shoot_end    ; Then skip
    ld a, (player_y)    ; Sets the vertical position
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
;    call check_missile_enemy_collision
    ld a, (hl)              ; Remove previous position
    and d
    ld (hl), a
;    ld a, 1
;    ld (player_missile_col), a
    ld a, 0                 ; Reset missile position
    ld (missiles), a
animate_missiles_end:
    ret

enemy_shoot:
    ; missiles+4: missile Y position (0 if no missile)
    ; missiles+5: high screen ptr of the missile
    ; missiles+6: low screen ptr of the missile
    ; missiles+7: shape/mask of the missile 
    ld a, (missiles+4)    ; If a missile is already shot
    cp 0
    jp nz,shoot_end    ; Then skip
    ld a, 240           ; Sets the vertical position
    ld (missiles+4),a
    ld a, $3C           ; Sets the missile shape/mask
    ld (missiles+7),a
    ld (missiles+5),iy  ; Sets the missile address. Use the ship address
    ld a,(missiles+5)   ; For the lower bytes,
    and $3F             ; Keep the lower 5 bits (horizontal line pos)
    inc a
    ld (missiles+5),a
    ld a,$fc            ; Sets the higher address to 0xFC__
    ld (missiles+6), a
    ret

animate_enemy_missiles:
    ld a, (missiles+4)        ; If there no missile shot
    cp 0
    jp z, animate_missiles_end  ; Then skip

move_enemy_missile_up:
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
    jp z, enemy_missile_reset    ; Then reset

    ld bc, $FFC0            ; Move the missile pointer up one line
    add hl, bc

    ld a, (hl)              ; Check for any collision
    and e
    cp 0
    jp nz, enemy_missile_collision
    ld a, (hl)              ; If there is no collision, draw the missile
    or e
    ld (hl), a
    ld (missiles+5), hl
    ret
enemy_missile_reset
    ld a, 0                 ; Reset missile position
    ld (missiles+4), a
    ret
enemy_missile_collision:
    push hl
    call clear_sprite
    pop hl
    ld a, (hl)              ; If there is no collision, draw the missile
    or e
    ld (hl), a
    call display_sprite
    
    ld a, (player_bot+1)     ; If the high byte of the missile pointer
    cp h                    ; is different than the sprite lower pointer
    jp nz, enemy_missile_hit_playfield ; high byte, we know it missed

    ld a, (player_bot)
    cp l
    jp nz, enemy_missile_check_second_byte
    jp enemy_missile_hit
enemy_missile_check_second_byte:
    inc a
    cp l
    jp nz, enemy_missile_check_second_byte
    jp enemy_missile_hit
enemy_missile_check_third_byte
    inc a
    cp l
    jp nz, enemy_missile_hit_playfield
    jp enemy_missile_hit
enemy_missile_hit_playfield:
    ld a, (hl)              ; Remove previous position
    and d
    ld (hl), a
    ld a, 0                 ; Reset missile position
    ld (missiles+4), a
    ret

enemy_missile_hit:
    call collide_with_playfield
    ret
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
;    call reset_player

    jp enemy_missile_hit_playfield

; ##########################################################################

joystick:
    ld hl, 03807h
    ld a, (hl)
    cp $ff
    jp z, joystick_end
    push af
    bit 3, a
    jp z, move_down
    bit 2, a
    jp z, move_up
check_left_right:
    pop af
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

update_enemy_ship_coords:
    ld a, (enemy_ships+1)
    cp 0
    jp z, move_missile_down_with_scroll
;    push hl
    ld hl, (enemy_ships)
    ld bc, $FFC0
    add hl, bc      ; Move the pointer to the next line
    ld (enemy_ships), hl
    ld a, (enemy_ships+4)
    dec a
    ld (enemy_ships+4), a
;    pop iy

move_missile_down_with_scroll:
    ld a, (missiles)    ; Move the missile Y pos ine line up
    cp 0
    jp z, move_enemy_missiles_up
    dec a
    ld (missiles), a

    ld hl, (missiles+1) ; Move the missile pointer one line up
    ld bc, $ffc0
    add hl, bc
    ld (missiles+1), hl

move_enemy_missiles_up
    ld a, (missiles+4)
    cp 0
    jp z, move_down_end
    dec a
    ld (missiles+4), a

    ld hl, (missiles+5) ; Move the missile pointer one line down
    ld bc, $ffc0
    add hl, bc
    ld (missiles+5), hl

move_down_end
    ret

move_down:
    ld a, (player_y)   ; If we're too low, stop
    cp 200
    jp z, check_left_right

    call clear_sprite
    ld bc, 64
    add iy, bc      ; Move the pointer to the next line
    ld a, (player_y)
    inc a
    ld (player_y), a      ; Increase the line
    call display_sprite
    ld hl, 03808h
    ld (hl), 0
    jp check_left_right

move_up:
    ld a, (player_y)      ; a = Y
    cp 0
    jp z, check_left_right

    call clear_sprite

    ld bc, 0FFC0h
    add iy, bc
    ld a, (player_y)
    dec a
    ld (player_y), a      ; Increase the line
    call display_sprite
    ld hl, 03808h
    ld (hl), 0
    jp check_left_right

move_left:
    ld a, (player_x)    ; a = X
    cp 0
    jp z, joystick_end  ; if a == 0, stop

    call clear_sprite
    ld a, (player_ps)    ; a = pixel shift
    cp 0
    jp nz, pixel_shift_left  ; if pixel shift != 0
reset_pixel_shift_left:
    ld a, 3
    ld (player_ps), a
    ld ix, sprites+9
;    call clear_right_sprite
    dec iy
    jp move_left_x
pixel_shift_left:
    dec a
    ld (player_ps), a      ; X pixel--
    dec ix
    dec ix
    dec ix
move_left_x:
    ld a, (player_x)
    dec a
    ld (player_x), a      ; X--

    call display_sprite
    ld hl, 03808h
    ld (hl), 0
    jp joystick_end

move_right:
    ld a, (player_x)    ; a = X
    cp 230
    jp z, joystick_end  ; if a == 240, stop

    call clear_sprite
    ld a, (player_ps)    ; a = pixel shift
    cp 3
    jp nz, pixel_shift_right  ; if pixel shift != 3
reset_pixel_shift_right:
    ld a, 0
    ld (player_ps), a     ; X pixel = 0
    ld ix, sprites
;    call clear_left_sprite
    inc iy
    jp move_right_x
pixel_shift_right:
    inc a
    ld (player_ps), a      ; X pixel++
    inc ix
    inc ix
    inc ix
move_right_x:
    ld a, (player_x)
    inc a
    ld (player_x), a      ; X++

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
sprite_loop:
    ; First byte
    ld a, (ix+12)   ; Load the mask
    cpl
    and (iy)        ; Compare with the screen
    cp 0            ; If there is nothing in common
    jp z, nocoll1   ; Then there is no collision
    ld a, $FF
    ld (player_col), a
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
    ld (player_col), a
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
    ld (player_col), a
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

erase_explosion:
    push ix
    push iy
    ld d, 10
    ld e, 34
    ld ix, explosion
erase_explosion_y:
    ld d, 10
erase_explosion_x:
    ld a, (ix+10)   ; Draws the mask
    and (iy)
    ld (iy), a

    inc ix          ; Move to next byte
    inc iy
    dec d           ; col = col - 1
    ld a, d
    cp 0
    jp nz, erase_explosion_x
    ld bc, 54
    add iy, bc
    ld bc, 10
    add ix, bc
    dec e           ; row = row - 1
    ld a, e
    cp 0
    jp nz, erase_explosion_y

    pop iy
    pop ix
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

collide_with_playfield:
    ld a,(missiles+4)        ; If there is an enemy missile, delete it
    cp 0
    jp z, no_delete_missile
 delete_missile
    ld a,(missiles+7)       ; Download the missile shape and mask
    ld e,a                  ; e=missile shape
    cpl
    ld d,a                  ; d=missile mask

    ld hl, (missiles+5)
    ld a, (hl)              ; Remove previous position
    and d
    ld (hl), a
    ld a, 0                 ; Reset missile position
    ld (missiles+4), a
no_delete_missile
    ld a, #0
    ld (player_col), a
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

    push iy
    ld bc, $FDBC
    add iy, bc
    call erase_explosion
    pop iy
    ret

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

game_over:
    ld hl, (lives)
    call DispHL
    ld de, 3089h    ; X and Y positions
    ld bc, game_won  ; Text
    call PUTSTR     ; Displays text on screen
happy_ending
    jp happy_ending

display_screen:
    ld a, 15
    ld de, 0C000h
display_screen_loop:
    push af
    call display_new_row
    pop af
    dec a
    cp 0
    jp nz, display_screen_loop

    ld a, (tilemap_idx)
    dec a
    ld (tilemap_idx), a

    ret

display_new_row:
    ld b, 0
    ld a, (tilemap_idx)     ; c = tilemap_idx
    ld c, a
    ld hl, tilemap
    add hl, bc              ; hl = &tilemap + tilemap_idx
    ld a, (hl)              ; a = tilemap[tilemap_idx]
    sla a
    sla a                   ; a *= 4
    add a,0x60
    ld h, a
    ld l, 0                 ; hl = 0x6000 + 0x400*tilemap[tilemap_idx]
    ld bc, 00400h
    ldir

    ld a, (tilemap_idx)
    inc a
    ld (tilemap_idx), a
    ret

scroll:
    ld hl, 0C040h       ; Move the whole screen up one line
    ld de, 0C000h
    ld a, 230
scroll_line:
REPT 64
    ldi
ENDM
    dec a
    cp 0
    jp nz, scroll_line

    ld hl, (tile_ptr)   ; Copy the new line at the end of the screen
    ld de, 0F980h
    ld bc, 00040h
    ldir
    ld (tile_ptr), hl   ; Save the tile pointer back to memory

    ld a, (tile_offset) ; Decrements the tile offset
    dec a
    ld (tile_offset), a
    cp 0
    jp nz, scroll_end   ; If offset > 0, keep going. Otherwise, get next tile
    ld a, 15            ; Resets the tile offset to 15
    ld (tile_offset), a
    ld a, (tilemap_idx) ; Increments the tile index
    inc a
    ld (tilemap_idx), a
    ld b, 0             ; 
    ld c, a             ; bc = tilemap_idx
    ld hl, tilemap      ; hl = &tilemap
    add hl, bc          ; hl = &tilemap + tilemap_idx
    ld a, (hl)              ; a = tilemap[tilemap_idx]
    cp $ff
    jp nz, no_tile_reset    ; If tile == $ff, reset tilemap_idx to 0
    jp game_over
    ld a, 0
    ld (tilemap_idx), a
    ld b, 0             ; 
    ld c, a             ; bc = tilemap_idx
    ld hl, tilemap      ; hl = &tilemap
    add hl, bc          ; hl = &tilemap + tilemap_idx
    ld a, (hl)          ; a = tilemap[tilemap_idx]
no_tile_reset:
    sla a
    sla a                   ; a *= 4
    add a,0x60
    ld h, a
    ld l, 0                 ; hl = 0x6000 + 0x400*tilemap[tilemap_idx]
    ld (tile_ptr), hl
scroll_end:
    ld bc, 0FFC0h       ; Move the sprite down
    add iy, bc          ; One line
    ret

title:
    db 20h, 20h, 20h
    db "HENON - Part 1", 0
subtitle:
    db "\"Cherie, je descends a la cave!\"", 0
author:
    db "By the Bitmap Fils Unique", 0
author2
    db "Copyleft Laurent Poulain 2024", 0
game_won:
    db "Vous avez gagne en "
score:
    db 0, 0, 0
    db " vies.",0

player_y    db 8        ; Sprite Y
player_x    db 128      ; Sprite X
player_ps   db 0        ; Sprite X pixel shift
player_bot  db $10, $C6 ; Sprite bottom position
player_col  db 0        ; Collision
player_missile_col  db 0    ; Collision missile
enemy_col   db 0        ; Enemy collision

enemy_ships db 0, 0, 0, 0, 0, 0, 0, 0

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

enemy_sprites:
    ; Sprites (pre-shifted)
    db 64,1,0,0,5,0,0,20,0,0,80,0
    db 63,252,255,255,240,255,255,195,255,255,15,255
    db 64,1,0,0,5,0,0,20,0,0,80,0
    db 63,252,255,255,240,255,255,195,255,255,15,255
    db 80,5,0,64,21,0,0,85,0,0,84,1
    db 15,240,255,63,192,255,255,0,255,255,3,252
    db 80,5,0,64,21,0,0,85,0,0,84,1
    db 15,240,255,63,192,255,255,0,255,255,3,252
    db 80,5,0,64,21,0,0,85,0,0,84,1
    db 15,240,255,63,192,255,255,0,255,255,3,252
    db 84,21,0,80,85,0,64,85,1,0,85,5
    db 3,192,255,15,0,255,63,0,252,255,0,240
    db 84,21,0,80,85,0,64,85,1,0,85,5
    db 3,192,255,15,0,255,63,0,252,255,0,240
    db 116,29,0,208,117,0,64,215,1,0,93,7
    db 3,192,255,15,0,255,63,0,252,255,0,240
    db 117,93,0,212,117,1,80,215,5,64,93,23
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 117,93,0,212,117,1,80,215,5,64,93,23
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 117,93,0,212,117,1,80,215,5,64,93,23
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 85,85,0,84,85,1,80,85,5,64,85,21
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 85,85,0,84,85,1,80,85,5,64,85,21
    db 0,0,255,3,0,252,15,0,240,63,0,192
    db 129,66,0,4,10,1,16,40,4,64,160,16
    db 60,60,255,243,240,252,207,195,243,63,15,207
    db 177,78,0,196,58,1,16,235,4,64,172,19
    db 12,48,255,51,192,252,207,0,243,63,3,204
    db 145,70,0,68,26,1,16,105,4,64,164,17
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

tilemap_idx:
    db 0
tile_offset
    db 9
tilemap:
include "henon1_tilemap.asm"
;    db  7,  8,  9, 10, 11, 12, 13, 14
;    db 15, 16, 17, 18,  0,  1,  2,  3
    db $ff
tile_ptr
    db $C0, $69

bitmap_title:
include "rsc_henon_title.asm"

    org 06000h
bitmap:
IF K7 = 0
include "rsc_henon1.asm"
ENDIF
    END
