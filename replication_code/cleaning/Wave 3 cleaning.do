***********************************************************************************
***********************************************************************************
* WAVE 3 CLEANING
***********************************************************************************

* Automating pull for latest dataset
global rawdata ///
	"$data/RCT wave 3/Raw/Wave 3 - High Freq 1_redownload with module randomizer info_August 26, 2022.xlsx"
global rawdata_limited ///
	"$data/RCT wave 3/Raw/Wave 3 - Limited Version_October 4, 2022_08.36.xlsx"
global missingids1 "$data/RCT wave 3/Data for survey embedding/Feb 2022 Limited Survey/Wave_3__Limited_Version-Distribution_History_AlNahda survey links_27Feb2022.csv"
global missing16 "$data/RCT wave 3/Raw/Wave 3 IDs for missing respondents_5Oct2022.xlsx"

*****************************************************************
* SECTION 1 - PULL IN DATA AND DROP OUT NON-SURVEYS
* SECTION 2 - MERGE IN DATA FROM WAVES 1 AND 2
* SECTION 3 - CLEANING
* SECTION 4 - GENERATE STATS ON MODULES STARTED AND COMPLETED
* SECTION 5 - INCORPORAT DATA FROM QUDRA LINK AND MERGE IN
* SECTION 6 - FINAL CLEAN UP AND LABELLING
*****************************************************************


*****************************************************************
* SECTION 1 - PULL IN DATA AND DROP OUT NON-SURVEYS
*****************************************************************

* pull in full main survey
import excel "$rawdata", firstrow allstring clear



foreach v of varlist * {
    local value = `v'[1]
	local vname = strtoname(`"`value'"')
    label var `v' `"`vname'"'
}

	* drop first two observations as they are labels
	drop if _n==1 | _n==2
	drop if Status=="Survey Preview" 
	*| Status == "Spam"
	destring ExternalReference, replace
	drop if ExternalReference==0
	
* tag these as long survey
gen short_survey = 0

save "$data/RCT wave 3/Raw/Wave 3 new wording survey - Raw.dta", replace

*********************************************************************************

* merge data from before we changed question wording (on gov acting fast enough)
import excel "$data/RCT wave 3/Raw/Wave 3 - High Freq 1_pre wording change for govt progress.xlsx", ///
firstrow allstring clear

drop if _n==1 | _n==2
drop if Status=="Survey Preview" 
*| Status == "Spam"
destring ExternalReference, replace
drop if ExternalReference==0

keep ExternalReference P1_1 ResponseId
rename P1_1 OLD_P1_1

*  fix spacing issue 

	replace OLD_P1_1 = "Completely disagree" if OLD_P1_1 == "Completely disagree "
	replace OLD_P1_1 = "Neither disagree nor agree" if OLD_P1_1 == "Neither disagree nor agree " ///
		| OLD_P1_1 == "Neither agree nor disagree" | OLD_P1_1 == "Neither agree nor disagree "
	replace OLD_P1_1 = "Somewhat agree" if OLD_P1_1 == "Somewhat agree "
	lab var OLD_P1_1 "Old version of 'gov working fast enough' qn"
				
* Generate numeric likert vars (1-completely disagree -> 5-completely agree)

	gen OLD_P1_1_likert = .
	replace OLD_P1_1_likert = 1 if OLD_P1_1 == "Completely disagree"
	replace OLD_P1_1_likert = 2 if OLD_P1_1 == "Somewhat disagree"
	replace OLD_P1_1_likert = 3 if OLD_P1_1 == "Neither disagree nor agree" ///
	| OLD_P1_1 == "Neither agree nor disagree"
	replace OLD_P1_1_likert = 4 if OLD_P1_1 == "Somewhat agree"
	replace OLD_P1_1_likert = 5 if OLD_P1_1 == "Completely agree"
	label var OLD_P1_1_likert "Old version of 'gov working fast enough' qn - in likert scale"

	gen question_timing = 0
	lab var question_timing "Original question wording for P1"
	
* merge into our latest data
merge 1:1 ExternalReference ResponseId using ///
"$data/RCT wave 3/Raw/Wave 3 new wording survey - Raw.dta"
drop _merge

save "$data/RCT wave 3/Raw/Wave 3 full survey - Raw.dta", replace
 
*********************************************************************************

* pull in IDs from the 16 respondents that were dropped in wave 2 
import excel "$missing16", firstrow allstring clear
rename participantid ID

save "$data/RCT wave 3/Raw/Wave 3 IDs for missing respondents_5Oct2022.dta", replace

* pull in limited survey (new as of Oct 2022) to append to full main survey
import excel "$rawdata_limited", firstrow allstring clear

foreach v of varlist * {
    local value = `v'[1]
	local vname = strtoname(`"`value'"')
    label var `v' `"`vname'"'
}

* drop out var label obs and test cases
drop if _n==1 | _n==2
drop if Status=="Survey Preview" 
*| Status == "Spam"

* pull respondent ID from "email" list
drop ExternalReference 
gen ExternalReference = substr(RecipientEmail, 1, length(RecipientEmail) - 8)

* give filler ID to missing IDs
replace ExternalReference= "9" if RecipientEmail=="1@23.com"

* merge in the 16 missing IDs
merge 1:1 StartDate EndDate Durationinseconds using ///
"$data/RCT wave 3/Raw/Wave 3 IDs for missing respondents_5Oct2022.dta"
drop _merge

replace ExternalReference = ID if ID!=""
* test link was ".@123.com" - drop any of those
drop if ExternalReference=="."

***************************** TO SOLVE ******************************************
* NOTE: we have a couple cases where an anonymous link was used, and not matched to an ID, drop
drop if ExternalReference==""

/* NOTE: 'ideal age to have first child' format is wonky (perhaps from Arabic keyboard?) - 
will have to drop weird responses */
tab G13_7_TEXT
*drop if strlen(G13_7_TEXT) > 3

*********************************************************************************

destring ExternalReference, replace 


* we changed the format of  Q133 to work with phone browser - rename to avoid confusion
rename Q133 Q133_new
lab var Q133_new "Q133 reformatted for limited survey - society change pace"

* tag these observations
gen short_survey = 1

append using "$data/RCT wave 3/Raw/Wave 3 full survey - Raw.dta"


* save new raw dataset
save "$data/RCT wave 3/Raw/Wave 3 - combined full and lim survey.dta", replace



************
* MERGE IN MISSING IDS FROM LIST OF SURVEY LINKS

import delimited "$missingids1", clear 

rename link Q_URL
keep responseid Q_URL
merge 1:m Q_URL using "$data/RCT wave 3/Raw/Wave 3 - combined full and lim survey.dta"
drop if _merge==1
drop _merge

replace ExternalReference=responseid if ExternalReference==9

************

*see if any observations started before official start date (6/1/2021)
gen startmo = substr(StartDate, 1,6)
tab startmo

* Resolve duplicate IDs by taking the most recent value for each observation
generate double EndDate2 = clock(EndDate, "MDYhm")
format EndDate2 %tc
lab var EndDate2 "EndDate as date and time var"


sort ExternalReference EndDate2 Durationinseconds		// Aug2,2023 update: added Durationinseconds as an additional sort var because it gives a unique sort 
collapse (lastnm) responseid-FL_37_DO short_survey-EndDate2, by(ExternalReference)


* Add time trend for question wording for new wording
replace question_timing=1 if question_timing==.

* Flag observations that we know are completed surveys
gen start_survey_w3 = 1
replace start_survey_w3 = 0 if C2!="Yes"
replace start_survey_w3 = 1  if M1!="" | E1!="" | G1_1!="" | R1!=""		// old version used M4_1_TEXT!=""
lab var start_survey_w3 "Started wave 3 survey"

* we have one blank observation that got left in
drop if ExternalReference==.



* update naming of participantid from survey
destring participantid, replace 

rename participantid pid_verified 
	lab var pid_verified "Participant ID from embedded data"
	destring pid_verified, replace
	
	rename ExternalReference participantid 
	lab var participantid "Participant ID"

* Save so we can merge in waves 1 and 2
save "$data/RCT wave 3/Cleaned/Wave3_combinedrawdata.dta", replace

*****************************************************************
* SECTION 2 - MERGE IN DATA FROM WAVES 1 AND 2
*****************************************************************

 use "$data/RCT wave 2/Final/Combined_waves1and2_final.dta", clear
 
	* let's remove observations that have been excluded from the sample (sample = 606)
	drop if Excluded==1
	
	* there is also a blank observation - drop this
	drop if participantid==.
	
	
	* Merge into wave 3 data
	merge 1:1 participantid using "$data/RCT wave 3/Cleaned/Wave3_combinedrawdata.dta"
	
	* some Excluded participants got called in this survey, let's drop them
	drop if _merge==2
	drop _merge
	
	lab var participantid "Participant ID"
	
	* let's save this combined dataset
	save "$data/RCT wave 3/Cleaned/Wave3raw_mergedwaves1and2.dta", replace


*****************************************************************
* SECTION 3 - DATA CLEANING
*****************************************************************

	* create treatment var
	gen treatment = 0 if inlist(treat,0,2)
	replace treatment = 1 if inlist(treat,1,3)
	lab var treatment "Treatment"

	

***************************************
* GENDER ATTITUDES
***************************************

	* labelling
	lab var  G1_1 "GA 1st: OK to put own needs above those of family - likert (wave 3)"
	lab var G1_2 "GA 1st: Doesn't need permission to meet a friend outside home - likert (wave 3)"
	lab var G1_3 "GA 1st: Doesn't need permission to make a purchase - likert (wave 3)"
	lab var G5_1 "GA 1st: Men make better business execs than women - likert (wave 3)"
	lab var G6_1 "GA 2nd - male fam: Men make better business execs than women - likert (wave 3)"
	lab var G6_2 "GA 2nd - fem net: Men make better business execs than women - likert (wave 3)"
	lab var G6_3 "GA 2nd - male net: Men make better business execs than women - likert (wave 3)"
	lab var G7_1 "GA 1st: woman's priority should be home - likert (wave 3)"
	lab var G8_1 "GA 2nd - male fam: woman's priority should be home - likert (wave 3)"
	lab var G8_2 "GA 2nd - fem net: woman's priority should be home - likert (wave 3)"
	lab var G8_3 "GA 2nd - male net: woman's priority should be home - likert (wave 3)"
	lab var G9_1 "GA 1st: when mother works, children suffer - likert (wave 3)"
	lab var G10_1 "GA 2nd - male fam: when mother works, children suffer - likert (wave 3)"
	lab var G10_2 "GA 2nd - fem net: when mother works, children suffer - likert (wave 3)"
	lab var G10_3 "GA 2nd - male net: when mother works, children suffer - likert (wave 3)"
	lab var G13_7_TEXT "Ideal age to have first child (wave 3)"
	lab var Q133_new "wording update: pave of change is fast enough to give women same rights and doesn't need to be faster (wave 3)"
	lab var Q134 "Prefer gender reforms to move slower (wave 3)" 
	lab var P3 "Voting in the next municipal election (wave 3)" 
	lab var question_timing "Original question wording for P1"
	lab var G3_1 "GA 1st: Education is more important for a boy than a girl - likert (wave 3)"
	lab var G4_1 "GA 2nd - male fam: Education is more important for a boy than a girl - likert (wave 3)"
	lab var G4_2 "GA 2nd - fem net: Education is more important for a boy than a girl - likert (wave 3)"
	lab var G4_3 "GA 2nd - male net: Education is more important for a boy than a girl - likert (wave 3)"
	lab var G11 "Desired edu for hypothetical daughter/granddaughter (wave 3)"
	lab var G12 "Desire for hypothetical daughter/granddaughter to work (wave 3)"
	lab var G14 "Groups belong to (wave 3)"
	lab var G15 "Number of times in past month attended meetings of groups belonging to (wave 3)"
	lab var P1_1 "Government/society is moving fast enough to make women'ss rights same as men's (wave 3)"
	


* rename P1_1 and P2_2 to match var names from before we changed the question
	rename P1_2 P1_3
	lab var P1_3 "Gov should allow a women's soccer team - likert (wave 3)"
	rename P1_1 P1_2
	lab var P1_2 "Feels impact of changes gov is making to give women same rights as men - likert (wave 3)"

	
* Now update Q133 to match P1_1 from orig version (before we changed the wording of that question)
rename Q133_1 P1_1

gen P1_1_likert = 1 if P1_1=="5"
replace P1_1_likert = 2 if P1_1=="4"
replace P1_1_likert = 3 if P1_1=="3"
replace P1_1_likert = 4 if P1_1=="2"
replace P1_1_likert = 5 if P1_1=="1"
lab var P1_1_likert "society moving fast enough to give equal rights to women (disagree...agree) (wave 3)"

