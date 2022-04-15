$TITLE	Read the SEDS dataset and Aggrgate States to a Regional Mapping

*	------------------------------------------------------------------------------
*	Runtime options
*	------------------------------------------------------------------------------

*	File separator

$set sep %system.dirsep%

*	Define regional aggregation (state or census):

$if not set rmap $set rmap state

*	Location of the core build directory and the WINDC base data:

$set core          ..%sep%core%sep%
$set windc_base    %core%windc_base.gdx

$if not set mapdir $set mapdir %system.fp%maps%sep%

*	Define the latest year -- used for cross checking current data

$set	year	2017

$ONTEXT
		State Energy Data System (SEDS)

Data Series Names (MSN) and Descriptions:
	- The MSNs are five-character codes, most of which are structured
          as follows:
	- First and second characters - describes an energy source (for
          example, NG for natural gas, MG for motor gasoline)
	- Third and fourth characters - describes an energy sector or an
	  energy activity (for example, RC for residential consumption, PR
	  for production)
	- Fifth character - describes a type of data (for example, P for
	  data in physical unit, B for data in billion Btu)

Commercial sector:

An energy-consuming sector that consists of service-providing
facilities and equipment of: businesses; federal, state, and local
governments; and other private and public organizations, such as
religious, social, or fraternal groups. The commercial sector includes
institutional living quarters. It also includes sewage treatment
facilities. Common uses of energy associated with this sector include
space heating, water heating, air conditioning, lighting,
refrigeration, cooking, and running a wide variety of other equipment.
Note: This sector includes generators that produce electricity and/or
useful thermal output primarily to support the activities of the
above-mentioned commercial establishments.

Industrial sector:

An energy-consuming sector that consists of all facilities and
equipment used for producing, processing, or assembling goods.  The
industry setor encompasses the following types of activity:
manufacturing (NAICS codes 31-33); agriculture, forestry, fishing, and
hunting (NAICS code 11); mining, including oil and gas extraction
(NAICS code 21); and construction (NAICS code 23).  Overall energy use
in this sector is largely for process heat and cooling and powering
machinery, with lesser amounts used for facility heating, air
conditioning, and lighting. Fossil fuels are also used as raw material
inputs to manufactured products. Note: This sector includes generators
that produce electricity and/or useful thermal output primarily to
support the above-mentioned industrial activities.

Transportation sector:

An energy-consuming sector that consists of all vehicles whose primary
purpose is transporting people and/or goods from one physical location
to another. Included are automobiles; trucks; buses; motorcycles;
trains, subways, and other rail vehicles; aircraft; and ships, barges,
and other waterborne vehicles. Vehicles whose primary purpose is not
transportation (e.g., construction cranes and bulldozers, farming
vehicles, and warehouse tractors and forklifts) are classified in the
sector of their primary use. In this report, natural gas used in the
operation of natural gas pipelines is included in the transportation
sector.

Electric power sector:

An energy-consuming sector that consists of electricity-only and
combined-heat-and-power plants within the NAICS (North American
Industry Classification System) 22 category whose primary business is
to sell electricity, or electricity and heat, to the public. Note:
This sector includes electric utilities and independent power
producers.

The State Codes are 2-character codes, following the U.S. Postal
Service State abbreviations. Geographic areas used throughout SEDS
includes the 50 States and the District of Columbia, and the United
States.  For production of crude oil and natural gas, Federal offshore
regions are identified by X3 and X5.
$OFFTEXT


* ------------------------------------------------------------------------------
*	Read in the SEDS data
* ------------------------------------------------------------------------------

SET
	source	"Dynamically created set from seds_units parameter, EIA SEDS source codes",
	sector_	"Dynamically created set from seds_units parameter, EIA SEDS sector codes",
	co2dim	"Dynamically created set from emissions_units parameter, EIA C02 sector codes",
	src(*)	"SEDS energy technologies",
	g	"BEA Goods and sectors categories",
	sr	"Super set of Regions (states + US) in WiNDC Database",
	r(sr)	"Regions in WiNDC Database",
	yr	"Years in WiNDC Database",
	version "WiNDC data version number";

PARAMETER	seds_units(source,sector_,sr,yr,*)	"Complete EIA SEDS data, with units as domain",
		heatrate_units(yr,*,*)			"EIA Elec Generator average heat rates, with units as domain",
		emissions_units(co2dim,r,yr,*)		"CO2 emissions, with units as domain",
		co2perbtu_units(*,*)			"Carbon dioxide -- not CO2e -- content, with units as domain";

