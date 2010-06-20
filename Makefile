DMD = dmd

DFLAGS         = -Isrc -version=Unicode -version=WindowsVista -op -w -wi
DFLAGS_DEBUG   = -debug -g -gc -unittest
DFLAGS_RELEASE = -release -inline -O -L/exet:nt/su:windows:4.0

PROGRAM = kaiko.exe

SRCS      = $(shell find src/kaiko -name "*.d") src/main.d
LIBS      = $(shell find lib -name "*.lib") gdi32.lib d3d9.lib d3dx9.lib d3dx9d.lib
RESOURCES = resources/resources.res

.PHONY: debug release clean

first: debug

debug: build\debug\$(PROGRAM)
	./build/debug/$(PROGRAM)

release: build\release\$(PROGRAM)

build\debug\$(PROGRAM): $(SRCS) $(RESOURCES)
	$(DMD) $(SRCS) $(LIBS) $(RESOURCES) $(DFLAGS) $(DFLAGS_DEBUG) -of$@

build\release\$(PROGRAM): $(SRCS) $(RESOURCES)
	$(DMD) $(SRCS) $(LIBS) $(RESOURCES) $(DFLAGS) $(DFLAGS_RELEASE) -of$@

clean:
	rm -rf build
	find . -name "*.def" -or -name "*.log" -or -name "*.lst" -or -name "*.map" -or -name "*~" | xargs rm -f
