all: bin/henon1.K7 bin/henon2.K7 bin/henon2.bin bin/henon1.bin bin/afond.bin bin/afond.k7

bin/henon1.K7: henon1_k7.bin rsc_henon1.bin
	python create_k7.py 1

bin/henon2.K7: henon2_k7.bin rsc_henon2.bin
	python create_k7.py 2

rsc_henon1.bin: rsc_henon1.asm
	pasmo.exe rsc_henon1.asm rsc_henon1.bin

henon1_tilemap.asm: henon1.tmx
	python create_tilemap.py

rsc_henon2.bin: rsc_henon2.asm
	pasmo.exe rsc_henon2.asm rsc_henon2.bin

henon1_k7.bin: henon1.asm henon1_tilemap.asm
	pasmo.exe -E K7=1 henon1.asm henon1_k7.bin

henon2_k7.bin: henon2.asm
	pasmo.exe -E K7=1 henon2.asm henon2_k7.bin

bin/henon1.bin: henon1.asm rsc_henon1.asm henon1_tilemap.asm
	pasmo.exe -E K7=0 henon1.asm bin/henon1.bin

bin/henon2.bin: henon2.asm rsc_henon2.asm
	pasmo.exe -E K7=0 henon2.asm bin/henon2.bin

hello.bin: hello.asm rsc.asm
	pasmo.exe hello.asm hello.bin

bin/olipix.bin: olipix.asm
	pasmo.exe olipix.asm bin/olipix.bin

bin/afond.bin: afond.asm rsc_afond.asm rsc_afond_bg.asm afond_bitmap_ptr.asm afond_upper_ram.asm afond_lower_ram.asm
	pasmo.exe -E K7=0 afond.asm bin/afond.bin afond.sym

afond_k7.bin: afond.asm rsc_afond.asm rsc_afond_bg.asm afond_bitmap_ptr.asm afond_upper_ram_include.asm afond_lower_ram.asm
	pasmo.exe -E K7=1 afond.asm afond_k7.bin afond_k7.sym

afond_upper_ram_include.asm: afond_upper_ram.asm rsc_afond.asm rsc_afond_bg.asm rsc_afond_needles.asm afond_bitmap_ptr.asm
	pasmo.exe afond_upper_ram.asm afond_upper_ram.bin afond_upper_ram_include.asm

bin/afond.k7: afond_k7.bin afond_upper_ram.bin
	python create_k7.py 3
