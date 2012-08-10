OCTFILES := __array_to_uint8__.oct
MKOCTFILE ?= mkoctfile
all: $(OCTFILES)

%.oct:  %.cc
	$(MKOCTFILE) $<

clean:
	-rm -f *.o core octave-core *.oct *~
