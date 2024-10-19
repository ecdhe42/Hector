RCHRAD  equ 5FE3h
SETSCR  equ 0D30h
CHRCOL  equ 062Eh
PUTC    equ 0C62h
DELAY   equ 07F6h
PUTSTR  equ 0D0Ch
CLS     equ 0D2Fh
SETCOLS equ 19E0h
COLORS  equ 0BD3h
FPS     equ 27

IF K7
include "afond_upper_ram_include.asm"
    org 4100h
include "afond_lower_ram.asm"

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
    ld a, 0
    call SETSCR     ; Screen color = 0 (black)
;    ld c, 1
;    CALL CHRCOL     ; Text color = 1 (red)

    ld a, 3
    ld (tmp), a
    ld de, $CB02
draw_title:
    ld a, 10
    ld hl, bitmap_title
    ld bc, 23
draw_title_line:
    ldir
    push hl
    ld h,d
    ld l,e
    ld bc, 41
    add hl, bc
    ld d,h
    ld e,l
    pop hl
    ld bc, 23
    dec a
    cp 0
    jp nz, draw_title_line
    ld a, e
    add a, 15
    inc d
    ld e, a
    ld a, (tmp)
    dec a
    ld (tmp), a
    cp 0
    jp nz, draw_title

    ld c, 2
    CALL CHRCOL     ; Text color = 2
    ld de, 185Ch    ; X and Y positions
    ld bc, please_select   ; Text
    call PUTSTR     ; Displays text on screen
    ld de, 186Ch    ; X and Y positions
    ld bc, track1_name  ; Text
    call PUTSTR     ; Displays text on screen
    ld de, 187Ch    ; X and Y positions
    ld bc, track2_name   ; Text
    call PUTSTR     ; Displays text on screen

    ld c, 3
    CALL CHRCOL     ; Text color = 3 (white)
    ld de, 289Ch    ; X and Y positions
    ld bc, author   ; Text
    call PUTSTR     ; Displays text on screen
    ld de, 18A9h    ; X and Y positions
    ld bc, author2  ; Text
    call PUTSTR     ; Displays text on screen
    ld de, 18B6h    ; X and Y positions
    ld bc, author3  ; Text
    call PUTSTR     ; Displays text on screen

splash_loop:
    ld hl, 03801h
    ld a, (hl)
    cp $ff
    jp z, splash_loop
    bit 1, a
    jp z, select_track1
    bit 0, a
    jp z, select_track2
    jp splash_loop
select_track1:
    ld bc, track1
    ld (track_ptr), bc
    jp splash_end
select_track2:
    ld bc, track2
    ld (track_ptr), bc
splash_end
    ld a, 0h
    call SETSCR     ; Screen color = 0 (black)

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
    ld (hl), 50h    ; color0 = 0 (black), color2 = 2 (green)
    ld hl, 01800h
    ld (hl), 39h    ; color1 = 1 (red), color3 = 7 (white)

    ld ix, bitmap_ptr               ; ix = track bitmap pointer
    ld iy, gear_speed
    ld (gear_speed_ptr), iy

    ld a, 24                        ; Set track speed of 3 frames
    ld (frame), a

    ld iy, turn_shift               ; Set turn_shift_ptr = &turn_shift
    ld (turn_shift_ptr), iy

    ld hl,bitmap                    ; Draw the top line of the track
    ld de,0D000h                    ; As it may not be fully drawn
    ld bc,$64
    ldir

draw_sky:
    ld hl,0C000h
    ld de,0C001h
    ld bc,$40
    ld a, $EE
    ld (hl), a                      ; Set the first byte of the first line to be $EE
    ldir                            ; Copy a whole line one byte right, i.e. write the whole line with $EE
    ld a, $BB
    ld (hl), a                      ; Set the first byte of the second line to be $BB
    ld bc,$40
    ldir                            ; Repeat the operation

    ld hl,0C000h                    ; Copy the first two lines for 38 more lines by using a similar trick
    ld de,0C080h
    ld bc,00800h
    ldir
end_draw_sky

    ld a, 28
    ld hl,bitmap_gauge
    ld de,$EB10
draw_init_speed_gauge:
    ld bc,10
    ldir
    ld bc,54
    push hl
    ld h,d
    ld l,e
    add hl,bc
    ld d,h
    ld e,l
    pop hl
    dec a
    cp 0
    jp nz, draw_init_speed_gauge

    ld a, 28
    ld hl,bitmap_gauge
    ld de,$EB26
draw_init_rpm_gauge:
    ld bc,10
    ldir
    ld bc,54
    push hl
    ld h,d
    ld l,e
    add hl,bc
    ld d,h
    ld e,l
    pop hl
    dec a
    cp 0
    jp nz, draw_init_rpm_gauge

    ld de,digits
    ld hl,$F42A
    call display_digit
    ld de,digits
    ld hl,$F42B
    call display_digit
    ld de,digits
    ld hl,$F42C
    call display_digit

    ld a, 12
    ld hl,bitmap_gearbox_icon
    ld de,$EF1F
