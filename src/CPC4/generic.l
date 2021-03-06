;
;	Generic Functions
;
;	Generic functions are functions whose semantics are type-dependent.
;
(declare
  (load 'need.o) (load 'defmac.o) (load 'hunkshell.o) (load 'enode.o))
(declare (special
	dalltruedef
	boolsymand
	boolsymeq
	boolsymimplies
	boolsymnot
	boolsymor
	booleantype
	universaltype
	))
;
;	dalltruedef  --  demon for alltrue
;
;
;	if n is boolean
;	    (alltrue! n) == X 
;	if n is array
;	    (alltrue! n) == (allarraytrue! n lowboundofx highboundofx)
;	if n is record
;	    (alltrue! n) == (and! (alltrue! (selectr! n field1)) ...)
;
;	Note that the forms more complex than the original are asserted with
;	propagate, while those less complex are asserted with emerge.
;	In the case of records, we have no other choice, because
;	we cannot emerge forms containing propositional operators.
;	For simple variables and arrays, the choice is made to optimize
;	performance.
;
;	There is no danger of looping here because the generated forms
;	always have simpler types than the input form, so eventually
;	the process must terminate.
;
(defunobj dalltruedef (node matchlist lab pattern)
  (prog (n ntype)
	(and (dtwait 'dalltruedef node matchlist lab pattern) (return)) ; typ ck
	(setq n (cdr (assq 'n matchlist)))
	(setq ntype (getdatatype n))		; type of n
	(cond ((eq (car ntype) (car booleantype)) ; if boolean
	       (emerge node (enode n))		; node = n
	       (return))			; done
	      ((and (eq (car ntype) 'array)	; if array
		    (eq (caadr ntype) 'subrange); and subscript subrange
		    (cadadr ntype)		; and low bound nonnil
		    (caddadr ntype))		; and high bound nonnil
	       (propagate (list boolsymeq node	; node = arraytrue(node lo hi)
				(list 'arraytrue! 
				      n
				      (cadadr ntype)
				      (caddadr ntype))))
	       (return))
	      ((eq (car ntype) 'record)		; if record, big conjunction
	       (propagate 			
		(booleanequality node
				 (conjunction
				  (mapcar
				   '(lambda (term)
					    (list 'alltrue!
						  (list 'selectr! n (car term))
						  )
					    )
				   (cddr ntype)))))	; list of fields
	       (return))
	      (t (return))			; otherwise no semantics
	      )))
;
;	conjunction  --  form conjunction of list of terms
;
(defun conjunction (lst)
	(cond ((null lst) 'true)		; true if none
	      ((null (cdr lst))			; if last elt
	       (car lst))			; just element
	      (t (list boolsymand 		; otherwise build conjunction
		       (car lst) 
		       (conjunction (cdr lst)))))) ; otherwise recurse
;
;	dalltrueselect  --  alltrue of select of record/array
;
;	If the entire object is defined, then any portion of it is defined.
;
;	alltrue(x) implies alltrue(selectr(x))
;	alltrue(x) implies alltrue(selecta(x))
;
(defunobj dalltrueselect (node matchlist lab pattern)
  (prog (a i)
	(setq a (cdr (assq 'a matchlist)))
	(setq i (cdr (assq 'i matchlist)))
	(propagate 
	    (list 'boolsymimplies
		(list 'alltrue! a)
		node))
	))
;
;	initialization
;
(defun initgeneric null
  (makedemon '(alltrue! n) dalltruedef '(n))
  (makedemon '(alltrue! (selectr! a i)) dalltrueselect '(a i))
  (makedemon '(alltrue! (selecta! a i)) dalltrueselect '(a i))
  )