*** NEW ADDITION WITH LIMITED SURVEY ***
* incorporate new revision that occured with limited survey

gen P_1_1_limited = 1 if Q133_new=="Completely agree with Statement B"
replace P_1_1_limited = 2 if Q133_new=="Mostly agree with Statement B"
replace P_1_1_limited = 3 if Q133_new=="Neutral between Statement A and Statement B"
replace P_1_1_limited = 4 if Q133_new=="Mostly agree with Statement A"
replace P_1_1_limited = 5 if Q133_new=="Completely agree with Statement A"
lab var P_1_1_limited "Pace of society change - limited survey version (wave 3)"

* Now let's merge the old version of the question with the new version
gen Combined_P1_1_likert = P1_1_likert
replace Combined_P1_1_likert = OLD_P1_1_likert if P1_1_likert==. & OLD_P1_1_likert!=.
replace Combined_P1_1_likert = P_1_1_limited if P1_1_likert==. & P_1_1_limited!=.
lab var Combined_P1_1_likert "Combined old and new versions of 'society moving fast enough' qn (wave 3)"


	* first fix spacing issue 
	
	global text_fix G1_1 G1_2 G1_3  P1_2 P1_3
	
	foreach var of global text_fix {
		replace `var' = "Completely disagree" if `var' == "Completely disagree "
		replace `var' = "Neither disagree nor agree" if `var' == "Neither disagree nor agree " | `var' == "Neither agree nor disagree" | `var' == "Neither agree nor disagree "
		replace `var' = "Somewhat agree" if `var' == "Somewhat agree "
		}
				
	* Generate numeric likert vars (1-completely disagree -> 5-completely agree)
	
	global likert_GA G1_1 G1_2 G1_3 P1_2 P1_3
	
	foreach var of global likert_GA {
		gen `var'_likert = .
		replace `var'_likert = 1 if `var' == "Completely disagree"
		replace `var'_likert = 2 if `var' == "Somewhat disagree"
		replace `var'_likert = 3 if `var' == "Neither disagree nor agree" | `var' == "Neither agree nor disagree"
		replace `var'_likert = 4 if `var' == "Somewhat agree"
		replace `var'_likert = 5 if `var' == "Completely agree"
		label var `var'_likert "`var' in likert scale (wave 3)"
		
		xtile `var'_abovemed = `var'_likert, nq(2)
		recode `var'_abovemed (1 = 0) (2 = 1)
		lab var `var'_abovemed "`var' - binary at median (wave 3)"
		
		* for binaries
		sum `var'_abovemed if treatment==0 
		gen `var'_abovemed_st = . 
		replace `var'_abovemed_st = (`var'_abovemed-r(mean))/r(sd)
		lab var `var'_abovemed_st "`var' - centered/standardized binary at median (wave 3)"
		
		* for likert version
		sum `var'_likert if treatment==0 
		gen `var'_likert_st = .
		replace `var'_likert_st = (`var'_likert - r(mean))/r(sd)
		lab var `var'_likert_st "`var' - center/standardized likert (wave 3)"

	}
	
	* Now add Combined_P1_1_likert
	xtile P1_1_abovemed = Combined_P1_1_likert, nq(2)
		recode P1_1_abovemed (1 = 0) (2 = 1)
		lab var P1_1_abovemed "society moving fast enough - binary at median (wave 3)"
		
		* for binary
		sum P1_1_abovemed if treatment==0 
		gen P1_1_abovemed_st = .
		replace P1_1_abovemed_st = (P1_1_abovemed-r(mean))/r(sd)
		lab var P1_1_abovemed_st "society moving fast enough - centered/standardized binary at median (wave 3)"
		
		* for likert version
		sum Combined_P1_1_likert if treatment==0 
		gen Combined_P1_1_likert_st = .
		replace Combined_P1_1_likert_st = (Combined_P1_1_likert - r(mean))/r(sd)
		lab var Combined_P1_1_likert_st "Combined_P1_1 - center/standardized likert (wave 3)"
	
		
	
	/* Anomalies: some binaries end up with just one value because too much gets 
		placed on one end of the likert scale - let's manually adjust these */
			
		* P1_1	
		drop P1_1_abovemed P1_1_abovemed_st
		sum Combined_P1_1_likert, detail
		scalar med = r(p50)
		gen P1_1_abovemed = 1 if Combined_P1_1_likert>=med & Combined_P1_1_likert!=.
		replace P1_1_abovemed = 0 if Combined_P1_1_likert<med & Combined_P1_1_likert!=.
		lab var P1_1_abovemed "society moving fast enough - binary at mean (wave 3)"
		
		sum P1_1_abovemed if treatment==0 
		gen P1_1_abovemed_st =.
		replace P1_1_abovemed_st = (P1_1_abovemed-r(mean))/r(sd)
		lab var P1_1_abovemed_st "society moving fast enough - centered/standardized binary at mean (wave 3)"
		
				
		* P1_2
		drop P1_2_abovemed P1_2_abovemed_st
		sum P1_2_likert, detail
		scalar med = r(p50)
		gen P1_2_abovemed = 1 if P1_2_likert>=med & P1_2_likert!=.
		replace P1_2_abovemed = 0 if P1_2_likert<med & P1_2_likert!=.
		lab var P1_2_abovemed "Feels impact of changes gov is making - binary at mean (wave 3)"
		
		sum P1_2_abovemed if treatment==0 
		gen P1_2_abovemed_st =.
		replace P1_2_abovemed_st = (P1_2_abovemed-r(mean))/r(sd)
		lab var P1_2_abovemed_st "Feels impact of changes gov is making-centered/standardized binary at mean (wave 3)"
			
	* Preference for even slower gender reforms (Q134)
	gen slower_reforms_Q134 = 1 if Q134=="Yes, I would like these social changes to move slower"
	replace slower_reforms_Q134 = 0 if Q134=="No, I do not want these social changes to move any slower"
	lab val slower_reforms_Q134 yesno
	lab var slower_reforms_Q134 "Would you prefer even slower gender reforms? (wave 3)"
	
	
	* Generate numeric likert vars that are reversed for consistency (1-completely agree -> 5-completely disagree) 
	global likert_reverse_GA G7_1 G9_1 G3_1 G5_1
	
	foreach var of global likert_reverse_GA {
		gen `var'_likert_reverse = .
		replace `var'_likert_reverse = 5 if `var' == "Completely disagree"
		replace `var'_likert_reverse = 4 if `var' == "Somewhat disagree"
		replace `var'_likert_reverse = 3 if `var' == "Neither disagree nor agree" ///
		| `var' == "Neither agree nor disagree"
		replace `var'_likert_reverse = 2 if `var' == "Somewhat agree"
		replace `var'_likert_reverse = 1 if `var' == "Completely agree"
		label var `var'_likert_reverse "`var' in reversed likert scale (wave 3)"	
		
		xtile `var'_abovemed = `var'_likert_reverse, nq(2)
		recode `var'_abovemed (1 = 0) (2 = 1)
		lab var `var'_abovemed "`var' - binary at median (wave 3)"
		
		* for binaries
		sum `var'_abovemed if treatment==0 
		gen `var'_abovemed_st = .
		replace `var'_abovemed_st = (`var'_abovemed-r(mean))/r(sd)
		lab var `var'_abovemed_st "`var' - centered/standardized binary at median (wave 3)"
		
		* for likert version
		sum `var'_likert_reverse if treatment==0 
		gen `var'_likert_reverse_st = .
		replace `var'_likert_reverse_st = (`var'_likert_reverse - r(mean))/r(sd)
		lab var `var'_likert_reverse_st "`var' - center/standardized likert (wave 3)"
		
	}

*XTILE FOR G3_1 RETURNS SINGLE-VAL VARIABLE, RECREATE THAT VAR
		drop G3_1_abovemed G3_1_abovemed_st 
		
		
		sum G3_1_likert_reverse, detail
		scalar med = r(p50)
		gen G3_1_abovemed = 1 if G3_1_likert_reverse>=med & G3_1_likert_reverse!=.
		replace G3_1_abovemed = 0 if G3_1_likert_reverse<med & G3_1_likert_reverse!=.
		lab var G3_1_abovemed "G3 - binary at median (created using mean) (wave 3)"
		
		sum G3_1_abovemed if treatment==0 
		gen G3_1_abovemed_st =.
		replace G3_1_abovemed_st = (G3_1_abovemed-r(mean))/r(sd)
		lab var G3_1_abovemed_st "G3 - centered/standardized binary at median (created using mean) (wave 3)"

		
		* Voting
	
	gen P3_scale = .
	replace P3_scale = 1 if inlist(P3, "Definitely no", "I do not know how to vote", ///
		"I do not know about any elections")
	replace P3_scale = 2 if P3 == "Probably no"
	replace P3_scale = 3 if P3 == "Unsure"
	replace P3_scale = 4 if P3 == "Probably yes"
	replace P3_scale = 5 if P3 == "Definitely yes"
	label var P3_scale "Voting in the next election, numeric scale for likert (wave 3)"
	
		* center/standardize for index
		sum P3_scale if treatment==0 
		gen P3_scale_st = .
		replace P3_scale_st = (P3_scale-r(mean))/r(sd)
		lab var P3_scale_st "P3 (Will vote) - centered/standardized binary at median (wave 3)"

	* Generate vars for proportion of male family/women in community/men in community/men
	
	global proportions_GA G4_1 G4_2 G4_3 G6_1 G6_2 G6_3 G8_1 G8_2 G8_3 G10_1 G10_2 G10_3
	
	foreach var of global proportions_GA {
		gen `var'_propor = .
		replace `var'_propor = 1 if `var' == "All of them"
		replace `var'_propor = 2 if `var' == "A majority"
		replace `var'_propor = 3 if `var' == "About half"
		replace `var'_propor = 4 if `var' == "A minority"
		replace `var'_propor = 5 if `var' == "None of them"
		label var `var'_propor "`var' in reversed numeric categories (wave 3)"
		
		*for binaries
		xtile `var'_abovemed = `var'_propor, nq(2)
		recode `var'_abovemed (1 = 0) (2 = 1)
		lab var `var'_abovemed "`var' - binary at median (wave 3)"
		
		sum `var'_abovemed if treatment==0 
		gen `var'_abovemed_st = .
		replace `var'_abovemed_st = (`var'_abovemed-r(mean))/r(sd)
		lab var `var'_abovemed_st "`var' - centered/standardized binary at median (wave 3)"
		
		* for likert version
		sum `var'_propor if treatment==0
		gen `var'_propor_st = .
		replace `var'_propor_st = (`var'_propor-r(mean))/r(sd)
		lab var `var'_propor_st "`var' - center/standardized likert (wave 3)"
	}

* XTILE RETURNS SINGLE VAL VAR FOR G4_1 and G4_2, LET'S RECREATE THIS VAR

		drop G4_1_abovemed G4_1_abovemed_st G4_2_abovemed G4_2_abovemed_st 
		
		foreach var of varlist G4_1 G4_2 {
		sum `var'_propor, detail
		scalar med = r(p50)
		gen `var'_abovemed = 1 if `var'_propor>=med & `var'_propor!=.
		replace `var'_abovemed = 0 if `var'_propor<med & `var'_propor!=. 
		lab var `var'_abovemed "`var' - binary at median (created manually)"
		
		sum `var'_abovemed if treatment==0 
		gen `var'_abovemed_st =.
		replace `var'_abovemed_st = (`var'_abovemed-r(mean))/r(sd)
		lab var `var'_abovemed_st "`var' - centered/standardized binary at median (created manually) (wave 3)"	
		}
			



