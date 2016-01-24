# On Windows, to build with the experimental Windows UI (not recommended):
#
#       make WINDOWS_UI=1
#
# Otherwise just:
#
#       make
#
# should do it, on both Windows and Linux.

# Tested with GNU Make 4.0, gcc 5.2.1 and clang 3.6.2 on Linux (Ubuntu).
# Tested with GNU Make 3.81, gcc (tdm64-1) 5.1.0 and clang 3.7.1 on Windows 10.
# NASM 2.11.08 on Windows, 2.11.05 on Linux.
# No support in this makefile for Microsoft tools.

VERSION = `git describe --tags`

CC = clang

CFLAGS = --std=c99 -D_GNU_SOURCE -g -m64
ASMFLAGS =
LINKFLAGS = -m64

OBJS = main.o os.o terminal.o backtrace.o forth.o

ifeq ($(OS),Windows_NT)
	CFLAGS += -DWIN64 -DWIN64_NATIVE
	ASMFLAGS += -DWIN64 -DWIN64_NATIVE
	FELINE_EXE = feline.exe
	FORTH_EXE = forth.exe
	FELINE_HOME_EXE = feline_home.exe
else
	FELINE_EXE = feline
	FORTH_EXE = forth
	FELINE_HOME_EXE = feline_home
endif

ifeq ($(OS),Windows_NT)
ifdef WINDOWS_UI
	CFLAGS += -DWINDOWS_UI
	ASMFLAGS += -DWINDOWS_UI
	LINKFLAGS += -mwindows
	OBJS += windows-ui.o winkey.o
endif
endif

$(FELINE_EXE):  $(OBJS)
	$(CC) $(LINKFLAGS) $(OBJS) -o $(FELINE_EXE)

feline_home.asm: $(FELINE_HOME_EXE)
	./feline_home

$(FELINE_HOME_EXE): feline_home.c
	$(CC) feline_home.c -o $(FELINE_HOME_EXE)

version.asm:
	echo "%define VERSION \"$(VERSION)\"" > version.asm

main.o:	forth.h windows-ui.h main.c Makefile
	$(CC) $(CFLAGS) -c -o main.o main.c

os.o:	forth.h os.c Makefile
	$(CC) $(CFLAGS) -c -o os.o os.c

terminal.o: forth.h windows-ui.h terminal.c Makefile
	$(CC) $(CFLAGS) -c -o terminal.o terminal.c

backtrace.o: forth.h backtrace.c Makefile
	$(CC) $(CFLAGS) -c -o backtrace.o backtrace.c

windows-ui.o: forth.h windows-ui.h windows-ui.c Makefile
	$(CC) $(CFLAGS) -c -o windows-ui.o windows-ui.c

winkey.o: forth.h windows-ui.h winkey.c Makefile
	$(CC) $(CFLAGS) -c -o winkey.o winkey.c

ASM_SOURCES = forth.asm feline_home.asm version.asm equates.asm macros.asm inlines.asm \
	align.asm \
	ansi.asm \
	arith.asm \
	branch.asm \
	bye.asm \
	cold.asm \
	compiler.asm \
	constants.asm \
	dictionary.asm \
	dot.asm \
	double.asm \
	exceptions.asm \
	execute.asm \
	fetch.asm \
	find.asm \
	include.asm \
	interpret.asm \
	io.asm \
	locals.asm \
	loop.asm \
	memory.asm \
	number.asm \
	objects.asm \
	opt.asm \
	parse.asm \
	quit.asm \
	stack.asm \
	store.asm \
	string.asm \
	strings.asm \
	tools.asm \
	value.asm

# -felf64 even on Windows
forth.o: $(ASM_SOURCES) Makefile
	nasm $(ASMFLAGS) -g -felf64 forth.asm

# Microsoft compiler and linker
# main.obj: main.c
# 	cl -Zi -c $(CFLAGS) main.c

# forth.obj: $(ASM_SOURCES)
# 	nasm $(ASMFLAGS) -g -fwin64 forth.asm

# forth.exe: main.obj forth.obj
# 	link /subsystem:console /machine:x64 /largeaddressaware:no forth.obj  main.obj /out:forth.exe

clean:
	-rm -f forth
	-rm -f forth.exe
	-rm -f feline
	-rm -f feline.exe
	-rm -f main.o*
	-rm -f os.o*
	-rm -f terminal.o*
	-rm -f forth.o*
	-rm -f feline_home.asm feline_home.exe feline_home
	-rm -f version.h version.asm

zip:
	-rm -f feline.zip
	zip feline.zip *.c *.h *.asm *.forth benchmarks/*.forth benchmarks/*.c tests/*.forth Makefile
