%token OTHER.IDENTIFIER string line.end zero counting.number

%token ASSIGN BEGIN BRANCH BREAK END FREEZE HANG JOIN NEW REIN RENEW
%token REOUT REQUIRE PROCLAIM SAFE SIDE SPLIT THAW WHEN

%token subrange boolean integer fixed set array record module
%token universal variable function rulefunction
%token consti1 addi1 subi1 negi1 succ1 pred1 muli1 divi1 mod1 odd1 
%token gei1 lei1 gti1 lti1 mini1 maxi1 constf1 scale1 addf1 subf1 
%token negf1 mulf1 divf1 gef1 lef1 gtf1 ltf1 minf1 maxf1 true1 
%token false1 and1 or1 not1 implies1 empty1 range1 union1 diff1 intersect1 
%token subset1 superset1 in1 equal1 notequal1 if1 defined1
%token select1 new1 
%token selecta1 selectr1 storea1 storer1
%token notimplies1 notimpliedby1 impliedby1 
%token alltrue1 arrayconstruct1 arraytrue1 emptyobject1

%%
/* yacc grammar for j-code */
start:
   j.code ;

empty :
    ;

j.code :
    j.unit.sequence ;

j.unit.sequence :
    empty | j.unit.sequence j.unit ;

j.unit :
     BEGIN unit.name line.end
     declaration.part statement.part END line.end ;

unit.name :
    identifier ;

declaration.part :
    declaration.sequence break.statement ;

declaration.sequence :
    empty | declaration.sequence declaration ;

declaration :
    variable.name ':'  form line.end | error line.end ;

/* The following productions are used to specify the allowed order
 * of J-statements.  Two kinds of order checking go on at the same
 * time.  A finite state machine is used to ensure that a J-unit 
 * consists of a series of blocks that begin with a catch statement
 * and end in a throw.statement.  The machine has two states: A and B.
 *
 *                             throw statement
 *                          +------------------+
 *                          |                  |
 *  +------------------ \   |                  V
 *  |                     \
 *  +-------------------->  A                  B
 *    simple statement
 *                          ^                  |
 *                          |                  |
 *                          +------------------+
 *                             catch statement
 *
 * Every J-unit begins with a break statement, which puts the machine into
 * state A.  When the unit ends, it must be in state B.
 *
 * The other order constraint is that the rein, renew, and reout statements
 * must be balanced in the same fashion as if-then-fi in Algol.  What makes
 * all this tricky is that although renew statements can only occur in state
 * A, rein and reout statements can occur in any state, and do not change
 * the state.
 *
 * We express these constraints in a Yacc grammar by writing rules for
 * four variables, each of the form x.bal.y, where x and y may each be
 * A or B.  The meaning of "x.bal.y" is a sequence of statements that
 * are balanced with respect to rein, renew, and reout, and change the
 * finite state machine from state x to state y.
 */

statement.part :
    A.bal.B ;

A.bal.A :
    empty |
    A.bal.A simple.statement |
    A.bal.B catch.statement |
    A.bal.A rein.statement A.bal.A renew.statement A.bal.A reout.statement |
    A.bal.B rein.statement B.bal.A renew.statement A.bal.A reout.statement ;

B.bal.A :
    B.bal.A simple.statement |
    B.bal.B catch.statement |
    B.bal.A rein.statement A.bal.A renew.statement A.bal.A reout.statement |
    B.bal.B rein.statement B.bal.A renew.statement A.bal.A reout.statement ;

A.bal.B :
    A.bal.A throw.statement |
    A.bal.A rein.statement A.bal.A renew.statement A.bal.B reout.statement |
    A.bal.B rein.statement B.bal.A renew.statement A.bal.B reout.statement ;

B.bal.B :
    empty |
    B.bal.A throw.statement |
    B.bal.A rein.statement A.bal.A renew.statement A.bal.B reout.statement |
    B.bal.B rein.statement B.bal.A renew.statement A.bal.B reout.statement ;

throw.statement:
    split.statement | branch.statement | hang.statement ;

catch.statement:
    when.statement | join.statement ;

simple.statement :
    require.statement |
    proclaim.statement |
    new.statement |
    assign.statement |
    break.statement |
    safe.statement |
    side.statement |
    freeze.statement |
    thaw.statement |
    erroneous.statement ;

require.statement :
    REQUIRE   expression string  line.end ;

proclaim.statement :
    PROCLAIM expression line.end ;

assign.statement :
    ASSIGN '(' decl.variable ')' selector.expression
    expression expression line.end ;

new.statement :
    NEW decl.variable.list expression line.end ;

split.statement :
    SPLIT label line.end ;

when.statement :
    WHEN expression label line.end ;

join.statement :
    JOIN label line.end ;

branch.statement :
    BRANCH string label line.end ;

label:
    whole.number ;

break.statement :
    BREAK string line.end ;

hang.statement :
    HANG line.end ;

