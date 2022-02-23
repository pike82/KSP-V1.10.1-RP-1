CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
SET TERMINAL:HEIGHT TO 65.
SET TERMINAL:WIDTH TO 45.
SET TERMINAL:BRIGHTNESS TO 0.8.
SET TERMINAL:CHARHEIGHT TO 10.
SET CONFIG:IPU to 150.

///preset trim values
global up_trim is -30. // m/s when to stick only upright on landing-30
global leg_trim is 200. // height to deploy legs
global stop_trim is 0. // target distance below surface to force landing (noramlly negative for underground but plus for drone ships).20
global dist_trim is 1000. // dist from landing to target margin in which can stop boost back.
Global radarOffset is -48.	 // The value of alt:radar when landed (on gear)
Global grndOffset is 0. //Distance above the ground of the landing spot (ie. bulding).
Global EngineStartTime is TIME:SECONDS.
Global Start_mass is ship:mass.

//Global gl_TargetLatLng is SHIP:GEOPOSITION.
//Print SHIP:GEOPOSITION.
//lock pitch to 90 - vectorangle(ship:up:forevector, ship:facing:forevector). //navball pitch (read only)
//set northPole to latlng(90,0).
//lock head to mod(360 - northPole:bearing,360). //navball heading (read only)

//RTLS co-ords
//Global gl_TargetLatLng is latlng(28.6083886236549, -80.5997508056089). // Exact Landing Pad Coords
// Global gl_TargetLatLng is latlng(28.6083886236549, -80.5982). // Next to Landing Pad Coords
//Global gl_TargetLatLng is latlng(28.6083895, -80.60527). // VAB Landing Pad Coords
Global gl_TargetLatLng is latlng(28.49751, -80.53525). // Spacex LZ-1, long bigger negative goes west
lock mapDist to ((ship:altitude^2)*0.0000082)+(ship:altitude*0.216)+10.

//Droneship co-ords
//Global gl_ALT_TargetLatLng is latlng(28.45, -74.30). 

// Get Booster Values
Print core:tag.
local wndw is gui(300).
set wndw:x to 400. //window start position
set wndw:y to 120.

local label is wndw:ADDLABEL("Enter Booster Values").
set label:STYLE:ALIGN TO "CENTER".
set label:STYLE:HSTRETCH TO True. // Fill horizontally
Print gl_TargetLatLng.

//LEO 22.8 expendable, 15.6 ASDS (68%), 9.5(42%) 
//GTO 8.3 expendable, 5.5 ASDS (68%), 3.5(42%) 

local box_azi is wndw:addhlayout().
	local azi_label is box_azi:addlabel("Heading").
	local azivalue is box_azi:ADDTEXTFIELD("90").
	set azivalue:style:width to 100.
	set azivalue:style:height to 18.

local box_pitch is wndw:addhlayout().
	local pitch_label is box_pitch:addlabel("Start Pitch").
	local pitchvalue is box_pitch:ADDTEXTFIELD("85").
	set pitchvalue:style:width to 100.
	set pitchvalue:style:height to 18.

local box_RTLS is wndw:addhlayout().
	local RTLS_label is box_RTLS:addlabel("Desired Dv"). //NROL-76 and CRS 11 provides first stage RTLS telem
	local RTLSvalue is box_RTLS:ADDTEXTFIELD("8700").// //8700 LEO, 9750 GTO, give a margin so second stage can deorbit
	set RTLSvalue:style:width to 100.
	set RTLSvalue:style:height to 18.

local box_RTLSMax is wndw:addhlayout().
	local RTLSMax_label is box_RTLSMax:addlabel("Second Stage DV"). //NROL-76 and CRS 11 provides first stage RTLS telem
	local RTLSMaxvalue is box_RTLSMax:ADDTEXTFIELD("6850").//5.5tonne = 8,110, 11 tonne = 6,850, 17 tonne 5,930 
	set RTLSMaxvalue:style:width to 100.
	set RTLSMaxvalue:style:height to 18.

local box_runmode is wndw:addhlayout().
	local runmode_label is box_runmode:addlabel("Runmode"). //NROL-76 and CRS 11 provides first stage RTLS telem
	local runmodevalue is box_runmode:ADDTEXTFIELD("0").
	set runmodevalue:style:width to 100.
	set runmodevalue:style:height to 18.

local somebutton is wndw:addbutton("Confirm").
set somebutton:onclick to Continue@.

// Show the GUI.
wndw:SHOW().
LOCAL isDone IS FALSE.
UNTIL isDone {
	WAIT 1.
}

Function Continue {
		set val to azivalue:text.
		set val to val:tonumber(0).
		Global sv_intAzimith is val.

		set val to pitchvalue:text.
		set val to val:tonumber(0).
		Global sv_anglePitchover is val.

		set val to RTLSvalue:text.
		set val to val:tonumber(0).
		Global sv_RTLS is val.
		
		set val to RTLSMaxvalue:text.
		set val to val:tonumber(0).
		Global sv_RTLSMax is val.

		set val to runmodevalue:text.
		set val to val:tonumber(0).
		Global Runmode is val.

	wndw:hide().
  	set isDone to true.
}
Print "Start Heading: " + sv_intAzimith.
Print "Start Pitch: " + sv_anglePitchover. 
Global sv_ClearanceHeight is 130. //tower clearance height

Print "sv_RTLS: " + sv_RTLS.
Print "sv_RTLSMax: " + sv_RTLSMax.
Global sv_Stage1_dV is max((sv_RTLS - sv_RTLSMax),0).//difference first stage needs to make up
Print "sv_Stage1_dV: " + sv_Stage1_dV.
Global ASDS_limit is 1900.

if sv_Stage1_dV < ASDS_limit{
	// do nothing
}Else{
	SET TARGET TO "ASDS".
	Set gl_TargetLatLng to target:GEOPOSITION.
	Print "gl_TargetLatLng" + target:GEOPOSITION.
	//Set sv_anglePitchover to sv_anglePitchover + 1.5.
}
Print "Geo Targets".
Global gl_TargetLatLngSafe is ff_GeoConv(2,90,gl_TargetLatLng:lat,gl_TargetLatLng:lng). // Just short of landing pad for re entry burn
Global gl_TargetLatLngBoost is ff_GeoConv(7,90,gl_TargetLatLng:lat,gl_TargetLatLng:lng).// short of landing pad for boost back

Print gl_TargetLatLng.
Print gl_TargetLatLngSafe.
Print gl_TargetLatLngBoost.

//Set Runmode to 0. 

