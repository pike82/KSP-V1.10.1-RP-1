// Get Booster Values
Print core:tag.


//Wait for launch window //16/07/1969 at 13:32:00 GMT
Set vYear to 19.
Set vDay to 202.
Set vHour to 13.
Set vMinute to 31.
Set vSecond to 59.

Until TIME:YEAR >= vYear and TIME:DAY >= vDay and Time:HOUR >= vHour and Time:MINUTE >= vMinute and Time:SECOND >= (vSecond-17) { // 
    Clearscreen.
    Print TIME:YEAR.
    Print TIME:DAY.
    Print Time:CLOCK.
    Wait 0.001.
}
Set basetime to time:seconds + 18.

Print "Waiting for activation".
//wait for active

Until time:seconds > (basetime + 11524){
    Print "Time until seperation:" + (basetime + 11524 - Time:seconds) at (0,10).
    wait 100.
}

Print "CMD Active".
Lock Throttle to 0.
Set SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.


Until time:seconds > (basetime + 11824){
    Print "Time until seperation:" + (basetime +11824 - Time:seconds) at (0,10).
    wait 10.
}

Clearscreen.
Print "Pilot control for LEM extraction".

Until time:seconds > (basetime + 96298){
    Print "Time until mid course correction:" + (basetime +96298 - Time:seconds) at (0,10).
    wait 10.
}

//80:11:36.6 lunar obit insertion

Until time:seconds > (basetime + 288639.6){
    Print "Time lunar obit insertion:" + (basetime +288639.6 - Time:seconds) at (0,10).
    wait 10.
}

//100:12:00 undocking

Until time:seconds > (basetime + 360720){
    Print "Time Undocking:" + (basetime +360720 - Time:seconds) at (0,10).
    wait 10.
}



//128:03:00 docking

Until time:seconds > (basetime + 460980){
    Print "Time Docking:" + (basetime + 460980 - Time:seconds) at (0,10).
    wait 10.
}

//130:09:31.2 ascent stage jettison

Until time:seconds > (basetime + 468571.2){
    Print "Time ascent jettison:" + (basetime +468571.2 - Time:seconds) at (0,10).
    wait 10.
}

//130:10:30.1 ascent stage seperation

Until time:seconds > (basetime + 468630.1){
    Print "Time ascent move away:" + (basetime +468630.1 - Time:seconds) at (0,10).
    wait 10.
}

//135:23:42.3 trans earth injection

Until time:seconds > (basetime + 468630.1){
    Print "Time Trans earth injection:" + (basetime +468630.1 - Time:seconds) at (0,10).
    wait 10.
}

//150:29:57.4 midcourse correction

//194:49:12.7 CSM separation


Shutdown. //ends the script