* Now generate numeric scales for the odd vars:
			
	* Level of desired edu for daughter/granddaughter

			gen G11_scale = .
			replace G11_scale = 1 if G11 == "Complete high school "
			replace G11_scale = 2 if G11 == "Complete diploma"
			replace G11_scale = 3 if G11 == "Complete vocational training"
			replace G11_scale = 4 if G11 == "Complete a university degree"
			replace G11_scale = 5 if G11 == "Complete a degree beyond university (graduate/professional)"
			label var G11_scale "Desired edu level for daughter/granddaughter (wave 3)"
		

	* Desire for daughter/granddaughter to work - likert

			gen G12_scale = .
			replace G12_scale = 1 if G12 == "Definitely no"
			replace G12_scale = 2 if G12 == "Probably no"
			replace G12_scale = 3 if G12 == "Not sure"
			replace G12_scale = 4 if G12 == "Probably yes"
			replace G12_scale = 5 if G12 == "Definitely yes"
			label var G12_scale "Desire for hypothetical daughter/granddaughter to work - numeric scale (wave 3)"
							
	* Ideal age for a woman to have her first child

		* fix typing error
		replace G13_7_TEXT="20" if G13_7_TEXT=="20 ŸÅŸÖÿß ŸÅŸàŸÇ"
		destring G13_7_TEXT, gen(G13_scale)
		lab var G13_scale "Ideal age to have 1st child (wave 3)"
		
		* this one doesn't need a binary created, so we just center/standardize it
		sum G13_scale if treatment==0 
		gen G13_scale_st = .
		replace G13_scale_st = (G13_scale-r(mean))/r(sd)
		lab var G13_scale_st "G13 - centered/standardized (wave 3)"
		

	* Agreement with statement A vs statement B
		
		global statements P2_1 P2_2 P2_3 P2_4
		
		foreach var of global statements {
			gen `var'_scale = .
			replace `var'_scale = 1 if `var' == "8"
			replace `var'_scale = 2 if `var' == "7"
			replace `var'_scale = 3 if `var' == "6"
			replace `var'_scale = 4 if `var' == "5"
			replace `var'_scale = 5 if `var' == "1"
			label var `var'_scale "`var' - numeric scale (wave 3)"
		}

		
		* Create binaries at the median for these odd vars and center/standardized

		global other_GA G11 G12 P2_1 P2_2 P2_3 P2_4 P3

		foreach var of global other_GA {
			xtile `var'_abovemed = `var'_scale , nq(2)
			recode `var'_abovemed (1 = 0) (2 = 1)
			lab var `var'_abovemed "`var' - binary at median (wave 3)"

			sum `var'_abovemed if treatment==0 
			gen `var'_abovemed_st = .
			replace `var'_abovemed_st = (`var'_abovemed-r(mean))/r(sd)
			lab var `var'_abovemed_st "`var' - centered/standardized binary at median (wave 3)"
			}
			
* xtile creates single val var for P2_2, G11 and G12, fix
		drop P2_2_abovemed P2_2_abovemed_st G11_abovemed G11_abovemed_st ///
			G12_abovemed G12_abovemed_st 
		
		global median_fix P2_2 G11 G12
		
		foreach var of global median_fix {
		sum `var'_scale, detail
		scalar med = r(p50)
		gen `var'_abovemed = 1 if `var'_scale>=med & `var'_scale!=.
		replace `var'_abovemed = 0 if `var'_scale<med & `var'_scale!=.
		lab var `var'_abovemed "`var' - binary at median (created using mean)"
		
		sum `var'_abovemed if treatment==0 
		gen `var'_abovemed_st =.
		replace `var'_abovemed_st = (`var'_abovemed-r(mean))/r(sd)
		lab var `var'_abovemed_st "`var' - centered/standardized binary at median (created using mean)"
		}

	lab def likert 1 "Completely disagree" 2 "Somewhat disagree" 3 "Neither agree nor disagree" ///
	4 "Somewhat agree" 5 "Completely agree"
	
	lab def likert_reverse 5 "Completely disagree" 4 "Somewhat disagree" 3 "Neither agree nor disagree" ///
	2 "Somewhat agree" 1 "Completely agree"
	
	lab val G1_1_likert G1_2_likert G1_3_likert Combined_P1_1_likert P1_2_likert P1_3_likert likert
	lab val G3_1_likert_reverse G7_1_likert_reverse G9_1_likert_reverse  G5_1_likert_reverse likert_reverse
	
	* age for 1st child
	replace G13_7_TEXT="20" if G13_7_TEXT== "20 ŸÅŸÖÿß ŸÅŸàŸÇ"
	destring G13_7_TEXT, replace
	*histogram G13_7_TEXT, percent
	
	 * relabel for Statement A/B and run plots
	lab def statements 1 "Completely agree with B" 2 "Mostly agree with B" ///
	3 "Neutral" 4 "Mostly agree with A" 5 "Completely agree with A"
	lab val P2_1_scale P2_2_scale P2_3_scale P2_4_scale statements
	

********************************
* DRIVE TRAINING AND LICENSE
********************************
	
	* create our drive training variable
	 gen saudi_drive_training = 1 if M1 == "No"  ///
	 | M1=="" & sauditraining == "No_ Please explain:"
	 replace saudi_drive_training = 2 if M1 == "No, trained outside of driving school" 
	 replace saudi_drive_training = 3 if M1 == "Yes but failed the theoretical test" ///
		| M1 == "Yes but failed the practical test" ///
		| M1=="Yes but stopped the training for other reasons. Please explain:" 
	 replace saudi_drive_training = 3 if M1=="" & ///
		sauditraining=="Yes but failed the practical test"
	 replace saudi_drive_training = 3 if M1=="" & ///
		sauditraining=="Yes but failed the theoretical test"
	 replace saudi_drive_training=3 if M1=="" & ///
		sauditraining=="Yes but stopped the training for other reasons. Please explain:"
	 replace saudi_drive_training = 4 if M1 == "Yes and completed successfully"
	 replace saudi_drive_training = 4 if M1=="" & ///
		sauditraining=="Yes and completed successfully"
		
		* replace missing values with responses from wave 2 only if they started wave 3 survey
		* No
		replace saudi_drive_training = 1 if saudidrivetraining_w2==0 & ///
		 saudi_drive_training==. & start_survey_w3==1
		* Yes but failed test
		replace saudi_drive_training = 3 if saudidrivetraining_w2==2 & ///
		inlist(saudi_drive_training, ., 1,2) & start_survey_w3==1
		* Yes and completed
		replace saudi_drive_training = 4 if saudidrivetraining_w2==1 & start_survey_w3==1
		lab var saudi_drive_training "Have you done the official Saudi drive training? (wave 3)"
		
		 * label 
		 lab def drivetrain 1 "No" 2 "Trained outside of the school" 3 "Yes but failed or stopped" ///
		 4 "Yes and completed successfully"
		 lab val saudi_drive_training drivetrain
		 lab var saudi_drive_training "Have you done the official Saudi drive training? (wave 3)"
		 
		 * create binary version
		gen s_train_bi_w3 = 1 if inlist(saudi_drive_training, 3, 4)
		replace s_train_bi_w3 = 0 if inlist(saudi_drive_training, 1,2)
		lab var s_train_bi_w3 "Did any official drive training (wave 3)"
	 

	* received license
	 gen license_w3 = 1 if M2=="Yes" &  start_survey==1
	 replace license_w3 = 1 if  drivinglicense=="Yes" &  start_survey==1
	 replace license_w3 = 0 if M2=="No" & license_w3==. &  start_survey==1
	 replace license_w3 = 0 if  drivinglicense=="No" & license_w3==. &  start_survey==1
	 
		* replace missing values with responses from wave 2 only if they started wave 3 survey
		 replace license_w3 = 1 if license_w2==1 & start_survey_w3==1
		 replace license_w3 = 0 if license_w2==0 & license_w3==. & start_survey_w3==1
		 lab var license_w3 "Has received license (wave 3)" 
		 
		 * label
		  lab def binary 0 "No" 1 "Yes"
		 lab val license_w3 binary
		 lab var license_w3 "Has received license (wave 3)"
		
		* create binary version
		gen s_train_complete = 1 if saudi_drive_training==4
		replace s_train_complete = 0 if inrange(saudi_drive_training, 1,3)
		lab var s_train_complete "Successfully completed the drive training (wave 3)"
		

		/* let's also make sure we relabel vars we don't want to use for analysis;
		   will drop these out for the final dataset 	*/
		 lab var M2 "OLD - did you receive the driving license"
		 lab var drivinglicense "OLD - wave 1&2 received license"
		 lab var license_w2 "Received license (wave 2)"
		 lab var saudidrivetraining_w2 "OLD - did the saudi driving training"
		 lab var sauditraining "W3 ONLY - did the saudi driving training"
	 
