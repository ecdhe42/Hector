RCHRAD  equ 5FE3h
SETSCR  equ 0D30h
CHRCOL  equ 062Eh
PUTC    equ 0C62h
DELAY   equ 07F6h
PUTSTR  equ 0D0Ch
CLS     equ 0D2Fh
SETCOLS equ 19E0h
COLORS  equ 0BD3h
FPS     equ 20

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
;    ld a, 0h
;    call SETSCR     ; Screen color = 0 (black)
;    ld c, 1h
;    CALL CHRCOL     ; Text color = 1 (red)

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

    ld iy, 0D2A0h
    ld (other_car_iy), iy

    ld iy, track
    ld (track_ptr), iy

    ld hl,bitmap                    ; Draw the top line of the track
    ld de,0D000h                    ; As it may not be fully drawn
    ld bc,$64
    ldir

    ld de,0C000h
    ld a, 40
draw_sky:
    ld hl,sky
    ld bc,$80
    ldir
    dec a
    cp 0
    jp nz, draw_sky

    ld iy, turn_shift               ; Set turn_shift_ptr = &turn_shift
    ld (turn_shift_ptr), iy

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

splash_loop:
    ld hl, 03800h
    ld a, (hl)
    cp $ff
    jp z, splash_loop
splash_end
    ld a, (hl)
    cp $ff
    jp nz, splash_end

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
    ld bc,$40
    ldir

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
    jp set_draw_track
bump1
    ld a, 2
    ld (car_bump), a
no_bump:
    ld de, 0D000h
set_draw_track:
    ld hl, bitmap+$1900
    ld iy, (turn_shift_ptr)
    ld a, 75                       ; Set the counter to 75+25=100 lines to be drawn (75 for the track, 25 for track+car)

draw_track:
    push de                 ; We save the screen-aligned value of de
    ld h,d
    ld l,e
    ld b,0
    ld c,(iy)
    push af                 ; Save register A
    ld a, (turn_dir)
    cp 0
    jp nz, shift_track_left
    add hl,bc               ; If we veer right, add the shift to the destination ptr
    jp done_shift_track
shift_track_left:
    and a
    sbc hl,bc               ; If we veer left, substract the shift from the destination ptr

done_shift_track:
    pop af                  ; Restore register A
    ld d,h
    ld e,l                  ; de += pixel shift

draw_track_ldir
    ld h, (ix)              ; hl = pointer
    ld l, (ix+1)
    ld bc, 00040h
    ldir
    pop hl
    ld bc,$40
    add hl,bc
    ld d,h
    ld e,l                  ; de += $40 (before the ldir command)
    dec a                   ; number of lines--
    inc ix                  ; next bitmap address
    inc ix
    inc iy                  ; next turn shift
    cp 0
    jp nz, draw_track
; END DRAW TRACK

    ld hl, bitmap_car       ; Save the address of the car bitmap
    ld a, h
    ld (car_bitmap_h), a
    ld a, l
    ld (car_bitmap_l), a

    ld a, (car_bump)            ; If car_bump is set, we only draw 21
    cp 1
    jp nz, end_car_bump_adjust
    ld a, 23                    ; We only draw 21 lines instead of 23
    jp draw_track_with_car      ; as we started 2 lines down
end_car_bump_adjust:
    ld a, 25

draw_track_with_car:
    push de                 ; We save the screen-aligned value of de
    ld h,d
    ld l,e
    ld b,0
    ld c,(iy)
    push af                 ; Save register A
    ld a, (turn_dir)
    cp 0
    jp nz, shift_track_left_with_car
    add hl,bc               ; If we veer right, add the shift to the destination ptr
    jp done_shift_track_with_car
shift_track_left_with_car:
    and a
    sbc hl,bc               ; If we veer left, substract the shift from the destination ptr

done_shift_track_with_car:
    pop af                  ; Restore register A
    ld d,h
    ld e,l                  ; de += pixel shift

draw_track_ldir_with_car
    ld h, (ix)              ; hl = pointer
    ld l, (ix+1)
    ld bc, 00040h
    ldir
    pop hl                  ; Restore the screen-aligned value of DE into HL
    push hl                 ; Save it again
    push af
    ld a, (car_x)
    ld b,0
    ld c,a
    add hl,bc
    ld d,h
    ld e,l                  ; de += $6

    ld a, (car_bitmap_h)    ; Restore the car bitmap pointer into HL
    ld h, a
    ld a, (car_bitmap_l)
    ld l, a

    ld bc, 1
REPT 12
    ld a, (de)              ; a = background
    and (hl)                ; a = background & mask
    add hl, bc
    or (hl)                 ; a = (background & mask) | car
    add hl, bc
    ld (de), a
    inc e
