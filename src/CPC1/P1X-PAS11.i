

procedure constdecl;
var
  p: itp;
  b: boolean;	{ dummy }
begin {constdecl}
if sym.sy <> ident then error( 2  {"expected identifier"});
while sym.sy = ident do begin
  newid(konst,nil,nil,p);
  b := exporter(p);  {if ident is exported, set the enclosed identifier link}
  insymbol;
  if (sym.sy = relop) and (sym.op = eqop) then insymbol else error(16);
  expression;
  if (gattr.akind <> cst) then error(106);
  with p^ do begin
    itype := gattr.atype;  kvalue := gattr.avalue
    end;
  if sym.sy = semicolon then insymbol else error(14)
  end
end {constdecl};


procedure typedecl;
var
  p1, p2, p3: itp;
  q1, q2: stp;
  b: boolean;	{ dummy }
begin {typedecl}
if sym.sy <> ident then error( 2  {"expected identifier"});
while sym.sy = ident do begin
  p1 := fwptr;  p3 := nil;  { p3 will point to a forward pointer id (if any) }
  while p1 <> nil do begin  { search current forward list }
    if match(p1^.name^.s, ord(p1^.name^.l), id.s, ord(id.l)) = 0 then begin
      p3 := p1;		{ got one, save it in p3 }
      if p1 = fwptr then fwptr := fwptr^.next else p2^.next := p1^.next
      end;
    p2 := p1;  p1 := p1^.next
    end;
  if p3 = nil then begin	{ if not a forward pointer, then enter it }
    newid(types,nil,nil,p3);
    b := exporter(p3);     {export type if required}
    q1 := nil
    end
  else q1 := p3^.itype;		{ q1 is the type of the forward pointer }
  insymbol;	{ gobble up the ident }
  if (sym.sy = relop) and (sym.op = eqop) then insymbol else error(16);
  typ(q2);	{ parse type field and return pointer to struct in q2 }
  p3^.itype := q2;
  q2^.typeid := p3;			{ attach type to name for varfile }
  if q1 <> nil then q1^.eltype := q2;	{ resolve forward pointer }
  if sym.sy = semicolon then insymbol else error(14)
  end
end {typedecl};
{
	monitorscopechk  --  enforcement of verifier rules regarding
			     monitor scopes

	except that signals and arrays of signals may be imported and
	exported.
}
procedure monitorscopechk(p: itp;	{ variable ident to be checked }
			isexport: boolean); { true if export mode }
var vtype: stp;				{ type of variable }
begin
    if enforce then begin		{ if we care }
	if p^.klass = xports then p := p^.enclosedident; { get real ident }
	assert(p <> nil);		{ must be linked }
	assert(p^.klass <> xports);	{ only one level of indirection }
	with p^ do begin		{ using ident item }
	    if klass = vars then begin	{ if this is a variable }
		vtype := itype;		{ get type of var }
		if vtype^.form = arrayt then { if array }
		    vtype := vtype^.aeltyp; { use element type }
		if vtype^.form <> signalt then begin { if other than signal }
		    if isexport then error(1002 {no export of var})
			        else error(1001 {no import of var});
		    end;
		end;			{ end is variable }
	    end;			{ end with }
	end;				{ end enforcing }
end {monitorscopechk};	
procedure valuedecl;
			{parse a VALUE declaration}

