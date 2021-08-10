@LAZYGLOBAL OFF.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SET TERMINAL:HEIGHT TO 65.
SET TERMINAL:WIDTH TO 45.
SET TERMINAL:BRIGHTNESS TO 0.8.
SET TERMINAL:CHARHEIGHT TO 10.

Local ClearanceHeight is 10. 
Global gv_ext is ".ks".
Global RunMode is 0.1.

PRINT ("Initialising libraries").
//Initialise libraries first

FOR file IN LIST(
	"Launch_atm"+ gv_ext,
	"Util_Vessel"+ gv_ext,
	"Util_Engine"+ gv_ext)
	{ 
		RUNONCEPATH("0:/Library/" + file).
		wait 0.001.	
	}

if runMode = 0.1 { 
	Print "Run mode is:" + runMode.
	ff_preLaunch().
	ff_liftoff().
	ff_liftoffclimb(87).
	set runMode to 1.1.
}	

if runMode = 1.1 { 
	Print "Run mode is:" + runMode.
	Wait until Stage:Ready.
	ff_GravityTurnAoA().
	set runMode to 2.1.
}	

if runMode = 2.1 { 
	Print "Run mode is:" + runMode.
	ff_coastT(90).
 	set runMode to 3.1.
}	

if runMode = 3.1 { 
	Print "Run mode is:" + runMode.
	ff_SpinStab().
	wait 30.
	set runMode to 4.1.
}

if runMode = 4.1 { 
	Print "Run mode is:" + runMode.
	LOCK Throttle to 1.
	wait 15. //ullage
	Stage. //jettison avionics and start engine
	Print "Avionics Jet".
	set runMode to 5.1.
}
if runMode = 5.1 { 
	Print "Run mode is:" + runMode.
	Local Endstage is false.
	Until Endstage {
		set Endstage to ff_FLAMEOUT("RCS", 0.01).
		Wait 0.05.
	}
}