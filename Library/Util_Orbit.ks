
//http://www.bogan.ca/orbits/kepler/orbteqtn.html
//https://en.wikipedia.org/wiki/Orbital_mechanics

///// Download Dependant libraies

///////////////////////////////////////////////////////////////////////////////////
///// List of functions that can be called externally
///////////////////////////////////////////////////////////////////////////////////

		// ff_EccOrbitVel,
		// ff_CircOrbitVel,
		// ff_Find_AN_INFO,
		// ff_Find_AN_UT,
		// ff_TAr,
		// ff_timeFromTA,  
		// ff_TAtimeFromPE,
		// ff_quadraticMinus,
		// ff_quadraticPlus,
		// ff_OrbVel,  
		// ff_OrbPer,
		// ff_HorVecAt,
		// ff_OrbSLR,
		// ff_OrbSLRh,
		// ff_TAvec,
		// ff_EccAnom,
		// ff_MeanAnom,
		// ff_normalvector,
		// ff_eccentrcity,
		// ff_OrbitEnergy,
		// ff_Orbit_Ang_Mom,
		// ff_Orbit_KE,
		// ff_Orbit_PE,
		// ff_OrbitSplitVel

////////////////////////////////////////////////////////////////
//File Functions
////////////////////////////////////////////////////////////////