safe.statement :
     SAFE  variable.list expression.list string line.end ;

decl.variable.list :
     '(' decl.variable.sequence ')' ;

decl.variable.sequence :
    empty | decl.variable.sequence decl.variable ;

decl.variable :
     variable.name  | variable.name ':' form ;

variable.list :
    '(' variable.sequence ')' ;

variable.sequence :
    empty | variable.sequence variable.name ;

expression.list :
    expression | expression.list expression ;

side.statement :
    SIDE expression line.end ;

rein.statement :
    REIN line.end ;

renew.statement :
    RENEW  expression line.end ;

reout.statement :
    REOUT  line.end ;

freeze.statement :
    FREEZE variable.name string line.end ;

thaw.statement :
    THAW variable.name line.end ;

erroneous.statement:
    error line.end ;

type :
    enumerated.type | other.type ;

enumerated.type :
    subrange.type | boolean.type ;

subrange.type :
    '(' subrange integer.constant integer.constant ')'  ;

boolean.type :
    '('  boolean  ')'  ;

other.type :
    '(' integer  ')' |
    '(' module ')' |
    '(' universal ')' |
    '(' fixed integer.constant integer.constant integer.constant ')'  |
    '(' set enumerated.type ')'  |
    '(' array index.type result.type ')'  |
    '(' record identifier field.list ')'  ;

index.type :
    enumerated.type ;

result.type :
    type ;

field.list :
    field | field.list field ;

field :
    '(' identifier type ')' ;

class :
    variable | function | rulefunction ;

form :
    '(' class type ')' ;

expression :
     '(' variable.name nonempty.expression.sequence ')' | 
     '(' new1 variable.name expression.sequence ')'  |
     '(' consti1 integer.constant ')' |
     '(' addi1 expression expression ')' |
     '(' subi1 expression expression ')' |
     '(' negi1 expression ')' |
     '(' succ1 expression ')' |
     '(' pred1 expression ')' |
     '(' muli1 expression expression ')' |
     '(' divi1 expression expression ')' |
     '(' mod1  expression expression ')' |
     '(' odd1 expression ')' |
     '(' gei1 expression expression ')' |
     '(' lei1 expression expression ')' |
     '(' gti1 expression expression ')' |
     '(' lti1 expression expression ')' |
     '(' mini1 expression expression ')' |
     '(' maxi1 expression expression ')' |

     '(' constf1 integer.constant integer.constant ')' |
     '(' scale1 expression integer.constant ')' |
     '(' addf1 expression expression ')' |
     '(' subf1 expression expression ')' |
     '(' negf1 expression ')' |
     '(' mulf1 expression expression ')' |
     '(' divf1 expression expression ')' |
     '(' gef1 expression expression ')' |
     '(' lef1 expression expression ')' |
     '(' gtf1 expression expression ')' |
     '(' ltf1 expression expression ')' |
     '(' minf1 expression expression ')' |
     '(' maxf1 expression expression ')' |

     '(' true1 ')' |
     '(' false1 ')' |
     '(' and1 expression expression ')' |
     '(' or1 expression expression ')' |
     '(' not1 expression ')' |
     '(' implies1 expression expression ')' |
     '(' notimplies1 expression expression ')' |
     '(' notimpliedby1 expression expression ')' |
     '(' impliedby1 expression expression ')' |

     selector.expression |

     '(' empty1 ')' |
     '(' range1 expression expression ')' |
     '(' union1 expression expression ')' |
     '(' diff1 expression expression ')' |
     '(' intersect1 expression expression ')' |
     '(' subset1 expression expression ')' |
     '(' superset1 expression expression ')' |
     '(' in1 expression expression ')' |

     '(' equal1 expression expression ')' |
     '(' notequal1 expression expression ')' |

     '(' if1 expression expression expression ')' |
     '(' defined1 variable.name ')' |
     '(' defined1 new1 variable.name ')' |
     '(' alltrue1 expression ')' |
     '(' arraytrue1 expression expression expression ')' |
     '(' arrayconstruct1 expression expression expression ')' ;

selector.expression : 
     '(' variable.name ')' | 
     '(' emptyobject1 ')' |
     '(' selecta1 expression expression ')' |
     '(' selectr1 expression identifier ')' |
     '(' storea1  expression expression expression ')' |
     '(' storer1 expression identifier expression ')' ;

nonempty.expression.sequence :
    expression.sequence expression ;

expression.sequence :
    empty | nonempty.expression.sequence ;

variable.name :
    identifier ;

integer.constant :
    whole.number | '-'  counting.number ;

whole.number :
    zero  | counting.number ;

identifier:
    BEGIN | BREAK | END | FREEZE | HANG | JOIN | NEW | REIN | RENEW |
    REOUT | REQUIRE | SAFE | SIDE | SPLIT | THAW | WHEN | subrange |
    boolean | integer | fixed | set | array | record | OTHER.IDENTIFIER ;