$GDXIN '%windc_base%'
$LOAD version
$LOAD src=seds_src
$LOAD sr
$LOAD r
$LOAD yr
$LOAD source<seds_units.dim1
$LOAD sector_<seds_units.dim2
$LOAD seds_units
$LOAD heatrate_units
$LOAD co2dim<emissions_units.dim1
$LOAD emissions_units
$LOAD co2perbtu_units
$GDXIN

* SHANE's EDITS BEGIN

* read in data for how to split motor gasoline between trucks and ldvs and split distillate fuel oil between trains and trucks
SET mg_split / road, nonroad /;
SET df_split / train, trk /;
ALIAS (r,r2);
PARAMETER trans_breakdown(r2, mg_split);
PARAMETER ground_breakdown(r2, df_split);

$GDXIN '%mapdir%%sep%..%sep%gdx%sep%trans_breakdown.gdx'
$LOAD trans_breakdown

$GDXIN '%mapdir%%sep%..%sep%gdx%sep%ground_breakdown.gdx'
$LOAD ground_breakdown

display trans_breakdown, ground_breakdown;

* SHANE's EDITS END

set	srcadd(*)	/wd	Wood and waste burning/;

*	Add WD to the set of sources:

src("wd") = srcadd("wd");

option src:0:0:1;
display src;


*	PA	"All Petroleum Products" -- See documentation for discription.

SET petr(source) "Petroleum products" /
	AR	"Asphalt and road oil"
	AV	"Aviation gasoline"
	DF	"Distillate fuel oil"
	JF	"Jet fuel"
	KS	"Kerosene"
	HL	"Hydrocarbon gas liquids"
	LU	"Lubricants"
	MG	"Motor gasoline"
	OP 	"Other petroleum products"
	PC	"Petroleum coke"
	RF	"Residual fuel oil" /;

SET sector(*) /set.sector_, AC_air, AC_ground, AC_water, AC_LDV /;
display sector;

SET s(sector_) "End use sectors" /
	RC	"Residential sector"
	CC	"Commercial sector"
	IC	"Industrial sector"
	AC	"Transportation sector"
	EI	"Electric power sector" /;

* SHANE's CHANGES BEGIN
SET s_new(sector) / 
	set.s 
	AC_air 		"Air transportation"
	AC_ground	"Ground transportation (trucks & trains)"
	AC_water	"Water transportation (that would be boats)"
	AC_LDV		"Personal transportation (LDVs)"
/;
* SHANE's CHANGES END

SET petruse(source,*) "Mapping energy sources with demand categories" /
	(DF,HL,KS).RC					"Residential sector"
	(DF,HL,KS,MG,RF,PC).CC				"Commercial sector"
	(AR,DF,HL,KS,LU,MG,OP,PC,RF).IC			"Industrial sector"
* SHANE's CHANGES BEGIN
*	(AV,DF,HL,JF,LU,MG,RF).AC			"Transportation sector"
	(AV,JF).AC_air					"Air transportation"
	(DF,HL).AC_ground				"Ground transportation (trucks and trains - will split out later into train, trk)"
	(RF).AC_water					"Water trandsportation (boats!)"
	(MG).AC_LDV						"Personal Transportation (Light Duty Vehicles)"
* Shane's CHANGES END
	(DF,PC,RF).EI					"Electric power sector"
	(AR,AV,DF,HL,JF,KS,LU,MG,OP,PC,RF).TOTAL	"All" /;

* SHANE's CHANGES BEGIN
* Building some sets for later
SET nonroad_sources(source) "SEDS sources -> nonroad" / AV, DF, HL, JF, LU, RF /;
SET air_sources(source) "SEDS sources -> air" / JF, AV /;
SET ground_sources(source) "SEDS sources -> ground" / DF, HL /;
* SHANE's CHANGES END

PARAMETER	pet_chk "Cross check on petroleum demand",
		pet_prc "Petroleum price";

pet_chk(petruse(petr,s)) = sum(sr, seds_units(petr,s,sr,"%year%","billion btu"));
pet_prc(petruse(petr,s)) = sum(sr, seds_units(petr,s,sr,"%year%","us dollars (USD) per million btu"));
pet_chk(petr,"rowsum") = sum((sr,petruse(petr,s)), seds_units(petr,s,sr,"%year%","billion btu"));
pet_chk(petr,"rowchk")$(NOT SAMEAS(petr,"PC"))
	= sum((sr,petruse(petr,s)), seds_units(petr,s,sr,"%year%","billion btu")) - sum(sr, seds_units(petr,"TC",sr,"%year%","billion btu"));

* TC: Total consumption. The above calculates how far off the listed
* disaggregate data is with provided totals. Hopefully the residual is due
* to rounding.

