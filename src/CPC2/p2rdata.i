procedure WHATrdata; const WHAT = '@(#)p2rdata.i    2.2'; begin SINK := WHAT; end;    { Version 2.2 of 12/13/82 }
{
    Read-only data handling
}
{
    readdatfield  --  read data objects file

    The given bit field is extracted from the byte-oriented
    VALUE data file.
}
function readdatfield(addr: bitaddress;        { address in bits }
         size: bitaddress)        { size in bits }
         : longint;            { returned value }
{
    readdatbit  --  read indicated bit from file
}
const maxfield = 16;                { maximum field size }
var i: 0..maxfield;                { for loop }
    t: 0..65535;                { field maximum }
function readdatbit(bitadd: bitaddress)        { bit to read }
           : bit;            { returned bit }
var b: 0..65535;                { 16-bit working value }
    i: 0..7;                    { for loop }
    byteadd: longint;                { byte number in file }
begin {readdatbit}
    byteadd := bitadd div 8;            { compute byte wanted }
    if byteadd <> lastrdataaddr then begin    { if not same as last time }
    if byteadd < lastrdataaddr then begin    { if less than last time }
        assign(dat,'pasf-data');
        reset(dat);                     { ***TEMP*** }
        lastrdataaddr := -1;        { now at byte -1 }
        end;
    assert(byteadd >= lastrdataaddr);    { now read forward }
    while byteadd > lastrdataaddr do begin    { if not there yet }
        read(dat,lastrdatabyte);        { read one byte }
        lastrdataaddr := lastrdataaddr + 1;    { increment current location }
        end;                { end read loop }
    end;                    { now synchronized }
    assert(lastrdataaddr = byteadd);        { correct byte now available }
    {
    Note that our addressing is from the high order end, i.e. our bit
    0 is the high bit of a byte, and our bit 7 is the low order bit.
    }
    b := lastrdatabyte;                { get working byte }
    for i := 1 to bitadd mod 8 do        { shift to left 0-7 bits }
    b := b + b;                { by addition }
                        { desired bit is now bit 7 }
    b := b div 128;                { desired bit is now bit 0 }
    readdatbit := b mod 2;            { extract bit 0 }
end {readdatbit};
begin {readdatfield}
    assert(size <= maxfield);            { field size limit }
    t := 0;                    { clear total }
    for i := 0 to size - 1 do begin        { for all indicated bits }
    t := t * 2 + readdatbit(addr + i);    { accumulate indicated field }
    end;
    readdatfield := t;                { return field value }
end {readdatfield};
{
    genconstsel  --  generate selector expression with constant
             subscripts.

    This routine may be called only for vnodes representing simple
    objects lacking further structure.
    Used for handling VALUE expressions only.
    Expressions with the effect of

    Array elements in jcode are of the form

        (selecta! <array expr> <subscript expr>)

    Record elements are of the form

        (selectr! <record expr> <type name> <field id>)

    These forms nest.
}
procedure genconstsel(v: varnodep;            { variable }
              var subtab: subconsttab);        { constant subs table }
var vbase, q: varnodep;                    { working nodes }
    sdepth: 0..subconstmax;                { depth into subtab }
    pathdepth: 0..maxselstack;                { depth of pathtab }
    i: 0..maxselstack;                    { for loop }
    pathtab: array [1..maxselstack] of varnodep;    { path of sel expr }
begin
    vbase := basevariable(v);                { get basevariable }
    sdepth := 0;                    { no entries yet }
    with v^ do begin                    { using leaf node }
                            { leaves are simple }
    assert(vardata.form in [fixeddata, booleandata, numericdata]);
    assert(down = nil);                { no children }
    pathdepth := 1;                    { leaf item }
    pathtab[pathdepth] := v;            { save leaf }
    q := up;                    { get parent }
    end;
    {
    Ascend structure, if any, generating relevant selector expression
    Only records and arrays may be non-leaves of selector expressions.
    }
    while q <> nil do begin                { for all below base }
    pathdepth := pathdepth + 1;            { save selector path }
    pathtab[pathdepth] := q;            { save this node }
    with q^ do begin                { using given node }
        case vardata.form of            { fan out on form }
        arraydata: begin                { array object }
        genstring15('(selecta!');        { array selector }
        genspace;
        end;

        recorddata: begin                { record object }
        genstring15('(selectr!');        { record selector }
        genspace;
        assert(pathdepth > 1);            { must not be leaf }
        end;
        end;                    { end cases }
        end;                    { With }
        q := q^.up;                    { toward base var }
    end;
                            { (basename) }
    gendataid(vbase ,nulltid, genwithoutnew, genwithoutdef);    
    {
    Now work back toward leaf of type description

    We stop at 2 so as not to process the leaf itself.
    The leaf entry is needed, though, so that the name of the field
    in a record may be found.
    }
    for i := pathdepth downto 2 do begin        { back down }
    with pathtab[i]^ do begin            { using this node }
        case vardata.form of            { fan out on form }
        arraydata: begin                { array }
        sdepth := sdepth + 1;            { on to next one }
        assert(sdepth <= subtab.sutop);        { no overflow }
        genspace;
        genintconst(subtab.sutab[sdepth]);    { next subscript }
        end;
        recorddata: begin                 { record }
        genspace;
        gentypeid(pathtab[i]);            { type name }
        genchar('$');                { combine fields }
        genfieldid(pathtab[i-1]);        { field id }
        end;                    { records are done }
        end;                    { of cases }
        genchar(')');                { close expression }
        end;                    { end With }
    end;                        { end for }
