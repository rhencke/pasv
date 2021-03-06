.H 1 "Appendices"
.AL
.LI
Restrictions and limitations
.LI
Reporting trouble
.LI
Acknowledgements
.LI
References
.LE
.H 2 "Restrictions and limitations"
This release of the system is the first release, and while we have taken
extensive precautions against unsoundness we cannot at this time
make strong statements about the validity of the verifications.
A number of features are unimplemented or implemented with restrictions;
however, none of these limitations affect soundness.
.H 3 "Unimplemented features"
The system is faithful to this manual except as noted below.
.BL
.LI
Fixed point arithmetic is unimplemented.
.LI
The SUMMARY statement is not implemented.
.LI
Arrays with negative lower bounds are prohibited.
.LI
Variant records are unimplemented.
.LI
Arrays with Boolean subscripts (not elements) are prohibited.
.LI
Most set operators are unimplemented.
.LI
The built-in functions of Pascal are unimplemented.  The type coercions
.I chr
and
.I ord,
along with the Pascal-F named type coercions, are implemented.
.LI
The EFFECT declaration part is not fully implemented; EFFECT clauses
are accepted and checked but not utilized in proofs.
.LE
.H 3 "Restrictions"
.BL
.LI
Side effect detection for functions is safe, but overly restrictive.
If a function has side effects, essentially the only way it can be
used is alone in an assignment statement.  Procedures with side effects
present no problems.
.LI
The Verifier's knowledge about multiplication is weak.
Nothing prevents the user from building new rules about the 
multiplication operator, but performance would be much better if the
knowledge were built-in.
.LI
The built-in knowledge about definedness of arrays is limited; arrays
must be initialized in strictly increasing order of subscript.
However, it is possible to prove more lemmas about
.B arraytrue!
to allow more general initialization if desired.
.LI
The target machine against which the Verifier verifies is the Ford
Electronic Engine Control IV, and the 16-bit, twos complement restrictions
of that machine are enforced by the verifier.
.LI
There is no compiler code generator pass compatible with the verifier
at present, so there is no way to run Pascal-F programs containing
verification statements.  There is a Pascal-F compiler for the EEC IV,
but it is not available for distribution outside Ford.
.LE
.H 3 "Known bugs"
.H 3 "Pass 1 (Compiler pass)"
.BL
.LI
Some VALUE statements generate unexpected syntax errors.
.LI
The compiler pass is not as solid as we would like; the intermediate code
generated for some operations confuses the decompiler in pass 2, resulting
in fatal internal errors.
.LE
.H 3 "Pass 2 (Semantic analysis)"
.BL
.LI
FORWARD declarations will cause pass 2 to become confused about block
numbers and an internal check will abort the Verifier.
.LI
There is a worry that the semantics of the FOR loop exit test may not
exactly match the compilers for the case where the bounds are near to
arithmetic overflow or underflow.  The Verifier's semantics are
conservative but may not be conservative enough.
.LI
Records with only one field can create ambiguities as to whether 
a reference to a data item refers to a field or the entire record.
This can result in pass 2 internal errors.
.LE
.H 3 "Pass 3 (Path tracing)"
.BL
.LI
The optimization of verification conditions will sometimes cause a
useful term to be omitted from a hypothesis of a verification condition.
The ommitted term will be from a proof goal, and will be a mention
of a function whose arguments contain no variables needed in the proof
at that point.  A work-around for this is known.
.LE
.H 3 "Pass 4 (Simplifier)"
.BL
.LI
Rule handling is unreasonably slow in the presence of many rules applicable
to the same expression.
.LI
In at least one known case, the numeric portion of the prover fails to
find a proof for a simple formula known to be true.
.LE
.H 3 "Rule Builder"
.BL
.LI
Lemmas about nonrecursive functions are not effectively used by
the Boyer-Moore prover.  This severly limits the proof power of the
system with respect to the integers.
.LI
The manual sections on hints are inadequate.
.LE
.H 2 "Reporting trouble"
Problems with the system should be reported to the address given in
the preface.  
All trouble reports should include
copies of the files in the scratch directory, the source program,
and the error messages printed.
Before submitting the trouble report, 
the verification should be rerun with the 
.B "-d"
keyletter on.
This will rerun the
verification with all debug output turned on.
.H 2 "Acknowledgements"
Pascal-F was developed at the Ford Scientific Research Laboratories in
Dearborn, Michigan, by Dr Edward Nelson.
The Verifier is the work of
Dr. Scott Johnson,
John Nagle, 
Dr. John Privitera,
and
Dr. David Snyder, of
Ford Aerospace and Communications Corporation.
Dr. Derek Oppen consulted on the theorem prover modifications.
The assistance of 
Dr. Robert Boyer
and 
Dr. Jay Moore, 
of the University of Texas at Austin, has been very valuable,
and we are indebted to 
Dr. Steven German, of Harvard University, for his formulation of the
problem of checking for run-time errors.
Finally, I would like to thank Dr. Shaun Devlin, of the Ford Motor
Scientific Research Labs, for his faith and encouragement
over the two years of the project.
.nf

                                        John Nagle
.fi
.H 2 "References"
.VL 16 2
.LI "BOYER79"
Boyer, Robert S, and Moore, J. Strother,
.I "A Computational Logic\c"
, Academic Press, New York, 1979.
.LI "BOYER80"
Boyer and Moore, private communication.
.LI "FLOYD67"
Floyd, Robert.,
.I "Assigning Meanings to Programs\c"
, Mathematical Aspects of Computer Science,
Proc. Symp. Applied Math. Vol XIX
American Mathematical Society, Providence, R.I. 1967
.LI "GERMAN81"
German, S. M.,
.I "Verifying the Absence of Common Runtime Errors In Computer Programs\c"
, PhD Thesis, Harvard University, 1981.
.LI "HOARE74"
C.A.R. Hoare, 
.I "Monitors: An Operating System Structuring Concept\c"
, Comm. ACM 17,
pp. 549-557  (October, 1974)
.LI "OPPEN79"
Oppen, Derek,
.I "Simplification by Co-operating Decision Procedures\c"
, Computer Science Department, Stanford University, 1979.
.LI "STANFORD79"
Luckham, German, v. Henke, Karp, Milne, Oppen, Polak, Scherlis,
.I "Stanford Pascal Verifier User Manual,"
Computer Science Department,
Stanford University, 1979.
.LE