draw_init_gearbox_icon:
    ld bc,3
    ldir
    ld bc,61
    push hl
    ld h,d
    ld l,e
    add hl,bc
    ld d,h
    ld e,l
    pop hl
    dec a
    cp 0
    jp nz, draw_init_gearbox_icon

; ######################################################################################
    di

    ld iy, (gear_speed_ptr)         ; iy = &gear_speed
    jp draw_speed_rpm

draw_frame:
    ld hl,bitmap_bg                 ; Prepare to draw the mountains in the background
    ld de, 0C880h
    ld b,0
    ld a,(bg_shift)
    ld c,a                          ; C = bg_shift
    add hl,bc                       ; Add the shift to the mountains pointer (bitmap_bg + bg_shift)
    ld a, (turn_dir)
    cp 0
    jp nz, shift_bg_left            ; if turn_dir=0 (straight or move right)
    ld a, (turn_speed)
    add a,c                         ; A = bg_shift + turn_speed
    jp store_new_bg_shift
shift_bg_left:
    and a                           ; Clear carry flag
    ld a, (turn_speed)
    ld b, a                         ; B = turn_speed
    ld a, c                         ; A = bg_shift
    sbc a,b                         ; A = bg_shift - turn_speed
store_new_bg_shift:
    and $3F
    ld (bg_shift),a                 ; bg_shift = bg_shift += turn_speed MOD 64

    ld a,30                         ; Set the counter to 30 lines to be drawn (background mountains)
draw_bg_loop:
    call copy_line

    ld bc,$40
    add hl,bc

    dec a
    cp 0
    jp nz, draw_bg_loop

; DRAW TRACK

    ld a, (car_bump)
    cp 0
    jp z,no_bump
    cp 1
    jp z, bump1
    ld de, 0D080h
    ld a, 1
    ld (car_bump), a
    ld a, 98                ; Set the counter to 98 lines to be drawn
    ld (track_line), a
    jp set_draw_track
bump1
    ld a, 2
    ld (car_bump), a
no_bump:
    ld de, 0D000h           ; DE = destination pointer, i.e. the screen
    ld a, 100               ; Set the counter to 100 lines to be drawn
    ld (track_line), a
set_draw_track:
    ld hl, bitmap+$1900     ; HL = source pointer, i.e. track bitmap
    ld iy, (turn_shift_ptr) ; iy = pointer to the turn byte shift table

    ld a, 0                 ; Resets test_cars_collision flag
    ld (test_cars_collision), a
    ld a, (other_car_y_max)
    ld (other_car_y), a     ; Other car starts at offset other_car_y_max
    dec a
    ld (other_car_y_max), a
    cp -76
    jp nz, other_car_settings
    ld a, -28
    ld (other_car_y_max), a
other_car_settings:
    add a, 28
    and a
    add a, 8
    jp nc, check_zone_1
zone0:
    ld hl, other_car_draw0
    ld (other_car_draw), hl ; Routine to draw
    ld hl, bitmap_cars_others0
    ld (other_car_ptr), hl  ; Pointer to the bitmap
    ld a, 8                 ; Set other car height
    jp other_car_turn
check_zone_1:
    add a, 8
    jp nc, check_zone_2
zone1:
    ld hl, other_car_draw1
    ld (other_car_draw), hl ; Routine to draw
    ld hl, bitmap_cars_others1
    ld (other_car_ptr), hl  ; Pointer to the bitmap
    ld a, 13                ; Set other car height
    jp other_car_turn
check_zone_2:
    add a, 8
    jp nc, check_zone_3
zone2:
    ld hl, other_car_draw2
    ld (other_car_draw), hl ; Routine to draw
    ld hl, bitmap_cars_others2
    ld (other_car_ptr), hl  ; Pointer to the bitmap
    ld a, 17                ; Set other car height
    jp other_car_turn
check_zone_3:
    add a, 8
    jp nc, zone_4
zone3:
    ld hl, other_car_draw3
    ld (other_car_draw), hl ; Routine to draw
    ld hl, bitmap_cars_others3
    ld (other_car_ptr), hl  ; Pointer to the bitmap
    ld a, 21                ; Set other car height
    jp other_car_turn
zone_4:
    ld hl, other_car_draw4
    ld (other_car_draw), hl ; Routine to draw
    ld hl, bitmap_cars_others4
    ld (other_car_ptr), hl  ; Pointer to the bitmap
    add a, 8
    jp c, zone_4_end
    ld a, 1
    ld (test_cars_collision), a
zone_4_end:
    ld a, 25                ; Set other car height

