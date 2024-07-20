    org 06000h
bitmap:
include "rsc_afond.asm"
bitmap_bg:
include "rsc_afond_bg.asm"
bitmap_needles:
include "rsc_afond_needles.asm"
bitmap_ptr:
include "afond_bitmap_ptr.asm"
car_x_bump
    ; Given the value of car_x, what's the value of car_bump
    db 1,1,1,1,1,1, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 1,1,1,1,1,1,1,1
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

end_upper_ram
