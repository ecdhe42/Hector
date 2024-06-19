all: hello.bin hello.K7 henon2.bin henon1.bin

rsc.asm: test.raw
	python convert.py

hello.bin: hello.asm rsc.asm
	pasmo.exe hello.asm hello.bin

henon1.bin: henon1.asm rsc_henon1.asm
	pasmo.exe henon1.asm henon1.bin

henon2.bin: henon2.asm rsc_henon2.asm
	pasmo.exe henon2.asm henon2.bin

rsc.bin: rsc.asm
	pasmo.exe rsc.asm rsc.bin

olipix.bin: olipix.asm
	pasmo.exe olipix.asm olipix.bin

hello.K7: olipix.bin rsc.bin
	python create_k7.py
