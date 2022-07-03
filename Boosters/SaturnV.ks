//Prelaunch
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SET TERMINAL:HEIGHT TO 65.
SET TERMINAL:WIDTH TO 45.
SET TERMINAL:BRIGHTNESS TO 0.8.
SET TERMINAL:CHARHEIGHT TO 10.
// Get Mission Values

local wndw is gui(300).
set wndw:x to 700. //window start position
set wndw:y to 120.


local label is wndw:ADDLABEL("Enter Booster Values").
set label:STYLE:ALIGN TO "CENTER".
set label:STYLE:HSTRETCH TO True. // Fill horizontally

local box_inc is wndw:addhlayout().
	local inc_label is box_inc:addlabel("Heading").
	local incvalue is box_inc:ADDTEXTFIELD("90").
	set incvalue:style:width to 100.
	set incvalue:style:height to 18.

local box_pitch is wndw:addhlayout().
	local pitch_label is box_pitch:addlabel("Start Pitch").
	local pitchvalue is box_pitch:ADDTEXTFIELD("87.25").
	set pitchvalue:style:width to 100.
	set pitchvalue:style:height to 18.

local box_APalt is wndw:addhlayout().
	local APalt_label is box_APalt:addlabel("End AP(km)").
	local APaltvalue is box_APalt:ADDTEXTFIELD("191.1").
	set APaltvalue:style:width to 100.
	set APaltvalue:style:height to 18.

local box_PEalt is wndw:addhlayout().
	local PEalt_label is box_PEalt:addlabel("End PE(km)").
	local PEaltvalue is box_PEalt:ADDTEXTFIELD("191.1").
	set PEaltvalue:style:width to 100.
	set PEaltvalue:style:height to 18.

local box_TAR is wndw:addhlayout().
	local TAR_label is box_TAR:addlabel("Launch Target").
	local TARvalue is box_TAR:ADDTEXTFIELD("Earth").
	set TARvalue:style:width to 100.
	set TARvalue:style:height to 18.

local box_OFF is wndw:addhlayout().
	local OFF_label is box_OFF:addlabel("Avg time to orbit (s)").
	local OFFvalue is box_OFF:ADDTEXTFIELD("360").
	set OFFvalue:style:width to 100.
	set OFFvalue:style:height to 18.

local box_Stg is wndw:addhlayout().
	local Stg_label is box_Stg:addlabel("PEG Stages").
	local Stgvalue is box_Stg:ADDTEXTFIELD("3").
	set Stgvalue:style:width to 100.
	set Stgvalue:style:height to 18.

local box_Res is wndw:addhlayout().
	local Res_label is box_Res:addlabel("Restart Location").
	local Resvalue is box_Res:ADDTEXTFIELD("0").
	set Resvalue:style:width to 100.
	set Resvalue:style:height to 18.

local somebutton is wndw:addbutton("Confirm").
set somebutton:onclick to Continue@.

// Show the GUI.
wndw:SHOW().
LOCAL isDone IS FALSE.
UNTIL isDone {
	WAIT 1.
}
Function Continue {

		set val to incvalue:text.
		set val to val:tonumber(0).
		Global gv_intAzimith is val.

		set val to pitchvalue:text.
		set val to val:tonumber(0).
		set gv_anglePitchover to val.

		set val to APaltvalue:text.
		set val to val:tonumber(0).
		Global tgt_ap is val*1000.

		set val to PEaltvalue:text.
		set val to val:tonumber(0).
		Global tgt_pe is val*1000.

		set val to TARvalue:text.
		set val to body(val).
		set L_TAR to val.

		set val to OFFvalue:text.
		set val to val:tonumber(0).
		set L_OFF to val.

		set val to Stgvalue:text.
		set val to val:tonumber(0).
		set Stg to val.

		set val to Resvalue:text.
		set val to val:tonumber(0).
		set runmode to val.

	wndw:hide().
  	set isDone to true.
}

Print "Azi: " + gv_intAzimith.
Print "Start Pitch: " + gv_anglePitchover. 
Print "AP at: " + tgt_ap + "m".
Print "PE turn at: " + tgt_pe + "m". 
Print "Target: " + L_TAR.
Print "Offset: " + L_OFF.
Print ship:GEOPOSITION:lat.

// Mission Values