ENDM

    ld a, h
    ld (car_bitmap_h), a    ; Save the car bitmap pointer (post ldir)
    ld a, l
    ld (car_bitmap_l), a
    pop af

    pop hl                  ; Restore the screen-aligned value of DE into HL
    ld bc,$40
    add hl,bc
    ld d,h
    ld e,l                  ; de += $40 (before the ldir command)

    dec a                   ; number of lines--
    inc ix                  ; next bitmap address
    inc ix
    inc iy                  ; next turn shift
    cp 0
    jp nz, draw_track_with_car

    ld a, (car_bump)                    ; If car_bump is set
    cp 1
    jp nz, end_car_bump_post_adjust     ; we need to update ix and iy
    inc ix                              ; for the two lines we didn't draw
    inc ix
    inc ix
    inc ix
;    inc iy
;    inc iy
end_car_bump_post_adjust:

animate_car_wheels:
    ld iy, $E641                        ; Base offset on the screen
    ld a, (frame)                       ; We use the frame count
    and $7                              ; A = frame MOD 8
    sra a
    sra a
    ld b, a                             ; B = (frame MOD 8) >> 2
;    bit 2, a
;    jp nz, animate_car_wheel_higher
;    ld b, 0
;    jp animate_car_wheel_draw
;animate_car_wheel_higher:
;    ld b, 1
;animate_car_wheel_draw:
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

    nop
    nop
    nop

    ld iy, (gear_speed_ptr)     ; iy = &gear_speed

;draw_other_car:
;    ld a, (other_car_y)
;    and $

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
    jp z, switch_gear_up
    bit 3, a
    jp z, switch_gear_down
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
;    bit 2, a
;    jp z, switch_gear_up
;    bit 3, a
;    jp z, switch_gear_down

update_track_position:
    ld b, (iy+7)                ; B = speed
    sra b
    sra b
    sra b
    and a                       ; clear carry
    ld a, (track_counter)       ; A = track counter
    add a, b
    ld (track_counter), a       ; track_counter += speed
    jp po, end_update_track_position    ; If there is no overflow, skip section
    ld a, (track_steps)
    dec a
    ld (track_steps), a            ; track_steps--
    cp 0
    jp nz, end_update_track_position    ; if track_steps > 0, skip section
    ld iy, (track_ptr)
    ld a, (iy)
    cp $FF
    jp z, game_over             ; If the track value = $FF, end of the game
    and $C0
    cp 0
    jp z, end_check_road_turn
check_turn_track_left
    cp 128
    jp nz, check_turn_track_right
    jp road_turn_left
check_turn_track_right:
    cp 64
    jp nz, end_check_road_turn
    jp road_turn_right
end_check_road_turn:
    ld a, (iy)
    and $3F
    ld (track_steps), a
    inc iy
    ld (track_ptr), iy
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
    ld de, 3089h    ; X and Y positions
    ld bc, game_won  ; Text
    call PUTSTR     ; Displays text on screen
game_over_loop:
    jp game_over_loop

;check_switch_gear:
;    ld hl, 05FF7H   ; Check if the player pushed the trigger button
;    ld a, (hl)
;    bit 7, a
;    jp nz, gear_section
switch_gear_up:
    ld a, (clutch_down)
    cp 0
    jp nz, end_check_switch_gear        ; If the clutch flag it set, do nothing

    ld a, (gear)
    cp 4
    jp z, end_check_switch_gear        ; If we're in top gear, do nothing - we're at the max

    inc a
    ld (gear), a            ; Otherwise gear++

    ld a, 1
    ld (clutch_down), a     ; We set the clutch flag
    ld (gear_refresh), a    ; We set the gear refresh flag

    ld iy, (gear_speed_ptr)     ; iy = &gear_speed

    ld a, (iy+4)
    ld b, 0
    ld c, a
    add iy, bc
    ld (gear_speed_ptr), iy     ; iy += *(iy+4)

    jp end_check_switch_gear