var
  p, tn : itp;
  coffset : addrrange;  cvalue : longint;
  b: boolean;	{ dummy }

  procedure structconst( fq: stp; emit: boolean );
	{   -----------		parse a structured constant (Value list)
		and optionally write it to the .DAT file. The second
		parameter allows values to be parsed without being
		written so that the components of a packed record
		can be packed into 16 bit integers;
		The parsing is driven by the type definition (pointed
		to by fq) of the value being parsed.  It calls
		itself recursively to parse a subtype of an array or
		record type.  }
    var
	nxtfld: itp;	{used to step through fields of a record}
	caddr:  addrrange;	{temp to save start address of array/record}
	nrelts, eltsize: longint;
	lmax, lmin: longint;		{ bounds of index type }
	tvalue, tscale: longint;  	{temps for fixed point conversion}
	k: longint;
	qq: stp;	{temp for searching variants}
	ptg: itp;	{temp pointer to tag field }
	foundit: boolean;

    begin
      if fq <> nil then
	case  fq^.form of

	  scalar,booleant,chart,integert,longintt,sett,fixedt:
	    begin	{simple (unstructured) types}
	      caddr := dc;	{ address to emit value to .. }
 	      expression;	{parse the value}
	      if not assignable( gattr.atype, fq ) then
	        error( 134 {illegal type of operand} );
		{check that the value was a constant}
	      if gattr.akind <> cst then
		error( 106 {constant expected} );
	      gendat( gattr );	{ ..  turns a set into mush }
	      if fq^.form = fixedt then
		begin	{scale and output }
		  transfertype( fq, gattr );  { get the scaling correct}
		  formatflit( gattr.avalue, tvalue, tscale ); {convert to scaled longint}
		  if emit then gendword( tvalue)
		end
	      else  if emit then
		begin	{ put out as byte or word }
		  if typsize( fq ) > 1 then
		    gendword( gattr.avalue.ival )
		  else
		    gendbyte( gattr.avalue.ival )
		end;
	      if emit then
	       begin  {mark that expression is now in .DAT file}
	        gattr.atype := fq;	{ set expression attributes }
	        gattr.avalue.kind := data;
	        gattr.avalue.daddr := caddr;
	       end;
	    end;	{ simple types }

	  arrayt:
	    begin
	      getbounds(fq^.inxtyp, lmin, lmax); { get subscript bounds }
	      nrelts := lmax - lmin + 1;	{ number of elts in array }
	      eltsize := typsize(fq^.aeltyp);  {size of each element}
	      if odd(dc) and (typalign(fq) > 1) and emit then
		gendbyte(0);	{ get the array on a word boundary }
	      caddr := dc;	{ save starting address in  data block }
	      if sym.sy = lparen then
		begin	{ now parse the list of values }
		  repeat	{  for each value in the list }
		    insymbol;
		    if sym.sy = stringconst then
			{NOTE: There is a local ambiguity in the value
			  list when it contains a sting constant at the
			  top level, since an array of char (string) is
			  written X('abc'), while an array of strings
			  (array of array of char) is written as
			  Y('abc','def').  Hence the parsing of the
			  value list must be explicitly directed by the
			  type definition at this point			}
		      begin	{ Note: a stringconst is written to the
				  data file when it is parsed by expression}
			if fq^.aeltyp^.form = chart then
			  begin		{it is a simple string}
			    expression;		{parse & store the string }
			    if gattr.atype^.size <> nrelts then
				error( 205 {string length incorrect} );
			    nrelts := 0;   {suppress error 127 below}
			  end
			else  { .. an array of strings }
			  begin
			    structconst( fq^.aeltyp, true );
			    if nrelts > 0 then
				nrelts := pred(nrelts)
			    else
			      error( 127 {incorrect number of items in list} )
			  end
		      end
		    else
		      begin  { call structconst recursively to parse element}
			structconst( fq^.aeltyp, true );
			if nrelts > 0 then
			  nrelts := pred(nrelts)
			else
			  error( 127  {incorrect number of items in list});
		      end
		  until sym.sy <> comma;
		  if nrelts <> 0 then
		    error( 127 {incorrect number of items in value list});
		  if sym.sy = rparen then
		    insymbol
		  else
		    error(4 {expected ')'});
		  gattr.atype := fq;
		  gattr.akind := cst;
		  gattr.avalue.kind := data;
		  gattr.avalue.daddr := caddr;
		end
	      else if sym.sy = stringconst then
		begin	{ we got here from a higher level call ?? }
		  expression;
		  if gattr.atype^.size <> nrelts then
		    error( 205 {incorrect length string} );
		end
	      else
		error( 9 {expected '('} );
	    end;	{ of case arrayt }

	  recordt:
	    begin
	      eltsize := typsize(fq);
	      if odd(dc) and (eltsize > auword) then
		gendbyte(0);	{align data file to word boundary}
	      caddr := dc;	{save starting address of record}
	      nxtfld := fq^.fstfld;	{pointer to fields of record}
			{ set up pointer to tag field to catch variants }
	      if fq^.recvar <> nil then
		ptg := fq^.recvar^.tagfld
	      else
		ptg := nil;

	      cvalue := 0;	{used to hold partial packed records}
	      if sym.sy = lparen then
		repeat		{ for all items in the value list }
		  insymbol;	{get the next item}
		  if nxtfld <> nil then
		   if nxtfld <> ptg then   {not the tag field }
		    if nxtfld^.ispacked then
		      begin	{packed record - eval field and add to cum val}
			structconst( nxtfld^.itype, false );
			k := typwidth( nxtfld^.itype ); {space reqrd for next item}
			while k > 0 do
			  begin cvalue := cvalue*2; k := k-1  end;
			if gattr.avalue.ival <= power2(nxtfld^.itype^.size) then
			  cvalue := gattr.avalue.ival
			else	
			  error( 208 {constant or value too large for field} );
			nxtfld := nxtfld^.next;  {advance}
			if nxtfld <> nil then
			  if nxtfld^.bdisp = 0 then
			    begin	{ emit cumulative value}
			      gendword( cvalue );  {always as 16 bits}
			      cvalue := 0
			    end;
		      end	{packed record}
		    else
		      begin  {unpacked rec - emit components at lower lev}
			structconst( nxtfld^.itype, true );
			nxtfld := nxtfld^.next;
		      end
		   else
		    begin	{ try for variants }
			expression;	{get the tagfield value}
			qq := fq^.recvar^.fstvar; foundit := false;
			while (qq <> nil) and not foundit do
				{search for the proper variant}
			  if gattr.avalue.ival = qq^.varval then
			    foundit := true
			  else
			    qq := qq^.nxtvar;

		    	if foundit then
			  nxtfld := qq^.firstvfld
			else
			  error( 114 {bad tagfield value});
		    end
		until sym.sy <> comma
	      else
		error( 9 {'(' expected});
	      if sym.sy = rparen then insymbol else error( 4 {expected ')'} );
	      if nxtfld <> nil then error( 127 {number of elements in list});
	      gattr.atype := fq;
	      gattr.akind := cst;
	      gattr.avalue.kind := data;
	      gattr.avalue.daddr := caddr
	  end;	{recordt}

	xcptnt, signalt, pointer, devicet:
	  error( 134 {illegal type of operand} );
      end;	{case fq^.form}

    end;	{ structconst }