Global gv_ext is ".ks".
Local ClearanceHeight is 130. 

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
ff_partslist(). //stand partslist create

///////////////////////////Lift Off Start up /////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

If runmode = 0{
	Wait 1. //Alow Variables to be set and Stabilise pre launch
	Print "Mission start".
	Print Stage:number.
	Print ship:mass.
	Print ship:drymass.
	Set basetime to time:seconds + 18.
	ff_preLaunch().
	ff_liftoff(0.98, 10).
	Global liftoff is time:seconds.
	Print ship:mass.
	Print ship:drymass.
	ff_liftoffclimb(gv_anglePitchover, gv_intAzimith, ClearanceHeight).
	Global Base_alt is alt:radar.
 	ff_GravityTurnAoA(gv_intAzimith, "fuelnostage", 0.0, 0.15, 1).// operate until 15% fuel fraction then shut down engine	
	Print "CECO "+ (time:seconds - liftoff).//135s
	FOR eng IN engList { 
		IF eng:TAG ="F1-C"{ 
			eng:shutdown. 
		}
	}

	ff_GravityTurnAoA(gv_intAzimith, "fuelnostage", 0.0, 0.06, 1).// operate until 6% fuel fraction then tilt arrest	
	Print "Tilt Arrest Enabled "+ (time:seconds - liftoff).//153
	set tiltArrest to ship:facing:vector.
	LOCK STEERING TO tiltArrest. //maintain current alignment
	Set Endstage to false.
	Until Endstage {
		set Endstage to ff_Flameout("fuelnostage", 0.0, 0.012, 1).// MECO at 1.2% fuel fraction then shut down all engines
		Wait 0.01.
	}
	Lock Throttle to 1.
	Print "MECO:"+(time:seconds - liftoff).//161
	Print "Speed: " + SHIP:AIRSPEED.
	Print "Altitude: " + altitude.
	Print ship:mass.
	Print ship:drymass.
	FOR eng IN engList { 
		IF eng:TAG ="F1-4" or eng:TAG ="F1-2" or eng:TAG ="F1-1" or eng:TAG ="F1-3" or eng:TAG ="F1-C"{ 
			eng:shutdown. 
		}
	}
	Wait 0.05.
	// Ullage motors
	Stage.
	Wait 0.15.
	//release S-IC
	wait until stage:ready.
	Stage.
	//S-II engine start
	Wait 0.1.
	wait until stage:ready.
	Stage.
	Print "Second Stage Ignition".
	Print ship:mass.
	Print ship:drymass.
	Set runmode to 0.1.
}