other_car_turn:
    push iy                 ; We need to know what byte offset depending of the car Y position
    ld c, a                 ; C = other car height
    ld a, (other_car_y)     ; A = other_car_y (from -28 to 103)
    ld b, a                 ; B = A
    ld a, $FF
    sub b                   ; A = 255 - other_car_y (from )
    add a, c                ; A = 255 - other_car_y + other_car_height
    ld c, a                 ; C = 255 - other_car_y + other_car_height
    ld b, 0
    add iy, bc              ; We look at line C inside the turn_shift table
    ld a, (iy)              ; A = turn shift (in bytes)
    pop iy

    ld b, a                 ; B = turn byte shift
    ld a, (turn_dir)        ; Depending of the turn direction, we add or subtract B
    cp 0
    ld a, 30                ; A = Other car default offset = 30
    jp z, other_car_turn_right
    sub b                   ; A = 30 - turn byte shift
    jp other_car_turn_done
other_car_turn_right:
    add a, b                ; A = 30 + turn byte shift
other_car_turn_done:
    ld (other_car_x), a     ; other_car_x = 30 +- turn byte shift

cars_collision_detection:
    ld a, (test_cars_collision)
    cp 0
    jp z, end_cars_collision_detection
    and a                   ; Clear carry flag
    ld a, (other_car_x)
    ld b, a                 ; B = other_car_x
    ld a, (car_x)           ; A = car_x
    sub b                   ; A = car_x - other_car_x
    jp nc, other_car_on_the_left
    ld b, a                 ; If A < 0
    ld a, $FF               ; A = $FF - A
    sub b
other_car_on_the_left:
    and a
    sub 11
    jp nc, end_cars_collision_detection
cars_crash:
    push iy
    ld iy, gear_speed
    ld (gear_speed_ptr), iy     ; Down to first RPM of first gear
    pop iy
    ld a, 0
    ld (gear), a                ; Down to first gear (gear=0)
    ld de, $E2C0
    ld a, (car_x)
    add a, e
    ld e, a                     ; DE = 0xE2C0 + car_x

    ld hl, bitmap_cars_collision
    ld a, h
    ld (car_bitmap_l), a
    ld a, l
    ld (car_bitmap_h), a        ; car_bitmap_h = &bitmap_cars_collision

    ld a, 25
    ld (other_car_height), a    ; Used for the number of iterations

    ld sp, (car_bitmap_h)   ; The stack pointer points to the sprite data
draw_cars_collision:
REPT 12
    pop bc                  ; B = sprite value, C = mask value
    ld a, (de)              ; A = background
    and c                   ; A = background & mask
    or b                    ; A = (background & mask) | car
    ld (de), a              ; Store byte back on the screen
    inc e
ENDM

    ex de, hl
    ld bc, 64-12
    add hl, bc
    ex de, hl               ; DE += 52 (next line)
    ld a, (other_car_height)
    dec a
    ld (other_car_height), a
    jp nz, draw_cars_collision
    ld sp, 0C000h

    ld a, -28
    ld (other_car_y_max), a     ; Reset other car Y position
    ld bc, $FFFF    ; Delay
    call DELAY      ; Wait
    jp draw_frame
end_cars_collision_detection

setup_car:
    ld hl, bitmap_car       ; Save the address of the car bitmap
    ld a, h
    ld (car_bitmap_l), a
    ld a, l
    ld (car_bitmap_h), a

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw_track:
    push de                 ; We save the screen-aligned value of DE
    ex de, hl               ; HL = destination address
    ld b,0
    ld c,(iy)               ; BC = gear_speed_ptr
    ld a, (turn_dir)
    cp 0
    jp nz, shift_track_left
    add hl,bc               ; If we veer right, add the shift to the destination ptr
    jp done_shift_track
shift_track_left:
    and a
    sbc hl,bc               ; If we veer left, substract the shift from the destination ptr

done_shift_track:
    ex de, hl               ; de += pixel shift

draw_track_line
    ld h, (ix)              ; HL = pointer to the track bitmap
    ld l, (ix+1)
    call copy_line          ; Copies 64 bytes from HL to DE and increments both pointers
    pop de                  ; DE = left-aligned address on the screen
    push de                 ; Make two copies of DE in the stack

draw_other_car_line
    ld a, (other_car_y)     ; A = other_car_y
    cp 0
    jp m, end_draw_other_car_line   ; If other_car_y < 0, skip section
    ld hl, (other_car_draw) ; HL = pointer
    ld b, a                 ; B = other_car_y
    ld a, (other_car_x)
    add a, e
    ld e, a
    jp (hl)                 ; Call the routine to draw the other car line
draw_other_car_line2:
    ld a, (other_car_y)
end_draw_other_car_line:
    inc a
    ld (other_car_y), a

check_if_draw_car:
    and a                               ; Clear carry bit
    ld a, (car_bump)
    cp 1
    ld a, (track_line)                  ; A = track_line
    jp z, draw_car_with_bump
    sub 26                              ; A -= 26
    jp check_if_draw_car_with_bump
draw_car_with_bump:
    sub 24
check_if_draw_car_with_bump:
    jp nc, end_draw_car                 ; If no carry bit (i.e. track_line >= 26) then we don't draw the car yet

draw_car:
    ld a, (car_x)
    ld b, a                 ; B = car_x
    ld a, e                 ; A = E (lower byte of screen address)
    and $C0                 ; Align A to the left of the screen
    add a, b                ; A += car_x
    ld e, a                 ; DE = screen address (left-aligned) + car_x
    ld sp, (car_bitmap_h)   ; The stack pointer points to the sprite data
