
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
    
    local output to thetaImpact - getThetaHeading().



    return output.


}.

//Returns the heading of the ship at the predicted impact point
function getThetaHeading {
    local output to arcsin(
        clamp(
            -1,
            cos(ship:orbit:inclination) / cos(addons:tr:impactpos:lat),
            1
        )
    ).

    if ship:latitude > 0 { set output to 180 - output. }.
    if ship:orbit:inclination > 90 { set output to mod(360 + output,360). }.

    return output.
}.

//Returns downrange error in meters; positive is downrange, negative is uprange
function getDownrangeError {
    return getErrorDistance * cos(getRelativeBearingError).
}.


//Returns crossrange error in meters; positive is right of course, negative is left of course
function getCrossrangeError {
    return getErrorDistance * sin(getRelativeBearingError).
}.