pet_chk("PO","rowchk") =
	sum(petruse(petr,s)$(SAMEAS(petr,"PO") OR SAMEAS(petr,"PC")), sum(sr, seds_units(petr,s,sr,"%year%","billion btu"))) -
	sum(petruse(petr,"total")$(SAMEAS(petr,"PO") OR SAMEAS(petr,"PC")), sum(sr, seds_units(petr,"TC",sr,"%year%","billion btu")));

pet_chk("colsum",s) = sum((sr,petruse(petr,s)), seds_units(petr,s,sr,"%year%","billion btu"));

pet_chk("colchk",s) = sum((sr,petruse(petr,s)), seds_units(petr,s,sr,"%year%","billion btu")) - sum(sr, seds_units("PA",s,sr,"%year%","billion btu"));


* The column check verifies that summing across all petroleum type goods
* is equivalent to the listed total. Row check sums across demanding
* sectors for each petroleum product.

pet_prc("PA",s)$sum(sr, seds_units("PA",s,sr,"%year%","billion btu"))
	= sum(sr, seds_units("PA",s,sr,"%year%","billion btu") * seds_units("PA",s,sr,"%year%","us dollars (USD) per million btu")) / sum(sr, seds_units("PA",s,sr,"%year%","billion btu"));

option pet_chk:0;
display pet_chk, pet_prc;

parameter	elechk "Check on electricity data";
elechk(sr,"EX") = seds_units("EL","EX",sr,"%year%","billion btu");
elechk(sr,"IM") = seds_units("EL","IM",sr,"%year%","billion btu");
elechk(sr,"NI") = seds_units("EL","NI",sr,"%year%","billion btu");
elechk(sr,"IS") = seds_units("EL","IS",sr,"%year%","billion btu");
elechk(sr,"LO") = seds_units("LO","TC",sr,"%year%","billion btu");
elechk(sr,"TC") = seds_units("ES","TC",sr,"%year%","billion btu");
elechk(sr,"C") = sum(s, seds_units("ES",s,sr,"%year%","billion btu"));
elechk(sr,"PR") = sum(s, seds_units("ES",s,sr,"%year%","billion btu")) - seds_units("EL","IS",sr,"%year%","billion btu")- seds_units("EL","NI",sr,"%year%","billion btu");

option elechk:0;

display 
	"EX: exported from US.",
	"IM: imported into US.",
	"NI: Net imports expenditures.",
	"IS: industrial sector excluding refinery fuel.",
	"TC: total consumption.",
	"EL: Electricity aggregates",
	"ES: Also Electricity. (sector related categories)",
	"LO: Electrical system energy loss.",
	elechk;


parameter	elegen "Electricity generation by source (mill. btu or tkwh for ele)";

loop(sr,

* Initial data is in billions of btu. Scaling by htrate converts to billions of kwh.

	elegen(sr,"col",yr) = seds_units("CL","EI",sr,yr,"billion btu") / heatrate_units(yr,"col","btu per kilowatthour");
	elegen(sr,"gas",yr) = seds_units("NG","EI",sr,yr,"billion btu") / heatrate_units(yr,"gas","btu per kilowatthour");
	elegen(sr,"oil",yr) = seds_units("PA","EI",sr,yr,"billion btu") / heatrate_units(yr,"oil","btu per kilowatthour");

* Initial data is in millions of kwh. Scaling by 1000 converts to billions of kwh.

	elegen(sr,"NU",yr) = seds_units("NU","EG",sr,yr,"million kilowatthours") / 1000;
	elegen(sr,"HY",yr) = seds_units("HY","EG",sr,yr,"million kilowatthours") / 1000;
	elegen(sr,"GE",yr) = seds_units("GE","EG",sr,yr,"million kilowatthours") / 1000;
	elegen(sr,"SO",yr) = seds_units("SO","EG",sr,yr,"million kilowatthours") / 1000;
	elegen(sr,"WY",yr) = seds_units("WY","EG",sr,yr,"million kilowatthours") / 1000;

* Add wood burned for producing electric power (in billion btu) -- heat rate
* from EIA: https://www.eia.gov/outlooks/aeo/assumptions/pdf/electricity.pdf.

	elegen(sr,"WD",yr) = seds_units("WD","EI",sr,yr,"billion btu") / 13500;

);
elegen("total",src,yr) = sum(sr, elegen(sr,src,yr));
elegen(sr,"total",yr) = sum(src, elegen(sr,src,yr));
elegen("total","total",yr) = sum(src, elegen("total",src,yr));

option elegen:2:2:1;
display elegen;

