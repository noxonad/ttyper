CC=./fasm
CFLAGS=-Wall -O3
CLIBS=-lncurses
CLEAR=*.o *.dump main
TARGET=ttyper
OBJ=ttyper.o
.PHONY: default build run dump hex

default: build

build: ttyper.asm
	$(CC) ttyper.asm
	gcc $(CFLAGS) $(CLIBS) $(OBJ) -o $(TARGET)

run: build $(TARGET)
	./$(TARGET)

dump: build $(TARGET)
	objdump -S -M intel $(TARGET) > $(TARGET).dump

hex: build $(TARGET)
	hexedit $(TARGET)

clean:
	rm -f $(TARGET) $(CLEAR)