If runmode = 0.1{

//Global function variables for PEG function
	Global pegbasetime is time:seconds.
	Global PEG_I is 0.
	Global HSL is 8.
	Global T3 is 20. //143
	Global T2 is 56.
	Global T1 is 321. //321
	Global tau_lock is false.
	Global s_acc is 0. //defind in PEG
	Global s_vx_offset is 0.
	Global s_vx is 0. //defind in PEG
	Global tgt_vx is 0. //defind in PEG
	Global tgt_pex is tgt_pe.

	ff_Orbit_Steer( //use the internal orbit steer function not the launch atm version
		Stg,//Stages
		tgt_pe,
		tgt_ap,
		gv_intAzimith,
		0,//Target true anomoly
		HSL, //end shutdown margin
	//Stage 3
		T3, // stage three estimated burn length
		214, //estimated mass flow(kg/s)
		166571, //estimated start mass in kg
		4205, //estimated exhuast vel (thrust(N)/massflow(kg/s))
		777, //(S-Ve/avg_acc) estimated effective time to burn all propellant S-Ve = ISP*g0
	//Stage 2 //
		T2, // stage two estimated burn length
		727, //estimated mass flow(kg/s)
		254600, //estimated start mass in kg
		4198, //estimated exhuast vel (thrust(kN)/massflow(kg/s))
		347, //(S-Ve/avg_acc) estimated effective time to burn all propellant
	//Stage 1 //
		T1, // stage one estimated burn length
		1239, //estimated mass flow
		4169.23, //estimated exhuast vel (do not make 0)
		667, //(S-Ve/avg_acc) estimated effective time to burn all propellant
	// shutdown offset for engine thrusts
		s_vx_offset,
	// first function to do stuff before PEG
		{
			UNTIL time:seconds > (pegbasetime + 30){ //163 engines start, this occors at 193
				wait 0.1.
			}
			Stage.
			Print "S-II aft interstage release".
			Print ship:mass.
			Print ship:drymass.
			//LET release
			UNTIL time:seconds > (pegbasetime + 35){ //198
				wait 0.1.
			}
			Stage.
			Print "S-LET release".
			Print ship:mass.
			Print ship:drymass.
			SET STEERINGMANAGER:MAXSTOPPINGTIME TO 0.10.
		},
	// Second function before thrust check
		{
			//Centre engine cutout
			if (time:seconds > (pegbasetime + 300)) and (PEG_I = 0){ //460
				Local englist is List().
				LIST ENGINES IN engList.
				FOR eng IN engList { 
					IF eng:TAG ="J-2C" { 
						eng:shutdown.
					}
				}
				Print "CECO" AT (0,1).
				Set PEG_I to PEG_I+1.
				Set T1 to 38.//force a new base value
			}

			// Move to IGM phase 2
			if (time:seconds > (pegbasetime + 335)) and (PEG_I = 1){ //495
				Set PEG_I to PEG_I+1.
				Set T1 to 0. //end phase 1
			}

			//High(5.5) to low MRS(4.34) command 
			if (time:seconds > (pegbasetime + 338)) and (PEG_I = 2){ //498
				LIST ENGINES IN engList.
				FOR eng IN engList { 
					IF eng:TAG ="J-2" { 
						Local M is eng:GETMODULE("EMRController").
						M:DOAction("change EMR mode", true).
					}
				}
				Print "Mixture Ratio Shift" AT (0,1).
				Set PEG_I to PEG_I+1.
			}

			// End tau mode
			if (time:seconds > (pegbasetime + 345)) and (PEG_I = 3){ //504
				Set tau_lock to false.
				Print "Tau unlocked" AT (0,3).
				Set PEG_I to PEG_I+1.
				set s_acc to ship:AVAILABLETHRUST/ship:mass.//needs to be reset from remainder of loop
			}
			// SECO and IGM phase 3
			if (AVAILABLETHRUST < 5) and (PEG_I = 4){ //548
				Set T2 to 0. //end phase 2
				FOR eng IN engList { 
					IF eng:IGNITION ="true"{ 
						eng:shutdown. 
					}
				}
				Print "SECO" AT (0,1). 

				// ullage motors
				Wait 0.1.
				wait until stage:ready.
				Stage.
				//seperation
				Wait 0.1.
				wait until stage:ready.
				Stage.
				//engine start
				wait until stage:ready.
				Stage.
				RCS on.
				FOR eng IN engList { 
					IF eng:TAG ="APS" { 
						eng:shutdown.
					}
					IF eng:TAG ="J-2F" { 
						Local M is eng:GETMODULE("EMRController").
						Print M:GETFIELD("current EMR").
						M:SETFIELD("current EMR",4.93).
						M:DOEvent("Show EMR Controller").
					}
				}
				Set PEG_I to PEG_I+1.
				SET STEERINGMANAGER:MAXSTOPPINGTIME TO 1.
				set s_acc to ship:AVAILABLETHRUST/ship:mass.//needs to be reset from remainder of loop
			}////

			// End tau mode
			if PEG_I = 5{
				Set tau_lock to false.
				Print "Tau unlocked" AT (0,3).
				set s_acc to ship:AVAILABLETHRUST/ship:mass.//needs to be reset from remainder of loop
			}
		},

		// Third function before HSL
		{
			//cutoff process
			if  (T3 < HSL) and (tau_lock = true) and (T2 = 0){
				Until false{
					set s_vx to sqrt(ship:velocity:orbit:sqrmagnitude - ship:verticalspeed^2) + s_vx_offset.
					Local track is time:seconds.
					//Set up for ECO command
					until (ship:orbit:eccentricity < 0.01) or (ship:periapsis > 50000) or (s_vx > (tgt_vx-15)) or (time:seconds > track + HSL) {
						wait 0.5.
						set s_vx to sqrt(ship:velocity:orbit:sqrmagnitude - ship:verticalspeed^2) + s_vx_offset.
					}
					//shutdown engine but keep throttle up for APS
					FOR eng IN engList { 
						IF eng:TAG ="J-2F" { 
							eng:shutdown.
						}
					}
					Print "ECO" AT (0,1).
					Print "APS Phase" AT (0,2).
					Print "Orbit Refinment" AT (0,3).
					set peg_step to 1000.
					//APS ullage command
					FOR eng IN engList { 
						IF eng:TAG ="APS" { 
							eng:activate.
						}
					}
					//Set up for APS shut off
					until (ship:orbit:eccentricity < 0.001) or (ship:periapsis > tgt_pex) or (tgt_vx < s_vx) or (time:seconds > track + 30){
						set s_vx to sqrt(ship:velocity:orbit:sqrmagnitude - ship:verticalspeed^2) + s_vx_offset.
						//Print tgt_vx AT (0,10). //DEBUG
						//Print s_vx AT (0,11). //DEBUG
						//Print ship:orbit:eccentricity AT (0,12). //DEBUG
						//KUniverse:PAUSE(). //DEBUG
						wait 0.001.
					}
					//Shutdown APS
					FOR eng IN engList { 
						IF eng:TAG ="APS" { 
							eng:shutdown.
						}
					}
					Lock Throttle to 0.
					Set SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
					Print "Insertion: "+ (TIME:SECONDS) AT (0,1).
					Print "Hold" AT (0,2).
					RCS off.	
					Set loop_break to true.
					break.
				}
			}	
		},//end of function
		-0.23, //A3 through to B1 intial values to make converge properly
		0.001, //B3
		-0.12, //B1
		0.001, //B2
		-0.12, //A1
		0.001 //B1
	). //end of ff_orbit_steer
	Set runmode to 1.
}

