.H 2 "An example in the form of an engine control program"
The ``engine control'' program here is not related to any real engine or
control electronics.
It is an example of a way in which a real-time program might be
written.
The program was written primarily to illustrate the kinds of things one
might attempt to prove about a program of this type.  It also demonstrates
that it is not overly difficult to
program under the restriction that monitors may not import or export
variables.  The program was written two years before the Verifier was
operational, and appeared in a preliminary version of this manual.
.P
This program has been verified by the Verifier.  Quite a number of bugs
were found in the program during the process.  Most of the work in getting
the Verifier to accept the program was in discovering the invariants
needed for the 
.I excluder
module.  Most of the bugs found were related to proper handling of failure
of the clock or crankshaft interrupts.  Note that the invariants provided
to check proper engine operation now hold even if the crankshaft interrupt
or clock interrupt never comes.  For example, there is code to fire the
spark (belatedly) if the next crankshaft interrupt comes in before the
spark has been fired under normal timing rules.  This code was
required before the constraint of one-spark-per-crank-pulse
could be met.
.P
.DP
program simpleengine;                   (*      version 1.50 of 1/14/83   *)
(*
        sample engine control program

   This is a sample program written to illustrate some features of
Pascal-F as extended for verification purposes.  The program has a
rather simple-minded model of the engine, and controls only the
fuel pump and spark.  The only inputs available to the program
are the clock, and the shaft position pulse.
   This program does not interface with any existing engine hardware.

                                        John Nagle
                                        Ford Aerospace and
                                        Communications Corporation
                                        Western Development Labs
*)
.DE
.DP

const
    maxticks = 1000;                    (* biggest time value *)
    maxrpm = 8000;                      (* largest possible RPM *)
    ms = 2;                             (* unit of time is 500 us *)
    cylinders = 8;                      (* size of engine *)
    maxsparkretard = 30;                (* max retard angle *)
    mustrecalc = 10;                    (* 10 rpm change forces recalc *)
    stalllim = 200*ms;                  (* after 0.2 secs, stop fuel *)
    interval = 2000;                    (* interval of spark table *)
    tablemax = 15;                      (* max entry in table *)
                                        (* retard at 1000 rpm int*)
type
    rpm = 0 .. maxrpm;                  (* revolutions per minute *)
    angle = 0..45;                      (* for shaft angles *)
    ticks = 0..maxticks;                (* for time measurement *)
    delay = 0..stalllim;                (* spark delay type *)
    tableindex = 0..5;                  (* index to retard table *)
    tableentry = 0..tablemax;           (* entry in table *)
    tabletype = array [tableindex] of tableentry; (* a retard table *)
                                        (* spark retard table *)
                                (* i.e at 2000 rpm, 12 degree retard*)
value sparktable = tabletype(15,12,8,6,2,0);
.DE
.DP
(*
        Rule function used in proofs concerning spark retard table
*)
rule function nonincreasing(a: tabletype; i,j: tableindex): boolean; 
        begin end;
.DE
.DP
(*
        Monitor for interlocking  -  within the monitor processing is
        sequential.

        There is no process associated with this monitor; it exists only
        to protect the shared variables.  The processes clockprocess and
        shaftprocess use the procedures exported from this monitor.
*)
monitor excluder priority 2;
exports
    doclocktick,                        (* called from clock monitor *)
    doshaftpulse;                       (* called from crankshaft monitor *)
imports
    nonincreasing, 
    rpm, angle, ticks,
    tableindex, tableentry, tabletype, tablemax,
    delay,
    sparktable,
    mustrecalc,
    maxticks,
    maxrpm,
    interval, 
    stalllim,
    excluder,
    ms, cylinders, maxsparkretard;

.DE
.DP
(*
        hardware interfaces
*)
type engineinterface = device
        fuelpumpswitch: boolean;        (* fuel pump on-off *)
        firespark: boolean;             (* store into here to fire *)
        end;



                                        (* max spark delay *)
const minrps = 1;                       (* minimum revs/second *)
                                        (* largest time per rev *)
      maxtimeperrev = (ms * 1000) div minrps;
                                        (* worst-case spark delay *)
      maxsparkdelay = stalllim;         (* worst-case spark delay *)