switch_gear_down:
    ld a, (clutch_down)
    cp 0
    jp nz, end_check_switch_gear        ; If the clutch flag it set, do nothing

    ld a, (gear)
    cp 0
    jp z, end_check_switch_gear        ; If we're in low gear, do nothing - we're at the max

    dec a
    ld (gear), a            ; Otherwise gear--

    ld a, 1
    ld (clutch_down), a     ; We set the clutch flag
    ld (gear_refresh), a    ; We set the gear refresh flag

    ld iy, (gear_speed_ptr)     ; iy = &gear_speed

    ld a, (iy+5)            ; A = offset inside gear_speed
    ld iy, gear_speed
    ld b, 0
    ld c, a
    add iy, bc
    ld (gear_speed_ptr), iy   ; iy = &gear+speed + *(iy+5)

    jp end_check_switch_gear

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
    ld hl, $F413
    call display_digit
    ld a, (iy+2)                ; a = speed high digit offset

    ld c, a                     ; bc = *(&gear_speed + gear_speed_offset)
    ld hl, digits
    ld c, a
    add hl, bc
    ld d,h
    ld e,l
    ld hl, $F414
    call display_digit
    ld a, (iy+3)                ; a = speed high digit offset

    ld c, a                     ; bc = *(&gear_speed + gear_speed_offset)
    ld hl, digits
    add hl, bc
    ld d,h
    ld e,l
    ld hl, $F415
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

;title:
;    db 20h, 20h, 20h
;    db "A FOND A FOND A FOND!", 0
;author2
;    db "Copyleft Laurent Poulain 2024", 0

turn_dir
    db 0
turn_speed
    db 0
turn_shift
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 9,8,8,8,8,8,8,7,7,7,7,7,7,6,6,6,6,6,6,6,6,5,5,5,5,5,5,5,5,5,4,4,4,4,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 17,16,16,16,15,15,14,14,13,13,13,12,12,12,11,11,11,10,10,10,10,9,9,9,9,8,8,8,8,7,7,7,7,7,6,6,6,6,6,6,5,5,5,5,5,5,5,4,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 27,26,25,25,24,23,22,21,21,20,19,19,18,18,17,16,16,15,15,14,14,13,13,13,12,12,11,11,11,10,10,10,9,9,9,8,8,8,8,7,7,7,7,6,6,6,6,6,5,5,5,5,5,5,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1

turn_shift_ptr  db 0, 0

car_bump    db 0
car_x       db $16
car_bitmap_h    db 0
car_bitmap_l    db 0
dist        db 10
frame       db 12
bg_shift    db 0
other_car_y     db 10
other_car_iy    db 0, 0
seconds_low     db 0
seconds_high    db 0
minutes_low     db 0
minutes_high    db 0
time_counter    db FPS
track_counter   db 0
track_steps     db 10

game_won:
    db "GAME OVER"

gear
    db 0
clutch_down
    db 0

gear_rpm
    db 16

gear_refresh
    db 0

gear_speed_offset
    db 0

gear_speed_ptr
    db 0, 0

gear_speed
    ; All 8 RPM positions (8x8 = 64 values) for all 5 gears (one gear per line)
    ; For each RPM position:
    ; byte #0: RPM (div 1000)
    ; byte #1: speed top digit (base 10)
    ; byte #2: speed middle digit (base 10)
    ; byte #3: speed low digit (base 10)
    ; byte #4: gear_speed shift when switching to a higher gear (e.g. +64 to)
    ; byte #5: gear_speed offset when switching to a lower gear (this is because sub or sbc don't work with iy)
    ; byte #6: acceleration
    ; byte #7: speed (in binary)
