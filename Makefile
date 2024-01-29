CC=./fasm
CFLAGS=-Wall -Wextra -ggdb -O0 -Wunreachable-code
CLIBS=-lc -lncurses
OBJ=ttyper.o
TARGET=ttyper
.PHONY: default build run dump hex

default: build run

build: ttyper.asm
	$(CC) ttyper.asm
	gcc $(CLIBS) $(OBJ) -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

dump: build $(TARGET)
	objdump -S -M intel $(TARGET) > $(TARGET).dump

hex: build $(TARGET)
	hexedit $(TARGET)

clean:
	rm -f $(TARGET) $(OBJ)