********************************
* MOBILITY
********************************

	destring M4_1_TEXT M5_1_TEXT M6_1_TEXT M7_1_TEXT M8_1_TEXT M9_2_TEXT, replace
	
	* Labeling
	lab var M3 "Number of times driven in last month (wave 3)"
	lab var M4_1_TEXT "Number of times left house in last 7 days (wave 3)"
	lab var M9_2_TEXT "Number of trips in last 7 days not accompanied by a mahrem (wave 3)"
	lab var M5_1_TEXT "Number of times left house in last 7 days: visit relatives (wave 3)"
	lab var M6_1_TEXT "Number of times left house in last 7 days: visit friends (wave 3)"
	lab var M7_1_TEXT "Number of times left house in last 7 days: HH errands (wave 3)"
	lab var M8_1_TEXT "Number of times left house in last 7 days: personal errands (wave 3)"
	lab var Q132_2_TEXT "Number of trips in last 7 days made alone (wave 3)"
	lab var M10 "Types of trips made without being accompanied by a family member (wave 3)"

	
	* Driving frequency in past month
	gen drive_freq_mo_cat_w3 = 0 if M3=="None" 
	replace drive_freq_mo_cat_w3 = 1 if M3=="Less than once a week" 
	replace drive_freq_mo_cat_w3 = 2 if M3=="About once a week" 
	replace drive_freq_mo_cat_w3 = 3 if M3=="A few times a week" 
	replace drive_freq_mo_cat_w3 = 4 if M3=="Almost every day" 
	lab var drive_freq_mo_cat_w3 "Driving freq in past month (wave 3)"


	/* Let's adjust travel type freq if they said they never went out (currently is 
	missing obs. for each travel type if they said they never left the house in 
	past week)	*/
	destring Q132_2_TEXT, replace

	global travel_types M5_1_TEXT M6_1_TEXT M7_1_TEXT M8_1_TEXT M9_2_TEXT ///
	Q132_2_TEXT 
	
	foreach var of global travel_types {
		replace `var' = 0 if M4_1_TEXT == 0 
	}
	
	* Now replace M9_2_TEXT with 0 if they selected 'none' in M9 or if they didn't go out
	replace M9_2_TEXT = 0 if M9=="None (all of my trips were accompanied by a mahrem)"

	
	* trips alone 
	replace Q132_2_TEXT = 0 if Q132== ///
	"None (all of my trips were made with at least one other person)"
		

	* trips without a mahrem / alone
	gen trips_unaccompanied_w3 = M9_2_TEXT
	replace trips_unaccompanied_w3 = 0 if strpos(M9,"None")
	replace trips_unaccompanied_w3 = Q132_2_TEXT if trips_unaccompanied_w3==.
	lab var trips_unaccompanied_w3 "Number of trips made without a chaperone (wave 3)"
	
	* trips without a mahrem / alone as a share of total trips
	gen share_trips_unaccomp_w3 = trips_unaccompanied_w3/M4_1_TEXT if trips_unaccompanied_w3!=.
	replace share_trips_unaccomp_w3 = 0 if trips_unaccompanied_w3==0
	lab var share_trips_unaccomp_w3 "Share of trips unaccompanied (wave 3)"
	
	* no trips without a chaperone
	gen no_trips_unaccomp_w3 = 1 if trips_unaccompanied_w3==0
	replace no_trips_unaccomp_w3 = 0 if trips_unaccompanied_w3>0 & trips_unaccompanied_w3!=.
	lab var no_trips_unaccomp_w3 "No trips made without a chaperone (wave 3)"
	
	
	* create estimate of # times per month
		gen drive_freq_mo_w3 = 0 if M3=="None" 
		replace drive_freq_mo_w3 = 2 if M3=="Less than once a week" 
		replace drive_freq_mo_w3 = 4 if M3=="About once a week" 
		replace drive_freq_mo_w3 = 12 if M3=="A few times a week" 
		replace drive_freq_mo_w3 = 28 if M3=="Almost every day" 
		lab var drive_freq_mo_w3 "Driving freq in past month - approx. # (wave 3)"
	

	
	* Any driving in past month
		gen  drive_any_mo_bi_w3 = 0 if M3=="None" 
		replace drive_any_mo_bi_w3 = 1 if inlist(M3,"Less than once a week", ///
		"About once a week", "A few times a week", "Almost every day") 
		lab var drive_any_mo_bi_w3 "Any driving in prev month (wave 3)"
	

	
	/* avg trips per day. Let's take the following steps:
			divide total trips made last week by 7	*/
		gen approx_trips_per_day_w3 = M4_1_TEXT/7 if M4_1_TEXT!=. 
		replace approx_trips_per_day_w3 = round(approx_trips_per_day_w3)
		lab var approx_trips_per_day_w3 "Avg no. trips per day (wave 3)"
		

				
		
	/* any travel made without family member. To do this let's:
			create var for any travel in last week without family/mahrem */
		gen  unaccompanied_travel_w3 = 0 if M9_2_TEXT==0 
		replace unaccompanied_travel_w3 = 0 if M4_1_TEXT == 0 
		replace unaccompanied_travel_w3 = 0 if (M9_2_TEXT==. & Q132_2_TEXT==0) 
		replace unaccompanied_travel_w3 = 1 if M9_2_TEXT>0 & M9_2_TEXT!=. 
		replace unaccompanied_travel_w3 = 1 if Q132_2_TEXT>0 & Q132_2_TEXT!=. 
		lab var unaccompanied_travel_w3 "Travel in past week without family/mahrem (wave 3)"
		
	
				
		
	/* any trip in last week to visit family:
			any trip in past week	*/
		gen trip_family_w3 = 0 if M5_1_TEXT==0 
		replace trip_family_w3 = 0 if  M4_1_TEXT==0 
		replace trip_family_w3 = 1 if (M5_1_TEXT>0 & M5_1_TEXT!=.) 
		lab var trip_family_w3 "Any trip to visit family in past 1 week (wave 3)"
		

		* number of visits to family
		gen numtrips_fam_w3 = M5_1_TEXT 
		replace numtrips_fam_w3 = 0 if M5_1_TEXT==. & M4_1_TEXT==0 
		lab var numtrips_fam_w3 "Number of trips to visit family in past week (wave 3)"
		
	/* any trip to visit friends in last week:
			any trip in last week	*/	
		gen trip_friends_w3 = 0 if M6_1_TEXT==0 
		replace trip_friends_w3 = 0 if  M4_1_TEXT==0 
		replace trip_friends_w3 = 1 if M6_1_TEXT>0 & M6_1_TEXT!=. 
		lab var trip_friends_w3 "Any trip to visit friends in past 1 week (wave 3)"
		
		
		* number of visits to friends
		gen numtrips_friend_w3 = M6_1_TEXT 
		replace numtrips_friend_w3 = 0 if M6_1_TEXT==. & M4_1_TEXT==0
		lab var numtrips_friend_w3 "Number of trips to visit friends in past week (Wave 3)"
		
	/* any trip other than work/study. For this let's not include household or 
		personal errands:
			any trip for family/friend 	*/
		gen nonwork_trip_w3 = 0 if (M5_1_TEXT==0 | M6_1_TEXT==0 |  M4_1_TEXT==0) 
		replace nonwork_trip_w3 = 1 if M5_1_TEXT>0 & M5_1_TEXT!=. 
		replace nonwork_trip_w3 = 1 if M6_1_TEXT>0 & M6_1_TEXT!=.
		lab var nonwork_trip_w3 ///
		"Any visit to family or friends in past 1 week (wave 3)"
		
		
		
		 
			
	* household errands (binary)
	gen trip_hherrand_w3 = 0 if M7_1_TEXT == 0 | M4_1_TEXT == 0
	replace trip_hherrand_w3 = 1 if M7_1_TEXT > 0 & M7_1_TEXT!=.
	lab var trip_hherrand_w3 "Any trip for household errands in past 1 week (Wave 3)"
	
	* household errands (number)
	gen numtrip_hherrand_w3 = M7_1_TEXT 
	replace numtrip_hherrand_w3 = 0 if M7_1_TEXT == . & M4_1_TEXT == 0
	lab var numtrip_hherrand_w3 ///
	"Number of trips for household errands in past 1 week (Wave 3, winsor99)"
	
	
	* personal errands
	gen trip_perrand_w3 = 0 if M8_1_TEXT == 0 | M4_1_TEXT == 0
	replace trip_perrand_w3 = 1 if M8_1_TEXT > 0 & M8_1_TEXT!=.
	lab var trip_perrand_w3 "Any trip for personal errands in past 1 week (Wave 3)"
	
	* personal errands (number)
	gen numtrip_perrand_w3 = M8_1_TEXT 
	replace numtrip_perrand_w3 = 0 if M8_1_TEXT == . & M4_1_TEXT == 0
	lab var numtrip_perrand_w3 ///
	"Number of trips for personal errands in past 1 week (Wave 3)"
	
	* combined errands (number)
	gen numtrip_allerrand_w3 = numtrip_hherrand_w3 +  numtrip_perrand_w3
	replace numtrip_allerrand_w3 = 0 if M7_1_TEXT == . & M7_1_TEXT == . & M4_1_TEXT == 0
	lab var numtrip_allerrand_w3 ///
	"Number of trips for all errands in past 1 week (Wave 3)"
	
	* Wave 3 only - approximate work trips
	gen approx_work_trips_w3 = M4_1_TEXT 
	replace approx_work_trips_w3 = approx_work_trips_w3 - numtrips_fam_w3 if numtrips_fam_w3!=.
	replace approx_work_trips_w3 = approx_work_trips_w3 - numtrips_friend_w3 if numtrips_friend_w3!=.
	replace approx_work_trips_w3 = approx_work_trips_w3 - numtrip_hherrand_w3 if numtrip_hherrand_w3!=.
	replace approx_work_trips_w3 = approx_work_trips_w3 - numtrip_perrand_w3 if numtrip_perrand_w3!=.
	// move any negative values to 0
	replace approx_work_trips_w3 = 0 if approx_work_trips_w3<0 & approx_work_trips_w3!=.
	lab var approx_work_trips_w3 "Approximated number of work trips in past 1 week (wave 3)"

	
	* Generate trip frequency vars for regression figures
* Generate variables

	tab 			drive_freq_mo_cat_w3 , gen(drive_freq_num_)
	
	forvalues 		i = 1/5 {
					lab var drive_freq_num_`i' "Binary indicator for category `i' of number of times driven in past month (wave 3)"
	}

	* 0 = none; 1 = once or twice a month; 2 = once a week; 3 = a few times a week; 4 = every day 

* Trimmed variable for frequency of leaving house in last 7 days

	generate		leave_house_cat_w3 = 0 if M4_1_TEXT==0
	replace			leave_house_cat_w3 = 1 if M4_1_TEXT>= 1 & M4_1_TEXT< 2
	replace			leave_house_cat_w3 = 2 if M4_1_TEXT>= 2 & M4_1_TEXT< 3
	replace			leave_house_cat_w3 = 3 if M4_1_TEXT>= 3 & M4_1_TEXT< 6
	replace			leave_house_cat_w3 = 4 if M4_1_TEXT>= 6 & M4_1_TEXT< 10
	replace			leave_house_cat_w3 = 5 if M4_1_TEXT>= 10 & M4_1_TEXT< 15
	replace			leave_house_cat_w3 = 6 if M4_1_TEXT>= 15 & M4_1_TEXT< .
	lab var 		leave_house_cat_w3 "Number of times left house in last 7 days, category (wave 3)"
				
	tab				leave_house_cat_w3 , gen(leave_house_cat_)
	
	forvalues 		i = 1/7 {
					lab var leave_house_cat_`i' "Binary indicator for left house `i' time(s) in last 7 days (wave 3)"
	}
	
* Trimmed variable for number of trips in past week without male chaperone
	gen 			unaccomp_trips_cat_w3 = 0 if trips_unaccompanied_w3==0
	replace			unaccomp_trips_cat_w3 = 1 if trips_unaccompanied_w3>= 1 & ///
					trips_unaccompanied_w3< 2
	replace			unaccomp_trips_cat_w3 = 2 if trips_unaccompanied_w3>= 2 & ///
					trips_unaccompanied_w3< 3
	replace			unaccomp_trips_cat_w3 = 3 if trips_unaccompanied_w3>= 3 & ///
					trips_unaccompanied_w3< 6
	replace			unaccomp_trips_cat_w3 = 4 if trips_unaccompanied_w3>= 6 & ///
					trips_unaccompanied_w3< 10
	replace			unaccomp_trips_cat_w3 = 5 if trips_unaccompanied_w3>= 10 & ///
					trips_unaccompanied_w3< 15
	replace			unaccomp_trips_cat_w3 = 6 if trips_unaccompanied_w3>= 15 & ///
					trips_unaccompanied_w3< .
					
	lab variable	unaccomp_trips_cat_w3 "Number of unaccompanied trips in last 7 days, category (wave 3)"
					
	tab				unaccomp_trips_cat_w3 , gen(unaccomp_trips_cat_)
	
	forvalues 		i = 1/7 {
					lab var unaccomp_trips_cat_`i' "Binary indicator for left house unaccompanied `i' time(s) in last 7 days (wave 3)"
	}
	
* Trimmed variable for number of trips in past week to visit family
	gen 			fam_trips_cat_w3 = 0 if numtrips_fam_w3==0
	replace			fam_trips_cat_w3 = 1 if numtrips_fam_w3>= 1 & numtrips_fam_w3< 2
	replace			fam_trips_cat_w3 = 2 if numtrips_fam_w3>= 2 & numtrips_fam_w3< 3
	replace			fam_trips_cat_w3 = 3 if numtrips_fam_w3>= 3 & numtrips_fam_w3< 6
	replace			fam_trips_cat_w3 = 4 if numtrips_fam_w3>= 6 & numtrips_fam_w3< .
	lab var 		fam_trips_cat_w3 "Number of trips in last 7 days to visit family, category (wave 3)"
					
	tab				fam_trips_cat_w3 , gen(fam_trips_cat_)
	
	forvalues 		i = 1/5 {
					lab var fam_trips_cat_`i' "Binary indicator for `i' trips in last 7 days to visit family (wave 3)"
	}
	
* Trimmed variable for number of trips in past week to visit friends
	gen 			fr_trips_cat_w3 = 0 if numtrips_friend_w3==0
	replace			fr_trips_cat_w3 = 1 if numtrips_friend_w3>= 1 & numtrips_friend_w3< 2
	replace			fr_trips_cat_w3 = 2 if numtrips_friend_w3>= 2 & numtrips_friend_w3< 3
	replace			fr_trips_cat_w3 = 3 if numtrips_friend_w3>= 3 & numtrips_friend_w3< 6
	replace			fr_trips_cat_w3 = 4 if numtrips_friend_w3>= 6 & numtrips_friend_w3< .
	lab variable	fr_trips_cat_w3 "Number of trips in last 7 days to visit friends (wave 3)"
					
	tab				fr_trips_cat_w3 , gen(fr_trips_cat_)
	
	forvalues 		i = 1/5 {
					lab var fr_trips_cat_`i' "Binary indicator for `i' trips in last 7 days to visit friends (wave 3)"
	}

* Trimmed variable for number of trips in past week for HH errands
	gen 			he_trips_cat_w3 = 0 if numtrip_hherrand_w3==0
	replace			he_trips_cat_w3 = 1 if numtrip_hherrand_w3>= 1 & numtrip_hherrand_w3< 2
	replace			he_trips_cat_w3 = 2 if numtrip_hherrand_w3>= 2 & numtrip_hherrand_w3< 3
	replace			he_trips_cat_w3 = 3 if numtrip_hherrand_w3>= 3 & numtrip_hherrand_w3< 6
	replace			he_trips_cat_w3 = 4 if numtrip_hherrand_w3>= 6 & numtrip_hherrand_w3< .
	lab var 		he_trips_cat_w3 "Number of trips in last 7 days for HH errands (wave 3)"
					
	tab				he_trips_cat_w3 , gen(he_trips_cat_)
	
	forvalues 		i = 1/5 {
					lab var he_trips_cat_`i' "Binary indicator for `i' trips in last 7 days for HH errands (wave 3)"
	}
	
* Trimmed variable for number of trips in past week for personal errands
	gen 			pe_trips_cat_w3 = 0 if numtrip_perrand_w3==0
	replace			pe_trips_cat_w3 = 1 if numtrip_perrand_w3>= 1 & numtrip_perrand_w3< 2
	replace			pe_trips_cat_w3 = 2 if numtrip_perrand_w3>= 2 & numtrip_perrand_w3< 3
	replace			pe_trips_cat_w3 = 3 if numtrip_perrand_w3>= 3 & numtrip_perrand_w3< 6
	replace			pe_trips_cat_w3 = 4 if numtrip_perrand_w3>= 6 & numtrip_perrand_w3< .
	lab var			pe_trips_cat_w3 "Number of trips in last 7 days for personal errands (wave 3)"
					
	tab				pe_trips_cat_w3 , gen(pe_trips_cat_)
	
	forvalues 		i = 1/5 {
					lab var pe_trips_cat_`i' "Binary indicator for `i' trips in last 7 days for personal errands (wave 3)"
	}
	