;    db 1,0,5,0,64,0,2,10,     2,0,10,0,56,0,4,20,   3,0,15,0,48,0,8,30,   4,0,20,0,40,0,8,40,   5,0,20,25,32,0,4,45,    6,0,25,0,24,0,2,50,   7,0,25,25,16,0,1,55,      8,0,30,0,16,0,0,60
;    db 1,0,25,0,64,40,0,50,   2,0,30,0,56,56,4,60,  3,0,35,0,48,56,8,70,  4,0,40,0,40,56,8,80,  5,0,40,25,32,56,4,85,   6,0,45,0,24,56,2,90,  7,0,45,25,16,56,1,95,     8,5,0,0,16,56,0,100
;    db 1,0,45,0,64,104,0,90,  2,5,0,0,56,120,4,100, 3,5,5,0,48,120,8,110, 4,5,10,0,40,120,8,120,5,5,10,25,32,120,4,125, 6,5,15,0,24,120,2,130,7,5,15,25,16,120,1,135,   8,5,20,0,16,120,0,140
;    db 1,5,15,0,64,168,0,130, 2,5,20,0,56,184,4,140,3,5,25,0,48,184,8,150,4,5,30,0,40,184,8,160,5,5,30,25,32,184,4,165, 6,5,35,0,24,184,2,170,7,5,35,25,16,184,1,175,   8,5,40,0,16,184,0,180
;    db 1,5,35,0,0,232,0,170,  2,5,40,0,0,248,4,180, 3,5,45,0,0,248,8,190, 4,10,0,0,0,248,8,200, 5,10,0,25,0,248,4,205,  6,10,5,0,0,248,2,210, 7,10,5,25,0,248,1,215,    8,10,10,0,0,248,0,220
    db 1,0,5,0,0,0,8,10,  2,0,10,0,0,0,8,20,  3,0,15,0,0,0,8,30,  4,0,20,0,40,0,8,40,  5,0,25,0,40,0,4,50,  6,0,30,0,40,0,2,60,  7,0,35,0,40,0,1,70,  8,0,40,0,40,0,0,80
    db 1,0,20,0,0,24,0,40,  2,0,25,0,0,32,4,50,  3,0,30,0,0,40,8,60,  4,0,35,0,40,48,8,70,  5,0,40,0,40,56,4,80,  6,0,45,0,40,56,2,90,  7,5,0,0,40,56,1,100,  8,5,5,0,40,56,0,110
    db 1,0,35,0,0,88,0,70,  2,0,40,0,0,96,4,80,  3,0,45,0,0,104,8,90,  4,5,0,0,40,112,8,100,  5,5,5,0,40,120,4,110,  6,5,10,0,40,120,2,120,  7,5,15,0,40,120,1,130,  8,5,20,0,40,120,0,140
    db 1,5,0,0,0,152,0,100,  2,5,5,0,0,160,4,110,  3,5,10,0,0,168,8,120,  4,5,15,0,40,176,8,130,  5,5,20,0,40,184,4,140,  6,5,25,0,40,184,2,150,  7,5,30,0,40,184,1,160,  8,5,35,0,40,184,0,170
    db 1,5,15,0,0,216,0,130,  2,5,20,0,0,224,4,140,  3,5,25,0,0,232,8,150,  4,5,30,0,0,240,8,160,  5,5,35,0,0,248,4,170,  6,5,40,0,0,248,2,180,  7,5,45,0,0,248,1,190,  8,10,0,0,0,248,0,200

track
    db 129, 129, 129, 65, 65, $FF

track_ptr   db 0, 0

bitmap_ptr
    include "afond_bitmap_ptr.asm"

    org 06000h
bitmap:
IF K7 = 0
include "rsc_afond.asm"
bitmap_bg:
include "rsc_afond_bg.asm"
bitmap_needles:
include "rsc_afond_needles.asm"
bitmap_car:
include "rsc_afond_car.asm"
include "rsc_afond_cars_others.asm"
sky
    db $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
    db $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
    db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
    db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB

bitmap_gauge
    db 0,0,0,0,255,255,0,0,0,0,0,0,0,255,0,3,255,0,0,0
    db 0,0,240,3,0,3,192,15,0,0,0,0,15,12,0,3,48,240,0,0
    db 0,192,0,12,0,0,48,0,3,0,0,48,0,0,0,3,0,0,12,0
    db 0,60,0,48,0,3,12,0,60,0,0,195,3,48,0,0,12,192,195,0
    db 192,0,0,0,0,0,0,0,0,3,192,0,48,0,0,0,0,12,0,3
    db 48,0,0,0,0,0,0,0,0,12,48,0,0,0,0,0,0,0,0,4
    db 204,3,0,0,0,0,0,0,64,17,12,240,0,0,0,0,0,0,15,16
    db 12,0,0,0,0,0,0,0,0,16,12,0,0,0,0,0,0,0,0,16
    db 3,0,0,0,0,0,0,0,0,64,3,0,0,0,0,0,0,0,0,64
    db 3,0,0,0,0,0,0,0,0,64,255,60,0,0,0,0,0,0,60,85
    db 3,0,0,0,0,0,0,0,0,64,3,0,0,0,0,0,0,0,0,64
    db 3,0,0,0,0,0,0,0,0,64,3,0,0,0,0,0,0,0,0,64
    db 12,240,0,0,192,3,0,0,15,16,12,3,0,0,240,15,0,0,64,16
    db 240,0,0,0,240,15,0,0,0,5,0,0,0,0,192,3,0,0,0,0

bitmap_gearbox_icon
    db $00,$FF,$00
    db $F0,$00,$0F
    db $0C,$00,$30
    db $CC,$30,$3C
    db $C3,$30,$CC
    db $C3,$30,$CC
    db $C3,$FF,$CF
    db $C3,$30,$C0
    db $CC,$30,$30
    db $0C,$00,$30
    db $F0,$00,$0F
    db $00,$FF,$00

digits
    db 12,51,51,51,12
    db 12,15,12,12,63
    db 12,51,48,12,63
    db 15,48,12,48,15
    db 48,12,03,63,12
    db 63,03,12,48,15
    db 60,03,15,51,12
    db 63,48,48,12,12
    db 12,51,12,51,12
    db 12,51,60,48,15

ENDIF
    END