Until Runmode = 100 {

//Prelaunch
	if runmode = 0{
		Wait 1. //Alow Variables to be set and Stabilise pre launch
		PRINT "Prelaunch.".
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
		Lock Throttle to 1.
		LOCK STEERING TO r(up:pitch,up:yaw,facing:roll).
		wait 1.
		Set runmode to 1.
	}


//Liftoff
	if runmode = 1{
		STAGE. //Ignite main engines
		Print "Starting engines".
		wait 0.2.
		Set EngineStartTime to TIME:SECONDS.
		Local MaxEngineThrust is 0. 
		Local englist is List().
		//List Engines.
		LIST ENGINES IN engList. //Get List of Engines in the vessel
		FOR eng IN engList {  //Loops through Engines in the Vessel
			//Print "eng:STAGE:" + eng:STAGE.
			//Print STAGE:NUMBER.
			IF eng:STAGE >= STAGE:NUMBER { //Check to see if the engine is in the current Stage
				SET MaxEngineThrust TO MaxEngineThrust + eng:MAXTHRUST. 
				//Print "Stage Full Engine Thrust:" + MaxEngineThrust. 
			}
		}
		Print "Checking thrust ok".
		Local CurrEngineThrust is 0.
		Local EngineStartFalied is False.
		until CurrEngineThrust > 0.99*MaxEngineThrust{ 
			Set CurrEngineThrust to 0.
			FOR eng IN engList {  //Loops through Engines in the Vessel
				IF eng:STAGE >= STAGE:NUMBER { //Check to see if the engine is in the current Stage
					SET CurrEngineThrust TO CurrEngineThrust + eng:THRUST. //add thrust to overall thrust
				}
			}
			if (TIME:SECONDS - EngineStartTime) > 5 {
				Lock Throttle to 0.
				Set SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
				Print "Engine Start up Failed...Making Safe".
				Shutdown. //ends the script
			}
		}
		Print "Releasing Clamps".
		STAGE. // Relase Clamps
		Global LOtime is time:seconds.
		PRINT "Lift off!!".
		local LchAlt is ALT:RADAR.

		// Clear tower
		Wait UNTIL ALT:RADAR > sv_ClearanceHeight + LchAlt.
		Wait UNTIL SHIP:Q > 0.015. 

		//Pitchover
		LOCK STEERING TO HEADING(sv_intAzimith, sv_anglePitchover).
		Wait 20.//settle pitchover
		lock pitch to 90 - VANG(SHIP:UP:VECTOR, SHIP:VELOCITY:SURFACE).
		Set runmode to 2.
	}

//Gravity turn
	if runmode = 2{
		LOCK STEERING TO heading(sv_intAzimith, pitch) .
		wait 2.
		until SHIP:Q > 0.20 {
			wait 0.1.
		}
		Print "Throttle down: " + (TIME:SECONDS - LOtime).
		Local englist is List().
		FOR eng IN engList {  
			IF eng:TAG ="1DC" { 
				set eng:THRUSTLIMIT to 70. 
				Print "Engine". 
			}
		}
		//Lock throttle to 0.9.
		wait 15.
		until SHIP:Q < 0.3 {
			wait 0.1.
		}
		Print "Throttleup: " + (TIME:SECONDS - LOtime).
		Local englist is List().
		FOR eng IN engList {  
			IF eng:TAG ="1DC" { 
				set eng:THRUSTLIMIT to 100.  
				Print "Engine". 
			}
		}
		//Lock throttle to 1.0.
		// MECO Shutdown time
		until ship:mass < 185 or ((sv_Stage1_dV < ASDS_limit) and (ship:mass < 205) and (sv_Stage1_dV < ship:velocity:surface:mag)){//Start_mass - 362{//(TIME:SECONDS - LOtime) > 148 { //RTLS time Start_mass(570) - 362 = 208
				Wait 0.1. 
				If (ship:velocity:surface:mag > ASDS_limit) and (sv_Stage1_dV < ship:velocity:surface:mag){
					Lock Throttle to 0.75.
				}
				If (sv_Stage1_dV > ASDS_limit){
					Set impactData to impact_UTs().
					Set impact to ground_track(impactData["time"]).
					Set Diff to hf_geoDistance(impact,target:GEOPOSITION).
					Print"Diff: " + Diff.
					If Diff < 10000{
						Break.
					}
				}
		}
		Lock Throttle to 0.
		Print "MECO and Release: " + (TIME:SECONDS - LOtime).
		Print "Mass:"+ ship:mass.//RTLS 208 tonnes, ASDS 190 tonnes
		Print "Speed: " + ship:airspeed.
		Print "orbit speed: " + ship:velocity:orbit:mag.
		SET NAVMODE TO "Orbit".
		Stage.//Release first stage
		If sv_Stage1_dV < ASDS_limit{
			Set runmode to 3.
			Print "Boostback Phase".
		} Else{
			Set runmode to 4.
			Print "Droneship Phase".
			Set impactData to impact_UTs().
			Print ground_track(impactData["time"]).
			Set gl_TargetLatLng to target:GEOPOSITION. // Landing Pad Coords
			Set gl_TargetLatLngSafe to target:GEOPOSITION. // Short of landing pad
			Set gl_TargetLatLngBoost to target:GEOPOSITION. // Same as above and no need to provide extra safety
		}
		RCS on.
		Local englist is List().
		LIST ENGINES IN engList. 
		FOR eng IN engList {  
			IF eng:TAG ="1DC" { 
				eng:activate. 
				//Print "Engine". 
			}
			IF eng:TAG ="1DEC" { 
				eng:shutdown. 
				//Print "Engine". 
			}
			IF eng:TAG ="1DE" { 
				eng:shutdown. 
				//Print "Engine". 
			}
		}
	}

//Boostback Setup
	if runmode = 3{
		wait 3.
		Global boost_pitch is 0.
		If ship:apoapsis > 120000{ //limit the apoapsis on boost back to make more shallow
			lock boost_pitch to (120000 -ship:apoapsis)/750.
		}Else{
			Set boost_pitch to 0.
		}
		LOCK STEERING TO HEADING(hf_mAngle(hf_geoDir(gl_TargetLatLngBoost, SHIP:GEOPOSITION)), boost_pitch).
		Set SteeringManager:PITCHTORQUEADJUST to 250.
		Set SteeringManager:YAWTORQUEADJUST to 250.
		Print hf_geoDir(gl_TargetLatLngBoost, SHIP:GEOPOSITION).
		Print gl_TargetLatLng:HEADING.
		Print hf_geoDistance(gl_TargetLatLngBoost, SHIP:GEOPOSITION).
		Print Ship:heading.
		Print Ship:bearing.
		SET SHIP:CONTROL:FORE to 1.0.
		SET SHIP:CONTROL:Yaw to 1.0.
		Wait 8.
		SET SHIP:CONTROL:FORE to 0.
		SET SHIP:CONTROL:Yaw to 0.
		Lock Throttle to 1.
		//SteeringManager:RESETTODEFAULT().//reset to normal RCS control
		//SteeringManager:RESETPIDS().
		Set SteeringManager:PITCHTORQUEADJUST to -100.
		Set SteeringManager:YAWTORQUEADJUST to -100.
		Set SteeringManager:ROLLTORQUEADJUST to -1.0.
		local burn_lnt is TIME:SECONDS.
		Print "Boostback: " + (TIME:SECONDS - EngineStartTime).
		local change is false.
		local lastdist is 1000000000.
		local calc_dist is 0.
		local diff is 0.
		Wait 5.// provide enough time for booster to start flip around
		//increase to 3 engines
		ff_outter_engine_A().
		RCS off.
		wait 10.// provide enough time for booster to settle in direction before measuring
		lock impactData to impact_UTs().
		lock impact to ground_track(impactData["time"]).
		local freectrl is true.
		until change = True {
			If ship:apoapsis < 120000{ //limit the apoapsis on boost back to make more shallow
			unlock boost_pitch.
				Set STEERING TO getSteeringBoost(gl_TargetLatLngBoost, impact).//, boost_pitch).// * ANGLEAXIS(boost_pitch,SHIP:FACING:STARVECTOR).//* v(tan(boost_pitch),0,0). //+ R(boost_pitch,0,0).
			}
			local northPole is latlng(90,0).
			local head is mod(360 - northPole:bearing,360).
			Set ground to ground_track(impactData["time"]).
			Set Diff to hf_geoDistance(ground,gl_TargetLatLngBoost).
			Print "Diff:" + Diff.
			if (diff > (60000)){
				Set lastdist to 1000000.
			}
			if (diff < (150000)) and freectrl{
				Set STEERING TO getSteeringBoost(gl_TargetLatLngBoost, impact).
			}
			if (diff < (10000)) {
				Print "Triming shutdown".
				//reduce to one engine allow more accurate shutoff
				Lock Throttle to 0.7.
				ff_outter_engine_S().
				set freectrl to false.
			}
			if (diff < lastdist) and (diff > dist_trim){
				Set lastdist to Diff.
			} else{
				Set change to true.
				print "exit loop change".
				break.
			}
			if (diff < (dist_trim)) {
				Set change to true.
				print "exit loop dist".
				break.
			}	
			//The following ensure the target spot is not will not be burnt passed.
			if (head > 315) and (head < 45){// check for north quarter
				if ground:lat > gl_TargetLatLngBoost:lat{
					print "exit loop lat".
					print ground:lat.
					print gl_TargetLatLngBoost:lat.
					Break.
				}
			}
			if (head > 45) and (head < 135){// check for east quarter
				if ground:lng > gl_TargetLatLngBoost:lng{
					print "exit loop lng".
					print ground:lng.
					print gl_TargetLatLngBoost:lng.
					Break.
				}
			}
			if (head > 135) and (head < 225){// check for south quarter
				if ground:lat < gl_TargetLatLngBoost:lat{
					print "exit loop lat".
					print ground:lat.
					print gl_TargetLatLngBoost:lat.
					Break.
				}
			}
			if (head > 225) and (head < 315){// check for west quarter
				if ground:lng < gl_TargetLatLngBoost:lng{
					Set change to true.
					print "exit loop lng".
					print ground:lng.
					print gl_TargetLatLngBoost:lng.
					break.
				}
			}
			Print head.
			Print ground:lng.
			Print gl_TargetLatLngBoost:lng.
			Print boost_pitch.
			wait 0.001.
			set vd2 to vecdraw(v(0,0,0), gl_TargetLatLngBoost:position:vec, blue, "Target", 1.0, true, 0.2).
			set vd3 to vecdraw(v(0,0,0), SHIP:GEOPOSITION:position:vec, green, "shadow", 1.0, true, 0.2).
		}
		Lock Throttle to 0.
		Set impactData to impact_UTs().
		Print ground_track(impactData["time"]).
		Print "Boostback End: " + (TIME:SECONDS - EngineStartTime).
		RCS on.
		wait 15.
		LOCK STEERING TO r(up:pitch,up:yaw,facing:roll).
		wait 5.
		Set runmode to 4.
	}

//Re-entry burn
	if runmode = 4{
		// Coast to re-entry
		//Big movements to orient in space
		Set SteeringManager:PITCHTORQUEADJUST to 50.
		Set SteeringManager:YAWTORQUEADJUST to 50.
		Set SteeringManager:ROLLTORQUEADJUST to 1.
		Set impactData to impact_UTs().
		Print "Diff:" + hf_geoDistance(ground_track(impactData["time"]),gl_TargetLatLngBoost).
		set ster TO r(up:pitch,up:yaw,facing:roll).
		lock steering to ster.
		until ship:verticalspeed < -200 {
			wait 1.
		}
		Print "Re-entry prep and next safe landing point: " + (TIME:SECONDS - EngineStartTime).
		Print hf_geoDistance(gl_TargetLatLngSafe, SHIP:GEOPOSITION).
		Set impactData to impact_UTs().
		Print "Diff:" + hf_geoDistance(ground_track(impactData["time"]),gl_TargetLatLngSafe).
		until (ship:altitude < 140000){
			wait 0.1.
		}
		Brakes on.//deploy grid fins
		//set up when the energy builds up enough to start slowing down for the entry burn, or altitude high enough to slow down and reach terminal velocity
		If sv_Stage1_dV < ASDS_limit{
			set burn_stt to 0.008.//800Pa //CRS-11 50.2km and 1250 m/s at 06:10 mm:ss;
			set burn_alt to 50000.
		} Else{
			set burn_stt to 0.005. //500Pa 
			set burn_alt to 60000.
		}
		Print "burn_stt: " + burn_stt.
		until (Ship:Q > burn_stt) or (ship:altitude < burn_alt){
			set impactData to impact_UTs().
			set impact to ground_track(impactData["time"]).
			set vd1 to vecdraw(v(0,0,0), impact:position:vec, green, "Landing", 1.0, true, 0.25).
			set vd2 to vecdraw(v(0,0,0), gl_TargetLatLngSafe:position:vec, blue, "Target", 1.0, true, 0.25).
			set impactData to impact_UTs().
			set impact to ground_track(impactData["time"]).
			lock ster to -ship:velocity:surface.
			wait 0.1.
		}
		Print "Booster entry burn:"+ (TIME:SECONDS - EngineStartTime).
		Print "Start Airspeed:" + ship:airspeed.
		Print "Start Altitude: " + ship:altitude.
		Set SteeringManager:PITCHTORQUEADJUST to 0.01. //was 1
		Set SteeringManager:YAWTORQUEADJUST to 0.01. //was 1
		Set SteeringManager:ROLLTORQUEADJUST to 0.001. //was 0.1
		set impactData to impact_UTs().
		set impact to ground_track(impactData["time"]).
		Set impactData to impact_UTs().
		Print "Diff:" + hf_geoDistance(ground_track(impactData["time"]),gl_TargetLatLngSafe).
		Print "Q:"+ Ship:Q.  // 0.00814 (800Pa)
		Lock Throttle to 1.
		set startburn to TIME:SECONDS.
		Print Ship:groundspeed.
		Print ship:airspeed.
		wait 3.
		//increase to 3 engines
		ff_outter_engine_A().
		//check for minimum conditions for stopping the entry burn
		set burn_stp to 34. //lowest fuel mass required for a three engine stop and equates to around 400 m/s
		Until (ship:mass < burn_stp) or (ship:airspeed < 700){ //check for max entry burn time, energy, or stop if not enough fuel left to land.
			set vd1 to vecdraw(v(0,0,0), impact:position:vec, green, "Landing", 1.0, true, 0.25).
			set vd2 to vecdraw(v(0,0,0), gl_TargetLatLngSafe:position:vec, blue, "Target", 1.0, true, 0.25).
			wait 0.1.
		}
		//reduce to one engine allow more accurate shutoff
		ff_outter_engine_S().
		wait 1.

		Print "Booster entry burn end:"+ (TIME:SECONDS - EngineStartTime).
		Print "Finish Airspeed:" + ship:airspeed.
		Print "Finish Altitude: " + ship:altitude.
		Print "Finsh Calc:" + (((ship:airspeed)^3)/ship:altitude).
		Print "Q:"+ Ship:Q. //0.025(2.5kPa)
		Lock throttle to 0.
		set impactData to impact_UTs().
		set impact to ground_track(impactData["time"]).
		Set runmode to 5.
	}

//Landing Glide (no long target safe spot)
		
	if runmode = 5{
		SET CONFIG:IPU to 500.//increase computation
		Set SteeringManager:PITCHTORQUEADJUST to 1. 
		Set SteeringManager:YAWTORQUEADJUST to 1. 
		Set SteeringManager:ROLLTORQUEADJUST to 0.01. 
		lock trueRadar to alt:radar + radarOffset.			// Offset radar to get distance from gear to ground
		lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
		lock maxDecel to abs(((ship:availablethrust / ship:mass) - g)*(sin(pitch))).	// Maximum deceleration possible (m/s^2), the sin pitch is an offset for the current angle.
		lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
		lock idealThrottle to (stopDist / (trueRadar-Stop_trim)).	// Throttle required for perfect hoverslam, the stoptrim is because we want to actually land so need to target slightly under surface
		lock impactData to impact_UTs().
		lock impact to ground_track(impactData["time"]).
		lock L_impact to Last_impact(radarOffset).
		lock pitch to 90 - vectorangle(ship:up:forevector, ship:facing:forevector).
		set mheading to srfretrogradehdg().
		set mpitch to srfretrogradepitch().
		lock ster to heading (mheading, mpitch).//make pitch surface retrograde
		lock steering to ster. 
		set TimeOnTgt to 100.
		
		///First part of glide settings (earth rotation still counts)
		set headingPID to PIDLOOP(0.2, 0.01, 0.01, -0.1, 0.1).//0.1, 0, 0.0, -0.1, 0.1
		set pitchPID to PIDLOOP(0.3, 0.01, 0.2, -0.5, 0.5).//0.1, 0.0, 0, -0.5, 0.5
		until (TimeOnTgt-(impactData["time"]-time:seconds)) < 3 { //set at 3 seconds to change to different gains
			
			set impact to ground_track(impactData["time"]).

			set targetheading to hf_mAngleInv(gl_TargetLatLng:HEADING). //heading to target
			set headingPID:SETPOINT to targetheading.
			set mheading to hf_mAngle(mheading + headingPID:UPDATE(time:seconds, hf_mAngle(hf_geoDir(SHIP:GEOPOSITION, impact)))). // heading to landing point (reversed due to retrograde)
			Print "mheading: " + mheading.
			Print headingPID:OUTPUT.


			set targetpitch to (impactData["time"]-time:seconds). // want slightly long
			set pitchPID:SETPOINT to targetpitch.
			set downrange to hf_geoDistance(SHIP:GEOPOSITION, gl_TargetLatLng).
			Set TimeOnTgt to downrange/ship:Groundspeed.
			set mpitch to mpitch + pitchPID:UPDATE(time:seconds, TimeOnTgt). //current surface speed compared to target arrival
			set mpitch to min(89,max(mpitch,45)).
			Print "mpitch: " + mpitch.
			Print pitchPID:OUTPUT.

			Print "high".
			Print "trueRadar: " + trueRadar.
			Print "maxDecel: " + maxDecel.
			Print "Stop Dist: " + stopDist.
			Print TimeOnTgt.
			Print (impactData["time"]-time:seconds).
			Print TimeOnTgt-(impactData["time"]-time:seconds).
			set vd1 to vecdraw(v(0,0,0), L_impact:position:vec, green, "Landing", 1.0, true, 0.2).
			set vd2 to vecdraw(v(0,0,0), gl_TargetLatLng:position:vec, blue, "Target", 1.0, true, 0.2).
			set vd3 to vecdraw(v(0,0,0), SHIP:GEOPOSITION:position:vec, red, "shadow", 1.0, true, 0.2).			

			// LOG MISSIONTIME + "," + 
			// trueRadar + "," + 
			// airSpeed + "," + 
			// Groundspeed + "," + 
			// verticalSpeed + "," + 
			// pitch + downrange + "," + 
			// ship:mass + "," + 
			// ship:availableThrust + "," + 
			// headingPID:SETPOINT + "," + 			
			// headingPID:INPUT + "," + 
			// headingPID:OUTPUT + "," + 
			// headingPID:Pterm + "," + 
			// headingPID:Iterm + "," + 
			// headingPID:Dterm + "," + 
			// pitchPID:SETPOINT + "," + 			
			// pitchPID:INPUT + "," + 
			// pitchPID:OUTPUT + "," + 
			// pitchPID:Pterm + "," + 
			// pitchPID:Iterm + "," + 
			// pitchPID:Dterm
			// TO "0:/dataoutput.csv".

			wait 0.2.
		}
		//final glide settings just before engine ignitions	
		Set SteeringManager:PITCHTORQUEADJUST to 150. //negative as we want to reduce the amount
		Set SteeringManager:YAWTORQUEADJUST to 150. //negative as we want to reduce the amount
		Set SteeringManager:ROLLTORQUEADJUST to 10. //negative as we want to reduce the amount
		Set AltstopDist to 1.
		
		
		set headingPID to PIDLOOP(0.2, 0.01, 0.2, -0.3, 0.3). //0.15, 0, 0.15, -0.2, 0.2).
		set pitchPID to PIDLOOP(0.2, 0.001, 0.2, -1, 1).//(0.1, 0, 0.1, -1, 1).
		
		until (trueRadar < stopDist) and (airspeed < 550) and (trueRadar < (4000* AltstopDist) ){ 
			//CRS-11 4.5km and 305 m/s at 07:10 mm:ss
			If ship:mass > 36{
				set AltstopDist to 1.25. //provide extra 25% for engine startup and control on RTLS as have extra fuel
				set overshoot to 2.
			}else If (ship:mass > 34) and (ship:mass < 36){
				set AltstopDist to 0.75. // at 34.5 provide less 75% for engine startup with 3 engines to use less fuel
				set overshoot to 0.6.
			}Else {
				set AltstopDist to 0.65. // at 33 provide less 65% for engine startup with 3 engines to use less fuel
				set overshoot to 0.4.
			}

			set impact to ground_track(impactData["time"]).
			
			set targetheading to hf_mAngleInv(gl_TargetLatLng:HEADING). //heading to target
			set headingPID:SETPOINT to targetheading.
			set mheading to hf_mAngle(mheading + headingPID:UPDATE(time:seconds, hf_mAngle(hf_geoDir(SHIP:GEOPOSITION, impact)))). // heading to landing point (reversed due to retrograde)
			Print "mheading: " + mheading.
			Print "input: " + headingPID:input.
			Print "setpoint: " + headingPID:setpoint.
			Print "error: " + headingPID:Error.
			Print "change: " + headingPID:changerate.
			Print headingPID:OUTPUT.
			Print headingPID:Pterm.
			Print headingPID:Iterm.
			Print headingPID:Dterm.


			set targetpitch to (impactData["time"]-time:seconds)-overshoot. // want slightly long
			set pitchPID:SETPOINT to targetpitch.
			set downrange to hf_geoDistance(SHIP:GEOPOSITION, gl_TargetLatLng).
			Set TimeOnTgt to downrange/ship:Groundspeed.
			set mpitch to mpitch + pitchPID:UPDATE(time:seconds, TimeOnTgt). //current surface speed compared to target arrival
			set mpitch to min(89,max(mpitch,45)).
			Print "mpitch: " + mpitch.
			Print "input: " + pitchPID:input.
			Print "setpoint: " + pitchPID:setpoint.
			Print "error: " + pitchPID:Error.
			Print "change: " + pitchPID:changerate.
			Print pitchPID:OUTPUT.
			Print pitchPID:Pterm.
			Print pitchPID:Iterm.
			Print pitchPID:Dterm.

			Print "trueRadar: "+ trueRadar.
			Print "maxDecel: "+ maxDecel.
			Print "stopDist:" + stopDist.
			Print "Pitch:" + Pitch.
			Print "idealThrottle: " + idealThrottle.
			Print "Head" + gl_TargetLatLng:HEADING.
			Print "AltstopDist: " + AltstopDist.
			Print "Downrange: " + downrange.
			Print overshoot.
			Print TimeOnTgt.
			Print (impactData["time"]-time:seconds).
			Print TimeOnTgt-(impactData["time"]-time:seconds).
			//Print hf_mAngleInv(gl_TargetLatLng:HEADING).
			set vd1 to vecdraw(v(0,0,0), L_impact:position:vec, green, "Landing", 1.0, true, 0.2).
			set vd2 to vecdraw(v(0,0,0), gl_TargetLatLng:position:vec, blue, "Target", 1.0, true, 0.2).
			set vd3 to vecdraw(v(0,0,0), SHIP:GEOPOSITION:position:vec, red, "shadow", 1.0, true, 0.2).	
			
			LOG MISSIONTIME + "," + 
			trueRadar + "," + 
			airSpeed + "," + 
			ship:Groundspeed + "," + 
			verticalSpeed + "," + 
			pitch + "," + 
			downrange + "," + 
			ship:mass + "," + 
			ship:availableThrust + "," + 
			headingPID:SETPOINT + "," + 			
			headingPID:INPUT + "," + 
			headingPID:OUTPUT + "," + 
			headingPID:ERROR + "," +			
			headingPID:Pterm + "," + 
			headingPID:Iterm + "," + 
			headingPID:Dterm + "," + 
			pitchPID:SETPOINT + "," + 			
			pitchPID:INPUT + "," + 
			pitchPID:OUTPUT + "," + 
			pitchPID:ERROR + "," + 
			pitchPID:Pterm + "," + 
			pitchPID:Iterm + "," + 
			pitchPID:Dterm
			TO "0:/dataoutput.csv".

			wait 0.15.
		}
		unlock impactData.
		Set runmode to 6.
	}

//Landing burn
	set headingPID to PIDLOOP(0.3, 0.01, 0.2, -0.5, 0.5).//0.3, 0, 0.15, -0.3, 0.3
	set pitchPID to PIDLOOP(0.3, 0.01, 0.2, -1, 1).//0.1, 0, 0.05, -1, 1
	if runmode = 6{
		lock L_impact to Last_impact(radarOffset).
		lock impactData to impact_UTs().
		Global throt_lim is 0.9.
		Print "Booster landing burn:"+ (TIME:SECONDS - EngineStartTime).

		until (0 > trueRadar) or (Ship:Status = "LANDED") or (ship:verticalspeed > 0) {
			Set faltm to hf_Fall(radarOffset).
			lock Throttle to min(max(0.1,idealThrottle),throt_lim).//ensure engine does not turn off
			//local mapGeo is ff_GeoConv (mapDist/1000, sv_intAzimith, gl_TargetLatLng:lat, gl_TargetLatLng:lng).
			
			set impact to ground_track(impactData["time"]).
			
			set targetheading to hf_mAngleInv(gl_TargetLatLng:HEADING). //heading to target
			set headingPID:SETPOINT to targetheading.
			set mheading to hf_mAngle(mheading + headingPID:UPDATE(time:seconds, hf_mAngle(hf_geoDir(SHIP:GEOPOSITION, impact)))). // heading to landing point (reversed due to retrograde)
			Print "mheading: " + mheading.
			Print "mheading: " + mheading.
			Print "input: " + headingPID:input.
			Print "setpoint: " + headingPID:setpoint.
			Print "error: " + headingPID:Error.
			Print "change: " + headingPID:changerate.
			Print headingPID:OUTPUT.
			Print headingPID:Pterm.
			Print headingPID:Iterm.
			Print headingPID:Dterm.


			set targetpitch to (impactData["time"]-time:seconds)-(overshoot/1.2). //
			set pitchPID:SETPOINT to targetpitch.
			set downrange to hf_geoDistance(SHIP:GEOPOSITION, gl_TargetLatLng).
			Set TimeOnTgt to downrange/ship:Groundspeed.
			set mpitch to mpitch + pitchPID:UPDATE(time:seconds, TimeOnTgt). //current surface speed compared to target arrival
			set mpitch to min(89,max(mpitch,50)).
			Print "mpitch: " + mpitch.
			Print "input: " + pitchPID:input.
			Print "setpoint: " + pitchPID:setpoint.
			Print "error: " + pitchPID:Error.
			Print "change: " + pitchPID:changerate.
			Print pitchPID:OUTPUT.
			Print pitchPID:Pterm.
			Print pitchPID:Iterm.
			Print pitchPID:Dterm.
			
			
			If (idealThrottle > 1.25) and ((Ship:Q <0.4) or (faltm["fallTime"] < 6)) and (trueRadar > (200 + grndOffset)){
				//start outter engines
				ff_outter_engine_A().
				Print "outter engines start".
				ff_outter_engine_A().
				set throttle to 1. //needs to be one to start outter engines.
				wait 2.//ensures engines actually start
			}
			If sv_Stage1_dV < ASDS_limit{
				//do nothing keep existing target
			}Else{
				set gl_TargetLatLng to target:GEOPOSITION. // ASDS Landing Pad Coords
			}

			If (trueRadar > (1500 + grndOffset)){
				local dist is hf_geoDistance(ground_track(impactData["time"]),gl_TargetLatLng).
				Set throt_lim to (idealThrottle*0.9).
				Print "Limited".
			} Else	If (trueRadar < (1500 + grndOffset)) { // under 1500m full throttle range
				Set throt_lim to 1.
				Print "unlimited".
			}
			if (ship:verticalspeed > (Up_trim/2)) or (Leg_trim > trueRadar){ ////CRS-11 0.3km and 70 m/s at 07:34 mm:ss
				Gear on.
			}
			if ((faltm["fallTime"]/sin(pitch) > 2) and (faltm["fallTime"]/sin(pitch) < 4)) or ((trueRadar > 25) and (trueRadar < 350)) { //cancel out ground speed 
				lock steering to heading(mheading, srfretrogradepitch()).//make pitch surface retrograde
				Print "Locked retro pitch".
			} 
			if ((faltm["fallTime"]/sin(pitch) < 2) and trueRadar > 25) or ((trueRadar > 25) and (trueRadar < 100)){ //cancel out ground speed 
				lock steering to heading(srfretrogradehdg(), srfretrogradepitch()).//make pitch surface retrograde
				Print "Locked retro".
			} 
			If (trueRadar < 25) { // under 25m stop just point straight up.
				lock steering to lookdirup(up:vector, ship:facing:topvector).
				Print "Locked 25".
			}
			if (idealThrottle > 0.2) and (idealThrottle < 0.4){
				Set throt_lim to 0.75.
			}
			if idealThrottle < 0.2{
				ff_outter_engine_S().
				Set throt_lim to 1.
				Print "outter shudown".
			}
			set vd1 to vecdraw(v(0,0,0), L_impact:position:vec, green, "Landing", 1.0, true, 0.2).
			set vd2 to vecdraw(v(0,0,0), gl_TargetLatLng:position:vec, blue, "Target", 1.0, true, 0.2).
			set vd3 to vecdraw(v(0,0,0), SHIP:GEOPOSITION:position:vec, green, "shadow", 1.0, true, 0.2).
			Print "trueRadar: "+trueRadar.
			Print "maxDecel: "+maxDecel.
			Print "stopDist "+stopDist.
			Print "Pitch " +Pitch.
			Print sin(pitch).
			Print "idealthrott " +idealThrottle.
			Print "throt_lim "+throt_lim.
			Print "Impact T: " + faltm["fallTime"].
			Print "Impact Sp: " + faltm["fallVel"].
			Print "Groundspeed" + ship:Groundspeed.
			Print "Ground prop" +(verticalspeed / ship:Groundspeed).
			Print "Downrange: " + downrange.
			
			wait 0.1.
		}
		Lock throttle to 0.	
		Set runmode to 7.
	}
	wait 10.
	Print SHIP:GEOPOSITION.
	Print alt:radar.
	Shutdown. //ends the script
}