parameter	gas_chk		"Cross check on natural gas demand",
		gas_prc		"Gas price";

gas_chk(s) = sum(sr, seds_units("NG",s,sr,"2017","billion btu")) / 1e6;
gas_chk("demand") = sum(s, gas_chk(s));
gas_chk("supply") = sum(sr, seds_units("NG",'MP',sr,"2017","billion btu")) / 1e6;
display gas_chk;

gas_prc(sr,s)$seds_units("NG",s,sr,"%year%","billion btu") = seds_units("NG",s,sr,"%year%","us dollars (USD) per million btu") + eps;
display gas_prc;

set col(source) "Coal Index" / CL /;

parameter	col_chk "Cross check on coal demand",
		col_prc "Coal price";

col_chk(s) = sum(sr, seds_units("CL",s,sr,"%year%","billion btu")) / 1000;
col_chk("demand") = sum(s, col_chk(s));
col_chk("supply") = sum(sr, seds_units("CL","PR",sr,"%year%","billion btu")) / 1000;
col_chk("ccexb") =  sum(sr, seds_units("CC","EX",sr,"%year%","billion btu")) / 1000;
col_chk("ccimb") =  sum(sr, seds_units("CC","IM",sr,"%year%","billion btu")) / 1000;
col_chk("ccexp") =  sum(sr, seds_units("CC","EX",sr,"%year%","thousand short tons")) / 1000;
col_chk("ccimp") =  sum(sr, seds_units("CC","IM",sr,"%year%","thousand short tons")) / 1000;

sets
    sec "End use sectors" /
		res	"Residential sector"
		com	"Commercial sector"
		ind	"Industrial sector"
		trn	"Transportation sector"
		ele	"Electric power sector" /,

    secmap(sec,s) "Remapping nameas" /
		res.RC	"Residential sector"
		com.CC	"Commercial sector"
		ind.IC	"Industrial sector"
		trn.AC	"Transportation sector"
		ele.EI	"Electric power sector" /,
		
* SHANE's CHANGEs BEGIN
		sec_new "Final End use sectors" /
		res		"Residential sector"
		com		"Commercial sector"
		ind		"Industrial sector"
*		trn		"Transportation sector
		ele		"Electric power sector"
		air 	"Air transportation"
* 		ground is sum of trn and trk and will eventually be zeroed out
		ground 	"Ground transportation" 
		train	"Train transportation"
		trk		"Truck transportation"
		water	"Water transportation"
		ldv		"Personal transportation"
		/;

* SHANE's CHANGES END

parameters	fuelexpend	"Fuel expenditures in electric utilities",
		fueluse		"Fuel useitures in electric utilities",
		fuelprice	"Fuel price in electric utilities";

fuelexpend("col",sr,yr) = seds_units("CL","EI",sr,yr,"millions of us dollars (USD)");
fuelexpend("gas",sr,yr) = seds_units("NG","EI",sr,yr,"millions of us dollars (USD)");
fuelexpend("oil",sr,yr) = seds_units("PA","EI",sr,yr,"millions of us dollars (USD)");

fueluse("col",sr,yr) = seds_units("CL","EI",sr,yr,"billion btu") / 1000;
fueluse("gas",sr,yr) = seds_units("NG","EI",sr,yr,"billion btu") / 1000;
fueluse("oil",sr,yr) = seds_units("PA","EI",sr,yr,"billion btu") / 1000;

fuelprice("col",sr,yr)$fueluse("col",sr,yr) = fuelexpend("col",sr,yr) / fueluse("col",sr,yr) + eps;
fuelprice("gas",sr,yr)$fueluse("gas",sr,yr) = fuelexpend("gas",sr,yr) / fueluse("gas",sr,yr) + eps;
fuelprice("oil",sr,yr)$fueluse("oil",sr,yr) = fuelexpend("oil",sr,yr) / fueluse("oil",sr,yr) + eps;

set	e	"Energy sectors" / oil,gas,col,ele,cru /,
	ff(e)	"Fossil Fuels" / col,gas,oil /,
	pq	"Price vs. quantities" / p,q /,
	ed(*)	"Energy data" / supply, set.sec, ref /,
* SHANE's CHANGES BEGIN
	ed_new(*) "Energy data - new" / supply, set.sec_new, ref/
* SHANE's Changes END
	;

parameter ngp	Natural gas statistics;

