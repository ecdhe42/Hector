; enemy_ships: address on screen
; enemy_ships+2: sprite address
; enemy_ships+4: Y position
; enemy_ships+5: X position
; enemy_ships+6: pixel shift

move_enemy_ship:
    push ix
    push hl
    ld a, (enemy_ships+1)             ; Check if enemy active
    cp 0
    jp nz, enemy_ship_movement      ; If so, move the ship up
    ld hl, $F060
    ld ix, enemy_sprites
    ld (enemy_ships), hl
    ld (enemy_ships+2), ix
    ld a, 194
    ld (enemy_ships+4), a           ; Y = 194
    ld a, 128
    ld (enemy_ships+5), a           ; X = 128
    ld a, 0
    ld (enemy_ships+6), a
enemy_ship_movement:
    ld hl, (enemy_ships)            ; HL = screen address
    ld ix, (enemy_ships+2)          ; IX = sprite address
    call clear_enemy_sprite               ; Delete the sprite on the screen
    ; Compare enemy position with ship position
    and a
    ld a, (player_x)
    ld b, a                         ; B = player_x
    ld a, (enemy_ships+5)           ; A = enemy_ship_x
    sbc a,b                         ; A = enemy_ship_x - player_x
    jp z, move_enemy_ship_up
    jp m, enemy_move_right
    jp enemy_move_left
move_enemy_ship_up:
    ld (enemy_ships+2), ix
    ld bc, $FF80
    add hl, bc
    ld (enemy_ships), hl
    and a
    ld a, (enemy_ships+4)           ; A = Y
    dec a
    dec a                           ; Y -= 2
    jp z, clear_enemy_ship
    ld (enemy_ships+4), a

    ld a, (missiles)
    cp 0
    jp z, draw_enemy_check_collision
    ld de, (missiles+1)     ; Redraw the player missile
    ld a,(missiles+3)
    ld b,a
    ld a, (de)
    or b
    ld (de), a
draw_enemy_check_collision:
    call display_enemy
    ld a, (enemy_col)
    cp 0
    call nz, enemy_ship_collision
    jp end_move_enemy_ship
clear_enemy_ship:
    ld hl, 0
    ld (enemy_ships), hl
end_move_enemy_ship
    pop hl
    pop ix
    ret

enemy_ship_collision:
;    ret
    ld hl, (enemy_ships)
    call clear_enemy_sprite
    ld a, 0
    ld (enemy_col), a
    ld (enemy_ships), a
    ld (enemy_ships+1), a
    ld (enemy_ships+2), a
    ld (enemy_ships+3), a
    ld (enemy_ships+4), a
    ld (enemy_ships+5), a
    ld (enemy_ships+6), a
    ret

; ##################################################################
enemy_move_left:
    ld a, (enemy_ships+5)    ; a = X
    cp 0
    jp z, move_enemy_ship_up  ; if a == 0, stop

    call clear_enemy_sprite
    ld a, (enemy_ships+6)    ; a = pixel shift
    cp 0
    jp nz, enemy_pixel_shift_left  ; if pixel shift != 0
enemy_reset_pixel_shift_left:
    ld a, 3
    ld (enemy_ships+6), a
    ld ix, enemy_sprites+9
;    call clear_right_sprite
    dec hl
    jp enemy_move_left_x
enemy_pixel_shift_left:
    dec a
    ld (enemy_ships+6), a      ; X pixel--
    dec ix
    dec ix
    dec ix
enemy_move_left_x:
    ld a, (enemy_ships+5)
    dec a
    ld (enemy_ships+5), a      ; X--
    jp move_enemy_ship_up

; ################################################################
enemy_move_right:
    ld a, (enemy_ships+5)    ; a = X
    cp 230
    jp z, move_enemy_ship_up  ; if a == 240, stop

    ld a, (enemy_ships+6)    ; a = pixel shift
    cp 3
    jp nz, enemy_pixel_shift_right  ; if pixel shift != 3
enemy_reset_pixel_shift_right:
    ld a, 0
    ld (enemy_ships+6), a     ; X pixel = 0
    ld ix, enemy_sprites
;    call clear_left_sprite
    inc hl
    jp enemy_move_right_x