//////////////////////////////////////////////////////////////////////////
///////////////////////FUNCTIONS
///////////////////////////////////////////////////////////////////////////



function hf_geoDistance { //Approx in meters using straight line. Good for flat surface approximatation and low computation. Does not take into accout curvature or lattitude.
	parameter geo1.
	parameter geo2.
	return (geo1:POSITION - geo2:POSITION):MAG.
}

function hf_geoDistanceCur { // Distance between to points takes into account lattitude and curvature
	parameter geo1.
	parameter geo2.
	
	set deltalat to abs(geo2:lat - geo1:lat).
	set deltalng to abs(geo2:lng - geo1:lng).
	
	set body_circumference to 2 * constant:pi * body:radius.

	return body_circumference / 360 * sqrt(deltalat^2 + cos(lat2)^2 * deltalng^2).
}

function hf_geoDir { //compass angle of direction to landing spot. Good for flat surface approximatation and low computation. Does not take into accout curvature.
	parameter geo1.
	parameter geo2.
	return ARCTAN2(geo1:LNG - geo2:LNG, geo1:LAT - geo2:LAT).
}
 
function hf_geoDirCur { // compass angle taking into account the curvature of the earth
	parameter gs_p1, gs_p2. //(point1,point2). 
	//Need to ensure converted to radians 
	//TODO Test if this still works in degrees
	Set P1Lat to gs_p1:lat * constant:DegtoRad.
	Set P2Lat to gs_p2:lat * constant:DegtoRad.
	Set P1Lng to gs_p1:lng * constant:DegtoRad.
	Set P2Lng to gs_p2:lng * constant:DegtoRad.

	set resultA to (cos(P1Lat)*sin(P2Lat)) -(sin(P1Lat)*cos(P2Lat)*cos(P2Lng-P1Lng)).
	set resultB to sin(P2Lng-P1Lng)*cos(P2Lat).
	set result to  arctan2(resultA, resultB).// this is the intial bearing formula go to www.moveable-type.co.uk for more informationn

return result.
}