REPT 12
    pop bc                  ; B = sprite value, C = mask value
    ld a, (de)              ; A = background
    and c                   ; A = background & mask
    or b                    ; A = (background & mask) | car
    ld (de), a              ; Store byte back on the screen
    inc e
ENDM
    ld (car_bitmap_h), sp
    ld sp, 0BFFEh           ; Restore the stack (BEWARE: need to make sure it's the right value)
end_draw_car

prepare_next_track_line:
    pop hl                  ; HL = destination pointer (screen-aligned)
    ld bc,$40
    add hl,bc               ; HL += $40
    ex de, hl               ; DE += $40 (before the ldir command)

    inc ix                  ; next bitmap address
    inc ix
    inc iy                  ; next turn shift
    ld a, (track_line)
    dec a                   ; number of lines--
    ld (track_line), a
    cp 0
    jp nz, draw_track
end_draw_track
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ld hl, bitmap_car       ; Save the address of the car bitmap
    ld a, h
    ld (car_bitmap_l), a
    ld a, l
    ld (car_bitmap_h), a

    ld a, (car_bump)                    ; If car_bump is set
    cp 1
    jp nz, end_car_bump_post_adjust     ; we need to update ix and iy
    inc ix                              ; for the two lines we didn't draw
    inc ix
    inc ix
    inc ix
end_car_bump_post_adjust:

animate_car_wheels:
    ld iy, $E641                        ; Base offset on the screen
    ld a, (frame)                       ; We use the frame count
    and $7                              ; A = frame MOD 8
    sra a
    sra a
    ld b, a                             ; B = (frame MOD 8) >> 2
    ld a, (frame)                       ; We use the frame count
    and $7                              ; A = frame MOD 8
    sla a
    sla a
    sla a
    sla a
    sla a
    sla a
    ld c, a                             ; C = (frame MOD 8) << 6
    ld a, (car_x)                       ; A = car_x
    add a, c
    ld c, a                             ; C = (frame MOD 8) << 6 + car_x
    add iy, bc

    ld a, $FF
    ld (iy), a
    ld bc, 9
    add iy, bc
    ld (iy), a

    ld iy, (gear_speed_ptr)     ; iy = &gear_speed

animate_track:
    ; The whole track pointer is 4800 bytes long (24 frames)
    ld a, (iy+7)            ; a = speed
    bit 7, a                ; check if a >= 128
    jp z, check_slow_speed
    ld bc, 1400             ; If speed >= 130, we animate the track by 6 frames
    ld d, 8
    jp animate_track_update_regs
check_slow_speed
    sub 50
    jp nc,fast_speed
check_slow_speed_no_xor:
    ; speed=10 -> a=1 -> bc=0 -> d=1
    ; speed=20 -> a=2 -> bc=200 -> d=2
    ; speed=30 -> a=3 -> bc=400 -> d=3
    ; speed=40 -> a=4 -> bc=600 -> d=4
    cp -40
    jp z, speed_1
    cp -30
    jp z, speed_2
    cp -20
    jp z, speed_3
    ld bc, 600
    ld d, 4
    jp animate_track_update_regs
speed_1:
    ld bc, 0
    ld d, 1
    jp animate_track_update_regs
speed_2:
    ld bc, 200
    ld d, 2
    jp animate_track_update_regs
speed_3:
    ld bc, 400
    ld d, 3
    jp animate_track_update_regs

fast_speed:
    ld bc,1000               ; We animate the track by 4 frames
    ld d,6
animate_track_update_regs:
    add ix,bc

    ld a, (frame)           ; Count the # of frames
    sub d
    jp c, animate_track_reset   ; if the counter < 0, reset
    ld (frame), a
    cp 0
    jp z, animate_track_reset    ; If the counter = 0 reset
    jp end_animate_track
animate_track_reset:
    ld ix, bitmap_ptr       ; Otherwise resets the track layout
    ld a, 24
    ld (frame), a
end_animate_track:

check_accel_decel:
    ; Check keyboard for space (acceleration)
    ld hl, 03800h
    ld a, (hl)
    cp $ff
    jp z, decelerate            ; If the key is not pressed, decelerate
accelerate:                     ; If the key is pressed, accelerate
    ld a, (iy)
    cp 8
    jp z, end_check_accel_decel ; If we're in top RPM, skip

    and a                   ; Reset carry
    ld a, (gear_rpm)        ; A = RPM sub-speed
    ld b, a
    ld a, (iy+6)            ; A = acceleration (given gear and RPM)
    adc a, b
    ld (gear_rpm), a
    jp po, end_check_accel_decel ; If there is no overflow, continue
    ld b,0                      ; Otherwise we switch RPM
    ld c,8
    add iy, bc
    ld (gear_speed_ptr), iy     ; iy += 8 (switch to higher RPM)
    ld a, 16
    ld (gear_rpm), a
    ld (gear_refresh), a
    jp end_check_accel_decel
decelerate:
    ld a, (iy)
    cp 1
    jp z, end_check_accel_decel  ; If we're in low RPM, skip

    and a                   ; Reset carry
    ld a, (gear_rpm)
    sbc a, 8
    ld (gear_rpm), a
    jp po, end_check_accel_decel ; If there is no overflow, continue
    ld b,$FF                    ; Otherwise we switch down RPM
    ld c,$F8
    add iy, bc
    ld (gear_speed_ptr), iy     ; iy -= 8 (switch to lower RPM)
    ld a, 16
    ld (gear_rpm), a
    ld (gear_refresh), a
end_check_accel_decel:

check_switch_gear:
    ; Check joystick for up and down (gear up and down)
    ld hl, 03807h
    ld a, (hl)
    cp $ff
    jp z, no_switch_gear        ; If no joystick, jump to next section
    bit 2, a
    jp z, switch_gear_up        ; If joystick up (bit 2 is off), switch gear up
    bit 3, a
    jp nz, no_switch_gear
    call switch_gear_down         ; If joystick down (bit 3 is off), switch gear down
no_switch_gear:
    ld a, 0
    ld (clutch_down), a     ; Reset clutch down flag
end_check_switch_gear:

check_car_turn:
    ; Check joystick for left and right (in the future it will be automated)
    ld hl, 03807h
    ld a, (hl)
    cp $ff
    jp z, end_check_car_turn        ; If no joystick, draw next frame

    bit 0, a                ; Check if joystick goes left
    jp z, car_turn_left
    bit 1, a
    jp z, car_turn_right    
end_check_car_turn:


update_advancement_on_track:
    ld b, (iy+7)                ; B = speed
;    srl b
    and a                       ; clear carry
    ld a, (track_counter)       ; A = track counter
    adc a, b
    ld (track_counter), a       ; track_counter += speed
    jp nc, end_update_track_position    ; If there is no overflow, skip section

drift:
    ld a, (turn_speed)          ; A = turn_speed
    cp 0
    jp z, end_drift             ; If turn_speed = 0, there is no drift. Skip the rest of this section
    ld b, a                     ; B = turn_speed
    ld a, (turn_dir)            ; Otherwise, check the turn direction
    cp 0
    jp nz, drift_right
drift_left:
    ld a, (car_x)               ; A = car_x, B = turn_speed
    sub b
    ld (car_x), a               ; car_x -= turn_speed
    sbc a, 4
    jp nc, drift_check_bump     ; if car_x > 4, skip the rest of this section
    ld a, 4
    ld (car_x), a               ; Otherwise car_x = 4
    jp drift_check_bump
drift_right:
    ld a, (car_x)               ; A = car_x, B = turn_speed
    add a, b
    ld (car_x), a               ; car_x += turn_speed
    sbc a, 46
    jp m, drift_check_bump ; if car_x < 46, skip the rest of this section
    ld a, 46                ; if car_x > 46, then car_x = 46
    ld (car_x), a
drift_check_bump:           ; Check if the car is hitting the side
    ld b, 0
    ld a, (car_x)
    ld c, a                 ; C = car_x
    ld hl, car_x_bump
    add hl, bc              ; HL = &car_x_bump + car_x
    ld a, (hl)
    ld (car_bump), a        ; car_bump = car_x_bump[car_x]
end_drift

check_car_bump:
    ld a, (car_bump)                ; A = car_bump
    cp 0
    jp z, end_check_car_bump
    call brake                      ; if car_bump flag set, brake
end_check_car_bump

next_track_step:
    ld a, (track_steps)
    dec a
    ld (track_steps), a            ; track_steps--
    cp 0
    jp nz, end_update_track_position    ; if track_steps > 0, skip section

    ld bc, (track_ptr)          ; Get the new track (bc=*track_ptr)
    ld a, (bc)
    cp $FF
    jp z, game_over             ; If the track value = $FF, end of the game
    and $C0                     ; A = *track_ptr & 0xC0 (top 2 bits of *track_ptr, direction)
    cp 0
    jp z, end_check_road_turn   ; If A = 0, then no turn
check_turn_track_left
    cp 128
    jp nz, check_turn_track_right
    jp road_turn_left           ; If A = 128 (7th bit on), then turn left
check_turn_track_right:
    cp 64
    jp nz, end_check_road_turn
    jp road_turn_right          ; If A = 64 (6th bit on), then turn right
end_check_road_turn:
    ld bc, (track_ptr)          ; Get the new track (bc=*track_ptr)
    ld a, (bc)
    and $3F                     ; A = *track_ptr & $3F (lower 6 bits of *track_ptr), number of steps after turn
    ld (track_steps), a         ; track_steps = (track value) % b00111111 (6 lower bits)
    inc bc
    ld (track_ptr), bc          ; track_ptr++
end_update_track_position

timer:
    ld a, (time_counter)
    dec a
    ld (time_counter), a
    cp 0
    jp nz, end_timer
    ld a, FPS
    ld (time_counter), a
    ld a, (seconds_low)
    add a, 5
    ld (seconds_low), a
    cp 50
    jp nz, refresh_counter
    ld a, 0
    ld (seconds_low), a
    ld a, (seconds_high)
    add a, 5
    ld (seconds_high), a
    cp 30
    jp nz, refresh_counter
    ld a, 0
    ld (seconds_high), a
    ld a, (minutes_low)
    add a, 5
    ld (minutes_low), a
    cp 50
    jp nz, refresh_counter
    ld a, 0
    ld (minutes_low), a
    ld a, (minutes_high)
    add a, 5
    ld (minutes_high), a
refresh_counter:
    ld b, 0
    ld a, (seconds_low)
    ld c, a
    ld hl, digits       
    add hl, bc          ; hl = digits + seconds_low
    ld d, h
    ld e, l
    ld hl, $EB22
    call display_digit
    ld b, 0
    ld a, (seconds_high)
    ld c, a
    ld hl, digits       
    add hl, bc          ; hl = digits + seconds_high
    ld d, h
    ld e, l
    ld hl, $EB21
    call display_digit
    ld b, 0
    ld a, (minutes_low)
    ld c, a
    ld hl, digits       
    add hl, bc          ; hl = digits + minutes_low
    ld d, h
    ld e, l
    ld hl, $EB1F
    call display_digit
    ld b, 0
    ld a, (minutes_high)
    ld c, a
    ld hl, digits       
    add hl, bc          ; hl = digits + minutes_high
    ld d, h
    ld e, l
    ld hl, $EB1E
    call display_digit
end_timer:

    jp check_gear_refresh


game_over:
    ld c, 1h
    CALL CHRCOL     ; Text color = 1 (red)
    ld de, 6069h    ; X and Y positions
    ld bc, game_won  ; Text
    call PUTSTR     ; Displays text on screen
    ld de, 5079h
    ld bc, (track_ptr)
    inc bc
    call PUTSTR     ; Displays text on screen

    ; Restore all variable initial states
    ld hl, variables_backup
    ld de, variables
    ld bc, variables_backup - variables
    ldir

    jp splash_loop

switch_gear_up:
    ld a, (clutch_down)
    cp 0
    jp nz, end_check_switch_gear        ; If the clutch flag it set, do nothing

    ld a, (gear)
    cp 4
    jp z, end_check_switch_gear        ; If we're in top gear, do nothing - we're at the max

    ld iy, (gear_speed_ptr)     ; iy = &gear_speed
    ld a, (iy+4)
    cp 0
    jp z, end_check_switch_gear         ; If we're not fast enough for the next gear (next = 0), do nothing

    ; Otherwise, switch gear up
    ld c, a
    ld b, 0
    add iy, bc
    ld (gear_speed_ptr), iy     ; iy += *(iy+4)

    ld a, (gear)
    inc a
    ld (gear), a            ; gear++

    ld a, 1
    ld (clutch_down), a     ; We set the clutch flag (so that we don't automatically switch gear up again)
    ld (gear_refresh), a    ; We set the gear refresh flag (so we know we need to update the dashboard)

    jp end_check_switch_gear

switch_gear_down:
    ld a, (clutch_down)
    cp 0
    ret nz                  ; If the clutch flag it set, do nothing

    ld a, (gear)
    cp 0
    ret z                   ; If we're in low gear, do nothing - we're at the max

    dec a
    ld (gear), a            ; Otherwise gear--

    ld a, 1
    ld (clutch_down), a     ; We set the clutch flag
    ld (gear_refresh), a    ; We set the gear refresh flag

    ld iy, (gear_speed_ptr) ; iy = &gear_speed

    ld a, (iy+5)            ; A = offset inside gear_speed
    ld iy, gear_speed
    ld b, 0
    ld c, a
    add iy, bc
    ld (gear_speed_ptr), iy   ; iy = &gear+speed + *(iy+5)
    ret

check_gear_refresh:
    ld a, (gear_refresh)
    cp 0
    jp z, draw_frame

draw_speed_rpm:
    ld a, 0
    ld (gear_refresh), a        ; Reset the refresh flag

    ld b, 0
    ld a, (iy+1)                ; a = speed high digit offset
    ld c, a                     ; bc = *(&gear_speed + gear_speed_offset)
    ld hl, digits
    add hl, bc                  ; hl = &digit + offset
    ld d,h
    ld e,l                      ; de = hl
    ld hl, $EF14
    call display_digit
    ld a, (iy+2)                ; a = speed high digit offset

    ld c, a                     ; bc = *(&gear_speed + gear_speed_offset)
    ld hl, digits
    ld c, a
    add hl, bc
    ld d,h
    ld e,l
    ld hl, $EF15
    call display_digit
    ld a, (iy+3)                ; a = speed high digit offset

    ld c, a                     ; bc = *(&gear_speed + gear_speed_offset)
    ld hl, digits
    add hl, bc
    ld d,h
    ld e,l
    ld hl, $EF16
    call display_digit

    ; Display gear
    ld a, (gear)
    inc a
    sla a
    sla a
    ld c, a
    ld a, (gear)
    inc a
    add a, c            ; c = gear * 5
    ld c, a
    ld hl, digits
    add hl, bc
    ld d, h
    ld e, l
    ld hl, $F420
    call display_digit

    ; Display RPM
    ld a, (iy)          ; a = rpm
    sla a
    sla a
    ld c, a             ; c = rpm * 4
    ld a, (iy)          ; a = rpm
    add a, c            ; c = rpm * 5
    ld c, a
    ld hl, digits       
    add hl, bc          ; hl = digits + rpm*5 (pointer to the RPM top digit)
    ld d, h
    ld e, l
    ld hl, $F429
    call display_digit

    ; Display RPM needle
    ld hl, bitmap_needles-128
    ld c, 0
    ld a, (iy)              ; A = RPM
    bit 0, a
    jp z, adjust_bitmap_top
    ld c, $80
adjust_bitmap_top:
    sra a
    ld b, a
    add hl, bc

    ld a, 16
    ld b, 0
    ld de, $EDE7
draw_needle_loop:
    ld c, 8
    ldir
    push af
    and a
    ld a, e
    adc a, 56
    ld e, a
    ld a, d
    adc a, 0
    ld d, a
    pop af
    dec a
    jp nz, draw_needle_loop

    jp draw_frame

brake:
    ld a, (iy)                  ; A = RPM number
    cp 1
    jp z, brake_gear_down
    ld b,$FF                    ; Otherwise we switch down RPM
    ld c,$F8
    add iy, bc
    ld (gear_speed_ptr), iy     ; iy -= 8 (switch to lower RPM)
    ld a, 16
    ld (gear_rpm), a
    ld (gear_refresh), a
    ret
brake_gear_down:
    call switch_gear_down
    ret

; #########################################################################################
; # ROAD TURNS
; #########################################################################################

car_turn_left:
    ld a, (car_x)               ; A = X position of the car
    cp 4
    jp z, end_move_car_left     ; Cannot go lower than 4
    cp 44
    jp nz, move_car_left        ; If car_x == 50 and we want to go left
    ld a, 0
    ld (car_bump), a            ; Reset car_bump
    ld a, (car_x)
move_car_left:
    dec a
    ld (car_x), a               ; car_x--
    cp 6                        
    jp nz, end_move_car_left    ; If new car_x == 6
    ld a, 1
    ld (car_bump), a            ; Shake
end_move_car_left:
    jp end_check_car_turn

car_turn_right:
    ld a, (car_x)                ; A = X position of the car
    cp 46
    jp z, end_move_car_right     ; Cannot go higher than 48
    cp 6
    jp nz, move_car_right       ; If car_x == 50 and we want to go left
    ld a, 0
    ld (car_bump), a            ; Reset car_bump
    ld a, (car_x)
move_car_right:
    inc a
    ld (car_x), a               ; car_x--
    cp 44
    jp nz, end_move_car_right   ; If new car_x == 6
    ld a, 1
    ld (car_bump), a            ; Shake
end_move_car_right:
    jp end_check_car_turn


road_turn_left:
    ld a, (turn_speed)
    cp 0                        ; If turn_speed = 0 (straight)
    jp nz, keep_move_left
    ld a, 1                     ; because we're moving left
    ld (turn_dir), a            ; then turn_dir = 1 (left)
    jp turn_left
keep_move_left:                 ; We know we're not heading straight
    ld a, (turn_dir)            ; If turn_dir = 0 (right)
    cp 0
    jp z, turn_less_right       ; then we decrease our right turn
turn_left:
    ld a, (turn_speed)          ; If we're at max turn
    cp 3                        ; (turn_speed=3)
    jp z, end_check_road_turn            ; then don't do anything

    inc a
    ld (turn_speed), a          ; turn_speed++

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    add hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr += 100

    jp end_check_road_turn
turn_less_right:
    ld a, (turn_speed)
    dec a
    ld (turn_speed), a

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    sbc hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr -= 100

    jp end_check_road_turn


road_turn_right:
    ld a, (turn_speed)
    cp 0                        ; If turn_speed = 0 (straight)
    jp nz, keep_move_right
    ld a, 0                     ; because we're moving right
    ld (turn_dir), a            ; then turn_dir = 0 (right)
    jp turn_right
keep_move_right:                ; We know we're not going straight
    ld a, (turn_dir)            ; If turn_dir = 1 (left)
    cp 1
    jp z, turn_less_right       ; then we decrease our right turn
turn_right:
    ld a, (turn_speed)          ; If we're at max turn
    cp 3                        ; (turn_speed=3)
    jp z, end_check_road_turn            ; then don't do anything

    inc a
    ld (turn_speed), a          ; turn_speed++

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    add hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr += 100

    jp end_check_road_turn
turn_less_left:
    ld a, (turn_speed)
    dec a
    ld (turn_speed), a          ; turn_speed--

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    sbc hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr -= 100

    jp end_check_road_turn


copy_line:
REPT 64
    ldi
ENDM
    ret

other_car_draw0:
    ld a, (other_car_y)
    cp 7
    jp nz, other_car_draw0_line
    ld a, -100
    ld (other_car_y), a
other_car_draw0_line:
    ld hl, (other_car_ptr)
    ldi
    ldi
    ldi
    ldi
    ld (other_car_ptr), hl
    jp end_draw_other_car_line

other_car_draw1:
    ld a, (other_car_y)
    cp 12
    jp nz, other_car_draw1_line
    ld a, -100
    ld (other_car_y), a
other_car_draw1_line:
    ld hl, (other_car_ptr)
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ld (other_car_ptr), hl
    jp end_draw_other_car_line

other_car_draw2:
    ld a, (other_car_y)
    cp 16
    jp nz, other_car_draw2_line
    ld a, -100
    ld (other_car_y), a
other_car_draw2_line:
    ld hl, (other_car_ptr)
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ld (other_car_ptr), hl
    jp end_draw_other_car_line

other_car_draw3:
    ld a, (other_car_y)
    cp 20
    jp nz, other_car_draw3_line
    ld a, -100
    ld (other_car_y), a
other_car_draw3_line:
    ld hl, (other_car_ptr)
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ld (other_car_ptr), hl
    jp end_draw_other_car_line

other_car_draw4:
    ld a, (other_car_y)
    cp 24
    jp nz, other_car_draw4_line
    ld a, -100
    ld (other_car_y), a
other_car_draw4_line:
    ld hl, (other_car_ptr)
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ldi
    ld (other_car_ptr), hl
    jp end_draw_other_car_line

display_digit:
    ld bc,64
    ld a, (de)
    ld (hl), a
    add hl,bc
    inc de
    ld a, (de)
    ld (hl), a
    add hl,bc
    inc de
    ld a, (de)
    ld (hl), a
    add hl,bc
    inc de
    ld a, (de)
    ld (hl), a
    add hl,bc
    inc de
    ld a, (de)
    ld (hl), a
    ret

title:
    db "A FOND A FOND A FOND!", 0
please_select:
    db "Choisissez votre circuit:", 0
author
    db "Copyleft Laurent Poulain 2024", 0
author2
    db "Avec l'aide d'Olipix pour les",0
author3
    db "graphiques",0
game_won:
    db "GAME OVER"

variables:
turn_dir        db 0
turn_speed      db 0
turn_shift_ptr  db 0, 0
tmp             db 0
car_bump        db 0
car_x           db $16
car_bitmap_h    db 0
car_bitmap_l    db 0
other_car_y     db 0
other_car_height db 0
other_car_x     db 30
other_car_y_max db -28
other_car_ptr   db 0, 0
other_car_draw  db 0, 0
dist            db 10
frame           db 12
bg_shift        db 0
seconds_low     db 0
seconds_high    db 0
minutes_low     db 0
minutes_high    db 0
time_counter    db FPS
track_counter   db 0
track_steps     db 10
track_line      db 0
gear            db 0
clutch_down     db 0
gear_rpm        db 16
gear_refresh    db 0
gear_speed_offset    db 0
gear_speed_ptr  db 0, 0
test_cars_collision  db 0

variables_backup:
    db 0, 0, 0, 0, 0, 0, $16, 0, 0, 0, 0, 30, -28, 0, 0, 0, 0, 10, 12, 0, 0, 0, 0, 0, FPS, 0, 10, 0, 0, 0, 16, 0, 0, 0, 0, 0

track1
    ; Bit 0: are we turning left
    ; Bit 1: are we turning right
    ; Bit 2-7: number of steps after the turn (min=1, max=63)
    ; Examples:
    ; 191 = Turn left and wait for 63 steps
    ; 129 = Turn left and wait for 1 step
    ; 127 = Turn right and wait for 63 steps
    ; 65 = Turn right and wait for 1 step
    ; 63 = Wait for 63 steps
    ; $FF = end of the track (game over)
    db 128+20, 64+48, 64+1, 64+63, 128+1, 128+63, 128+1, 128+1, 128+63, 64+1, 64+1, 64+1, 64+1, 64+1, 64+63, 128+1, 128+1, 128+63, $FF
track1_name
    db "1. Petit joueur", 0
track2
    db 129,129,191,65,65,65,65,65,127,129,129,129,129,129,191,65,65,65,65,65,127,129,129,191,$FF
track2_name
    db "2. Jaitaibourrai", 0

track_ptr   db 0, 0

IF K7=0
include "afond_lower_ram.asm"
ENDIF

include "rsc_afond_cars_others.asm"

end_program

IF K7 = 0
include "afond_upper_ram.asm"
;include "rsc_afond.asm"
;bitmap_bg:
;include "rsc_afond_bg.asm"
;bitmap_needles:
;include "rsc_afond_needles.asm"
;bitmap_ptr:
;include "afond_bitmap_ptr.asm"
;end_upper_ram
ENDIF
    END
