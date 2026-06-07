
//=====Data Display=====
function rangerDisplayInit {
    clearscreen.

    print "=====RANGER GUIDANCE=====" at(0,0).
    print "ERR:" at(0,1).
    print "DRE:" at(0,2).
    print "XRE:" at(0,3).
    print "ROL:" at(0,4).
    print "DIR:" at(0,5).
    print "TTR:" at(0,6).
    print "XTR:" at(0,7).
    print "=========================" at(0,8).

    print "KM"   at(15,1).
    print "KM"   at(15,2).
    print "KM"   at(15,3).
    print "DEG"  at(15,4).
    print "SEC"  at(15,6).
    print "KM"   at(15,7).
}.

function rangerDisplayUpdate {
    print round(rangerLex:totalError / 1000,1)       + "  " at(5,1).
    print round(rangerLex:downrangeError / 1000,1)   + "  " at(5,2).
    print round(rangerLex:crossrangeError / 1000,1)  + "  " at(5,3).
    print round(rangerLex:targetRoll,1)              + "  " at(5,4).
    print choose "L"
        if rangerLex:rollDirection = 1
        else "R"                                 + "  " at (5,5).
    print round(
        time:seconds -
        (rangerLex:lastRollReversalTime +
        rangerInit:timeBetweenReversals),
        1)                                           + "  " at(5,6).
    print round(
        (rangerInit:crossrangeTolerance -
        abs(rangerLex:crossrangeError)) / 1000,
        1)                                           + "  " at(5,7).
}.

//=====Create Vecdraws=====
global steerVecDraw to vecDraw(
    v(0,0,0),
    ship:srfprograde:forevector,
    rgb(1,0,0),
    "SteeringVec",
    50.0,
    false,
    0.01
).

global steerTopVecDraw to vecDraw(
    v(0,0,0),
    ship:srfprograde:topvector,
    rgb(0,1,0),
    "",
    50.0,
    false,
    0.01
).

