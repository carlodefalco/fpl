OCTFILES := array_to_uint8.oct

all: $(OCTFILES)

%.oct:  %.cc
	mkoctfile $<

clean:
	-rm -f *.o core octave-core *.oct *~