.DE
.DP
var
(*
        monitor global variables
*)
    engine: engineinterface[01000];     (* engine hardware i/o *)

    sparkdelay: 0..maxsparkdelay;       (* between pulse and spark*)
                                        (* angle: pulse to spark *)
    enginespeed: rpm;                   (* actual engine speed *)
    fuelpumpon: boolean;                (* last orders to fuel pump *)
    ticksuntilspark: 0..maxsparkdelay;  (* ticks until next spark needed *)
    tickssinceshaft: ticks;             (* ticks since crankshaft pulse *)
    oldenginespeed: rpm;                (* speed at last spark recalc *)
(*
        global proof variables

        these have no existence in the operational program
        and can be used only in verification statements.
*)
    cylssincespark: extra integer;
    tickssincespark: extra integer;

.DE
.DP
invariant
(*
        The follogin invariants are invariants of the excluder
        module.  These invariants must be true whenever control
        is not in the excluder module.
*)
.DE
.DP
(*
        The following invariants describe real-world constraints to
        be proved about the program.
*)
                        (* if fuel pump is on, spark must occur soon*)
    fuelpumpon implies (tickssincespark < (1000*ms));

                        (* fuel pump must be disabled if the
                           engine is not rotating *)
    (enginespeed < rpm(1)) implies (not fuelpumpon);

                        (* a spark must be issued for each cylinder pulse *)
    cylssincespark <= 1;

.DE
.DP
(*
        The following invariants are needed to help the proof process.
        They must be proven; they are not accepted as given.
*)
                                (* either we have a spark scheduled or
                                   we haven't seen a cylinder pulse
                                   since the last spark
                                *)
           ((cylssincespark > 0)
            and (ticksuntilspark > 0))
         or ((cylssincespark = 0)
             and (ticksuntilspark = 0));
                                (* the invariants below were introduced
                                   during the task of making the program
                                   verifiable *)
                                (* if engine is running, 
                                   spark delay must be set *)
    (enginespeed > 0) implies (sparkdelay > 0);
                                (* also true for last time around *)
    (oldenginespeed > 0) implies (sparkdelay > 0);
                                (* consistency of timers *)
    (cylssincespark = 0) implies (tickssinceshaft >= tickssincespark);
                                (* upper bound on tickssincespark *)
    (enginespeed > 0) implies 
        ((tickssinceshaft + 2*stalllim) >= tickssincespark);
                                (* consistency of tickssincespark *)
    (enginespeed > 0) implies 
        ((tickssincespark + ticksuntilspark) <= 2*stalllim);
                                (* if timeout, stalled *)
    (tickssinceshaft > stalllim) implies (enginespeed = 0);
                                (* fuel pump locked to engine speed *)
    (enginespeed > 0) = fuelpumpon;
                                (* old speed reset after stall *)
    (oldenginespeed = 0)  =  (enginespeed = 0);
                                (* definedness conditions *)
    defined(enginespeed);
    defined(ticksuntilspark);
    defined(tickssinceshaft);
    defined(fuelpumpon);
    defined(cylssincespark);
    defined(tickssincespark);
    defined(oldenginespeed);
    defined(sparkdelay);
    defined(excluder);
.DE
.DP
(*
        spark  --  fire spark and update counters
*)
procedure spark;
    exit tickssincespark = 0;
         cylssincespark = 0;
begin
    engine.firespark := true;                (* fire spark *)
    proof tickssincespark := 0;              (* update proof variables *)
    proof cylssincespark := 0;
end (* spark *);
.DE
.DP
(*
        fuelpumpset  --  check engine speed and set fuel pump
*)
procedure fuelpumpset;
exit fuelpumpon = (enginespeed.old > 0);     (* on iff engine running *)
begin
    fuelpumpon := enginespeed > 0;   (* turn on iff engine running *)
    engine.fuelpumpswitch := fuelpumpon;(* DEVICE I/O *)