begin 	{valuedecl}
  if vmode <> codemode then		{ if not ordinary code mode }
    error(1025 {VALUE not permitted in PROOF mode});
  if sym.sy <> ident then error( 2  {"expected identifier"});
  while sym.sy = ident do          {..for each ident being declared}
    begin
      tn := udptrs[types];		{default value if undefined }
      newid(konst,nil,nil,p);      	{enter identifier}
      b := exporter(p);    {if value is exported, set enclosed ident link}
      insymbol;				{get = sign}
      if (sym.sy=relop) and (sym.op=eqop)
	then  insymbol
	else  error(16);

      if sym.sy = ident then    	{name of type being declared}
	begin
	  tn := searchid([types]);
	  insymbol;		{eat the identifier}
	  if tn = udptrs[types] then error(104)    {undeclared type}
	end
      else
	error(2);			{"expected type identifier"}

      coffset := 0;  cvalue := 0;	{initialize for structconst}
      structconst(tn^.itype, true);  {parse and emit the list of values }
      p^.itype := tn^.itype;
      p^.kvalue := gattr.avalue;    		{ ??? flaky!!	}
      if sym.sy = semicolon
	then  insymbol
	else  error(19)		{"expected semicolon"}
    end

end;	{valuedecl}


procedure vardecl;
var
  p1, p2, p3, p4: itp;
  q: stp;
  b: boolean;	{ dummy }
  endoflist: boolean;
  verc: verclass;			{ normal or extra }