* Trimmed variable for number of trips in past week for all errands
	gen 			errand_trips_cat_w3 = 0 if numtrip_allerrand_w3==0
	replace			errand_trips_cat_w3 = 1 if numtrip_allerrand_w3>= 1 & numtrip_allerrand_w3< 2
	replace			errand_trips_cat_w3 = 2 if numtrip_allerrand_w3>= 2 & numtrip_allerrand_w3< 3
	replace			errand_trips_cat_w3 = 3 if numtrip_allerrand_w3>= 3 & numtrip_allerrand_w3< 6
	replace			errand_trips_cat_w3 = 4 if numtrip_allerrand_w3>= 6 & numtrip_allerrand_w3< .
	lab var			errand_trips_cat_w3 "Number of trips in last 7 days for all errands (wave 3)"
					
	tab				errand_trips_cat_w3 , gen(errand_trips_cat_)

	forvalues 		i = 1/5 {
					lab var errand_trips_cat_`i' "Binary indicator for `i' trips in last 7 days for all errands (wave 3)"
	}
	

	
********************************
* EMPLOYMENT AND JOB SEARCH
********************************

	* labelling 
	lab var E1 "Employment status (wave 3)"
	lab var E4_6_TEXT "Number of jobs applied to in last month (wave 3)"
	lab var E2_12_TEXT "Number of hours worked | employed (wave 3)"
	lab var E3 "Steps taken in past month to search for job (wave 3)"
	
	* employment
		* first drop employed var (this was part of embedded data from wave 1&2)
		drop employed 
		
	gen employed_w3 = 0 if strpos(E1, "No")
	replace employed_w3 = 1 if strpos(E1, "Yes")
	lab var employed_w3 "Employed (wave 3)"
	lab val employed_w3 binary
	
	* category version
	gen employ_cat_w3 = 0 if E1=="No, I am not employed and I‚Äôm not looking for a job" ///
		| E1== "No, I am a student and I plan to work after graduation " ///
		| E1== "No, I am a student and I‚Äôm not looking for a job"
		replace employ_cat_w3 = 1 if E1== "No, I am not employed and I am looking for a job "
		replace employ_cat_w3 = 2 if E1== "Yes, I am employed but not looking for a different job" ///
		| E1== "Yes, I am employed and open to looking for a different or additional job"
	lab var employ_cat_w3 "Employment category (wave 3)"
	
	
	* create center/standardized version for labor force index
	sum employed_w3 if treatment==0 
	gen employed_st_w3 = .
	replace employed_st_w3 = (employed_w3-r(mean))/r(sd)
	lab var employed_st_w3 "Employed - centered/standardized (wave 3)"

	
	
	* number of hours worked
	destring E2_12_TEXT, replace
	*histogram E2_12_TEXT
	* NOTE: let's start with creating a binary at the median, can revise later 
	xtile hrs_worked_w3 = E2_12_TEXT, nq(2)
	lab var hrs_worked_w3 "Hours worked last week: binary at median (wave 3)"
	
		* now create unconditional version
		gen E2_unconditional = E2_12_TEXT
		replace E2_unconditional = 0 if employed_w3==0 
		lab var E2_unconditional "E2 (hours worked last week) - unconditional (wave 3)"
	
	
	* number of jobs applied to in last month
	destring E4_6_TEXT, replace
	replace E4_6_TEXT = 0 if E4=="None "
		

	
	* number of activities taken in last month to search for a job
	gen E3_ncommas = length(E3) - length(subinstr(E3, ",", "", .))
	replace E3_ncommas = . if E3==""
	gen E3_numbered = E3_ncommas + 1
	replace E3_numbered = 0 if E3=="" & E1!=""
	replace E3_numbered = 0 if (strpos(E1, "not looking"))
	replace E3_numbered = 0 if E3=="I prefer not to answer this question" | ///
	E3=="I have not taken any steps in the last 30 days to look for a job"
	replace E3_numbered =. if E3== "Call ended / connection lost / respondent hung up the phone"
	lab var E3_numbered "E3: number of job search activities undertaken in past month (wave 3)"

	* desired edu for (grand)daughter
	 lab def edu 1 "Complete high school " 2 "Complete diploma" ///
	 	3 "Complete vocational training" 4 "Complete a university degree" ///
		5 "Complete a degree beyond university (graduate/professional)"
	lab val G11_scale edu
	
	lab def agreement 1 "Definitely no" 2 "Probably no" 3 "Unsure" 4 "Probably yes" ///
	5 "Definitely yes"
	lab val G12_scale agreement
	
	
	
		
		* Not in LFP - 0 if in LF and 1 if not
		gen not_in_LF_w3 = .
		replace not_in_LF_w3 = 1 if E1=="No, I am not employed and I‚Äôm not looking for a job" ///
			| E1== "No, I am a student and I plan to work after graduation " ///
			| E1== "No, I am a student and I‚Äôm not looking for a job"
		replace not_in_LF_w3 = 0 if E1== "No, I am not employed and I am looking for a job "
		replace not_in_LF_w3 = 0 if E1== "Yes, I am employed but not looking for a different job" ///
			| E1== "Yes, I am employed and open to looking for a different or additional job"
		lab var not_in_LF_w3 "Not in labor force (wave 3)"
		lab def noLF 0 "in LF" 1 "not in LF" 
		lab val not_in_LF_w3 noLF
		
		
		* LFP - 0 if  not employed and not looking,  1 if unemployed and looking, 2 if employed
		gen LFP_w3 = .
		replace LFP_w3 = 0 if E1=="No, I am not employed and I‚Äôm not looking for a job" ///
			| E1== "No, I am a student and I plan to work after graduation " ///
			| E1== "No, I am a student and I‚Äôm not looking for a job"
			
		replace LFP_w3 = 1 if E1== "No, I am not employed and I am looking for a job "
		replace LFP_w3 = 2 if E1== "Yes, I am employed but not looking for a different job" ///
			| E1== "Yes, I am employed and open to looking for a different or additional job"
		
		lab var LFP_w3 "Labor force participation (wave 3)"
		lab def lfp 0 "out of LF" 1 "unemployed" 2 "employed"
		lab val LFP_w3 lfp	
		
		* Binary LFP
		gen in_LF_w3 = LFP_w3
		replace in_LF_w3 = 1 if LFP_w3==2
		lab var in_LF_w3 "In the labor force (wave 3)"
		lab def lf_bi 0 "out of LF" 1 "in LF"
		lab val in_LF_w3 lf_bi
		
		* create center/standardized version for labor force index
		sum in_LF_w3 if treatment==0 
		gen in_LF_st_w3 = .
		replace in_LF_st_w3 = (in_LF_w3-r(mean))/r(sd)
		lab var in_LF_st_w3 "In labor force - centered/standardized (wave 3)"
		
		
	/* searching for a job (NOTE: simple defn of any search, we don't use this and 
		instead use defn of search to be actively applying to jobs)	*/
		gen job_search_w3 = .
		replace job_search_w3 = 0 if (strpos(E1, "not looking"))
		replace job_search_w3 = 0 if E1=="No, I am a student and I plan to work after graduation "
		replace job_search_w3 = 1 if E1=="No, I am not employed and I am looking for a job " ///
			| E1=="Yes, I am employed and open to looking for a different or additional job"	
		lab var job_search_w3 "Searching for a job (wave 3)"
		
			/* on the job search - 0 not empl., or empl but not looking; 1 - empl
			and looking */
			gen on_job_search_w3 = .
			replace on_job_search_w3 = 0 if E1=="No, I am not employed and I‚Äôm not looking for a job" ///
			| E1== "No, I am a student and I plan to work after graduation " ///
			| E1== "No, I am a student and I‚Äôm not looking for a job" ///
			| E1== "No, I am not employed and I am looking for a job " ///
			| E1== "Yes, I am employed but not looking for a different job"
			replace on_job_search_w3 = 1 if ///
			E1== "Yes, I am employed and open to looking for a different or additional job"
			lab var on_job_search_w3 "On the job search (wave 3)"
			
		
			
			* off the job search (unemployed search)
			gen unemployed_w3 = .
			replace unemployed_w3 = 0 if E1=="No, I am not employed and I‚Äôm not looking for a job" ///
			| E1== "No, I am a student and I plan to work after graduation " ///
			| E1== "No, I am a student and I‚Äôm not looking for a job" ///
			| E1== "Yes, I am employed but not looking for a different job" ///
			| E1 == "Yes, I am employed and open to looking for a different or additional job"
			replace unemployed_w3 = 1 if ///
			E1== "No, I am not employed and I am looking for a job "
			lab var unemployed_w3 "Unemployed job search (wave 3)"
			
				* standardize for indices
				sum unemployed_w3 if treatment==0 
				gen unemployed_w3_st =.
				replace unemployed_w3_st = (unemployed_w3-r(mean))/r(sd)
				lab var unemployed_w3_st "Unemployed (wave 3) - centered/standardized binary (created using mean)"
			
		
			
			* employed not searching 
			gen employed_nosearch_w3 = .
			replace employed_nosearch_w3 = 0 if E1== ///
			"No, I am not employed and I‚Äôm not looking for a job" ///
			| E1== "No, I am a student and I plan to work after graduation " ///
			| E1== "No, I am a student and I‚Äôm not looking for a job" ///
			| E1== "No, I am not employed and I am looking for a job " ///
			| E1== "Yes, I am employed and open to looking for a different or additional job"
			replace employed_nosearch_w3 = 1 if E1== ///
			"Yes, I am employed but not looking for a different job"
			lab var employed_nosearch_w3 "Employed and not searching (wave 3)"
			
			
		
	* percent of job search activities undertaken
		gen search_act_prop_w3 = (E3_numbered/8) 
		replace search_act_prop_w3 = 0 if (strpos(E1, "not looking")) 
		lab var search_act_prop_w3 "Percentage of job search activities undertaken (wave 3)"
		
			
	
	* travelled to search for job
		gen  travel_job_search_w3 = 0 if ///
			!(strpos(E3, "Visited a job centre (JPC) in person")) ///
			& !(strpos(E3,"Travelled to employers in person to ask about job opportunities or drop off your CV")) ///
			& !(strpos(E3,"Call ended / connection lost / respondent hung up the phone")) ///
			 & E1!=""
		replace travel_job_search_w3 = 0 if (strpos(E1, "not looking")) 
		replace travel_job_search_w3 = 1 if ((strpos(E3,"Visited a job centre (JPC) in person") | ///
			strpos(E3,"Travelled to employers in person to ask about job opportunities or drop off your CV")))
		lab var travel_job_search_w3 "Travelled for job search (wave 3)"
		
		
		
	* number of jobs applied to in last month
		gen jobs_applied_w3 = E4_6_TEXT 
		replace jobs_applied_w3 = 0 if E4=="None " 
		replace jobs_applied_w3 = 0 if (strpos(E1, "not looking")) 
		replace jobs_applied_w3 = 0 if (strpos(E1, "I am a student")) 
		lab var jobs_applied_w3 "Number of jobs applied to in last month (wave 3)"
		
	* number of jobs applied to in last month by employed
	gen jobs_applied_empl_w3 = jobs_applied_w3*employed_w3
	lab var jobs_applied_empl_w3 "Jobs applied to in last month x employed (wave 3)"
	
	* number of jobs applied to in last month by employed
	gen jobs_applied_unempl_w3 = jobs_applied_w3*unemployed_w3
	lab var jobs_applied_unempl_w3 "Jobs applied to in last month x unemployed (wave 3)"
	
	
		
	* binary indicator for applied to any job in last month
		gen job_any_applied_w3 = 0 if jobs_applied_w3!=.
		replace job_any_applied_w3 = 1 if jobs_applied_w3>0 & jobs_applied_w3!=.
		lab var job_any_applied_w3 "Applied to any job in past month (wave 3)"
			
	* employed job search (binary indicator for employed and applied to any job)
	gen empl_jobsearch_w3 = 0 if jobs_applied_w3!=. & employed_w3!=.
	replace empl_jobsearch_w3 = 0 if jobs_applied_w3==. & employed_w3==0
	replace empl_jobsearch_w3 = 1 if jobs_applied_w3!=. & jobs_applied_w3>0 & employed_w3==1
	lab var empl_jobsearch_w3 "Employed and applied in past month (wave 3)"
	
		* Standardize for indices
		sum empl_jobsearch_w3 if treatment==0 
		gen empl_jobsearch_w3_st =.
		replace empl_jobsearch_w3_st = (empl_jobsearch_w3-r(mean))/r(sd)
		lab var empl_jobsearch_w3_st "Emp and applied in past month (wave 3) - centered/standardized binary (created using mean)"
	
	* unemployed job search (binary indicator for unemployed and applied to any job)
	gen unempl_jobsearch_w3 = 0 if jobs_applied_w3!=. & unemployed_w3!=.
	replace unempl_jobsearch_w3 = 0 if jobs_applied_w3==. & unemployed_w3==0
	replace unempl_jobsearch_w3 = 1 if jobs_applied_w3!=. & jobs_applied_w3>0 & unemployed_w3==1
	lab var unempl_jobsearch_w3 "Unemployed and applied in past month (wave 3)"
	
	* any job search 
	gen any_jobsearch_w3 = 0 if jobs_applied_w3!=. & unemployed_w3!=. & employed_w3!=.
	replace any_jobsearch_w3 = 0 if unemployed_w3==0 & employed_w3==0
	replace any_jobsearch_w3 = 1 if unemployed_w3==1 | empl_jobsearch_w3==1
	lab var any_jobsearch_w3 "Searching for job (wave 3)"
			
	  