function hf_geoVelSplit{ // returns the surface velocity of ship in lat and long

	set north_vector to heading(0,0):vector.
	set east_vector to heading(90,0):vector.

	set vel_lat to vxcl(vcrs(SHIP:UP:VECTOR,north_vector), SHIP:velocity:surface).
	set vel_lng to vxcl(vcrs(SHIP:UP:VECTOR,east_vector), SHIP:velocity:surface).
	
	Return list(vel_lat, vel_lng).
}

FUNCTION hf_mAngle{
PARAMETER a.
  UNTIL a >= 0 { SET a TO a + 360. }
  RETURN MOD(a,360).
  
}
FUNCTION hf_mAngleInv{
PARAMETER a.
  SET a TO a + 180.
  RETURN MOD(a,360).
  
}

function ff_quadraticPlus {
	parameter a, b, c.
	return (b - sqrt(max(b ^ 2 - 4 * a * c, 0))) / (2 * a).
}

FUNCTION impact_UTs {//returns the UTs of the ship's impact, NOTE: only works for non hyperbolic orbits
	PARAMETER minError IS 1.
	IF NOT (DEFINED impact_UTs_impactHeight) { GLOBAL impact_UTs_impactHeight IS 0. }
	LOCAL startTime IS TIME:SECONDS.
	LOCAL craftOrbit IS SHIP:ORBIT.
	LOCAL sma IS craftOrbit:SEMIMAJORAXIS.
	LOCAL ecc IS craftOrbit:ECCENTRICITY.
	LOCAL craftTA IS craftOrbit:TRUEANOMALY.
	LOCAL orbitPeriod IS craftOrbit:PERIOD.
	LOCAL ap IS craftOrbit:APOAPSIS.
	LOCAL pe IS craftOrbit:PERIAPSIS.
	LOCAL Alt_TA is alt_to_ta(sma,ecc,SHIP:BODY,MAX(MIN(impact_UTs_impactHeight,(ap - 1)),(pe + 1)))[1].
	LOCAL impactUTs IS startTime + time_betwene_two_ta(ecc,orbitPeriod,craftTA,Alt_TA).
	//Print "impactUTs:" + impactUTs.
	LOCAL newImpactHeight IS ground_track(impactUTs):TERRAINHEIGHT.
	SET impact_UTs_impactHeight TO (impact_UTs_impactHeight + newImpactHeight) / 2.
	RETURN LEX("time",impactUTs,//the UTs of the ship's impact
	"impactHeight",impact_UTs_impactHeight,//the aprox altitude of the ship's impact
	"converged",((ABS(impact_UTs_impactHeight - newImpactHeight) * 2) < minError)).//will be true when the change in impactHeight between runs is less than the minError
}

