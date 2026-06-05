# RANGER
## Reentry Assessment, Navigation, Guidance, and Error Reduction

RANGER provides entry guidance for spaceplanes via constant AoA and dynamic bank angles. It calculates and manages crossrange and downrange errors via bank angle modulation and roll reversal maneuvers. RANGER simply provides a DIRECTION via which your script should use to steer your spaceplane. It does not provide late atmospheric guidance; once your spaceplane is into the normal atmospheric flight regime, you should switch to a more tradtional aircraft guidance system that can handle the complexities of atmospheric flight. Manual flight control can be regained at any time via the ABORT action, either via the backspace key or via command in your script that calls the RANGER update function.

### Dependencies:
* Kerbal Operating System (kOS) version 1.6.0 or higher - may work with older versions, but not tested
* Trajectories 2.4.0 or higher

### Installation:
1. Install kOS and Trajectories mods via CKAN or manually.
2. Download the RANGER script from the GitHub repository:
3. Drop the ranger.ks file into the kOS scripts directory (usually located at `Kerbal Space Program/Ships/Script`).

### Usage:
1. Create a new kOS script that copies the RANGER script to the ship's local archive:
```
copypath("0:/ranger.ks", "1:/").
```

2. Create the rangerInit lexicon that defines the necessary parameters for the RANGER script. The only parameter that's actually required is the Angle Of Attack parameter; RANGER will assume safe defaults for everything else:

|Parameter|Description|Unit|Required|Default Value|
|---|---|---|---|---|
|angleOfAttack|The desired angle of attack to maintain during reentry|degrees|yes||
|target|The targeted landing site as geocoordinates `latlng(latitude, longitude)`|geocoordinates|no|Vanilla KSC coordinates|
|rollReversalMode|"range" reverses bank angle when crossrange error exceeds crossRangeTolerance, "time" reverses bank angle after `timeBetweenReversals` seconds, "both" reverses when either is exceeded|string|no|"range"|
|timeBetweenReversals|The minimum time between roll reversals|seconds|if rollReversalMode is set to "time" or "both"|60|
|crossRangeTolerance|The crossrange error tolerance at which to trigger a roll reversal|meters|if rollReversalMode is set to "range" or "both"|10000|
|smoothReversal *not yet implemented* |Whether to smoothly transition the bank angle during a roll reversal or to immediately switch to the new bank angle|boolean|no|true|
|minimumBank|The minimum bank angle to use. Recommended to keep this at least 10 degrees; if set to 0, the script may not be able to correct for crossrange errors if the downrange error is negative|degrees|no|10|
|maximumBank|The maximum bank angle to use. Recommended to keep this at least 60 degrees; if set too low, the script may not be able to correct for large downrange errors if the downrange error is positive|degrees|no|90|
|bankGain|The proportional gain for calculating the bank angle based on the downrange error. Higher values will result in more aggressive bank angle adjustments, while lower values will result in smoother but slower corrections. Adjust this value based on the performance of your spaceplane and the desired responsiveness|degrees per meter|no|0.004|
|displayData|Whether to display real-time guidance data on the terminal while RANGER is active. Set to false to use your own custom data display|boolean|no|true|
|displayVecDraws|Whether to display vecdraws that show where the script is directing the spaceplane to point|boolean|no|false|

```
global rangerInit to lexicon(
    "angleofAttack",            40,
    "target",                   latlng(0.1025, -74.5752), // KSC coordinates
    "rollReversalMode",         "both",
    "timeBetweenReversals",     90,
    "crossRangeTolerance",      10000,
    "smoothReversal",           true,
    "minimumBank",             10,
    "maximumBank",             90,
    "bankGain",                0.004,
    "displayData",             true,
    "displayVecDraws",         false
).
```

3. Call the RANGER update function in your main control loop. Include an exit condition to break out of the loop once RANGER has completed its guidance. Also set a steering variable prior to the loop, and LOCK STEERING to it. Be sure to unlock the steering afterwards.


```
local reentrySteering to ship:facing.
lock steering to reentrySteering.

until ship:velocity:surface:mag < 1200 {
    set reentrySteering to getRangerGuidance().
}

unlock steering.
```
    
RANGER will discontinue providing active guidance if the ABORT action is triggered, however your loop should also take the ABORT action into account as an exit condition. You can add another line to your UNTIL loop to break free if this happens:
```
until ship:velocity:surface:mag < 1200 or abort {
    set reentrySteering to getRangerGuidance().
}
```

You can also set up ABORT conditions in the main loop that trigger if the guidance gets out of certain bounds that you would like to maintain, such as if the downrange or crossrange errors get too high. This is left up to you to determine, as every spaceplane design is different.

# Other Notes:
* RANGER is only designed to provide a steering DIRECTION. You may use the built-in KOS steering controller, or write your own if it would better suit your needs.
* RANGER will typically maintain a few kilometers of overshoot by virtue of it using a simple proportional controller to manage bank angle based on downrange error. In my testing, the downrange error tends to drop off to a kilometer or two of undershoot as the spaceplane slows and loses lift in the final stages of reentry. This is usually not an issue, as the spaceplane will still be at roughly 30-40km of altitude when RANGER guidance becomes useless, leaving you plenty of energy to manage the final descent to the runway.
* RANGER intentionally sets up the Trajectories AoA descent angles so that the `low altitude` and `final approach` segments are set to zero degrees. This is so that Trajectories will intentionally underestimate your final glide and give you some extra energy for approach to the runway.
* Be mindful that your spaceplane may have the ABORT action set to perform certain functions on your spaceplane that may be undesirable to trigger accidentally.