********************************	
* SOCIAL NETWORK AND CIVIC ENGAGEMENT VARS
********************************

	* labelling 
	lab var N2_4_TEXT "Number of people texted with in last 7 days (wave 3)"
	lab var N4 "Met anyone in past month and exchanged contact info (wave 3)"
	lab var R1 "Do you have a Whatsapp account (wave 3)"
	lab var R2 "Do you have a LinkedIn account (wave 3)"
	lab var R6 "Do you have an Instagram account (wave 3)"
	lab var R8 "Option selected for Instagram followers (wave 3)"
	lab var R8_1_TEXT "Number of people followed on Instagram (wave 3)"
	lab var R8_2_TEXT "Number of followers on Instagram (wave 3)"
	lab var R10 "Do you have a Twitter account (wave 3)"
	lab var R12 "Option selected for Twitter followers (wave 3)"
	lab var R12_1_TEXT "Number of people followed on Twitter (wave 3)"
	lab var R12_2_TEXT "Number of followers on Twitter (wave 3)"
	lab var R16 "Would you like to nominate friends for Qudra (wave 3)"
	lab var R16_5_TEXT "Number of people she'd like to nominate for Qudra (wave 3)"
	lab var Q124 "Registered on national volunteering platform (wave 3)"
	lab var Q125 "Registered on national volunteering platform (wave 3)"
	lab var CM1 "People can spread COVID-19 without symptoms (wave 3)"
	lab var CM2 "Agreement with government saying there cannot be large public gatherings due to COVID-19 (wave 3)"
	lab var CM3 "Agreement with WHO saying there cannot be large public gatherings due to COVID-19 (wave 3)"
	lab var CM8 "Feelings about restrictions being placed in response to COVID-19 (wave 3)"
	lab var CM9 "Stated feeling about reaction of government to COVID-19 (wave 3)"

	

	* interactions in past 1 week
	destring  N1_4_TEXT, replace
		* one outlier at 403, let's drop this outlier
	gen N1_cleaned = N1_4_TEXT
	replace N1_cleaned = . if N1_cleaned==403
	lab var N1_cleaned "Number of people spoken to on phone (wave 3)"
	
		* create binary version for index
		xtile N1_cleaned_abovemed = N1_cleaned, nq(2)
		recode N1_cleaned_abovemed (1 = 0) (2 = 1)
		lab var N1_cleaned_abovemed "Number of people spoken to on phone - binary at median (wave 3)"
		
		sum N1_cleaned_abovemed if treatment==0 
		gen N1_cleaned_abovemed_st = .
		replace N1_cleaned_abovemed_st = (N1_cleaned_abovemed - r(mean))/r(sd)
		lab var N1_cleaned_abovemed_st "N1_cleaned_abovemed - center/standardized likert (wave 3)"
		
	* texted with in past week
	destring  N2_4_TEXT, replace
	
	* met up with in past week
	tab N3_1_TEXT
	
	*** NOTE: fix character error for one entry ('50Ÿ™')
	replace N3_1_TEXT="50" if N3_1_TEXT =="50Ÿ™"
	destring N3_1_TEXT, replace
		* there's one val of 300, which seems like an outlier - let's move that to missing
	gen N3_cleaned = N3_1_TEXT
	replace N3_cleaned = . if N3_cleaned==300
	lab var N3_cleaned "Number of people met with in last 7 days (wave 3)"
	
		* create binary version for index
		xtile N3_cleaned_abovemed = N3_cleaned, nq(2)
		recode N3_cleaned_abovemed (1 = 0) (2 = 1)
		lab var N3_cleaned_abovemed "Number of people met with in last 7 days - binary at median (wave 3)"
		
		sum N3_cleaned_abovemed if treatment==0 
		gen N3_cleaned_abovemed_st = .
		replace N3_cleaned_abovemed_st = (N3_cleaned_abovemed - r(mean))/r(sd)
		lab var N3_cleaned_abovemed_st "N3_cleaned_abovemed - center/standardized likert (wave 3)"
	
	* met anyone in past month where contact info was exchanged
	gen N4_cleaned = 1 if N4=="Yes"
	replace N4_cleaned = 0 if N4=="No"
	lab var N4_cleaned "N4 as binary yes/no"
	
	* number of people texted in last 24 hrs
	winsor2 N2_4_TEXT, cuts(0 98)
	rename N2_4_TEXT_w text_prev_24hr_w3
	lab var text_prev_24hr_w3 "Number of people texted in prev. 24 hrs (right tail winsor to 98p) (wave 3)" 
	
	* LinkedIn connections (only 39 respondents have an account)
	destring R5_5_TEXT, replace
	gen R5_cleaned = R5_5_TEXT
	* let's replace missings with 0 as they don't have an account
	destring R5_6_TEXT, replace
	replace R5_cleaned = 0 if R2=="No"
	replace R5_cleaned = R5_6_TEXT if R5_6_TEXT!=.
	lab var R5_cleaned "R5 - number of LinkedIn connections"
	
		* let's transform this: inverse hyperbolic sine
		ihstrans R5_cleaned
		lab var ihs_R5_cleaned "No. of LinkedIn connections (IHS transformation) (wave 3)"
	
	* Instagram followers
	gen insta_followers =  R8_2_TEXT 
	
		* remove unwanted characters (add additional characters below)
		global characters _ asa sa ,
		foreach j of global characters {
		replace insta_followers = subinstr(insta_followers, "`j'", "", .)
		}

		* replace 'k' with additional zeroes
		replace insta_followers = insta_followers + "000" if strpos(R8_2_TEXT, "k")
		replace insta_followers = subinstr(insta_followers, "k", "", .)
		replace insta_followers = "" if insta_followers=="Ÿ°Ÿ©Ÿ†"
		destring insta_followers, replace
		replace insta_followers = 0 if R6=="No"
		
		* let's transform this: inverse hyperbolic sine
		ihstrans insta_followers
		lab var insta_followers "No. of instagram followers"
		lab var ihs_insta_followers "No. of instagram followers (IHS transformation) (wave 3)"


	
	* Twitter followers
	destring R12_2_TEXT, replace
	gen twitter_followers = R12_2_TEXT
	replace twitter_followers = 0 if R10 == "No"
	lab var twitter_followers "Number of Twitter followers"
	
		* let's transform this: inverse hyperbolic sine
		ihstrans twitter_followers
		lab var ihs_twitter_followers "No. of Twitter followers (IHS transformation) (wave 3)"
		
	

	
	/* volunteering using national registry: let's create binary if they've signed up for 
	any opportunities (too few have even registered that I'm not sure it makes sense to 
	look at how many times they've actually volunteered) */
	destring  Q125_1_TEXT, replace
	gen volunt_regist = 0 if Q124=="Yes" | strpos(Q125, "I have not")
	replace volunt_regist = 1 if Q125_1_TEXT>0 &  Q125_1_TEXT!=.
	lab var volunt_regist "Registered for natl vol & signed up for 1+ opport (wave 3)"
	
	* number of volunteer opportunities
	gen num_volunteer = Q125_1_TEXT
	replace num_volunteer = 0 if strpos(Q125, "I have not")
	lab var num_volunteer "Number of volunteer opportunities signed up for (wave 3)"
	
	* number of volunteer opportunities attended
	destring Q126_1_TEXT, replace
	gen num_times_volunteer = Q126_1_TEXT
	replace num_times_volunteer = 0 if strpos(Q126, "I have not")
	lab var num_times_volunteer "Number of volunteer opportunities attended (wave 3)"
	
	* number of groups respondent belongs to (G14)
	gen G14_ncommas = length(G14) - length(subinstr(G14, ",", "", .)) if G14!=""
	gen G14_numbered = G14_ncommas + 1
	replace G14_numbered = . if G14=="Prefer not to answer"
	* | G14=="" 
	lab var G14_numbered "Number of group types she belongs to (wave 3)"
	
	* number of times in past month she attended meetings of any of these groups
	destring G15_4_TEXT, replace
	gen G15_cleaned = G15_4_TEXT
	replace G15_cleaned = 0 if strpos(G15, "I did not attend")
	lab var G15_cleaned "Number of times attended meetings of any group in past month (wave 3)"
	
	* Now create social network vars that are centered/standardized for index
	global socnet N1_cleaned N2_4_TEXT N3_cleaned N4_cleaned R5_cleaned ihs_insta_followers ///
	twitter_followers G14_numbered G15_cleaned
	
	foreach var of global socnet {
			gen `var'_st = .
			sum `var' if treatment==0 
			replace `var'_st = (`var'-r(mean))/r(sd)
			lab var `var'_st "`var' - centered/standardized (wave 3)"	
	}
	

* MISC CLEANING
	lab var participantid "Participant ID"
	


	
*****************************************************************
* SECTION 4 - GENERATE STATS ON MODULES STARTED AND COMPLETED
*****************************************************************

	
	* create globals for each module
	* mobility
		global mobility M1 M3 M4 M4_1_TEXT M5_1_TEXT M6_1_TEXT M7_1_TEXT M8_1_TEXT ///
		M9_2_TEXT Q132_2_TEXT M10 N1_4_TEXT N2_4_TEXT N3_1_TEXT N4
		
	local mobility=0
	foreach var of global mobility {
		local mobility = `mobility' + 1
	}
	di `mobility'
	* 15 vars of interest
	
	egen mobility_miss = rownonmiss($mobility), strok
	replace mobility_miss = mobility_miss/`mobility' 
	
	* employment
	gen E1_response = E1 if E1!="Call ended / connection lost / respondent hung up the phone" ///
	& E1!=""
	
	gen employ_modstart = 1 if E1_response!=""
	replace employ_modstart = 0 if E1_response==""
	lab var employ_modstart "Started employment module (wave 3)"

	
	* gender/political attitudes and civic engagement
	global attitudes G1_1 G1_2 G1_3 G3_1 G4_1 G4_2 G4_3 G5_1 G6_1 G6_2 G6_3 ///
		G7_1 G8_1 G8_2 G8_3 G9_1 G10_1 G10_2 G10_3 G11 G12 G13_7_TEXT G14 ///
		G15_cleaned Combined_P1_1_likert P1_2 P1_3 P2_1 P2_2 P2_3 P2_4 P3_scale
		
	local attitudes=0
	foreach var of global attitudes {
		local attitudes = `attitudes' + 1
	}

	egen attitudes_miss = rownonmiss($attitudes), strok
	replace attitudes_miss = attitudes_miss/`attitudes' 
	
	* real choice
	global real R1 R2 R5_cleaned R6 R8 R10 R14 R16 Q124 R17
	
	local real=0
	foreach var of global real {
		local real = `real' + 1
	}

	egen real_miss = rownonmiss($real) , strok
	replace real_miss = real_miss/`real' 
	
* now created a "started X module var"
global module_complete mobility attitudes real

foreach i of global module_complete {
	gen `i'_modstart = 0
	replace `i'_modstart = 1 if `i'_miss >0 & `i'_miss!=.
	lab var `i'_modstart "`i' module started"
}

foreach i of global module_complete {
	gen `i'_mod50 = 0
	replace `i'_mod50 = 1 if `i'_miss >=.5 & `i'_miss!=.
	lab var `i'_mod50 "`i' module 50% completed"
}
	


* FLAG RANDOMIZED MODULE ORDER AND MISSINGS ACROSS MODULES


* randomized module order (combine the two order vars)
gen module_order = FL_37_DO
replace module_order = FL_20_DO if short_survey==0
lab var module_order "Module order presented to respondent"