procedure varaddr(fp: itp);
			{ calculate the address of variable & allocate
			  storage for it.				}
var needspace: boolean;				{ true if space needed }
begin  {varaddr}
  needspace := true;				{ assume space needed }
  with fp^ do
   if itype <> nil then	{ errors may cause NIL ptr }
    begin  {normal and device variables are handled differently}
      if itype^.form = devicet then
	begin  {Address is given with type.  No storage is allocated}
	  if itype^.addressed then begin
	    needspace := false;			{ no space needed }
	    vaddr := itype^.devaddr
	  end else begin
	    error(177  {"device address not specified"})
	    end;
	end;					{ end device variable }
      if needspace then begin			{ if space needed }
	if (not verifier) and (vclass <> executablevar) then begin {FREE/EXTRA }
	    vaddr := illegaladdress;		{ do not assign space }	
	end else				{ if space is required }
	begin			{***  Phase 1 Storage Allocator  ***}
	  if level = 1 then					{***}
	    begin	{global var}				{***}
	      lc := ceil(lc, typalign(itype));  {round up}	{***}
	      vaddr := lc;					{***}
	      lc := lc + typsize(itype)				{***}
	    end							{***}
	  else							{***}
	    begin	{local var}				{***}
	      lc := lc - typsize(itype);			{***}
	      lc := -ceil(-lc,typalign(itype)); {round down}	{***}
	      vaddr := lc					{***}
	    end							{***}
	end;							{***}
	end;					{ end need space }
      if itype^.form = signalt then
	begin	{retain information about the signal}
	  signalcount := signalcount + 1;
	  with signallist[signalcount] do
	    begin
	      varaddr := vaddr;
	      varlev := vlev;		{lexical level}
	      if itype^.addresspresent then
		begin 	{hardware signal}
		  hardwired := true;
		  vecaddr := itype^.trapvec;
		end
	      else
		hardwired := false;
	    end;
	end;	{ signal type }

    end		
end;	{varaddr}



begin {vardecl}
p3 := nil;
if sym.sy <> ident then error( 2  {"expected identifier"});
while sym.sy = ident do begin
  repeat
    if sym.sy = ident then begin
      newid(vars,nil,p3,p3);
      b := exporter(p3);  {export if necessary}
      with p3^ do begin
	vkind := local;  vlev := level
	end;
      insymbol		{ gobble up the ident }
      end
    else error(2);
    if sym.sy = comma then
      begin  endoflist := false;  insymbol  end
    else  endoflist := true
  until endoflist;
  if sym.sy = colon then insymbol else error(5);
  verc := executablevar;	{ assume not extra }
  if sym.sy = extrasy then begin { EXTRA variable }
    if vmode <> codemode then error(1009 {EXTRA within EXTRA block});
    verc := extravar; insymbol;	{ so set }
    end;
				{ in PROOF code, implicitly declare EXTRA }
  if (vmode = proofmode) and (verc = executablevar) then begin
    verc := extravar;		{ declare as EXTRA }
    end;
  typ(q);
  if verc <> executablevar then begin { only executable may be hardware }
    if q^.form in [xcptnt, signalt, devicet] then { hardware types }
	error(1024 {hardware cannot be EXTRA/FREE});
    end;
  if p3 <> nil then begin
    p4 := p3;  p2 := nil;	{ after reversing, p4 is tail, p2 is head }
    repeat			{ assign type and reverse list }
      with p3^ do begin		{ get new var item }
	itype := q;		{ assign type }
	vclass := verc;		{ assign verifier class }
	end;
				{ if exported from monitor, extra checks }
      if b and (blktype = montyp) then monitorscopechk(p3, true);
      p1 := p3^.next;
      p3^.next := p2;
      p2 := p3;  p3 := p1
    until p3 = nil;
    p3 := p2;
    repeat	{ assign addresses }
      varaddr(p3);
      p3 := p3^.next
    until p3 = nil;
    p4^.next := varlst;  varlst := p2;	{ add to list of all variables }
    end;
  if sym.sy = semicolon then insymbol else error(14)
  end
end {vardecl};