FUNCTION alt_to_ta {//returns a list of the true anomalies of the 2 points where the craft's orbit passes the given altitude
	PARAMETER sma,ecc,bodyIn,altIn.
	LOCAL rad IS altIn + bodyIn:RADIUS.
	LOCAL taOfAlt IS ARCCOS((-sma * ecc^2 + sma - rad) / (ecc * rad)).
	RETURN LIST(taOfAlt,360-taOfAlt).//first true anomaly will be as orbit goes from PE to AP
}

FUNCTION time_betwene_two_ta {//returns the difference in time between 2 true anomalies, traveling from taDeg1 to taDeg2
	PARAMETER ecc,periodIn,taDeg1,taDeg2.
	
	LOCAL maDeg1 IS ta_to_ma(ecc,taDeg1).
	LOCAL maDeg2 IS ta_to_ma(ecc,taDeg2).
	
	LOCAL timeDiff IS periodIn * ((maDeg2 - maDeg1) / 360).
	
	RETURN MOD(timeDiff + periodIn, periodIn).
}

FUNCTION ta_to_ma {//converts a true anomaly(degrees) to the mean anomaly (degrees) NOTE: only works for non hyperbolic orbits
	PARAMETER ecc,taDeg.
	LOCAL eaDeg IS ARCTAN2(SQRT(1-ecc^2) * SIN(taDeg), ecc + COS(taDeg)).
	LOCAL maDeg IS eaDeg - (ecc * SIN(eaDeg) * CONSTANT:RADtoDEG).
	RETURN MOD(maDeg + 360,360).
}