end {genconstsel};
{
    rdatagen  --  generate ASSIGN expressions for every element of
              a constant table from a VALUE expression
}
procedure rdatagen(v: varnodep);        { item to generate }
var subtab: subconsttab;            { constant subscripts }
{
    rdataitem  --  generate ASSIGN for single read-only data item
}
procedure rdataitem(v: varnodep;        { simple data item }
            addr: bitaddress);    { address of node }
var i: longint;                    { working value }
begin
    with v^ do begin                { using given node }
    genstring15('ASSIGN');            { ASSIGN of basic item }
    genspace;
                        { object to assign to }
    gendataid(basevariable(v), 
        nulltid, genwithoutnew, genwithoutdef);    
    genspace;
    genconstsel(v, subtab);            { generate lhs expr }
    genspace;
    genstring15('(true!)');            { definedness }
    genspace;
    case vardata.form of            { fan out on form }
    numericdata: begin            { longint object }
        i := readdatfield(addr,vardata.size);    { get value of object }
        if vardata.minvalue < 0 then begin    { if signed field }
        if vardata.size <> 16 then    { if not 16 bits }
        if vardata.size <> 16 then begin{ if not 16 bits }
            badvarnode(v, 205);        { negative VALUE field size bad}
            i := 0;            { effect repair }
            end;
        i := extractsigned(i);        { handle signed machine value }
            end;
        if i > vardata.maxvalue then
        badvarnode(v,202);        { oversize rdata constant }
        if i < vardata.minvalue then
        badvarnode(v,203);        { undersize rdata constant }
        genintconst(i);            { generate constant }
        end;
    booleandata: begin            { boolean object }
        i := readdatfield(addr,vardata.size);{ get value of object }
        if not (i in [0,1]) then         { if not boolean }
        badvarnode(v, 204);        { bad Boolean rdata constant }
        case i of                { fan out on values }
        0:  genstring15('(false!)');    { false value }
        1:  genstring15('(true!)');        { true value }
        end;                { end case i }
        end;
    fixeddata: begin            { fixed-point object }
        unimplemented(vardata.vrsource);    { ***UNIMPLEMENTED*** }
        end;
        end;                { of cases }
    if comments then begin            { commentary }
        gencomment(vardata.vrsource);    { line number of decl }
        genstring15('VALUE constant');
        genstring15(' (ROM bits');
        genchar(' ');
        geninteger(addr);
        genchar(':');
        geninteger(addr+vardata.size-1);
        genchar('=');
        geninteger(i);
        genchar(')');
        end;
    genline;                { finish line }
    end;                    { With }
end {rdataitem};
{
    rdatadescend  --  descend structure, generating ASSIGNs of
              values
}
procedure rdatadescend(v: varnodep;        { working varnode }
               addr: bitaddress);    { address of node }
var q: varnodep;                { for working chain }
    eltsize, eltaddr: bitaddress;        { for address calculation }
    i: targetinteger;                { subscript for scan }
begin
    with v^ do begin                { using given node }
    case vardata.form of            { fan out on form }
        monitordata, pointerdata, moduledata, programdata, 
        proceduredata, functiondata,
        signaldata: begin            { non-data object }
        badvarnode(v, 201);        { non-data in VALUE clause }
        end;
        recorddata: begin            { record object }
        q := down;            { get first element }
        while q <> nil do begin        { for all subelements }
            rdatadescend(q, addr + q^.vardata.loc.address);
            q := q^.right;        { get next element }
            end;
        end;
        arraydata: begin            { array object }
        eltsize := down^.vardata.size;    { get size of element }
        eltaddr := addr;        { current elt address }
        subtab.sutop := subtab.sutop + 1; { push subscript stack }
        for i := vardata.minvalue to vardata.maxvalue do begin
            subtab.sutab[subtab.sutop] := i; { save subscript }
            rdatadescend(down, eltaddr);{ descend }
            eltaddr := eltaddr + eltsize; { address of next element }
            end;            { end element loop }
        subtab.sutop := subtab.sutop - 1; { pop subscript stack }
        end;
        numericdata, booleandata, fixeddata: begin { simple object }
        rdataitem(v, addr);        { handle simple item }
        end;
        end;                { of cases }
    end;                    { With }
end {rdatadescend};
begin {rdatagen}
    subtab.sutop := 0;                { initially empty }
    with v^ do begin                { using given node }
    assert(vardata.loc.relocation = valueaddr); { must be in value space }
    rdatadescend(v, vardata.loc.address);    { recursive descend }
    end;
end {rdatagen};
{
    assignvalues  --  cause generation of ASSIGN entries for all
              input VALUE variables for given block
}
procedure assignvalues(blk: blocknodep);    { relevant block }
var r: refnodep;                { reference node }
begin
    r := blk^.blrefs;                { get ref chain }
    while r <> nil do begin            { for all refs }
    with r^ do begin            { using given ref }
        if refkind = useref then begin    { if use of arg }
        if refvar^.vardata.loc.relocation = valueaddr then begin
            if refvar^.idunique <> 0 then { if declared }
                rdatagen(refvar);    { handle VALUE variable }
            end;
        end;                { end is use ref }
        end;                { end With }
    r := r^.refnext;            { get next ref }
    end;                    { end while }
end {assignvalues};
