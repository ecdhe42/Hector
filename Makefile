all: henon1.K7 henon2.K7 henon2.bin henon1.bin afond.bin

henon1.K7: henon1_k7.bin rsc_henon1.bin
	python create_k7.py 1

henon2.K7: henon2_k7.bin rsc_henon2.bin
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

henon1.bin: henon1.asm rsc_henon1.asm henon1_tilemap.asm
	pasmo.exe -E K7=0 henon1.asm henon1.bin

henon2.bin: henon2.asm rsc_henon2.asm
	pasmo.exe -E K7=0 henon2.asm henon2.bin

hello.bin: hello.asm rsc.asm
	pasmo.exe hello.asm hello.bin

olipix.bin: olipix.asm
	pasmo.exe olipix.asm olipix.bin

afond.bin: afond.asm rsc_afond.asm rsc_afond_bg.asm afond_bitmap_ptr.asm
	pasmo.exe -E K7=0 afond.asm afond.bin