ngp(sr,"d",sec) = sum(secmap(sec,s), seds_units("NG",s,sr,"%year%","us dollars (USD) per million btu"));
ngp(sr,"v",sec) = sum(secmap(sec,s), seds_units("NG",s,sr,"%year%","millions of us dollars (USD)"));
ngp(sr,"b",sec) = sum(secmap(sec,s), seds_units("NG",s,sr,"%year%","billion btu"))/1000;
ngp(sr,"d*b",sec) = sum(secmap(sec,s), seds_units("NG",s,sr,"%year%","billion btu") * seds_units("NG",s,sr,"%year%","us dollars (USD) per million btu"))/1000;

option ngp:1:2:1;
display ngp;

* Btu prices for states are calculated by dividing the physical unit prices by the
* conversion factor 3,412 Btu per kilowatthour. U.S. Btu prices are calculated as
* the average of the state Btu prices, weighted by consumption data from SEDS,
* adjusted for process fuel consumption in the industrial sector.

* Note that electricity data is in billions of kwh.

parameter	energydata(sr,pq,e,*,yr) "Benchmark energy data (trillion btu and $ per btu)";
loop(sr,

* Supply data is in trillions of btu.

	energydata(sr,"q","gas","supply",yr) = seds_units("NG","MP",sr,yr,"billion btu") / 1000;
	energydata(sr,"q","cru","supply",yr) = seds_units("PA","PR",sr,yr,"billion btu") / 1000;
	energydata(sr,"q","col","supply",yr) = seds_units("CL","PR",sr,yr,"billion btu") / 1000;

* Supply of electricity is in billions of kwh.

	energydata(sr,"q","ele","supply",yr) = sum(src, elegen(sr,src,yr));

* Sector level demands of electricity are scaled to be in billions of kwh.

	energydata(sr,"q","ele",ed(sec),yr) = sum(secmap(sec,s), seds_units("ES",s,sr,yr,"million kilowatthours")) / 1000;

* Sector level demands of gas, coal and oil in trillions of btu's.

	energydata(sr,"q","gas",ed(sec),yr) = sum(secmap(sec,s), seds_units("NG",s,sr,yr,"billion btu")) / 1000;
	energydata(sr,"q","oil",ed(sec),yr) = sum(secmap(sec,s), seds_units("PA",s,sr,yr,"billion btu")) / 1000;

* SHANE's CHANGES BEGIN
* We're splitting the "trn" sector into road (trucking, personal transit) and non-road (boats, planes, trains) transportation based on the fuel type from SEDS

	energydata(sr, "q", "oil", "air", yr) = sum(petruse(source,"AC_air"), seds_units(source,"ac",sr,yr,"billion btu")) / 1000;
	energydata(sr, "q", "oil", "water", yr) = sum(petruse(source, "AC_water"), seds_units(source,"ac",sr,yr,"billion btu")) / 1000;
	energydata(sr, "q", "oil", "ground", yr) = sum(petruse(source,"AC_ground"), seds_units(source,"ac",sr,yr,"billion btu")) / 1000;
	energydata(sr, "q", "oil", "ldv", yr) = sum(petruse(source, "AC_ldv"), seds_units(source,"ac",sr,yr,"billion btu")) / 1000;

*	energydata(sr,"q","oil","trn",yr) = sum(petruse(source,"AC"), seds_units(source,"ac",sr,yr,"billion btu")) / 1000;

* SHANE's CHANGES END

	energydata(sr,"q","col",ed(sec),yr) = sum(secmap(sec,s), seds_units("CL",s,sr,yr,"billion btu")) / 1000;

	energydata(sr,"q","col","ele",yr) = seds_units("CL","EI",sr,yr,"billion btu") / 1000;
	energydata(sr,"q","gas","ele",yr) = seds_units("NG","EI",sr,yr,"billion btu") / 1000;
	energydata(sr,"q","oil","ele",yr) = seds_units("PA","EI",sr,yr,"billion btu") / 1000;

* Refinery demands are included in the industrial category. See appendix
* in documentation.

	energydata(sr,"q","gas","ref",yr) = seds_units("NG",'RF',sr,yr,"billion btu") / 1000;
	energydata(sr,"q","gas","ind",yr) = energydata(sr,"q","gas","ind",yr) - energydata(sr,"q","gas","ref",yr);

	energydata(sr,"q","col","ref",yr) = seds_units("CL",'RF',sr,yr,"billion btu") / 1000;
	energydata(sr,"q","col","ind",yr) = energydata(sr,"q","col","ind",yr) - energydata(sr,"q","col","ref",yr);

* Amount of refined oil used in other refining processes include LPG +
* Distillate Fuel + Petroleum Coke + Residual Fuel Oil.

	energydata(sr,"q","oil","ref",yr) =
		(seds_units("DF",'RF',sr,yr,"billion btu") + seds_units('HL','RF',sr,yr,"billion btu") +
		 seds_units("PC",'RF',sr,yr,"billion btu") + seds_units('RF','RF',sr,yr,"billion btu") ) / 1000;

	energydata(sr,"q","cru","ind",yr) = seds_units('CO','IC',sr,yr,"billion btu") / 1000;

* Assume that the amount of crude oil consumed in the production of
* refined oils is equal to the sum of other types of oils consumed in the
* refining process.

	energydata(sr,"q","cru","ref",yr) = seds_units('P5','RF',sr,yr,"billion btu") / 1000;
	energydata(sr,"q","oil","ind",yr) = energydata(sr,"q","oil","ind",yr) - energydata(sr,"q","oil","ref",yr);

* Need to include electricity sales to refineries.
*	= electricity consumed by refineries (trillion btu) *
*	(elec consumed by ind sector (million kwh) / elec consumed by ind
*	sector (billion btu))
* In doing so, convert trillion btu's to billions of kwh in line with the
* above data.

	energydata(sr,"q","ele","ref",yr) = seds_units("ES",'RF',sr,yr,"billion btu") / 1000 *
		(seds_units("ES",'IC',sr,yr,"million kilowatthours") / seds_units("ES",'IC',sr,yr,"billion btu"));

	energydata(sr,"q","ele","ind",yr) = energydata(sr,"q","ele","ind",yr) - energydata(sr,"q","ele","ref",yr);

* Prices in dollars per million btu. Crude oil energy prices? No. Keeping
* these units, multiplying price x quantity will result in millions of
* dollars.

	energydata(sr,"p","gas",ed(sec),yr) = sum(secmap(sec,s), seds_units("NG",s,sr,yr,"us dollars (USD) per million btu"));
	energydata(sr,"p","oil",ed(sec),yr) = sum(secmap(sec,s), seds_units("PA",s,sr,yr,"us dollars (USD) per million btu"));
	energydata(sr,"p","col",ed(sec),yr) = sum(secmap(sec,s), seds_units("CL",s,sr,yr,"us dollars (USD) per million btu"));

* SHANE's CHANGES BEGIN
* Overwrite some of the oil prices for transportation
* We don't have to do a weighted average here because that happens later, I'm pretty sure
* Here's what that would look like just in case, though :shrug:
* energydata(sr,"p","oil","air",yr)$sum(source$air_sources(source),seds_units(source,"AC",sr,yr,"billion btu")) = (sum(source$air_sources(source),seds_units(source,"AC",sr,yr,"us dollars (USD) per million btu")) * sum(source$air_sources(source),seds_units(source,"AC",sr,yr,"billion btu"))) / sum(source$air_sources(source),seds_units(source,"AC",sr,yr,"billion btu"));
* energydata(sr,"p","oil","ground",yr) = (sum(source$ground_sources(source),seds_units(source,"AC",sr,yr,"us dollars (USD) per million btu")) * sum(source$ground_sources(source),seds_units(source,"AC",sr,yr,"billion btu"))) / sum(source$ground_sources(source),seds_units(source,"AC",sr,yr,"billion btu"));
* energydata(sr,"p","oil","water",yr) = seds_units("RF","AC",sr,yr,"us dollars (USD) per million btu");
* energydata(sr,"p","oil","ldv",yr) = seds_units("MG","AC",sr,yr,"us dollars (USD) per million btu");
	energydata(sr,"p","oil","air",yr) = (seds_units("AV","AC",sr,yr,"us dollars (USD) per million btu") + seds_units("JF","AC",sr,yr,"us dollars (USD) per million btu"))/2;
	energydata(sr,"p","oil","ground",yr) = (seds_units("DF","AC",sr,yr,"us dollars (USD) per million btu") + seds_units("HL","AC",sr,yr,"us dollars (USD) per million btu"))/2;
	energydata(sr,"p","oil","water",yr) = seds_units("RF","AC",sr,yr,"us dollars (USD) per million btu");
	energydata(sr,"p","oil","ldv",yr) = seds_units("MG","AC",sr,yr,"us dollars (USD) per million btu");

* grapes
* SHANE's CHANGES END

 	energydata(sr,"p","col","ele",yr)$seds_units("CL","EI",sr,yr,"billion btu") = seds_units("CL","EI",sr,yr,"millions of us dollars (USD)") / (seds_units("CL","EI",sr,yr,"billion btu") / 1000);

	energydata(sr,"p","gas","ele",yr)$seds_units("NG","EI",sr,yr,"billion btu") = seds_units("NG","EI",sr,yr,"millions of us dollars (USD)") / (seds_units("NG","EI",sr,yr,"billion btu") / 1000);

	energydata(sr,"p","oil","ele",yr)$seds_units("PA","EI",sr,yr,"billion btu") = seds_units("PA","EI",sr,yr,"millions of us dollars (USD)") / (seds_units("PA","EI",sr,yr,"billion btu") / 1000);


* Prices of electricity are millions of dollars per thousand kilowatt
* hours. Not quite. Millions of dollars divided by billions of kwh. So the
* price for electricity is dollars per thousand kwh as written below. If I
* keep these units, by multiplying by quantity, will end up with millions
* of dollars.

	energydata(sr,"p","ele",ed(sec),yr)$energydata(sr,"q","ele",ed,yr)
		 = sum(secmap(sec,s), seds_units("ES",s,sr,yr,"millions of us dollars (USD)")) / energydata(sr,"q","ele",ed,yr);

);

