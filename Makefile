
CC = gcc
CCFLAGS = -O3 -std=c11 -Wall -Werror -march=native -mtune=native -mavx -fuse-ld=mold -g
CCLIBS = -lcrypto -lssl -lsodium

ASM=src/asm/tuned/6_delayed.s

all_targets: bench example_poly1163 example_chacha_poly1163

clean:
	rm -rf ./build

bench: bench/bench.c src/chacha20_poly1163.c src/poly1163.c $(ASM) src/asm/chacha20.s
	mkdir -p build
	$(CC) $(CCFLAGS) bench/bench.c src/chacha20_poly1163.c src/poly1163.c $(ASM) src/asm/chacha20.s -o build/$@ $(CCLIBS)  -DDELAYED=4


example_poly1163: examples/example_poly1163.c src/poly1163.c $(ASM)
	mkdir -p build
	$(CC) $(CCFLAGS) examples/example_poly1163.c src/poly1163.c $(ASM) -o build/$@ $(CCLIBS)  -DDELAYED=4

example_chacha_poly1163: examples/example_chacha20_poly1163.c src/chacha20_poly1163.c src/poly1163.c $(ASM) src/asm/chacha20.s
	mkdir -p build
	$(CC) $(CCFLAGS) examples/example_chacha20_poly1163.c src/chacha20_poly1163.c src/poly1163.c $(ASM) src/asm/chacha20.s -o build/$@ $(CCLIBS)  -DDELAYED=4