split module_order, p(|)
// This gives us three variables in the order in which the modules were presented
lab var module_order1 "First module presented"
lab var module_order2 "Second module presented"
lab var module_order3 "Third module presented"


* Tag missings for each section
	* Mobility
	gen mobility_missing = 0
	replace mobility_missing = 1 if M3=="" & M4=="" & M4_1_TEXT==. & M9=="" & ///
		M9_2_TEXT==. & N1=="" & N1_4_TEXT==. & N3=="" & N3_1_TEXT==.
	lab var mobility_missing "Missing all mobility (short survey) module responses"
	
	* Gender & Political Attitudes and Civic Engagement
	gen gpa_ce_missing = 0
	replace gpa_ce_missing = 1 if G1_1=="" & G1_2=="" & G1_3=="" & G5_1=="" & ///
		G6_1=="" & G6_2=="" & G6_3=="" & G7_1=="" & G8_1=="" & G8_2=="" & G8_3=="" ///
		& G9_1=="" & G10_1=="" & G10_2=="" & G10_3=="" & G13=="" & G13_7_TEXT==. ///
		& Combined_P1_1_likert==. & P1_2=="" & P1_3=="" & Q134=="" & P3==""
	lab var gpa_ce_missing ///
		"Missing all gender/political attitudes and civic engage (short survey) module responses"
		
	* Employment
	gen employ_missing = 0 
	replace employ_missing = 1 if E1=="" & E4=="" & E4_6_TEXT==.
	lab var employ_missing "Missing all employment (short survey) module responses"
	
	* create var for whether they started the endline based on these
	gen endline_start_w3 = 0
	replace endline_start_w3 = 1 if employ_modstart==1 | mobility_modstart==1 | ///
	attitudes_modstart==1 | real_modstart==1
	replace endline_start_w3 = 1  if M1!="" | E1!="" | G1_1!="" | R1!=""	
	lab var endline_start_w3 "Started endline survey"
	
	* create var for whether they started the Xth module presented to them (1st,2nd,3rd)
	
		* first tag which module they saw 1st, 2nd, 3rd
		gen module_appear = FL_37_DO
		replace module_appear = FL_20_DO if module_appear==""
		split module_appear, p(|)
	
	
		gen modstart_1 = 0
		replace modstart_1 = 1 if employ_modstart==1 & substr(module_appear1,1,10)=="Employment"
		replace modstart_1 = 1 if employ_modstart==1 & substr(module_appear1,1,10)=="Employment"
		replace modstart_1 = 1 if mobility_modstart==1 & substr(module_appear1,1,8)=="Mobility"
		replace modstart_1 = 1 if mobility_modstart==1 & substr(module_appear1,1,8)=="Mobility"
		replace modstart_1 = 1 if attitudes_modstart==1 & substr(module_appear1,1,6)=="Gender"
		replace modstart_1 = 1 if attitudes_modstart==1 & substr(module_appear1,1,6)=="Gender"
		lab var modstart_1 "Started Module 1"
		
		gen modstart_2 = 0
		replace modstart_2 = 1 if employ_modstart==1 & substr(module_appear2,1,10)=="Employment"
		replace modstart_2 = 1 if employ_modstart==1 & substr(module_appear2,1,10)=="Employment"
		replace modstart_2 = 1 if mobility_modstart==1 & substr(module_appear2,1,8)=="Mobility"
		replace modstart_2 = 1 if mobility_modstart==1 & substr(module_appear2,1,8)=="Mobility"
		replace modstart_2 = 1 if attitudes_modstart==1 & substr(module_appear2,1,6)=="Gender"
		replace modstart_2 = 1 if attitudes_modstart==1 & substr(module_appear2,1,6)=="Gender"
		lab var modstart_2 "Started Module 2"

		gen modstart_3 = 0
		replace modstart_3 = 1 if employ_modstart==1 & substr(module_appear3,1,10)=="Employment"
		replace modstart_3 = 1 if employ_modstart==1 & substr(module_appear3,1,10)=="Employment"
		replace modstart_3 = 1 if mobility_modstart==1 & substr(module_appear3,1,8)=="Mobility"
		replace modstart_3 = 1 if mobility_modstart==1 & substr(module_appear3,1,8)=="Mobility"
		replace modstart_3 = 1 if attitudes_modstart==1 & substr(module_appear3,1,6)=="Gender"
		replace modstart_3 = 1 if attitudes_modstart==1 & substr(module_appear3,1,6)=="Gender"
		lab var modstart_3 "Started Module 3"

* Volunteer and leadership sign-up	
	* Qudra sign up - we sent reminders to anyone who started the survey, so set to 0
		gen R14_scale = 0 if endline_start_w3==1
		replace R14_scale = 1 if R14 == "Yes "
		*replace R14_scale = 0 if R14 != "Yes " & R14 != ""
		lab var R14_scale "Interested in signing up for Qudra (wave 3)"
		
		* Giving this a num scale created the binary, so we can just center/standardize
		sum R14_scale if treatment==0 
		gen R14_scale_st = .
		replace R14_scale_st = (R14_scale-r(mean))/r(sd)
		lab var R14_scale_st "R14 - centered/standardized (wave 3)"
		
	* Himma sign up - we sent reminders to anyone who started the survey, so set to 0
		gen R17_scale = 0 if endline_start_w3==1
		replace R17_scale = 1 if R17 == "Yes"
		*replace R17_scale = 0 if R17 == "No"
		lab var R17_scale "Interested in Himma (wave 3)"
		
		* Giving this a num scale created the binary, so we can just center/standardize
		sum R17_scale if treatment==0 
		gen R17_scale_st = .
		replace R17_scale_st = (R17_scale-r(mean))/r(sd)
		lab var R17_scale_st "R17 - centered/standardized (wave 3)"
			
	
	* save 
	save "$data/RCT wave 3/Final/Combined_allwaves_final.dta", replace

*****************************************************************
* SECTION 5 - INCORPORAT DATA FROM QUDRA LINK AND MERGE IN
*****************************************************************

* Import qudra follow up dataset
import excel "$data/RCT wave 3/Raw/Qudra Follow-up_September 21, 2022_14.47.xlsx", ///
	sheet("Sheet1") firstrow clear


* drop first row (excel labels), and test responses (participandid==0 or ==.)
drop if StartDate=="Start Date"		// drop var label observation
drop if strpos(StartDate, "Import")	// drop second var label observation
drop if inlist(participantid, "0", "")

* let's use IP address to collapse to individuals instead of individual clicks
generate double EndDate2 = clock(EndDate, "MDYhm")
format EndDate2 %tc
lab var EndDate2 "EndDate as date and time var"


sort IPanon EndDate2
collapse (lastnm) Status Progress-sauditraining EndDate2, by(IPanon)


* CREATE OUTCOME VARS
	
	* anyone clicked
	gen anyone_clicked_w3 = 1
	
	* number of people clicked
	gen number_people_clicked_w3 = .
	bysort participantid: replace number_people_clicked_w3 = _N
	
	* number of people who clicked and said friend sent
	bysort participantid: egen number_friends_clicked_w3 = total(Q2=="Someone else sent me this link")
	
* collapse to participandid level
collapse (first) IPanon-participantgroup residence_area-number_friends_clicked_w3, by(participantid)
	lab var anyone_clicked_w3 "Any clicks on Qudra link"
	lab var number_people_clicked_w3 "Number of people who clicked on Qudra link"
	lab var number_friends_clicked_w3 "Number of friends who clicked on Qudra link"

* keep just the vars we need and merge to our dataset
destring participantid, replace
keep anyone_clicked_w3 number_people_clicked_w3 number_friends_clicked_w3 participantid
merge 1:1 participantid using "$data/RCT wave 3/Final/Combined_allwaves_final.dta"

// NOTE: we have a few IDs who got a link but had been excluded from the sample, let's drop
drop if _merge==1
drop _merge 

* clean up missing vars
replace anyone_clicked_w3 = 0 if anyone_clicked_w3==. & endline_start_w3==1
replace number_people_clicked_w3 = 0 if number_people_clicked_w3==. & endline_start_w3==1
replace number_friends_clicked_w3 = 0 if number_friends_clicked_w3==. & endline_start_w3==1

* create centered/standardized version of anyone_clicked and number_friends_clicked for indices
	
	* anyone_clicked
	sum anyone_clicked_w3 if treatment==0 
	gen anyone_clicked_st_w3 = . 
	replace anyone_clicked_st_w3 = (anyone_clicked_w3-r(mean))/r(sd)
	lab var anyone_clicked_st_w3 "Anyone clicked on Qudra link - centered/standardized (wave 3)"
	
		
	* number of clicks
		* continuos version
		sum number_people_clicked_w3 if treatment==0 
		gen num_ppl_clicked_st_w3 = . 
		replace num_ppl_clicked_st_w3 = (number_people_clicked_w3-r(mean))/r(sd)
		lab var num_ppl_clicked_st_w3 "Num. people clicked on Qudra link - centered/standardized (wave 3)"
	
	
		* binary version
		xtile numppl_click_abovemed = number_people_clicked_w3, nq(2)
		recode numppl_click_abovemed (1 = 0) (2 = 1)
		lab var numppl_click_abovemed "Num. people clicked on Qudra link - binary at median (wave 3)"
		
		sum numppl_click_abovemed if treatment==0 
		gen numppl_click_abovemed_st = . 
		replace numppl_click_abovemed_st = (numppl_click_abovemed-r(mean))/r(sd)
		lab var numppl_click_abovemed_st "Num. people clicked on Qudra link - centered/standardized binary at median (wave 3)"