option energydata:3:3:1;
display energydata;

* Taken from https://www.eia.gov/environment/emissions/co2_vol_mass.cfm:

parameter	totals "BTU use totals";

* Scaling to billions of btus. Note that 1000kg = 1 metric tonne -->
* Totals below are denominated in metric tonnes.

totals(e,yr,"seds_btu") = sum((r,ed(sec)), energydata(r,"q",e,ed,yr)) / 1000;
totals(ed(sec),yr,"seds_btu") = sum((r,e), energydata(r,"q",e,ed,yr)) / 1000;

totals(e,yr,"seds_co2") = sum((r,ed(sec)), energydata(r,"q",e,ed,yr)) / 1000 * co2perbtu_units(e,"kilograms CO2 per million btu");
totals(ed(sec),yr,"seds_co2") = sum((r,e), energydata(r,"q",e,ed,yr) / 1000 * co2perbtu_units(e,"kilograms CO2 per million btu"));

* Only output data for 50 states + Distric of Columbia:

* Compare calculated emissions from SEDS with published CO2 emissionsn
* from EPA:

totals(co2dim,yr,"epa") = sum(r, emissions_units(co2dim,r,yr,"million metric tons of carbon dioxide"));

option totals:1:2:1;
display totals;

* Report other aggregate social and economic data in SEDS:

