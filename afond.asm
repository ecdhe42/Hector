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
    ld (hl), 10h    ; color0 = 0 (black), color2 = 2 (green)
    ld hl, 01800h
    ld (hl), 39h    ; color1 = 1 (red), color3 = 7 (white)

    ld ix, bitmap_ptr

    ld a, 3                         ; Set track speed of 3 frames
    ld (frame), a

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

; ######################################################################################

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

    ld a, 100                       ; Set the counter to 100 lines to be drawn (track)
    ld hl, bitmap+$1900
    ld de, 0D000h
    ld iy, (turn_shift_ptr)

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

    ld bc,800               ; Speed of the track
    add ix,bc

    ld a, (frame)           ; Count the # of frames
    dec a                   ; for the track layout
    ld (frame), a
    cp 0
    jp nz, draw_frame

    ld ix, bitmap_ptr       ; Resets the track layout
    ld a, 3
    ld (frame), a

    ; Check joystick
    ld hl, 03807h
    ld a, (hl)
    cp $ff
    jp z, draw_frame        ; If no joystick, draw next frame

    bit 0, a                ; Check if joystick goes left
    jp z, move_left
    bit 1, a
    jp z, move_right    

    jp draw_frame


move_left:
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
    jp z, draw_frame            ; then don't do anything

    inc a
    ld (turn_speed), a          ; turn_speed++

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    add hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr += 100

    jp draw_frame
turn_less_right:
    ld a, (turn_speed)
    dec a
    ld (turn_speed), a

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    sbc hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr -= 100

    jp draw_frame


move_right:
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
    jp z, draw_frame            ; then don't do anything

    inc a
    ld (turn_speed), a          ; turn_speed++

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    add hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr += 100

    jp draw_frame
turn_less_left:
    ld a, (turn_speed)
    dec a
    ld (turn_speed), a          ; turn_speed--

    and a   ; Clear carry flag
    ld hl, (turn_shift_ptr)
    ld bc, 100
    sbc hl, bc
    ld (turn_shift_ptr), hl     ; turn_shift_ptr -= 100

    jp draw_frame


title:
    db 20h, 20h, 20h
    db "A FOND A FOND A FOND!", 0
author2
    db "Copyleft Laurent Poulain 2024", 0

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

dist        db 10
frame       db 12
bg_shift    db 0

sky
    db $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
    db $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE
    db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
    db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB

bitmap_ptr
    include "afond_bitmap_ptr.asm"

    org 06000h
bitmap:
IF K7 = 0
include "rsc_afond.asm"
bitmap_bg:
include "rsc_afond_bg.asm"
ENDIF
    END
