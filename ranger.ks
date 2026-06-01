//RANGER
//Reentry Assessment, Navigation, Guidance, and Error Reduction
//Created by lonespace, 2026
//Licensed uner GPLv3


@lazyglobal off.


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




//=====DATA STORAGE=====
global rangerLex to lexicon().
set rangerLex:lastRollReversalTime to time:seconds.
set rangerLex:rollDirection to 1.  //1 for left roll, -1 for right roll; initialized to left roll
function updateRangerLex {
    set rangerLex:impactPos to addons:tr:impactpos.
    set rangerLex:impactLatRads to constant:degToRad * rangerLex:impactPos:lat.
    set rangerLex:impactLonRads to constant:degToRad * rangerLex:impactPos:lng.

    set rangerLex:targetPos to addons:tr:gettarget.
    set rangerLex:targetLatRads to constant:degToRad * rangerLex:targetPos:lat.
    set rangerLex:targetLonRads to constant:degToRad * rangerLex:targetPos:lng.

    set rangerLex:latDiff to rangerLex:impactLatRads - rangerLex:targetLatRads.
    set rangerLex:lonDiff to rangerLex:impactLonRads - rangerLex:targetLonRads.

    set rangerLex:rollDirection to getRollDirection().
}.




//=====ERROR CALCULATIONS=====

//Returns the distance between the impact point and the target point in meters, regardless of direction
function getErrorDistance {
    local squareHalfChord to 
        sin(rangerLex:latDiff / 2) ^ 2 + 
        cos(rangerLex:impactLatRads) * 
        cos(rangerLex:targetLatRads) * 
        sin(rangerLex:lonDiff / 2) ^ 2.

    local angularDistanceRads to 2 * arctan2(sqrt(squareHalfChord), sqrt(1 - squareHalfChord)).
    return angularDistanceRads * ship:body:radius. //convert from radians to meters
}.


//Returns the angle between the impact point and the target point, taking into account the heading of the ship
//Uses the Haversine formula
function getRelativeBearingError {
    local y to 
        sin(rangerLex:lonDiff) * 
        cos(rangerLex:impactLatRads).
    local x to 
        cos(rangerLex:targetLatRads) * 
        sin(rangerLex:impactLatRads) - 
        sin(rangerLex:targetLatRads) * 
        cos(rangerLex:impactLatRads) * 
        cos(rangerLex:lonDiff).

    local thetaImpact to arctan2(y, x).
    
    return thetaImpact - getThetaHeading().
}.

//Returns the heading of the ship at the predicted impact point
//TODO: fix for non-equatorial targets
function getThetaHeading {
    return choose  
        (90 + ship:obt:inclination)
        if (ship:geoposition:lat < 90)
        else (90 - ship:obt:inclination).
}.

//Returns downrange error in meters; positive is downrange, negative is uprange
function getDownrangeError {
    return getErrorDistance * cos(getRelativeBearingError).
}.


//Returns crossrange error in meters; positive is right of course, negative is left of course
function getCrossrangeError {
    return getErrorDistance * sin(getRelativeBearingError).
}.


//Returns the direction of roll correction; positive is left roll, negative is right roll
function getRollDirection {
    local output to rangerLex:rollDirection.

    if rangerInit:rollReversalMode = "range" {
        if      getCrossrangeError() > (rangerInit:crossrangeTolerance)       { set output to 1. }
        else if getCrossrangeError() < (rangerInit:crossrangeTolerance * -1)  { set output to -1.}.

    } else if rangerInit:rollReversalMode = "time" {
        if time:seconds > (rangerLex:lastRollReversalTime + rangerInit:timeBetweenReversals) {
            if getCrossrangeError() > 0 { set output to 1. }
            else                        { set output to -1.}.

            set rangerLex:lastRollReversalTime to time:seconds.
        }.

    } else if rangerInit:rollReversalMode = "both" {
        if getCrossrangeError() > (rangerLex:crossrangeTolerance) {
            set output to 1.
            set rangerLex:lastRollReversalTime to time:seconds.
            
        } else if getCrossrangeError() < (rangerLex:crossrangeTolerance * -1) {
            set output to -1.
            set rangerLex:lastRollReversalTime to time:seconds.
        }.

        if time:seconds > (rangerLex:lastRollReversalTime + rangerInit:timeBetweenReversals) {
            if getCrossrangeError() > 0 { set output to 1. }
            else                        { set output to -1.}.

            set rangerLex:lastRollReversalTime to time:seconds.
        }.

    }.

    //TODO: add in smooth roll reversal
    return output.
}.


//TODO: add data display functions


//=====Create Vecdraws=====
local steerVecDraw to vecDraw(
    v(0,0,0),
    steeringDir:forevector,
    rgb(1,0,0),
    "SteeringVec",
    20.0,
    false,
    0.01
).

local steerTopVecDraw to vecDraw(
    v(0,0,0),
    steeringDir:topvector,
    rgb(0,1,0),
    "",
    10.0,
    false,
    0.01
).


function clamp { parameter minval, val, maxval. return max(minval, min(maxval, val)). }.

//=====MAIN FUNCTION=====
function getRangerGuidance {
    
    if not(abort) {

        updateRangerLex().

        local shipProgradeVec to ship:velocity:surface.

        local targetRoll to getDownrangeError() * rangerInit:bankGain.

        set rangerLex:targetRoll to clamp(
            rangerInit:minimumBank,
            targetRoll,
            rangerInit:maximumBank
        ) * rangerLex:rollDirection.


        local rollDirection to angleaxis(rangerLex:targetRoll, shipProgradeVec) *
            lookdirup(shipProgradeVec, ship:up:forevector).

        local pitchDirection to angleaxis(-rangerInit:angleOfAttack, rollDirection:starvector) * 
            rollDirection.

        if rangerInit:displayVecDraws {
            set steerVecDraw:vec to pitchDirection:forevector.
            set steerTopVecDraw:vec to pitchDirection:topvector.
        }.

        set steerVecDraw:visible to rangerLex:displayVecDraws.
        set steerTopVecDraw:visible to rangerLex:displayVecDraws.

        //If in the atmosphere, use the calcuated roll vector
        if ship:altitude < ship:body:atm:height {
            return pitchDirection.

        //If ship is above the atmosphere, use surface prograde for steering
        } else {
            return lookdirup(shipProgradeVec, ship:up:forevector).
        }.


    } else { unlock steering. }.

}
