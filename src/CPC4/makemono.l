"@(#)makemono.l	2.2"
; Note: it is important that this file be run by feeding it to the
; standard input of lisp, and not by loading it.  When loading takes
; place, garbage collection is disabled.  If this file is loaded, it
; will produce a dumped version of lisp in which garbage collection
; is disabled.  That system will run for about five minutes and then
; die, announcing that it has run out of memory.

; load the simplifier
(progn
  (terpr)
  (patom '|Loading the simplifier...|)
  (terpr))
(load 'setup)

; tell the function argflags where to look for flags
(setq startarg 1)

; dump the loaded simplifier so that 'main will be top level when
; it comes back
(progn
  (setq user-top-level 'main)
  (patom '|Dumping lisp as pasver4...|)
  (terpr)
  (dumplisp pasver4)
  (patom '|Dump complete.|)
  (terpr)
  (exit 0))