enemy_pixel_shift_right:
    inc a
    ld (enemy_ships+6), a      ; X pixel++
    inc ix
    inc ix
    inc ix
enemy_move_right_x:
    ld a, (enemy_ships+5)
    inc a
    ld (enemy_ships+5), a      ; X++
    jp move_enemy_ship_up

; ################################################################
display_enemy:
    push hl
    push ix
    ld bc, 64
    ld d, 16
enemy_sprite_loop:
    ; First byte
    ld a, (ix+12)   ; Load the mask
    cpl
    and (hl)        ; Compare with the screen
    cp 0            ; If there is nothing in common
    jp z, enemy_nocoll1   ; Then there is no collision
    ld a, $FF
    ld (enemy_col), a
enemy_nocoll1
    ld a, (ix+12)   ; Load the mask
    and (hl)        ; Compare with the screen
    ld (hl), a      ; Draws the mask
    ld a, (ix)      ; Loads the bitmap
    or (hl)         ; Merges with the screen
    ld (hl), a      ; Draws the result

    ; Second byte
    inc hl
    ld a, (ix+13)
    cpl
    and (hl)
    cp 0
    jp z, enemy_nocoll2
    ld a, $FF
    ld (enemy_col), a
enemy_nocoll2
    ld a, (ix+13)
    and (hl)
    ld (hl), a
    ld a, (ix+1)
    or (hl)
    ld (hl), a

    ; Third byte
    inc hl
    ld a, (ix+14)
    cpl
    and (hl)
    cp 0
    jp z, enemy_nocoll3
    ld a, $FF
    ld (enemy_col), a
enemy_nocoll3
    ld a, (ix+14)
    and (hl)
    ld a, (ix+14)
    and (hl)
    ld (hl), a
    ld a, (ix+2)
    or (hl)
    ld (hl), a

    ld bc, 62
    add hl, bc
    ld bc, 24
    add ix, bc
    dec d
    ld a, d
    cp 0
    jp nz, enemy_sprite_loop
    pop ix
    pop hl
    ret

; ################################################################
clear_enemy_sprite:
    push hl
    push ix
    ld bc, 64
    ld d, 16
clear_enemy_sprite_loop:
    ld a, (ix+12)
    and (hl)
    ld (hl), a

    inc hl
    ld a, (ix+13)
    and (hl)
    ld (hl), a

    inc hl
    ld a, (ix+14)
    and (hl)
    ld (hl), a

    ld bc, 62
    add hl, bc
    ld bc, 24
    add ix, bc
    dec d
    ld a, d
    cp 0
    jp nz, clear_enemy_sprite_loop
    pop ix
    pop hl
    ret

; ################################################################
; HL = player's missile address on screen
; DE = enemy address on screen
check_missile_enemy_collision:
    ; First compare horizontal positions
    ld de, (enemy_ships)
    ld a, e
    and 63
    ld b, a         ; B = enemy_ships line offset (in bytes)
    ld a, l
    and 63          ; A = missile line offset (in bytes)
    cp b
    jp z, compare_vertical_positions
    inc b           ; Check next byte on screen
    inc e           ; Increment E so that DE is vertically aligned with HL
    cp b
    jp z, compare_vertical_positions
    inc b           ; Check next byte on screen
    inc e           ; Increment E so that DE is vertically aligned with HL
    cp b
    jp nz, no_missile_enemy_collision       ; If A != B, B+1 and B+2 then there is no collision
compare_vertical_positions:
;    ld bc, 960
;    ex de, hl
;    add hl, bc
;    ex de, hl       ; DE = address of the bottom of the enemy ship (&enemy_ships + 15*64)
    and a           ; Reset carry bit
    sbc hl, de      ; HL = missile address - enemy address
    bit 7, h        ; Check H high bit. If HL < 0, it should be set
    jp nz, no_missile_enemy_collision   ; If HL < 0, then there is no collision
    and a           ; Reset carry bit
    ld bc, 960
    sbc hl, bc
    bit 7, h        ; Check H high bit. If HL < 0, it should be set
    jp z, no_missile_enemy_collision   ; If HL >= 0, then there is no collision
missile_enemy_collision:
    call enemy_ship_collision
    ret
no_missile_enemy_collision:
    ret