parameter	otherdata "Other SEDS data";

otherdata(sr,"rgdp",yr) = seds_units("GD","PR",sr,yr,"millions of chained (2012) us dollars (USD)") / 1000 + eps;
otherdata(sr,"gdp",yr) = seds_units("GD","PR",sr,yr,"millions of us dollars (USD)") / 1000 + eps;
otherdata(sr,"pop",yr) = seds_units("TP","OP",sr,yr,"thousand") + eps;

* Only output data from 1997-%year% in accordance with national Input Output
* tables for the United States.

parameter	sedsenergy(r,pq,e,ed_new,yr)	"SEDS energy data for IO integration",
		sedsother(r,*,yr)		"Other SEDS data",
		sedsco2compare(co2dim,yr,*)	"CO2 comparison between computed and EPA estimates",
		co2emis(r,yr,*,*,*)		"CO2 regional emissions by source";

alias (u,*);

*	Just converting names here to be a bit more explicit

* SHANE's CHANGES BEGIN - just swapping ed_new for ed
sedsenergy(r,pq,e,ed_new,yr) = energydata(r,pq,e,ed_new,yr);
sedsother(r,u,yr) = otherdata(r,u,yr);
sedsco2compare(co2dim,yr,u) = totals(co2dim,yr,u);
co2emis(r,yr,co2dim,"total","epa") = emissions_units(co2dim,r,yr,"million metric tons of carbon dioxide");
co2emis(r,yr,e,sec,"seds") = energydata(r,"q",e,sec,yr) / 1000 * co2perbtu_units(e,"kilograms CO2 per million btu");
co2emis(r,yr,e,"total","seds") = sum(sec, co2emis(r,yr,e,sec,'seds'));

*	Aggregate unloaded parameters to match regional aggregation

$INCLUDE %mapdir%%rmap%.map

alias(u,uu,uuu,*);

parameter
    sedsenergy_(rr,pq,e,ed_new,yr)		"SEDS energy data for IO integration",
    sedsother_(rr,*,yr)			"Other SEDS data",
    co2emis_(rr,yr,*,*,*)		"CO2 regional emissions by source",
    elegen_(rr,*,yr)			"Electricity generation by source (mill. btu or tkwh for ele)",
    seds_units_(source,sector_,rr,yr,*)	"Complete EIA SEDS data, with units as domain";

alias (yr,yrh);

*	Price data is aggregated using weighted average

