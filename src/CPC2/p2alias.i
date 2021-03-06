procedure WHATalias; const WHAT = '@(#)p2alias.i    2.1'; begin SINK := WHAT; end;    { Version 2.1 of 10/12/82 }
{
    Aliasing and side effect checking
}
{
    identical  --  are two expressions totally identical?
}
function identical(p1, p2: ptn)            { expressions to compare }
           : boolean;
var nodiff: boolean;                { true if no differences }
    i: cardinal;                { for loop }
begin
    identical := false;                { assume failure }
    with p1^ do begin                { using first node }
    if code = p2^.code then            { if codes match }
        if disp = p2^.disp then        { if disp matches }
        if size = p2^.size then        { if size matches }
                        { if arg count matches }
            if nrarg = p2^.nrarg then begin            
                        { compare args }
            nodiff := true;        { assume args same }
            for i := 1 to nrarg do begin
                if not identical(arg[i], p2^.arg[i]) then
                nodiff := false; { difference found }
                end;        { end for loop }
            identical := nodiff;    { return difference state }
            end;            { end subarg compare }
    end;                    { end With }
end {identical};
{
    requiredisjoint  --  require that selector expressions be
                 disjoint.

    If the expressions differ in any static way, no REQUIRE is
    generated.  If the expressions are identical, an error message
    is generated.  If the expressions differ in subscript expressions
    only, a REQUIRE is generated that the subscripts differ.
    Note that processing is fast when the expressions being
    compared do not refer to the same variable.
}
procedure requiredisjoint(p1, p2: ptn);        { selector expressions }
const comparemax = 10;                { max subscripts in expression }
var stk1, stk2: selstack;            { working selector stacks }
    base1, base2: varnodep;            { base variables }
    d1, d2: 0..maxselstack;            { position on sel stack }
    disjoint: boolean;                { known to be disjoint }
    comparecount: 0..comparemax;        { position in compare table }
    compares: array [1..comparemax] of record    { compare table }
    cp1: ptn;                { first expression }
    cp2: ptn;                { second expression }
    end;
{
    requireunequal  --  require that expressions be unequal

    Used in requiring that selector expressions be disjoint.
    Messages generated are of the form:

        cannot prove: i <> j    (check for "a[i]" and "a[j]" disjoint)
}
procedure requireunequal;
const spacing = 4;                { spaces before explain }
var i: 1..comparemax;                { for loop on compares }
    n: 1..spacing;                { for spacing }
