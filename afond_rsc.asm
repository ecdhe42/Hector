bitmap:
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