sedsenergy_(rr,'q',e,ed_new,yrh) = sum(rmap(rr,r), sedsenergy(r,'q',e,ed_new,yrh));
sedsenergy_(rr,'p',e,ed_new,yrh)$sum(rmap(rr,r), sedsenergy(r,'q',e,ed_new,yrh)) =
    sum(rmap(rr,r), sedsenergy(r,'p',e,ed_new,yrh)*sedsenergy(r,'q',e,ed_new,yrh)) / sum(rmap(rr,r), sedsenergy(r,'q',e,ed_new,yrh));
* SHANE's CHANGEs END

* SHANE's CHANGES BEGIN
* splitting DFO between trk and train
sedsenergy_(rr,'q','oil','trk',yrh) = sedsenergy_(rr,'q','oil','ground',yrh) * ground_breakdown(rr,'trk');
sedsenergy_(rr,'q','oil','train',yrh) = sedsenergy_(rr,'q','oil','ground',yrh) * ground_breakdown(rr,'train');

* give some MG back to trk from ldv
sedsenergy_(rr,'q','oil','trk',yrh) = sedsenergy_(rr,'q','oil','trk',yrh) + (sedsenergy_(rr,'q','oil','ldv',yrh) * trans_breakdown(rr,'nonroad'));
sedsenergy_(rr,'q','oil','ldv',yrh) = sedsenergy_(rr,'q','oil','ldv',yrh) * trans_breakdown(rr,'road');

* update prices
sedsenergy_(rr,'p','oil','trk',yrh) = sedsenergy_(rr,'p','oil','ground',yrh);
sedsenergy_(rr,'p','oil','train',yrh) = sedsenergy_(rr,'p','oil','ground',yrh);
sedsenergy_(rr,'p','oil','ldv',yrh) = seds_units("MG","AC",rr,yrh,"us dollars (USD) per million btu");

* avoid double counting
sedsenergy_(rr,'q','oil','ground',yrh) = 0; 
sedsenergy_(rr,'p','oil','ground',yrh) = 0;
display sedsenergy_;

* seds_oil_demand -- will be passed to bluenote and used there
PARAMETER seds_oil_demand(yrh,rr,*,*);

seds_oil_demand(yrh,rr,"oil",ed_new) = (sedsenergy_(rr,"q", "oil",ed_new,yrh) * sedsenergy_(rr,"p","oil", ed_new,yrh)) / 1000;

* SHANE's CHANGES END

* rates need to be averaged in seds_units

set ru(*)   rates in seds_units /
            "us dollars (USD) per million btu"
	    "million btu per barrel"
	    "million btu per short ton"
	    "thousand btu per cubic foot"
	    "thousand btu per chained (2012) us dollars (USD)" /;
    
seds_units_(source,sector_,rr,yrh,u) = sum(rmap(rr,r), seds_units(source,sector_,r,yrh,u));
seds_units_(source,sector_,rr,yrh,ru) = sum(rmap(rr,r), seds_units(source,sector_,r,yrh,ru)) / sum(rmap(rr,r), 1);

* others are quantity based
sedsother_(rr,u,yrh) = sum(rmap(rr,r), sedsother(r,u,yrh));
co2emis_(rr,yrh,u,uu,uuu) = sum(rmap(rr,r), co2emis(r,yrh,u,uu,uuu));
elegen_(rr,src,yrh) = sum(rmap(rr,r), elegen(r,src,yrh));

execute_unload '%system.fp%gdx%sep%seds_%rmap%.gdx', sedsenergy_=sedsenergy, sedsother_=sedsother,
    sedsco2compare, co2emis_=co2emis, elegen_=elegen, seds_units_=seds_units,
	seds_oil_demand=seds_oil_demand,
    src, e, sec, co2dim;

*	Report the inputs to refinery fuels:

parameter refinputs "Inputs to Refinery Fuel (RF)";
refinputs("DF",rr,yrh) = sum(rmap(rr,r), seds_units("DF","RF",r,yrh,"billion btu"));
refinputs("HL",rr,yrh) = sum(rmap(rr,r), seds_units("HL","RF",r,yrh,"billion btu"));
refinputs("PC",rr,yrh) = sum(rmap(rr,r), seds_units("PC","RF",r,yrh,"billion btu"));
refinputs("RF",rr,yrh) = sum(rmap(rr,r), seds_units("RF","RF",r,yrh,"billion btu"));
refinputs("P5",rr,yrh) = sum(rmap(rr,r), seds_units("P5","RF",r,yrh,"billion btu"));

execute_unload '%system.fp%gdx%sep%refinputs_%rmap%.gdx',refinputs;
