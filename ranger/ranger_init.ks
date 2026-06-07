
//=====VALIDATION=====

if not(addons:tr:available) {
    if not(addons:tr:isvertwofour) {
        if not(addons:tr:hasimpact) {
            print "Init Failure: No impact detected".
            abort on.
        }.
        print "Init Failure: Trajectories 2.4 or later required".
        abort on.
    }.
    print "Init Failure: Trajectories not installed".
    abort on.
}.


if not(rangerInit:haskey("angleOfAttack"))          { abort on. print "Init Failure: No AoA specified". }.

if not(rangerInit:haskey("target"))                 { rangerInit:add("target",                  latlng(0.1025, -74.5752)). }. //Vanilla KSC coordinates
if not(rangerInit:haskey("rollReversalMode"))       { rangerInit:add("rollReversalMode",        "range"). }.
if not(rangerInit:haskey("timeBetweenReversals"))   { rangerInit:add("timeBetweenReversals",    60). }.
if not(rangerInit:haskey("crossrangeTolerance"))    { rangerInit:add("crossrangeTolerance",     10000). }.
if not(rangerInit:haskey("smoothReversal"))         { rangerInit:add("smoothReversal",          true). }.
if not(rangerInit:haskey("minimumBank"))            { rangerInit:add("minimumBank",             10). }.
if not(rangerInit:haskey("maximumBank"))            { rangerInit:add("maximumBank",             90). }.
if not(rangerInit:haskey("bankGain"))               { rangerInit:add("bankGain",                1/250). }.
if not(rangerInit:haskey("displayData"))            { rangerInit:add("displayData",             true). }.
if not(rangerInit:haskey("displayVecDraws"))        { rangerInit:add("displayVecDraws",         false). }.



//=====TRAJECTORIES INIT=====
set addons:tr:prograde to true.  //sets all descent modes to prograde
set addons:tr:descentmodes to list(true, true, true, true).  //sets all descent modes to AoA control
set addons:tr:descentangles to list(
    rangerInit:angleOfAttack,
    rangerInit:angleOfAttack,
    0,
    0
).
addons:tr:settarget(rangerInit:target).
clearvecdraws().
