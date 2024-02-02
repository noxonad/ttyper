# TTYper

> Still under development

Fasm terminal application to test and train your typing speed.

The application is written in [fasm](https://flatassembler.net/) and uses [ncurses](https://invisible-island.net/ncurses/) library and works for linux x86_64.

## Installation

To make the installation easier, there's a Makefile. To build the app simply run:
```console
$ make
```

Or you can manually build it:
```console
$ ./fasm ttyper.asm
$ gcc -lncurses ttyper.o -o ttyper
```

To run it you can either run it directly:
```console
$ ./ttyper
```

or via makefile:
```console
$ make run
```

## Removing

The app isn't creating files other than in the current folder, so removing the folder is enough.

If you want to delete the binaries only, run the following command:
```console
$ make clean
```