FUNCTION ground_track {	//returns the geocoordinates of the ship at a given time(UTs) adjusting for planetary rotation over time
	PARAMETER posTime.
	LOCAL pos IS POSITIONAT(SHIP,posTime).
	LOCAL localBody IS SHIP:BODY.
	LOCAL rotationalDir IS VDOT(localBody:NORTH:FOREVECTOR,localBody:ANGULARVEL). //the number of radians the body will rotate in one second (negative if rotating counter clockwise when viewed looking down on north
	LOCAL timeDif IS posTime - TIME:SECONDS.
	LOCAL posLATLNG IS localBody:GEOPOSITIONOF(pos).
	LOCAL longitudeShift IS rotationalDir * timeDif * CONSTANT:RADTODEG.
	LOCAL newLNG IS MOD(posLATLNG:LNG + longitudeShift ,360).
	IF newLNG < - 180 { SET newLNG TO newLNG + 360. }
	IF newLNG > 180 { SET newLNG TO newLNG - 360. }
	RETURN LATLNG(posLATLNG:LAT,newLNG).
}

function getSteeringBoost {
	Parameter tgt, impact.
    local errorVector is (impact:position - tgt:position).
    local velVector is -ship:velocity:surface.
    local result is ((velVector + errorVector) * -1).
	local result is  result + up:vector.// * pitch).

    return (lookDirUp(result, up:vector)).
}

function getSteeringTrans {
	Parameter aoa, tgt, impact, ratio, offset is 0.
    local errorVector is (impact:POSITION - tgt:ALTITUDEPOSITION(max(tgt:TERRAINHEIGHT + offset, 0))).
    local velVector is -ship:velocity:surface.
    local result1 is velVector + errorVector.
	local result2 is velVector - errorVector.

    if vang(result1, velVector) > aoa {
        set result1 to velVector:normalized + tan(aoa) * errorVector:normalized. //Atmosphere result
    }
	if vang(result2, velVector) > aoa {
        set result2 to velVector:normalized - tan(aoa) * errorVector:normalized.
    }

	local result is (result1*ratio) + (result2).

    return lookDirUp(result, facing:topvector).
}

function getSteeringEngine {
	Parameter aoa, tgt, impact, offset is 0.
    local errorVector is (impact:POSITION - tgt:ALTITUDEPOSITION(max(tgt:TERRAINHEIGHT + offset, 0))).
    local velVector is -ship:velocity:surface.
    local result is velVector - errorVector.

    if vang(result, velVector) > aoa {
        set result to velVector:normalized - tan(aoa) * errorVector:normalized.
    }
    return lookDirUp(result, facing:topvector).
}

function getSteering {
	Parameter aoa, tgt, impact, offset is 0.
    local errorVector is (impact:POSITION - tgt:ALTITUDEPOSITION(max(tgt:TERRAINHEIGHT + offset, 0))).
    local velVector is -ship:velocity:surface.
    local result is velVector + errorVector.

    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * errorVector:normalized.
    }
    return lookDirUp(result, facing:topvector).
}

function getSteeringEngineStop {
	Parameter aoa.
    local errorVector is (ship:POSITION - SHIP:GEOPOSITION:ALTITUDEPOSITION(max(SHIP:GEOPOSITION:TERRAINHEIGHT, 0))).
	set horizontalVel to vxcl(up:vector, velocity:surface).
    local velVector is -ship:velocity:surface - (horizontalVel*1.5).//1.25
    local result is velVector + (errorVector).
	
    if vang(result, velVector) > aoa {
        set result to velVector:normalized + tan(aoa) * errorVector:normalized.
    }
    return lookDirUp(result, facing:topvector).
}

function srfretrogradepitch { // identify the surface retorgrade pitch
	set progradepitch to 90 - vectorangle(ship:up:vector, ship:velocity:surface).
	return -progradepitch.
}

