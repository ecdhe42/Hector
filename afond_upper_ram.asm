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


end_upper_ram