begin
    genstring15('REQUIRE');            { start REQUIRE }
    genspace;
    assert(comparecount > 0);            { at least one compare }
    for i := 1 to comparecount do begin        { for all given compares }
    with compares[i] do begin        { using nth compare }
        if i < comparecount then begin    { if not last one }
        genstring15('(or!');        { must or terms together }
        genspace;
        end;
        genstring15('(notequal!');        { (notequal! <e1> <e2>) }
        genspace;
        genjexpr(cp1);            { first expression }
        genspace;
        genjexpr(cp2);            { second expression }
        genchar(')');            { close notequal }
        end;                { end With }
    end;                    { end first loop }
    for i := 1 to comparecount - 1 do         { close all ors }
    genchar(')');                { with paren }
                        { now, the message }
    genspace;
    genmsgstart(p1^.linen);            { begin message }
    if comparecount > 1 then             { if more than 1 }
    genchar('(');                { enclose for or }
    for i := 1 to comparecount do begin        { for all items }
    with compares[i] do begin        { using this compare }
        if i > 1 then begin            { if not first }
        genstring15(') or (');        { separate with or }
        end;
            genmexpr1(cp1, relationaloperator);    { " i <> j }
            genstring15(' <>');            { not equal }
            genchar(' ');
            genmexpr1(cp2, relationaloperator);{ second expression }
        if (i = comparecount) and (comparecount > 1) then begin
        genchar(')');            { finish or }
        end;
        end;                { end With }
    end;                    { end for }
    for n := 1 to spacing do genchar(' ');    { precede with spaces }
    genstring15('(check');            { explaination of message }
    genstring15(' for "');
    genmexpr(p1);
    genstring15('" and "');
    genmexpr(p2);
    genstring15('" disjoint)');
    genmsgend;                    { finish message }
    genline;                    { finish REQUIRE }
end {requireunequal};
begin
    assert(optab[p1^.code].opclass = slcti);    { must be selector }
    assert(optab[p2^.code].opclass = slcti);    { must be selector }
    base1 := basevariable(p1^.vtype);        { get base of op 1 }
    base2 := basevariable(p2^.vtype);        { get base of op 2 }
    if base1 = base2 then begin            { if a clash is possible }
    comparecount := 0;            { no compares stored yet }
    disjoint := false;            { not definitely disjoint }
    buildselstack(p1, stk1);        { build selector stack for 1 }
    buildselstack(p2, stk2);        { build selector stack for 2 }
    d1 := stk1.top;                { working position in stack }
    d2 := stk2.top;                { working position in stack }
    while (d1 > 0) and (d2 > 0) do begin    { until one stack bottoms }
        assert(stk1.tab[d1].stkind = stk2.tab[d2].stkind); { forms in sync }
        case stk1.tab[d1].stkind of         { fan out on form }
        recordsel: begin            { record selection }
        if stk1.tab[d1].stvar <> stk2.tab[d2].stvar then begin
            disjoint := true;        { definitely disjoint }
            end;
        end;
        variablesel: begin            { variable itself }
        assert(d1 = stk1.top);        { must be last on stack }
        end;
        arraysel: begin            { array selection (subscript) }
                        { if forms differ, save }
                        { a REQUIRE may be needed }
        if not identical(stk1.tab[d1].stsub, stk2.tab[d2].stsub) 
            then begin
            if comparecount > comparemax then { if too many compares }
                verybadnode(p1,172);    { compare table full }
            comparecount := comparecount + 1; { increase compare count }
            with compares[comparecount] do begin { using compare entry }
                cp1 := stk1.tab[d1].stsub; { save subscript expr 1 }
                cp2 := stk2.tab[d2].stsub; { save subscript expr 2 }
                end;            { end With }
            end;            { end not identical }
        end;                { end array case }
            end;                { end cases }    
        if disjoint then begin        { if definitely disjoint }
        d1 := 0;            { force exit }
        end else begin            { if not disjoint }
        d1 := d1 - 1;            { back one on stack }
        d2 := d2 - 1;            { back one on stack }
        end;                { end not disjoint }
        end;                { end while loop }
    if not disjoint then begin        { if possibly the same }
        if comparecount = 0 then begin    { if definitely the same }
        usererrorstart(p1^.linen);    { begin error message }
        write('Use of "');
        writestring15(output, base1^.vardata.itemname); 
        write('" violates aliasing or side effect rules.');
        usererrorend;            { finish error message }
        end else begin            { if not definitely the same }
        requireunequal;            { generate unequal require }
        end;                { end for loop }
        end;                { end not disjoint }
    end;                    { end not different vars }
end {requiredisjoint};
{
    aliaschk  --  check for aliasing

    Every VAR argument is checked for conflict with every later
    VAR argument and every global argument.
}
procedure aliaschk(p: ptn);            { call node to check }
var r: refnodep;                { working ref node }
    parg, warg: ptn;                { working args }
    expr1: ptn;                    { first VAR expression }
    base1: varnodep;                { base of arg }
    out1: boolean;                { true if arg is output }
    i: cardinal;                { for arg loop }
    j: cardinal;                    { want 1..maxarg + 1 }
    outvar: array [1..maxarg] of boolean;    { true if output arg }
    formal: varnodep;                { for formal arg chaining }
begin
    with p^ do begin                { using given node }
    assert(code = callop);            { must be call }
                        { find output VAR args }
    formal := vtype^.down;            { get first arg }
    if isfunction(vtype) then         { if is function }
        formal := formal^.right;        { skip returned value arg };
    for i := 1 to nrarg do begin        { for all args }
        assert(formal <> nil);        { formal must exist }    
        base1 := basevariable(formal);    { get base of var }
        outvar[i] := base1^.varset;        { true if output VAR }
        formal := formal^.right;        { get next formal }
        end;
                        { check pairs for clashes }
    for i := 1 to nrarg do begin        { for all args }
        parg := arg[i];            { working arg }
        if parg^.code = referop then begin    { if refer, consider }
        expr1 := parg^.arg[1];        { first expr }
        base1 := basevariable(parg^.vtype); { first variable }
        out1 := outvar[i];        { if output }
        for j := i + 1 to nrarg do begin{ against other VAR args }
            warg := arg[j];        { second working arg }
            if warg^.code = referop then begin { if VAR arg }
            if out1 or outvar[j] then begin { if either is output }
                requiredisjoint(expr1, warg^.arg[1]);
                end;
            end;
            end;            { end second arg loop }
        r := vtype^.blockdata^.blrefs;    { get refer chain }
        while r <> nil do begin        { for all refers }
            with r^ do begin        { using this refer }
            if refkind in [setref, useref] then begin
                if base1 = refvar then begin
                usererrorstart(p^.linen);
                write(output,'Variable "');
                writestring15(output, base1^.vardata.itemname);
                write(output,
                '" is already used globally by "');
                writestring15(output,
                        p^.vtype^.vardata.itemname);
                write(output,'".');
                usererrorend;
                end;        { end aliasing violation }
                end;        { end valid ref }
            end;            { end With on refer }
            r := r^.refnext;        { on to next refer }
            end;            { end refer loop }
        end;                { end first arg is VAR }
        end;                { end arg loop }
    end;                    { end outer With }
end {aliaschk};