function srfretrogradehdg {// identify the surface retorgrade heading

    local trig_x is vdot( heading( 90, 0 ):vector, ship:srfprograde:vector ).
    local trig_y is vdot( heading(  0, 0 ):vector, ship:srfprograde:vector ).

    return mod( arctan2( trig_x, trig_y ) +360 + 180, 360 ).
}

function Last_impact {
	Parameter offset is 0, rel_position is ship:position-ship:body:position.
	local falling is hf_Fall(offset).
	local impact_position is ship:velocity:surface * falling["falltime"] + rel_position.
	local impact is convertPosvecToGeocoord(impact_position).
    return impact.
}

function convertPosvecToGeocoord { //Find the co-ordinates for a specific position vector relative to the ship.
	parameter posvec.
	//sphere coordinates relative to xyz-coordinates
	local lat is 90 - vang(v(0,1,0), posvec).
	//circle coordinates relative to xz-coordinates
	local equatvec is v(posvec:x, 0, posvec:z).
	local phi is vang(v(1,0,0), equatvec).
	if equatvec:z < 0 {
		set phi to 360 - phi.
	}
	//angle between x-axis and geocoordinates
	local alpha is vang(v(1,0,0), latlng(0,0):position - ship:body:position).
	if (latlng(0,0):position - ship:body:position):z >= 0 {
		set alpha to 360 - alpha.
	}
	return latlng(lat, phi + alpha).
}

function ff_GeoConv{ //Find the co-ordinates a specific distance and heading from another point.
	parameter dist, brng, lat1, long1.//km, deg 0-360, deg-180+180, deg-90+90
	Print dist. 
	//Set brng to brng * constant:DegToRad.
	Print brng.
	Set lat1 to lat1 * constant:DegToRad.
	Print lat1.
	Set long1 to long1 * constant:DegToRad.
	Print long1.
	local lat2 is arcSin((sin(lat1) * cos(dist/6372)) + (cos(lat1) * sin(dist/6372) * cos(brng))).
	Print Lat2 * constant:RadToDeg.
	local long2 is long1 + arcTan2(sin(brng) * sin(dist/6372) * cos(lat1), cos(dist/6372) - (sin(lat1) * sin(lat2))).
	Print sin(brng) * sin(dist/6372) * cos(lat1).
	Print cos(dist/6372) - (sin(lat1) * sin(lat2)).
	Print arcTan2(sin(brng) * sin(dist/63872) * cos(lat1), cos(dist/6372) - (sin(lat1) * sin(lat2))).
	Print Long2 * constant:RadToDeg. 
	return latlng(lat2 * constant:RadToDeg, long2 * constant:RadToDeg).
}

Function hf_Fall{
	parameter offset is 0.
//Fall Predictions and Variables
	local Grav is body:mu / (ship:Altitude + body:radius)^2.
	local fallTime is ff_quadraticPlus(-Grav/2, -ship:verticalspeed, (alt:radar + offset) - SHIP:GEOPOSITION:TERRAINHEIGHT).//r = r0 + vt - 1/2at^2 ===> Quadratic equiation 1/2*at^2 + bt + c = 0 a= acceleration, b=velocity, c= distance
	local fallVel is abs(ship:verticalspeed) + (Grav*fallTime).//v = u + at
	local disthorz is falltime*ship:velocity:surface.

	local arr is lexicon().
	arr:add ("fallTime", fallTime).
	arr:add ("fallVel", fallVel).
	arr:add ("disthorz", disthorz).
	
	Return(arr).
}

function ff_quadraticPlus {
	parameter a, b, c.
	return (b - sqrt(max(b ^ 2 - 4 * a * c, 0))) / (2 * a).
}

function ff_centre_engine_A{
	Local englist is List().
	LIST ENGINES IN engList. 
	FOR eng IN engList { 
		IF eng:TAG ="1DC" { 
			if eng:ALLOWRESTART{
				eng:activate. 
				//Print "Engine". 
			}
		}
	}
}

function ff_outter_engine_A{
	Local englist is List().
	LIST ENGINES IN engList. 
	FOR eng IN engList { 
		IF eng:TAG ="1DEC" { 
			if eng:ALLOWRESTART{
				eng:activate. 
				Print "Engine On". 
			}
		}
	}
}
function ff_outter_engine_S{
	Local englist is List().
	LIST ENGINES IN engList. 
	FOR eng IN engList { 
		IF eng:TAG ="1DEC" { 
			if eng:ALLOWSHUTDOWN{
				eng:shutdown. 
				//Print "Engine off".
			} 
		}
	}
}



FUNCTION ff_main {
	print "Landing guidance script loaded".
	wait until ship:name = "Falcon 9 Debris".
	clearscreen.
	set info to "Landing guidance script enabled".
	set runmode tO "RELEASING SECOND STAGE".
	wait 8.		
	
	set body_circumference to 2 * constant:pi * body:radius.
	set gravity_acceleration to constant:G * body:mass / (body:radius)^2.
	
	set targetcoordinates to LATLNG(28.608434,-80.58609). //LZ-1
	
	lock srfdisterror to dgtom(targetcoordinates:lat,targetcoordinates:lng,impactcoordinates():lat,impactcoordinates():lng).
	
	set MerlinSLthrust to 845. //thrust of a single Melin 1D++ engine at sea level in (kN)
	
	set burndist1 to -1.
	set masterpitch to -1.
	set masterhead to -1.
	set telemetry to true.
	
	lock pitch to 90 - vectorangle(ship:up:forevector, ship:facing:forevector). //navball pitch (read only)
	set northPole to latlng(90,0).
	//lock head to mod(360 - northPole:bearing,360). //navball heading (read only)
	set shipheight to 45.
	lock truealt to ship:altitude - targetcoordinates:terrainheight - shipheight. //sbsolute altitude (read only)
	
	lock steering to heading(masterhead,masterpitch).	
	set thrott to 0.
	lock throttle to thrott.

	when(telemetry) then {
		printtelemetry(0.1).
		preserve.
	}
	
	boostback().
	coastphase().
	entryburn().
	descentguidance().
	landing().
}

FUNCTION ff_entryburn {	
	set runmode to "ENTRYBURN".	
	set info to "Entry burn start".
	set thrott to 1.
	
	until (machnumber() < 3) {
		//HEADING CONTROL		
		set distlat to dglattom(impactcoordinates():lat - targetcoordinates:lat).
		set distlng to dglngtom(impactcoordinates():lng - targetcoordinates:lng, targetcoordinates:lat).
		
		set alpha to arctan(distlat/distlng).
		
		if(impactcoordinates():lat > targetcoordinates:lat) {
			if(impactcoordinates():lng < targetcoordinates:lng) {
				set targethead to 270 + alpha.
			} else {
				set targethead to 90 - alpha.
			}
		} else {
			if(impactcoordinates():lng < targetcoordinates:lng) {
				set targethead to 270 - alpha.
			} else {
				set targethead to 90 + alpha.
			}
		}
		set targethead to targethead + 180.
		
		//PITCH CONTROL
		set srfdist1 to srfdisterror.
		wait 0.01.
		set srfdist2 to srfdisterror.
		
		if(srfdist2 > 150) {
			set targetpitch to 75.
		} else {
			set approachspeed to (srfdist1 - srfdist2)/0.01.
			set timetotarget to srfdist2/approachspeed.
			set impacttime to abs(truealt/ship:verticalspeed).			
			if(timetotarget < impacttime - 5) {
				set targetpitch to targetpitch - 0.2.
			} else {
				set targetpitch to targetpitch + 0.2.
			}
		}
		
		set targetpitch to max(75,min(targetpitch,90)).
		
		//BURN DISTANCE CALCULATION
		if(machnumber() < 1) {
			set enginespullupdistance to  - ship:verticalspeed * 2.5.
			set burndist1 to ship:velocity:surface:mag^2 / (2 * (MerlinSLthrust/ship:mass - gravity_acceleration)) + enginespullupdistance.	
		}
		
		//OUTPUT
		set masterhead to mod(targethead,360).
		set masterpitch to targetpitch.
	}
	
	set thrott to 0.
	set info to "Entry burn shutdown".
}