end (* fuelpumpset *);
.DE
.DP
(*
    doclocktick  --  called from clock monitor on every tick

    this procedure issues the spark command when required, and
    turns the fuel pump on and off based on engine rpm.
*)
procedure doclocktick;
begin
     proof if tickssincespark < maxticks then (* count time for 
                                                spark proof *)
        tickssincespark := tickssincespark + 1;

     if tickssinceshaft < maxticks then     (* avoid timer overflow *)
         tickssinceshaft :=       (* used to compute inverse of rpm *)
         tickssinceshaft + 1;

     if tickssinceshaft >= stalllim then (* check for stalled engine *)
     begin
         enginespeed := 0;                  (* engine is not rotating *)
         oldenginespeed := 0;               (* forget past history *)
          proof cylssincespark := 0;        (* forget about spark history *)
         proof tickssincespark := 0;        (* forget about spark history *)
         tickssinceshaft := 0;              (* forget about crank history *)
         ticksuntilspark := 0;              (* unschedule spark *)
         end;

                                            (* spark timing *)
     if ticksuntilspark > 0 then            (* if spark scheduled *)
     begin                         (* count down time until spark *)
        ticksuntilspark := ticksuntilspark - 1;
        if ticksuntilspark = 0 then spark;  (* fire spark if time *)
     end;
     fuelpumpset;                           (* decide fuel pump on/off *)
end; (* doclocktick *)
.DE
.DP
(*
        recalcretard  --  recalculate the spark offset

    This is called only when engine RPM changes by a significant amount.
    The calculation is by linear interpolation from a table.
*)
procedure recalcretard;
exit (enginespeed.old > 0) implies (sparkdelay > 0);
     oldenginespeed = enginespeed.old;
                                            (* retard at 1000 rpm int*)
type tdiff = 0..tablemax;                   (* table difference *)
var
    low, high: tableentry;                  (* value in table *)
    diff: tdiff;                          (* difference between neighbors *)
    offset: 0..interval;                    (* offset from start of entry *)
    i: tableindex;                          (* which entry *)

const tickspersec = 1000*ms;                (* ticks per second *)
                                       (* really need fixed-point here *)
      k = (tickspersec div 360) * 60;  (* convert degrees to rpm-ticks *)
var sparkretard: angle;                (* calculated spark retardation *)
    delaywork: 0..45*k;                     (* largest possible value *)
begin
                                        (* force case analysis for table *)
    assert(nonincreasing(sparktable,0,0));  (* table is monotonic *)
    assert(nonincreasing(sparktable,0,1));  (* table is monotonic *)
    assert(nonincreasing(sparktable,0,2));  (* table is monotonic *)
    assert(nonincreasing(sparktable,0,3));  (* table is monotonic *)
    assert(nonincreasing(sparktable,0,4));  (* table is monotonic *)
    assert(nonincreasing(sparktable,0,5));  (* table is monotonic *)

    i := tableindex(enginespeed div interval); (* calc table index *)
    assert(sparktable[i] >= sparktable[i+1]); (* goal for rule *)
    offset := enginespeed mod interval;  (* offset from last entry *)
    low := sparktable[i];                (* table entry from low side *)
    high := sparktable[i+1];             (* table entry from high side *)
    assert(high <= low);                 (* this is a decreasing table *)
    diff := tdiff(low - high);           (* difference in this interval *)
                                         (* linear interpolation *)
    sparkretard := angle(high + (diff * offset) div interval);
    assert(sparkretard <= maxsparkretard);  (* not too much *)
                                            (* compute delay until spark *)
    sparkdelay := 0;                        (* assume 0 (no spark) *)
    if enginespeed > 0 then begin           (* if engine turning *)
                                            (* compute spark delay *)
        delaywork := ((k*sparkretard) div enginespeed) + 1;
                                           (* avoid oversize delay 
                                              at low rpm *)
        if delaywork <= (stalllim div 2) then sparkdelay := delay(delaywork)
                                         else sparkdelay := delay(stalllim);
    end;
    oldenginespeed := enginespeed;          (* save speed at last calc *)
end; (* recalcretard *)
.DE
.DP
(*
        doshaftpulse  --  handle crankshaft pulse
*)
procedure doshaftpulse;
var speedchange: integer;                   (* local for calculation *)
    rpmwork: 0..20000;                      (* working RPM *)
