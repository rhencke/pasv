#
#	*************************************************
#	*						*
#	*	     The Pascal-F Verifier 		*
#	*						*
#	*	    Theorem Prover - Pass 4		*
#	*						*
#	*						*
#	*************************************************  }
#
#{
#	Permission is hereby given to modify or use, but not for profit,
#	any or all of this program provided that this copyright notice 
#	is included:
#
#	Copyright 1985
#
#		Ford Motor Company
#		The American Road
#		Dearborn, Michigan  48121
#
#	This work was supported by the Long Range Research Program of
#	the Ford Motor Company, and was carried out at Ford Scientific
#	Research Labs in Dearborn, Michigan and Ford Aerospace and
#	Communications Corporation's Western Development Laboratories
#	in Palo Alto, California.
#}
#
#					Version 2.26 of 2/24/86
#
#	pasver4  --  the simplifier
#
SOURCE = ..
DEST=../bin
PASS4 = $(SOURCE)/cpc4/src
LISPINCL=/usr/local/src/cmd/lisp/franz/h
#
#	make 			with no arguments makes pasver4
#	make install		makes and installs pasver4
#

# default rules
l = liszt
.SUFFIXES:
.SUFFIXES: .o .l
.l.o: ; $l $*.l

o =          debug.o defmac.o e.o enode.o hunkshell.o main.o map.o pform.o \
	     pp.o princ.o setup.o ruleprep.o z.o ze.o need.o pipeopen.o \
	     timer.o newsplit.o newsimp.o normalize.o builtin.o eventtran.o \
	     type.o typee.o eform.o generic.o

all:	     pasver4
install:     pasver4
	     -rm -f $(DEST)/pasver4.old
	     -mv $(DEST)/pasver4 $(DEST)/pasver4.old
	     ln pasver4 $(DEST)
obj:         $o 

source:      debug.l defmac.l e.l enode.l hunkshell.l map.l pform.l pp.l \
             princ.l setup.l ruleprep.l z.l ze.l main.l need.l pipeopen.c \
	     makemono.l match.l progvn.l newsplit.l \
	     newsimp.l normalize.l builtin.l eventttran.l type.l typee.l \
	     eform.l generic.l

# monolithic simplifier made by dumping lisp
pasver4:     $o makemono.l fixes.l
	     rm -f pasver4
	     lisp <makemono.l
	     chmod 555 pasver4
#
#	Run regression test
#
regress:     pasver4 tests.l traceaids.l
	     sh echo "(load 'traceaids.l) (load 'tests.l) (runtests)" | pasver4	 
timer.o:     timer.l defmac.o princ.o need.o

debug.o:     debug.l defmac.o need.o

defmac.o:    defmac.l

e.o:         e.l defmac.o hunkshell.o enode.o debug.o princ.o map.o need.o

enode.o:     enode.l defmac.o hunkshell.o need.o

hunkshell.o: hunkshell.l

main.o:      main.l defmac.o map.o need.o

newsplit.o:  hunkshell.o need.o match.o

map.o:       map.l defmac.o need.o

need.o:      need.l

pform.o:     pform.l defmac.o map.o need.o

pp.o:        pp.l princ.o need.o

princ.o:     princ.l defmac.o need.o

setup.o:     setup.l

newsimp.o:    newsimp.l enode.o princ.o map.o need.o progvn.o match.o

normalize.o: normalize.l need.o defmac.o progvn.o match.o

builtin.o:    builtin.l need.o defmac.o enode.o hunkshell.o

generic.o:    generic.l need.o defmac.o enode.o hunkshell.o

ruleprep.o:    ruleprep.l princ.o map.o need.o

z.o:         z.l defmac.o hunkshell.o enode.o debug.o princ.o need.o

ze.o:        ze.l enode.o debug.o princ.o map.o need.o

eventtran.o: eventtran.l

type.o:     type.l

typee.o:     typee.l defmac.o hunkshell.o enode.o need.o

eform.o:     eform.l defmac.o hunkshell.o enode.o debug.o princ.o map.o need.o

pipeopen.o:  pipeopen.c ccvms.sh
	     sh ccvms.sh -c -I$(LISPINCL) pipeopen.c

# SCCS dependencies
defmac.l:    $(PASS4)/s.defmac.l; get $(PASS4)/s.defmac.l
debug.l:     $(PASS4)/s.debug.l; get $(PASS4)/s.debug.l
e.l:         $(PASS4)/s.e.l; get $(PASS4)/s.e.l
enode.l:     $(PASS4)/s.enode.l; get $(PASS4)/s.enode.l
eform.l:     $(PASS4)/s.eform.l; get $(PASS4)/s.eform.l
hunkshell.l: $(PASS4)/s.hunkshell.l; get $(PASS4)/s.hunkshell.l
map.l:       $(PASS4)/s.map.l; get $(PASS4)/s.map.l
pform.l:     $(PASS4)/s.pform.l; get $(PASS4)/s.pform.l
pp.l:        $(PASS4)/s.pp.l; get $(PASS4)/s.pp.l
princ.l:     $(PASS4)/s.princ.l; get $(PASS4)/s.princ.l
setup.l:     $(PASS4)/s.setup.l; get $(PASS4)/s.setup.l
newsimp.l:    $(PASS4)/s.newsimp.l; get $(PASS4)/s.newsimp.l
ruleprep.l:    $(PASS4)/s.ruleprep.l; get $(PASS4)/s.ruleprep.l
z.l:         $(PASS4)/s.z.l; get $(PASS4)/s.z.l
ze.l:        $(PASS4)/s.ze.l; get $(PASS4)/s.ze.l
need.l:      $(PASS4)/s.need.l; get $(PASS4)/s.need.l
main.l:      $(PASS4)/s.main.l; get $(PASS4)/s.main.l
newsplit.l:  $(PASS4)/s.newsplit.l; get $(PASS4)/s.newsplit.l
makemono.l:  $(PASS4)/s.makemono.l; get $(PASS4)/s.makemono.l
match.l:     $(PASS4)/s.match.l; get $(PASS4)/s.match.l
progvn.l:    $(PASS4)/s.progvn.l; get $(PASS4)/s.progvn.l
timer.l:     $(PASS4)/s.timer.l; get $(PASS4)/s.timer.l
normalize.l: $(PASS4)/s.normalize.l; get $(PASS4)/s.normalize.l
builtin.l:    $(PASS4)/s.builtin.l; get $(PASS4)/s.builtin.l
generic.l:    $(PASS4)/s.generic.l; get $(PASS4)/s.generic.l
eventtran.l:    $(PASS4)/s.eventtran.l; get $(PASS4)/s.eventtran.l
type.l:    $(PASS4)/s.type.l; get $(PASS4)/s.type.l
typee.l:    $(PASS4)/s.typee.l; get $(PASS4)/s.typee.l
pipeopen.c:  $(PASS4)/s.pipeopen.c; get $(PASS4)/s.pipeopen.c
ccvms.sh:  $(PASS4)/s.ccvms.sh; get $(PASS4)/s.ccvms.sh

traceaids.l:    $(PASS4)/s.traceaids.l; get $(PASS4)/s.traceaids.l
tests.l:    $(PASS4)/s.tests.l; get $(PASS4)/s.tests.l
fixes.l:    $(PASS4)/s.fixes.l; get $(PASS4)/s.fixes.l