FUNCTION ff_descentguidance {
	set runmode to "DESCENT GUIDANCE".
	reset_controls().
	RCS on.	
	
	lock steering to heading(masterhead,masterpitch).
		
	until (truealt < burndist1) {
		if(machnumber() >= 0.8) {
			set masterhead to srfretrogradehdg().
			set masterpitch to srfretrogradepitch().
		} else {
			//HEADING CONTROL		
			set distlat to dglattom(impactcoordinates():lat - targetcoordinates:lat).
			set distlng to dglngtom(impactcoordinates():lng - targetcoordinates:lng, targetcoordinates:lat).
			
			set alpha to arctan(distlat/distlng).
			
			if(impactcoordinates():lat > targetcoordinates:lat) {
				if(impactcoordinates():lng < targetcoordinates:lng) {
					set targethead to 270 + alpha.
				} else {
					set targethead to 90 - alpha.
				}
			} else {
				if(impactcoordinates():lng < targetcoordinates:lng) {
					set targethead to 270 - alpha.
				} else {
					set targethead to 90 + alpha.
				}
			}
			
			//PITCH CONTROL
			set srfdist1 to srfdisterror.
			wait 0.01.
			set srfdist2 to srfdisterror.
			
			if(srfdist2 > 150) {
				set targetpitch to 60.
			} else {
				set approachspeed to (srfdist1 - srfdist2)/0.01.
				set timetotarget to srfdist2/approachspeed.
				set impacttime to abs(truealt/ship:verticalspeed).			
				if(timetotarget < impacttime - 5) {
					set targetpitch to targetpitch - 0.2.
				} else {
					set targetpitch to targetpitch + 0.2.
				}
			}
			
			set targetpitch to max(75 - srfretrogradepitch(),min(targetpitch,90)).
			
			//BURN DISTANCE CALCULATION
			if(machnumber() < 1) {
				set enginespullupdistance to  - ship:verticalspeed * 2.5.
				set burndist1 to ship:velocity:surface:mag^2 / (2 * (MerlinSLthrust/ship:mass - gravity_acceleration)) + enginespullupdistance.	
			}
			
			//OUTPUT
			set masterhead to mod(targethead,360).
			set masterpitch to targetpitch.
		}
		wait 0.1.
	}	
}

FUNCTION ff_landing {
	set runmode to "LANDING".
	toggle AG9.	
	reset_controls().
	RCS on.	
	set targethead to srfretrogradehdg.
	set targetpitch to srfretrogradepitch.
	lock steering to heading(masterhead,masterpitch).
	set throttin to 1.
	set thrott to throttin.
	set info to "Landing burn start".
	wait 2.5.
	lock burndist1 to ship:velocity:surface:mag ^ 2 / (2 * (MerlinSLthrust/ship:mass - gravity_acceleration)).
	
	until (ship:status = "LANDED" or ship:verticalspeed > -1) { //until ship is on the surface or starts ascending up
		//THORTTLE CONTROL
		
		set delta1alt to truealt - burndist1.
		wait 0.01.
		set delta2alt to truealt - burndist1.
		if(delta2alt < 3) { //if distance to stop is GREATER than altitude
			set throttin to 1.
		} else { //if distance to stop is smaller than altitude
			if (delta2alt > 20) { //if distance to stop is much smaller than altitude
				set throttin to throttin - 0.1.
			} else { //if distance to stop is slightly smaller than altitude
				if (delta2alt > delta1alt) { //if difference between distance to stop and altitude increases
					set throttin to throttin - 0.1.
				} else { //if difference between distance to stop and altitude decreases
					set throttin to throttin + 0.1.
				}
			}
		}	

		//ORIENTATION CONTROL
		if(abs(ship:verticalspeed) >= 150) { //if ships velocity > 150m/s, it locks steering to srfretrograde
			set targethead to srfretrogradehdg.
			set targetpitch to srfretrogradepitch.
		} else if(abs(ship:verticalspeed) > 75 and abs(ship:verticalspeed) < 150) { //if ships velocity is between 50 and 150m/s, it controls pitch and head to reach as close to the target as possible
			//HEADING CONTROL		
			set distlat to dglattom(impactcoordinates():lat - targetcoordinates:lat).
			set distlng to dglngtom(impactcoordinates():lng - targetcoordinates:lng, targetcoordinates:lat).
		
			set alpha to arctan(distlat/distlng).
		
			if(impactcoordinates():lat > targetcoordinates:lat) {
				if(impactcoordinates():lng < targetcoordinates:lng) {
					set targethead to 270 + alpha.
				} else {
					set targethead to 90 - alpha.
				}
			} else {
				if(impactcoordinates():lng < targetcoordinates:lng) {
					set targethead to 270 - alpha.
				} else {
					set targethead to 90 + alpha.
				}
			}
			set targethead to targethead + 180.
		
			//PITCH CONTROL
			set srfdist1 to srfdisterror.
			wait 0.01.
			set srfdist2 to srfdisterror.
		
			if(srfdist2 > 50) {
				set targetpitch to 75.
			} else if (srfdist2 < 1) {
				lock steering to srfretrograde.
			} else {
				set approachspeed to (srfdist1 - srfdist2)/0.01.
				set timetotarget to srfdist2/max(approachspeed,0.01).
				set impacttime to abs(truealt/ship:verticalspeed).			
				if(timetotarget < impacttime) {
					set targetpitch to targetpitch - 0.4.
				} else {
					set targetpitch to targetpitch + 0.4.
				}
			}			
			set targetpitch to max(75,min(targetpitch,90)).		
			
		} else {
			if(not gear) {
				gear on.
				set info to "Landing legs deployed".
			}
			set targethead to srfretrogradehdg.
			set targetpitch to srfretrogradepitch.
		}
		
		set thrott to max(min(throttin,1),0.1).		
		
		set masterhead to mod(targethead,360).
		set masterpitch to targetpitch.
	}
	
	set thrott to 0.	
	set info to "The Falcon has landed!".
	wait 1.
	set telemetry to false.
}


FUNCTION dglngtom {
	PARAMETER lng.
	PARAMETER lat.
	
	return abs(body_circumference * lng * cos(lat) / 360).	
}

FUNCTION dglattom {
	PARAMETER lat.
	
	return abs(body_circumference * lat / 360).
}



FUNCTION mlngtodg {
	PARAMETER dist.
	PARAMETER lat.
	
	return 360 * dist / (body_circumference * cos(lat)).
}

FUNCTION impactcoordinates {
	if(addons:tr:hasimpact) {
		return addons:tr:impactpos.
	} else {
		return ship:geoposition.
	}
}




FUNCTION srfretrogradepitch {
	set progradepitch to 90 - vectorangle(ship:up:vector, ship:velocity:surface).

	return -progradepitch.
}

FUNCTION headingtopolarvec {
	PARAMETER head.
	PARAMETER pitch.
	
	local magnitude to 90 - pitch.
	
	local xc to magnitude * sin(head).
	local yc to magnitude * cos(head).
	
	local Vc to V(xc,yc,0).
	
	return Vc.
}

FUNCTION polarvectoheading {
	PARAMETER Vec2D.
	
	local xc to Vec2D:x.
	local yc to Vec2D:y.
	
	local magnitude to sqrt(xc^2 + yc^2).
	local pitch to 90 - magnitude.
	
	local thetaprim to arctan(abs(xc/yc)).
	
	if(xc >= 0 and yc >= 0) {
		local theta to thetaprim.
		return list(theta,pitch).
	} else if (xc > 0 and yc < 0) {
		local theta to 180 - thetaprim.
		return list(theta,pitch).
	} else if (xc < 0 and yc < 0) {
		local theta to 180 + thetaprim.
		return list(theta,pitch).
	} else {
		local theta to 360 - thetaprim.
		return list(theta,pitch).
	}
}