begin
    if ticksuntilspark > 0 then begin       (* if spark still in future *)
                                      (* TROUBLE: clock may have failed *)
        spark;                         (* force spark now, poorly timed *)
        end;

    assert(cylssincespark = 0);             (* must not miss spark *)
    proof cylssincespark        (* we try to prove this never reaches 2 *)
           := cylssincespark + 1;
                                            (* engine speed computation *)
    if (tickssinceshaft > 0) then begin
                                            (* compute new rpm *)
        rpmwork := 1 + (60*ms*(1000 div cylinders)) div
                tickssinceshaft;
        assert(rpmwork > 0);            (* must be running if cyl pulse *)
        if rpmwork > maxrpm then        (* limit measured engine speed *)
            enginespeed := maxrpm 
        else enginespeed := rpm(rpmwork);
        tickssinceshaft := 0;               (* clear shaft timer *)
    end else begin                     (* TROUBLE: probable clock fail *)
        enginespeed := rpm(1);              (* assume minimum RPM *)
        end;
                                            (* recalc spark if speed chg*)
    if oldenginespeed = 0 then begin        (* engine just started *)
        ticksuntilspark := 0;          (* clear all timers and counters *)
        tickssinceshaft := 0;
        proof tickssincespark := 0;
        recalcretard;                       (* recalc spark retardation *)
    end else begin                          (* engine did not just start *)
        speedchange := enginespeed - oldenginespeed; (* calc speed change *)
                                            (* take abs value *)
        if speedchange < 0 then speedchange := - speedchange; 
        if (speedchange > mustrecalc) then  (* if big change *)
            recalcretard;                   (* go recalculate spark *)
        end;                                (* end time to recalculate *)

    ticksuntilspark := sparkdelay;          (* schedule next spark *)
    fuelpumpset;                            (* turn fuel pump on *)
end (* doshaftpulse *);
.DE
.DP
begin
(*
        initialization
*)
    enginespeed := 0;                       (* start with engine stopped *)
    ticksuntilspark := 0;
    tickssinceshaft := 0;
    sparkdelay := 0;
    fuelpumpon := false;
    proof cylssincespark := 0;
    proof tickssincespark := 0;
    oldenginespeed := 0;                    (* original speed is zero *)
end; (* excluder *)
.DE
.DP
(*
        shaft signal process - once per cylinder time
*)
monitor shaftprocess priority 2;
imports excluder, rpm, doshaftpulse;
entry defined(excluder);                    (* must be defined at INIT *)
invariant defined(excluder);                (* must stay defined *)

var
    shaftpulse: signal[0002B];         
                                            (* crankshaft pulse interrupt *)
(*
        shaft processing loop
*)
begin
    while true do begin
        wait(shaftpulse);                   (* wait for shaft pulse *)
        doshaftpulse;                       (* handle shaft pulse *)
        state(defined(excluder));           (* loop invariant *)
    end;                                    (* end forever loop *)
end; (* shaftprocess *)
.DE
.DP
(*
        clock monitor

        all the processing is done in the shaft monitor.
*)
monitor clockprocess priority 2;
imports excluder, doclocktick;              (* from shaft *)
entry defined(excluder);                    (* must be defined at INIT *)
invariant defined(excluder);                (* must stay defined *)
var hardwareclock: signal[0004B];           (* clock interrupt *)
begin
    while true do
        begin wait(hardwareclock);          (* wait for clock interrupt *)
              doclocktick;                  (* handle clock interrupt *)
              state(defined(excluder));     (* loop invariant *)
        end;
end;                                        (* end of clock monitor *)
.DE
.DP
(*
        main program
*)
begin
    init excluder;                          (* initialize variables *)
    init shaftprocess;                      (* start crankshaft process *)
    init clockprocess;                      (* start clock process *)
end.

.DE
.P
Verification of this program takes about one hour and seven minutes
on a VAX 11/780, without
any previous history being available.  This does not include the 
building of some necessary rules about the function
.I nonincreasing
with the Rule Builder.
are sufficient to verify this program.
.P
.DP
Verifying clockprocess 
No errors detected

Verifying excluder 
No errors detected

Verifying excluder-doclocktick 
No errors detected

Verifying excluder-doshaftpulse 
No errors detected

Verifying excluder-fuelpumpset 
No errors detected

Verifying excluder-recalcretard 
No errors detected

Verifying excluder-spark 
No errors detected

Verifying shaftprocess 
No errors detected

Verifying simpleengine 
No errors detected
.DE