function ff_EccOrbitVel{ //returns the eccentirc orbital velocity of the ship at a specific altitude and sma.
	parameter alt is ship:Altitude.
	parameter sma is ship:orbit:semimajoraxis.
	local vel is sqrt(Body:MU*((2/(alt+body:radius))-(1/sma))).
	return vel.
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_CircOrbitVel{ //returns the circular orbital velocity of the current ship at a specific altitude.
	parameter alt.
	return sqrt(Body:MU/(alt + body:radius)).
}
///////////////////////////////////////////////////////////////////////////////////
Function ff_Find_AN_INFO { // returns parameters related to the ascending node of the current vessel and a target vessel.
	parameter tgt.
	///Orbital vectors
	local ship_V is ship:obt:velocity:orbit.//:normalized * 9000000000.
	local tar_V is tgt:obt:velocity:orbit.//:normalized * 9000000000.

	///Position vectors
	Local ship_r is ship:position - body:position.
	Local tar_r is tgt:position - body:position.

	////plane normals also known as H or angular momentum
	local ship_N is vcrs(ship_V,ship_r).//:normalized * 9000000000.
	local tar_N is vcrs(tar_V,tar_r).//:normalized * 9000000000.

	/// AN vector which is perpendicular to the plane normals
	set AN to vcrs(ship_N,tar_N):normalized. // the magnitude is irrelavent as it is a combination of parralellograms which has not real meaning
	Set AN_inc to vang(ship_N,tar_N). // the inclination change angle

	local arr is lexicon().
	arr:add ("ship_V", ship_V).
	arr:add ("ship_r", ship_r).
	arr:add ("ship_N", ship_N).
	arr:add ("tar_V", tar_V).
	arr:add ("tar_r", tar_r).
	arr:add ("tar_N", tar_N).
	arr:add ("AN", AN).
	arr:add ("AN_inc", AN_inc).
	
	Return (arr).
	
}/// End Function
///////////////////////////////////////////////////////////////////////////////////

Function ff_Find_AN_UT { // Finds the time to the ascending node of the current vessel and a target vessel/moon.
//TODO: Remove redundant code relating to sector adjustment once fully tested.
//TODO: Remove redundant code relating to Ship TA and AN Eccetric anomoly and Mean anomoly once the time to PE code is fully tested.
//TODO: Remove redundant array call from AN info.
	parameter tgt.
	Print "Finding AN/DN..".		  
	//Conduct manever at the AN or DN to ensure inclination	is spot on and low dv.
	local arr is lexicon().
	Set arr to ff_Find_AN_INFO(tgt).
	// Set ship_V to arr ["ship_V"].
	// Set ship_r to arr ["ship_r"].
	// Set ship_N to arr ["ship_N"].
	// Set tar_V to arr ["tar_V"].
	// Set tar_r to arr ["tar_r"].
	// Set tar_N to arr ["tar_N"].
	Set AN to arr ["AN"].
	Set AN_inc to arr ["AN_inc"].

	//Current Ship Information.
	Set Ship_e to Ship:orbit:Eccentricity.
	Set Ship_Per to Ship:orbit:Period.
	Set ship_eta_apo to eta:apoapsis.
	Set ship_eta_PE to eta:periapsis.
	Set Ship_a to ship:orbit:SEMIMAJORAXIS.

	Set AN_True_Anom to Constant:DegtoRad*(ff_TAvec(AN)).
	Print "AN True Anom alt Rad" + AN_True_Anom.

	Set AN_Ecc_Anom to ff_EccAnom(Ship_e, AN_True_Anom).
	Print "AN Ecc Anom Rad" + AN_Ecc_Anom.
	
	Set AN_Mean_Anom to ff_MeanAnom (Ship_e, AN_Ecc_Anom).
	Print "AN Mean Anom Rad" + AN_Mean_Anom.

	Set AN_time_From_PE to ff_TAtimeFromPE(Constant:RadtoDeg*AN_True_Anom,Ship_e).
	Print "AN_time_From_PE: " + AN_time_From_PE.
	
	local AN_time is ship_eta_PE + AN_time_From_PE.
	Print "AN_time " + AN_time.	
	
	If (time:seconds + AN_time) < (time:seconds + 240){
		Set AN_time to time:seconds + AN_time + Ship_Per. //put on next orbit as its too close to calculate in time.
		Print "AN time too close Shifting Orbit".
	}
	Else {
		Set AN_time to time:seconds + AN_time.
	}
	
	Print "AN_time UT" + AN_time.
	//Refine the UT using hill climb
	ff_Seek_low(AN_time, ff_freeze(0), ff_freeze(0), ff_freeze(0), { 
		parameter mnv. 
		Set AN_time to time:seconds + mnv:ETA.
		return - vang ((positionat(ship, time:seconds + mnv:eta)-body:position),AN). // want the angle to be zero between the ship radial vector and the AN node.
		}
	).
	Set x to nextnode.
	Set AN_time to time:seconds + x:ETA.
	Remove nextnode.
	wait 0.1.
	If x:ETA < 240{
		Set AN_time to AN_time + Ship_Per. //put on next orbit as its too close to calculate in time.
		Print "AN time too close Shifting Orbit".
	}
	Print "Final AN time" + AN_time.
	Return AN_time.

}/// End Function
///////////////////////////////////////////////////////////////////////////////////	
function ff_TAr {
	parameter r, SMA, ecc. // full orbital radius, Semimajoraxis, eccentricity.
	local p is ff_OrbSLR(SMA, ecc).
	local TA is arccos(p / r / ecc - 1 / ecc).
	//Print "TAr:" + TA.
	return TA. // Returns the True Anomoly at specified radius in degress
	
	//Old version
	//Set TA to ((ship_a*(1-(ship_e*ship_e))) - ship_r:mag) / (ship_e * ship_r:mag).
	//Set TA to arccos( TA ).//eq(4.82)
	
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_timeFromTA {
//TODO: Check this code work for all positions and cases need to check if TA time from PE returns only in one direction or swaps times once 180 degrees has been reached.

	parameter TA, ecc. // True anomoly (must be in degrees), eccentricity.
	Local timetoTA is ff_TAtimeFromPE (TA, ecc).
	Print (ETA:periapsis + timetoTA).
	Print Ship:orbit:Period.
	Print (ETA:periapsis + timetoTA) - Ship:orbit:Period.
	If (ETA:periapsis + timetoTA) - Ship:orbit:Period > 0{ // we know we will get to the TA before the PE.
		Print "Not Else".
		return (ETA:periapsis + timetoTA) - Ship:orbit:Period.
	}
	Else {  // we know we will get to the PE before the TA.
		return  (ETA:periapsis + timetoTA). //TA time from PE in seconds (add time:seconds to get UT).
		Print "Else".
	}
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_TAtimeFromPE {
	parameter TA, ecc. // True anomoly (must be in degrees), eccentricity.
	local EA is ff_EccAnom(ecc, TA).
	Print "EA:" + EA.
	local MA is ff_MeanAnom(ecc, EA).
	Print "MA:" + MA.
	local TA_time is Ship:orbit:Period/360. //sec per degree
	Print "TA time intermediate: " + TA_time.
	Set TA_time to MA*TA_time.
	Print "TA Time From PE:" + TA_time.
	return TA_time. //TA time from PE in seconds, Range from 0 to Ship:Orbital period
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_quadraticMinus {
	parameter a, b, c.
	return (-b - sqrt(max(b ^ 2 - 4 * a * c, 0))) / (2 * a).
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_quadraticPlus {
	parameter a, b, c.
	return (b - sqrt(max(b ^ 2 - 4 * a * c, 0))) / (2 * a).
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_OrbVel {
	parameter r, SMA, mu. // full orbital raduis, Semimajoraxis, mu.
	return sqrt(mu * (2 / r - 1 / SMA)). //returns Orbital velocity for specific orbit and radius
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_OrbPer {
	parameter a, mu is body:mu. // Semimajoraxis, mu.
	return (2 * constant:pi) * sqrt((a^3)/mu).//returns Orbital period
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_HorVecAt {
	parameter ut. // universal time
	local vBod is ship:body:position - positionat(ship, ut).
	return vxcl(vBod,velocityat(ship, ut):orbit). //returns the surface horizontal velocity vector component of the ship vector at a specific time. 
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_OrbSLR {
	parameter SMA, ecc. // Semimajoraxis, eccentricity.
	Local p is SMA * (1 - ecc ^ 2).
	//Print "SLR:" + p.
	return p. //Returns the Semilatus rectum
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_OrbSLRh {
	parameter h, mu. // Sspecific angular momentum, mu.
	Local p is (h^2)/mu.
	//Print "SLR:" + p.
	return p. //Returns the Semilatus rectum
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_TAvec {
	parameter vec. // a vector along ships orbit that you want the TA for.
	set orbnorm to ff_normalvector(ship). // gives vector from ship to centre of body
	set vecProj to vxcl(orbnorm,vec). // this provides the vector projected to the ships current plane
	set vPEr to positionat(ship,time:seconds+eta:periapsis)-ship:body:position. // gives vector of periapsis
	set TA to vang(vPEr,vecProj). // give angle between the two (TA raw)
	if abs(vang(vecProj,vcrs(orbnorm,vPEr))) < 90 {
		return 360-TA.
	}
	else{
		return TA. // Returns the True Anomoly of a vector along the ships orbit in degrees
	}
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_EccAnom {
	parameter ecc, TA. // eccentricity, True Anomoly (in radians or degrees).
	Print ecc.
	Print TA.
	local E is arccos(  (ecc + cos(TA)) / (1 + (ecc * cos(TA)))  ).
	Print "EccAnom:" + E.	
	//Old version
	//Local E is arctan(sqrt(1-(ecc*ecc))*sin(TA) ) / ( ecc + cos(TA) ). // note this version is suitable for radians only
	//Print "Old EccAnom:" + E.
	return E. //Eccentric Anomoly in True anomoly input (radians or degrees)

}
///////////////////////////////////////////////////////////////////////////////////	
function ff_MeanAnom {
	parameter ecc, EccAnom. // eccentricity, Eccentric Anomoly (in radians or degrees).
	local MA is EccAnom - (ecc * sin(EccAnom)).
	//Print "MeanAnom:" + MA.
	return MA. //Mean Anomoly in EccAnom input(radians or degrees)
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_normalvector{
	parameter ves.
	set vel to velocityat(ves,time:seconds):orbit.
	set norm to vcrs(vel,ves:up:vector). 
	return norm:normalized.// gives vector pointing towards centre of body from ship
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_eccentrcity{
	parameter ApR is Orbit:Apoapsis + body:radius, PeR is Orbit:Periapsis + body:radius. // full radius of the periapsis and apoapsis including the body:radius
	Set ecc to ((ApR - PeR) / (ApR + PeR)).
	return ecc.
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_OrbitEnergy{
	Parameter ApR is Orbit:Apoapsis + body:radius, PeR is Orbit:Periapsis + body:radius, mu is ship:mu .
	Set OrbitEnergy to -mu / (PeR + ApR).
	Return OrbitEnergy.
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_Orbit_Ang_Mom{
	Parameter OrbitEnergy is ff_OrbitEnergy(), mu is ship:mu, ApR is Orbit:Apoapsis + body:radius, PeR is Orbit:Periapsis + body:radius.
	Set h to Sqrt(Abs(((OrbitEnergy * (ApR - ApR))^2 - mu^2) / (2 * OrbitEnergy))). // visa-viva equation E=-1/2 * (mu^2/h^2) (1-e^2)  => through alot of substitution and manipulation  h^2 = ((E(ra - rp)^2 - mu^2)/2E
	return h.
}    
///////////////////////////////////////////////////////////////////////////////////	
//TODO: Double check the plus and minus units for the Poetintial and Kinetic Energy functions below 

function ff_Orbit_KE{
	Parameter OrbitEnergy is ff_OrbitEnergy(), radius is ship:altitude + body:radius, mu is ship:mu. // full radius including the body:radius
	Set KE to (OrbitEnergy - mu) / radius.// Orbit Energy = -mu/2a + mu/R  => mu/2a = Orbit Energy - mu /R	= Kinetic Energy component of orbit
	Return KE.
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_Orbit_PE{
	Parameter OrbitEnergy is ff_OrbitEnergy(), sma is ship:sma, mu is ship:mu. // full radius including the body:radius
	Set PE to (OrbitEnergy + mu) / 2*sma.// Orbit Energy = -mu/2a + mu/R  => mu/R = Orbit Energy + mu/2a	= Potential Energy component of orbit
	Return PE.
}
///////////////////////////////////////////////////////////////////////////////////	
function ff_OrbitSplitVel{
	Parameter Orbit_Ang_Mom, Orbit_KE is ff_Orbit_KE(), radius is ship:altitude + body:radius. // full radius including the body:radius
	Set horizontalV  to  Orbit_Ang_Mom / radius.   //horizontal velocity of new orbit at radius
    Set verticalV to Sqrt(Abs(2 * Orbit_KE - horizontalV * horizontalV)). //vertical velocity of new orbit at UT
	
	local arr is lexicon().
	arr:add ("Horz_V", horizontalV).
	arr:add ("Vert_V", verticalV).
	Return (arr).
}

////////////////////////////////////////////////////////////////
//Helper Functions
////////////////////////////////////////////////////////////////





