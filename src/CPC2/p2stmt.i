procedure WHATstmt; const WHAT = '@(#)p2stmt.i    2.3'; begin SINK := WHAT; end;    { Version 2.3 of 1/2/83 }
{
    Jcode generation for statements
}
{
    internal procedures for icode operators representing statements
}
{
    sequence operator - used for compound statements
}
procedure opseq(p: ptn);
var i: 0..maxarg;                { for counting seq items }
begin    
    with p^ do begin                { using given node }
    for i := 1 to nrarg do statement(arg[i]);{ process individual stmts }
    end;
end {opseq};
{
    raise operator - used for RAISE statement
}
procedure opraise(p: ptn);
begin
    unimplemented(p^.linen);            { ***UNIMPLEMENTED*** }
end {opraise};
{
    call operator - used for procedure calls
    (function calls are handled in expression processing)
}
procedure opcall(p: ptn);
begin
                        { check priority rules }
    prioritycheck(p,lastblockp^.blpriority,p^.vtype^.blockdata);
    proccall(p);                { do procedure call }
end {opcall};
{
    lock operator  -  used to lock before a procedure call here
}
procedure oplock(p: ptn);
begin
                        { check priority rules }
    with p^ do begin                { using given node }
    assert(code = lockop);            { must be lock }
    assert(arg[1]^.code = callop);        { must point to call }
        prioritycheck(p,disp,arg[1]^.vtype^.blockdata);
        proccall(arg[1]);            { do procedure call }
        end;
end {oplock};
{
    if operator - used for IF statement
}
procedure opif(p: ptn);
var truebranch, falsebranch: labelid;        { for labels }
    condcode: ptn;                { code for condition }
    truecode, falsecode: ptn;            { code for THEN and ELSE parts }
    condline: lineinfo;                { line number for THEN part }
begin
    truebranch := nextlabel;            { assign label for TRUE case }
    falsebranch := nextlabel;            { assign label for FALSE case }
    with p^ do begin                { using IF node }
    assert(code = ifop);            { must be IF }
    condcode := arg[1];            { condition expression }
    truecode := arg[2];            { THEN part }
    falsecode := arg[3];            { ELSE part }
    end;
    safeexpr(condcode);                { insure condition valid value }
    assert(condcode^.mtype = b1);        { checked in augment1 }
    condline := condcode^.linen;        { line number of condition }
    genstring15('SPLIT');            { SPLIT <true label> }
    genspace;
    geninteger(truebranch);            { true branch }
    if comments then begin            { if generating comments }
        gencomment(condline);            { line number in comment }
        genstring15('IF');
    end;
    genline;
    genstring15('WHEN');            { WHEN <cond> <true label> }
    genspace;
    genjexpr(condcode);                { condition }
    genspace;
    geninteger(truebranch);            { true branch }
    genline;
                            { ***NEED SIDE CHECK*** }
    statement(truecode);            { CODE for true branch }
                        { now branch around ELSE part }
    genstring15('BRANCH');            { BRANCH <msg> <false label> }
    genspace;
    genmsgstart(condline);            { msg associated with cond loc }
    genstring15('IF->THEN');             { "IF->THEN" }
    genmsgend;
    genspace;
    geninteger(falsebranch);            { for false case }
    genline;
                        { the ELSE part }
    genstring15('WHEN');            { WHEN <not cond> <true label> }
    genspace;
    genstring15('(not!');            { negate condition }
    genspace;
    genjexpr(condcode);                { condition }
    genchar(')');                { end negation }
    genspace;
    geninteger(truebranch);            { true label }
    genline;
                            { ***NEED SIDE CHECK*** }
    statement(falsecode);            { else case statements }
    genstring15('BRANCH');            { BRANCH <msg> <false case> }
    genspace;
    if falsecode <> nil then begin        { if ELSE part }
    genmsgstart(condline);            { message }
        genstring15('IF->ELSE');        { path }
    end else begin                { null ELSE part }
    genmsgstart(condline);            { line number from IF }
    genstring15('IF not');
    end;
    genmsgend;
    genspace;   
    geninteger(falsebranch);
    genline;
    genstring15('JOIN');            { JOIN <false case> }
    genspace;
    geninteger(falsebranch);
    genline;
