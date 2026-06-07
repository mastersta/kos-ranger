

local rollFirstCalc to true.

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
    
        if time:seconds > (rangerLex:lastRollReversalTime + rangerInit:timeBetweenReversals) {
            if getCrossrangeError() > 0 { set output to 1. }
            else                        { set output to -1.}.

            set rangerLex:lastRollReversalTime to time:seconds.
        }.

        if getCrossrangeError() > (rangerLex:crossrangeTolerance) {
            set output to 1.
            set rangerLex:lastRollReversalTime to time:seconds.
            
        } else if getCrossrangeError() < (rangerLex:crossrangeTolerance * -1) {
            set output to -1.
            set rangerLex:lastRollReversalTime to time:seconds.
        }.


    }.

    if rollFirstCalc = true {
        set output to choose 
            1
            if getCrossrangeError() > 0
            else -1.
        set rollFirstCalc to false.
    }.
    

    //TODO: add in smooth roll reversal
    return output.
}.

