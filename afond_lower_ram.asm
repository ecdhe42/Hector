bitmap_title
    db 80,85,85,85,0,0,84,85,85,21,0,0,0,0,0,0,0,0,64,85,5,85,21
    db 208,255,255,127,1,0,245,255,255,95,0,0,0,0,0,0,0,0,64,255,71,255,95
    db 80,253,247,127,1,0,84,255,253,23,85,85,85,81,85,85,21,84,85,255,69,245,95
    db 80,255,245,95,0,0,212,127,85,21,253,255,127,81,255,255,31,245,255,255,69,255,23
    db 208,255,255,95,0,0,253,255,255,71,255,215,127,209,255,253,23,253,223,127,209,255,23
    db 84,255,253,95,0,0,213,95,85,69,245,247,127,84,127,253,23,213,223,127,81,253,7
    db 244,127,253,23,0,0,253,95,85,69,255,247,95,244,127,255,69,255,215,127,80,85,5
    db 212,127,255,23,0,64,245,95,0,80,253,255,95,212,127,255,69,245,255,95,244,255,5
    db 85,85,85,5,0,64,85,21,0,80,85,85,21,85,85,85,81,85,85,85,84,85,1
    db 84,85,85,5,0,0,85,21,0,64,85,85,21,84,85,85,65,85,85,21,84,85,1

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

turn_shift
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ; round(math.exp(line*0.023))-1
    db 9,9,8,8,8,8,7,7,7,7,7,7,6,6,6,6,6,6,5,5,5,5,5,5,5,4,4,4,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ; round(math.exp(line*0.03))-1
    db 18,18,17,17,16,16,15,15,14,14,13,13,13,12,12,11,11,11,10,10,10,9,9,9,8,8,8,8,7,7,7,7,6,6,6,6,6,5,5,5,5,5,5,4,4,4,4,4,4,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ; round(math.exp(line*0.0335))-1
    db 27,26,25,24,23,22,22,21,20,19,19,18,17,17,16,16,15,15,14,14,13,13,12,12,11,11,11,10,10,9,9,9,8,8,8,8,7,7,7,6,6,6,6,6,5,5,5,5,5,4,4,4,4,4,4,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0

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

bitmap_car:
include "rsc_afond_car.asm"

bitmap_flag:
include "rsc_afond_flag.asm"

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