end {opif};
{
    dtemp operator - used for WITH statement

    Actual expansion of WITH expressions took place in augmentation.
    Only freeze/thaw processing is required here.
}
procedure opdtemp(p: ptn);
begin
    freezeselector(p^.arg[1]);            { freeze vars in sel expr }
    statement(p^.arg[2]);            { do statements within WITH }
    thawselector(p^.arg[1]);            { thaw vars in sel expr }
end {opdtemp};
{
    assignment operators - used for ":="
}
procedure assignmentops(p: ptn);         
var lhs: ptn;                    { left hand side var }
    rhs: ptn;                    { right hand side var }
    baselhs: varnodep;                { base var of lhs }
begin
   with p^ do begin                { using given node }
    assert(code in [stolop, stofop, movemop]); { operators handled }
    lhs := arg[1];                { left hand side }
    rhs := arg[2];                { right hand side }
    baselhs := basevariable(lhs^.vtype);    { base variable of lhs }
    checknotfrozen(lhs,baselhs);           { check for freeze error }
    safeselector(lhs);            { insure left side valid }
    safeexpr(rhs);                { insure right side valid }
                        { insure compatability }
    requirecompat(p, lhs^.vtype, lhs^.vtype^.varmtype, rhs);
    genstring15('ASSIGN');            { NEW (<var>) (<var = expr>) }
    genspace;
    genchar('(');
    genname(baselhs);            { var }
    genchar(')');
    genspace;
    genjselector(lhs);            { lhs to be stored into }
    genspace;
    gentrueobject(lhs^.vtype);        { defined state is true }
    genspace;
    genjexpr(arg[2]);            { generate rhs expression }
    if comments then begin            { if generating comments } 
        gencomment(linen);            { <var> := <expr> }    
        genmselector(lhs);            { left side }
        genstring15(' :=');            { replacement }
        genchar(' ');
        genmexpr(arg[2]);            { right hand side }
        end;
    genline;
    end;                    { end With }
end {assignmentops};
{
    assert operator - used for SUMMARY, STATE, and ASSERT

    This routine is used only for statement assertions, not
    declaration assertions.
}
procedure opasert(p: ptn);
var subcode: cardinal;                { ASERT subcode }
    i: 0..maxarg;                { for arg count }
begin
    genassertrequires(p);            { generate REQUIRE sequence }
    subcode := p^.disp;                { subcode }
    assert(subcode in [statesubcode, summarysubcode, assertsubcode]);
    case subcode of                { fan out on assertion type }
    statesubcode: begin                { STATE statement }
                        { not allowed here }
    diag(p^.linen,'STATE statement illegal outside loops.');
    end;
    summarysubcode: begin            { SUMMARY statement }
    {
        This doesn't work.  A much more elaborate form of Jcode
        must be generated, because of the problem of handling
        TEMP variables needed for .old forms in EXIT conditions
        and other purposes.
    }
    genstring15('BREAK');            { hard break }
    if comments then begin            { if generating comments }
        gencomment(p^.linen);
        genstring15('SUMMARY');        { explain }
        genstring15(' statement');        { explain }
        end;
    genline;
    unimplemented(p^.linen);        { ***UNIMPLEMENTED*** }
    end;
    assertsubcode: begin            { ASSERT statement }
    end;                    { no special action }
    end;                    { cases }
end {opasert};
{
    statement  --  statement operators dispatcher
}
procedure statement(p: ptn);                { forward referenced }
begin
    if p <> nil then                { if not null statement }
    with p^ do begin                { using given node }
    tick;                    { advance statement clock }
    sideeffectinthisstmt := false;        { clear side eff flag }
    if code in [nullop, seqop, raiseop, icallop, waitop, sendop, ifop,
            caseop, loopop, forop, dtempop, asertop,
            callop, lockop,
            stofop, stolop, movemop] then
    case code of                { fan out on op code }
        nullop:     begin end;        { null statement }
        seqop:     opseq(p);
        raiseop:     opraise(p);
        icallop:     opicall(p);
        waitop:     opwait(p);
        sendop:     opsend(p);
        ifop:     opif(p);
        caseop:     opcase(p);
        loopop:     oploop(p);
        forop:     opfor(p);
        dtempop:     opdtemp(p);
        asertop:     opasert(p);
        callop:     opcall(p);
        lockop:     oplock(p);
        stolop, stofop, movemop:  assignmentops(p);{ assignment operators }
        end else                { if not valid }
        badnode(p,102);            { illegal statement operator }
    end;
end {statement};