If runmode = 1{
	Local counter is 0.
	Until counter > 240{
		Clearscreen.
		Print "Refine moon transfer to start descent burn before: " + (240-counter).
		wait 1.
		Set Counter to counter +1.
	}
	Set runmode to 1.1.
}

If runmode = 1.1{
	Local englist is List().
	local startTime is time:seconds + nextnode:eta - (ff_Burn_Time(nextnode:deltaV:mag/2, 426, 880, 1)).
	Print (ff_Burn_Time(nextnode:deltaV:mag/2, 426, 880, 1)).
	wait 1.
	///wait for pre mnv setup
	until time:seconds > (startTime -120){
		wait 1.
	}
	Print "Mnv set up".
	RCS on.
	SAS on.
	unlock steering.
	wait 1.
	Set SASMODE to "MANEUVER".
	//wait for ullage
	until time:seconds > (startTime -20){
		wait 1.
	}
	Print "Ullage Start".
	FOR eng IN engList { 
		IF eng:TAG ="APS" { 
			eng:activate.
		}
	}
	lock Throttle to 1.
	SAS off.
	lock steering to nextnode:burnvector.
	///move to J2 and stop ullage
	until time:seconds > (startTime -10){
		wait 1.
	}
	Print "Engine Start".
	FOR eng IN engList { 
		IF eng:TAG ="APS" { 
			eng:shutdown.
		}
	}
	LIST ENGINES IN engList. //Get List of Engines in the vessel
	FOR eng IN engList { 
		IF eng:TAG ="J-2F" { 
			eng:activate.
		}
	}
	wait 0.1.
	Print "EMR setup".
	FOR eng IN engList { 
		IF eng:TAG ="J-2F" { 
			Local M is eng:GETMODULE("EMRController").
			Print M:GETFIELD("current EMR").
			M:SETFIELD("current EMR",4.5).
		}
	}
	///move MRS at 116 seconds in
	until time:seconds > (startTime +116){
		wait 1.
	}
	FOR eng IN engList { 
		IF eng:TAG ="J-2F" { 
			Local M is eng:GETMODULE("EMRController").
			Print M:GETFIELD("current EMR").
			M:SETFIELD("current EMR",5).
		}
	}
	//wait until mnv complete
	until hf_isManeuverComplete(nextnode) {
		wait 0.001.
	}
	lock throttle to 0.
	unlock steering.
	RCS off.
	FOR eng IN engList { 
		IF eng:TAG ="J-2F" { 
			eng:shutdown.
		}
	}
	Print "Burn complete".
	wait 30.
	Shutdown.
}

wait 2.
Print "Stage Finshed".
Shutdown. //ends the script
