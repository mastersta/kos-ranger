//RANGER
//Reentry Assessment, Navigation, Guidance, and Error Reduction
//Created by lonespace, 2026
//Licensed uner GPLv3


@lazyglobal off.

copypath("0:/kslib/ranger/ranger_init.ks", "1:/").
print "copied ranger_init.ks".
copypath("0:/kslib/ranger/ranger_geo.ks", "1:/").
print "copied ranger_geo.ks".
copypath("0:/kslib/ranger/ranger_control.ks", "1:/").
print "copied ranger_control.ks".
copypath("0:/kslib/ranger/ranger_display.ks", "1:/").
print "copied ranger_display.ks".
copypath("0:/kslib/ranger/ranger_misc.ks", "1:/").
print "copied ranger_misc.ks".

//runpath("1:/ranger_init.ks.").
//runpath("1:/ranger_geo.ks.").
//runpath("1:/ranger_control.ks.").
//runpath("1:/ranger_display.ks.").
//runpath("1:/ranger_misc.ks.").
run ranger_init.
run ranger_geo.
run ranger_control.
run ranger_display.
run ranger_misc.



//=====DATA STORAGE=====
global rangerLex to lexicon().
set rangerLex:lastRollReversalTime to time:seconds.
set rangerLex:rollDirection to 0.  //1 for left roll, -1 for right roll
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
    set rangerLex:totalError to getErrorDistance().
    set rangerLex:downrangeError to getDownrangeError().
    set rangerLex:crossrangeError to getCrossrangeError().

}.



if rangerInit:displayData { rangerDisplayInit(). }.

//=====MAIN FUNCTION=====
function getRangerGuidance {
    
    if not(abort) {

        updateRangerLex().


        local shipProgradeVec to ship:velocity:surface.

        local targetRoll to rangerLex:downrangeError * rangerInit:bankGain.

        set rangerLex:targetRoll to clamp(
            rangerInit:minimumBank,
            targetRoll,
            rangerInit:maximumBank
        ) * rangerLex:rollDirection.

        if rangerInit:displayData { rangerDisplayUpdate(). }.

        local rollDirection to angleaxis(rangerLex:targetRoll, shipProgradeVec) *
            lookdirup(shipProgradeVec, ship:up:forevector).

        local pitchDirection to angleaxis(-rangerInit:angleOfAttack, rollDirection:starvector) * 
            rollDirection.

        if rangerInit:displayVecDraws {
            set steerVecDraw:vec to pitchDirection:forevector.
            set steerTopVecDraw:vec to pitchDirection:topvector.
        }.

        set steerVecDraw:show to rangerInit:displayVecDraws.
        set steerTopVecDraw:show to rangerInit:displayVecDraws.

        //If in the atmosphere, use the calcuated roll vector
        if ship:altitude < ship:body:atm:height {
            return pitchDirection.

        //If ship is above the atmosphere, use surface prograde for steering
        } else {
            return lookdirup(shipProgradeVec, ship:up:forevector).
        }.


    } else {

        unlock steering.


        if rangerInit:displayData {
            clearscreen.
        }.

        print "RANGER GUIDANCE COMPLETE".
        print "MANUAL CONTROL REESTABLISHED".
        clearvecdraws().
    }.

}
