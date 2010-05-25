DMD = dmd

DFLAGS         = -Isrc -version=Unicode -version=WindowsVista -op -w
DFLAGS_DEBUG   = -debug -g -gc -unittest
DFLAGS_RELEASE = -release -inline -O -L/exet:nt/su:windows:4.0

PROGRAM = kaiko.exe

LIBS = $(shell find lib -name "*.lib")
SRCS = $(shell find src/kaiko -name "*.d") src/main.d

.PHONY: debug release clean

first: debug

debug: build\debug\$(PROGRAM)
	./build/debug/$(PROGRAM)

release: build\release\$(PROGRAM)

build\debug\$(PROGRAM): $(SRCS) $(LIBS)
	$(DMD) $(SRCS) $(LIBS) $(DFLAGS) $(DFLAGS_DEBUG) -of$@

build\release\$(PROGRAM): $(SRCS) $(LIBS)
	$(DMD) $(SRCS) $(LIBS) $(DFLAGS) $(DFLAGS_RELEASE) -of$@

clean:
	rm -rf build
	find . -name "*.def" -or -name "*.log" -or -name "*.lst" -or -name "*.map" -or -name "*~" | xargs rm -f
