
#
#	Make file for support routines for verifier
#
#	Nothing here is required for normal operation of the Verifier
#
#				Version 1.4 of 3/3/86
SOURCE=..
BINSRC=$(SOURCE)/util/src
all: regress vertest
#
#	Utilities for regression testing
#
regress: regress.sh
	rm -f regress
	ln regress.sh regress
	chmod 555 regress
vertest: vertest.sh
	rm -f vertest
	ln vertest.sh vertest
	chmod 555 vertest
#
#	SCCS dependencies
#
regress.sh: $(BINSRC)/s.regress.sh ; get $(BINSRC)/s.regress.sh
vertest.sh: $(BINSRC)/s.vertest.sh ; get $(BINSRC)/s.vertest.sh
