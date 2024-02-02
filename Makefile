CC=./fasm
CFLAGS=-dynamic-linker /lib/ld-linux-x86-64.so.2
CLIBS=-lc -lncurses
CLEAR=*.o *.dump main
TARGET=ttyper
OBJ=ttyper.o
.PHONY: default build run dump hex

default: build

build: ttyper.asm
	$(CC) ttyper.asm
	ld ttyper.o $(CLIBS) $(CFLAGS) -o $(TARGET)

run: build $(TARGET)
	./$(TARGET)

dump: build $(TARGET)
	objdump -S -M intel $(TARGET) > $(TARGET).dump

hex: build $(TARGET)
	hexedit $(TARGET)

clean:
	rm -f $(TARGET) $(CLEAR)