**************************************	
* NOW CREATE INDICES
**************************************


	* create indicator for control to use with swindex
	gen control = 1 if treatment==0
	replace control =0 if treatment==1

		
	* Gender Attitudes - First Order Beliefs

		* binary version
			global GA_1stOrder G1_1_abovemed_st G5_1_abovemed_st G7_1_abovemed_st ///
			G9_1_abovemed_st G13_scale_st P1_3_abovemed_st
			
			* UPDATE: using swindex
			swindex $GA_1stOrder, generate(ga_1st_order_binary_sw) normby(control)
			lab var ga_1st_order_binary_sw ///
			"Gender Attitudes: 1st Order Index - binary, swindex (wave 3)"
			
		* likert version
			global GA_1stOrder_likert G1_1_likert_st G5_1_likert_reverse_st G7_1_likert_reverse_st ///
			G9_1_likert_reverse_st G13_scale_st P1_3_likert_st
			
			* Using swindex
			swindex $GA_1stOrder_likert, generate(ga_1st_order_likert_sw) normby(control)
			lab var ga_1st_order_likert_sw ///
			"Gender Attitudes: 1st Order Index - likert, swindex (wave 3)"


		
	* Gender Attitudes - Second Order: Men in Respondent's family

		* binary version
			global GA_2ndOrder_MaleFam G6_1_abovemed_st G8_1_abovemed_st G10_1_abovemed_st 
			
			* UPDATE: using swindex
			swindex $GA_2ndOrder_MaleFam, generate(ga2nd_mfam_binary_sw) normby(control)
			lab var ga2nd_mfam_binary_sw ///
			"Gender Attitudes: 2nd Order (Male Fam) Index - binary, swindex (wave 3)"
			
		* likert version
			global GA_2ndOrder_MaleFam_likert G6_1_propor_st  G8_1_propor_st G10_1_propor_st 
			
			* UPDATE: using swindex
			swindex $GA_2ndOrder_MaleFam_likert, generate(ga2nd_mfam_likert_sw) normby(control)
			lab var ga2nd_mfam_likert_sw ///
			"Gender Attitudes: 2nd Order (Male Fam) Index - likert, swindex (wave 3)"
		

		
	* Gender Attitudes - Second Order: Women in Community

		* binary version
			global GA_2ndOrder_FemCom G6_2_abovemed_st G8_2_abovemed_st G10_2_abovemed_st 
			
			* UPDATE: using swindex
			swindex $GA_2ndOrder_FemCom, generate(ga2nd_fcom_binary_sw) normby(control)
			lab var ga2nd_fcom_binary_sw ///
			"Gender Attitudes: 2nd Order (Female Commm.) Index - binary, swindex (wave 3)"
			
		* likert version
			global GA_2ndOrder_FemCom_likert G6_2_propor_st G8_2_propor_st G10_2_propor_st 
			
			* UPDATE: using swindex
			swindex $GA_2ndOrder_FemCom_likert, generate(ga2nd_fcom_likert_sw) normby(control)
			lab var ga2nd_fcom_likert_sw ///
			"Gender Attitudes: 2nd Order (Female Commm.) Index - likert, swindex (wave 3)"

			
	* Gender Attitudes - Second Order: Men in Community
		
		* binary version
			global GA_2ndOrder_MaleCom G6_3_abovemed_st G8_3_abovemed_st G10_3_abovemed_st 
			
			* UPDATE: using swindex
			swindex $GA_2ndOrder_MaleCom, generate(ga2nd_mcom_binary_sw) normby(control)
			lab var ga2nd_mcom_binary_sw ///
			"Gender Attitudes - 2nd Order (Male Commm.) Index - binary, swindex (wave 3)"
			
		* likert version
			global GA_2ndOrder_MaleCom_likert G6_3_propor_st G8_3_propor_st G10_3_propor_st 
			
			* UPDATE: using swindex
			swindex $GA_2ndOrder_MaleCom_likert, generate(ga2nd_mcom_likert_sw) normby(control)
			lab var ga2nd_mcom_likert_sw ///
			"Gender Attitudes - 2nd Order (Male Commm.) Index - likert, swindex (wave 3)"
		
	* Create index of all male attitudes (combining male family and male social network)
		* binary version
			global GA_2ndOrder_AllMen G6_1_abovemed_st G8_1_abovemed_st ///
			G10_1_abovemed_st G6_3_abovemed_st G8_3_abovemed_st G10_3_abovemed_st 
			
			* UPDATE: using swindex
			swindex $GA_2ndOrder_AllMen, generate(ga2nd_allmen_binary_sw) normby(control)
			lab var ga2nd_allmen_binary_sw ///
			"Gender Attitudes - 2nd Order (All men) Index - binary, swindex (wave 3)"
			
		* likert version
			global GA_2ndOrder_AllMen_likert G6_1_propor_st  G8_1_propor_st ///
			G10_1_propor_st G6_3_propor_st G8_3_propor_st G10_3_propor_st 
	 		
			* UPDATE: using swindex
			swindex $GA_2ndOrder_AllMen_likert, generate(ga2nd_allmen_likert_sw) ///
			normby(control)
			lab var ga2nd_allmen_likert_sw ///
			"Gender Attitudes - 2nd Order (All men) Index - likert, swindex (wave 3)"
			
	/* Create index of social contact (number of people spoken to on phone and met
			in last 24 hrs)	*/
		* binary version
			global socialcontact_bi N1_cleaned_abovemed_st N3_cleaned_abovemed_st 
			
			* UPDATE: using swindex
			swindex $socialcontact_bi, generate(social_contact_binary_sw) ///
			normby(control)
			lab var social_contact_binary_sw ///
			"Social Contact Index - binary, swindex (wave 3)"	
			
		* continuous version
			global socialcontact N1_cleaned_st N3_cleaned_st
			
			* UPDATE: using swindex
			swindex $socialcontact, generate(social_contact_sw) ///
			normby(control)
			lab var social_contact_sw ///
			"Social Contact Index - swindex (wave 3)"
			
	* Labor force index (using employed dummy and in LF dummy)
	swindex employed_st_w3 in_LF_st_w3, generate(LF_index_sw_w3) normby(control)
	lab var LF_index_sw_w3 "Labor force index, swindex (wave 3)"
	
	
	* Stated approval of gender policy (`gov is working fast enough' and `feels the impact')
		* binary version
		global approval_bi P1_1_abovemed_st P1_2_abovemed_st
		
			* UPDATE: using swindex
			swindex $approval_bi, generate(gen_policy_binary_sw) ///
			normby(control)
			lab var gen_policy_binary_sw ///
			"Stated Approval of Gender Policy Index - binary, swindex (wave 3)"	
			
		* continuos version
			global approval Combined_P1_1_likert_st P1_2_likert_st
		
			* UPDATE: using swindex
			swindex $approval, generate(gen_policy_sw) ///
			normby(control)
			lab var gen_policy_sw ///
			"Stated Approval of Gender Policy Index - swindex (wave 3)"
			
	* Civic engagement (P3_abovemed R17_scale R14_scale anyone_clicked ppl_clicked)
		* binary version
		global 	civ_eng_bi P3_abovemed_st R17_scale_st R14_scale_st anyone_clicked_st_w3 ///
				numppl_click_abovemed_st
				
		* UPDATE: using swindex
			swindex $civ_eng_bi, generate(civ_engage_binary_sw) ///
			normby(control)
			lab var civ_engage_binary_sw ///
			"Civic Engagement Index - binary, swindex (wave 3)"	
		
		* continuous version 
		global 	civ_eng P3_scale_st R17_scale_st R14_scale_st anyone_clicked_st_w3 ///
				num_ppl_clicked_st_w3
				
				
			* UPDATE: using swindex
			swindex $civ_eng, generate(civ_engage_sw) ///
			normby(control)
			lab var civ_engage_sw ///
			"Civic Engagement Index - swindex (wave 3)"
			
	* Mobility and Spending control 
	global mobspencntrl G1_2_abovemed_st G1_3_abovemed_st
	
		* SWINDEX
		swindex $mobspencntrl, generate(mobspencntrl_binary_sw) ///
			normby(control)
			lab var mobspencntrl_binary_sw ///
			"Mobility and Spending Control Index - binary, swindex (wave 3)"
			
	* Job search index (unemployed + on the job search)
	global job_search unemployed_w3_st empl_jobsearch_w3_st
	
		* SWINDEX
		swindex $job_search, generate(job_search_binary_sw) ///
			normby(control)
			lab var job_search_binary_sw ///
			"Job Search Index - binary, swindex (wave 3)"

			
*****************************************************************
* SECTION 6 - FINAL CLEAN UP AND LABELLING
*****************************************************************





* Save a version of the dataset that includes all variables from wave 3
save "$data/RCT wave 3/Cleaned/Combined_allwaves_fullwave3vars_cleaned.dta", replace


* Now drop out vars we don't need/use in analysis for paper
keep 	randomization_cohort2 file_nbr participantid treatment ///
		husb_influence_kids hte_rel_status hte_rel_status_alt husb_influence_kids_alt ////
		age_4group_BL  edu_category_BL  married ///
		divorced_separated widowed single  household_size ///
		 one_car mult_cars cars ///
		 employed_BL unemployed_BL  treatment question_timing ///
		unaccomp_trips_cat_* employed_w3 G1_3_abovemed G1_3_abovemed_st s_train_bi_w3 license_w3 ///
		drive_any_mo_bi_w3 M4_1_TEXT share_trips_unaccomp_w3 unemployed_w3 not_in_LF_w3 ///
		empl_jobsearch_w3 no_trips_unaccomp_w3 G1_2_abovemed G1_2_abovemed_st  mobility_modstart ///
		employ_modstart attitudes_modstart real_modstart drive_freq_num_* ///
		leave_house_cat_* age_BL household_size ///
		hh_les18_w hh_more18_w cars_num driving_likely_BL less_than_primary_BL ///
		elementary_BL highschool_BL any_tertiary_edu_BL not_in_LF_BL unemployed_BL ///
		employed_BL on_job_search_BL ever_employed_BL work_experience_cond_BL ///
		salary_less3k_BL salary_3kto4999_BL salary_5kto6999_BL rel_status_BL ///
		trip_any_w2 tripnb_yesterday_w2 mean_trip_duration_w2 trip_duration_work_cond_w2 ///
		trip_any_leisure_friendscond_w2 trip_any_leisure_relcond_w2 ///
		trip_any_leisure_parkcond_w2 trip_any_leisure_mealcond_w2 trip_any_pers_govtcond_w2 ///
		trip_any_pers_healthcond_w2 trip_any_shopping_hhcond_w2 ///
		trip_any_shopping_perscond_w2 trip_any_pickdropcond_w2 trip_any_unicond_w2 ///
		trip_any_workcond_w2 trip_mode_buscond_w2 trip_mode_footcond_w2 ///
		trip_mode_car_drivercond_w2 trip_mode_car_familycond_w2 ///
		trip_mode_car_paiddrivercond_w2 trip_mode_car_poolingcond_w2 ///
		trip_mode_hailingcond_w2 trip_mode_taxicond_w2 trip_mode_othercond_w2 ///
		ga2nd_fcom_binary_sw G6_2_abovemed G8_2_abovemed G10_2_abovemed ///
		ga2nd_mfam_binary_sw G6_1_abovemed G8_1_abovemed G10_1_abovemed ///
		ga2nd_mcom_binary_sw G6_3_abovemed G8_3_abovemed  G10_3_abovemed ///
		number_people_clicked number_friends_clicked N1_cleaned N3_cleaned P3_abovemed ///
		R17_scale R14_scale P1_2_abovemed ga_1st_order_binary_sw  G5_1_abovemed ///
		G7_1_abovemed G9_1_abovemed G1_1_abovemed G13_scale P1_3_abovemed ///	
		wusool_T driving_T group_strata	saudidrive_w2 license_w2 ///
		expectcomm_ehai_amount_tr_w2 drive_lastm_w2 drive_month_w2 ///
		future_drive_med_w2 future_drive_w2 drove_yest_w2 recenttripyestod_w2 rectripyestodnofam_w2 ///
		rectripyestodrelat_w2 rectripyestodfd_w2 nonwork_trip_w2 jobsearch_w2 ///
		careerfair_w2 jobhuntprop_w2 jh_travel_w2 lowestsalary_txt_w2 ///
		jobapplied_lastm_w2 job_interview_w2 job_interviewattend_w2 ///
		takejob_15mins_w2 takejob_30mins_w2 G5_1_likert_reverse G7_1_likert_reverse ///
		G9_1_likert_reverse G6_1_propor G6_2_propor G6_3_propor G8_1_propor ///
		G8_2_propor G8_3_propor G10_1_propor G10_2_propor G10_3_propor BLsearch ///
		anyone_clicked_w3 P1_1_abovemed G1_2_likert G1_3_likert LFP_w3 M9_2_TEXT ///
		hh_kid_adu_ratio LF_BL G1_1_likert P1_2_likert P1_3_likert ///
		Combined_P1_1_likert G3_1_likert_reverse G1_1_likert_st G1_2_likert_st ///
		G1_3_likert_st P1_2_likert_st P1_3_likert_st Combined_P1_1_likert_st ///
		G7_1_likert_reverse_st G9_1_likert_reverse_st G3_1_likert_reverse_st ///
		G5_1_likert_reverse_st G4_1_propor G4_2_propor G4_3_propor G4_1_propor_st ///
		G4_2_propor_st G4_3_propor_st G6_1_propor_st G6_2_propor_st G6_3_propor_st ///
		G8_1_propor_st G8_2_propor_st G8_3_propor_st G10_1_propor_st ///
		G10_2_propor_st G10_3_propor_st ga_1st_order_likert_sw ga2nd_mfam_likert_sw ///
		ga2nd_fcom_likert_sw ga2nd_mcom_likert_sw P3_scale hh_kid_adult_abovemed_BL ///
		salary_BL_cat trip_all_leisure_cond_w2 ///
		trip_personal_errands_cond_w2 trip_HH_errands_cond_w2 trip_commute_cond_w2 ///
		endline_start_w3 husb_influence_kids_original age_med edu_nohs owns_car ///
		relationship_status_BL ever_married trip_any_shopping_pers_w2 trip_commute_w2 ///
		trip_HH_errands_w2 trip_personal_errands_w2 trip_all_leisure_w2 LF_index_sw_w3 ///
		ga2nd_allmen_likert_sw ga2nd_allmen_binary_sw N1_cleaned_abovemed ///
		N1_cleaned_abovemed_st N1_cleaned_st N3_cleaned_abovemed N3_cleaned_abovemed_st ///
		N3_cleaned_st social_contact_binary_sw social_contact_sw social_contact_binary_sw gen_policy_binary_sw ///
		gen_policy_sw civ_engage_binary_sw civ_engage_sw anyone_clicked_st_w3 ///
		numppl_click_abovemed_st P3_scale_st num_ppl_clicked_st_w3 ///
		P3_abovemed_st  R17_scale_st R14_scale_st driving_likely_likert_BL jobs_applied_w3 ///
		G13_scale_st modstart_1 modstart_2 modstart_3 start_survey_w3 one_child ///
		mult_children work_experience_BL unempl_jobsearch_w3 Institution saudi_drive_training ///
		trips_unaccompanied_w3 mobspencntrl_binary_sw job_search_binary_sw any_jobsearch_w3 ///
		education_diploma education_college education_masters subsidy_unaware_BL
		
		  
			
save "$data/RCT wave 3/Final/Combined_allwaves_final.dta", replace



