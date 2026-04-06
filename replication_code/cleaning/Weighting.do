/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		REWEIGHTING	USING NATIONAL ESTIMATES (GASTAT)



********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

************************************************************
* SECTION 1 - IMPORT AND SET UP NATIONAL ESTIMATES FROM GASTAT
* SECTION 2 - WEIGHTS FOR: AGE, MARITAL STATUS, EDU, EMPLOYMENT
************************************************************

************************************************************		
* SECTION 1 - IMPORT AND SET UP NATIONAL ESTIMATES FROM GASTAT
************************************************************

* pull in national estimates
import excel "$data/Government admin data/education_and_training_surveyen_1.xlsx", ///
sheet("8-2 ") cellrange(B7:AE20) firstrow clear
drop O-AE
* adjust age and edu categories to match
insobs 3
replace AREA="15-29" if _n==14
replace AREA="30-44" if _n==15
replace AREA="45+" if _n==16
rename AREA age


egen less_than_primary = rowtotal(Illiterate ReadWrite Primary)
egen elementary = rowtotal(Intermediate PreSecondaryDiploma)
gen highschool = SecondaryEquivalent
egen any_tertiary = rowtotal(PreUnivDiploma Bachelors HigherDiploma Master PhD)


* sum age-edu bins for updated age ranges

foreach var in less_than_primary elementary highschool any_tertiary {
	replace `var' = `var'[2] + `var'[3] + ///
		`var'[4] if _n==14
		
	replace `var' = `var'[5] + `var'[6] + ///
		`var'[7] if _n==15
		
	replace `var' = `var'[8] + `var'[9] + ///
		`var'[10] + `var'[11] + `var'[12] if _n==16
}

* update total pop (remove age 10-19 pop)
global total_20pl = Total[13]-Total[1]
* gen shares of total pop for each age-edu group	
foreach var in less_than_primary elementary highschool any_tertiary {
	gen `var'_share = `var'/$total_20pl if _n>=14
}

* drop unnecessary cells
keep if _n>=14 & _n<17
keep age less_than_primary elementary highschool any_tertiary less_than_primary_share elementary_share highschool_share any_tertiary_share

* reshape to merge
local i = 1
foreach var in less_than_primary_share elementary_share highschool_share any_tertiary_share {
	rename `var' edu`i'
	local i = `i'+1
}
reshape long edu, i(age) j(educat)
encode age, gen(age_3grp)
rename edu share_edu_age

lab def edu 1 "Less than primary" 2 "Elementary" 3 "Highschool" 4 "Any tertiary"
lab val educat edu
rename educat edu_4cat

* keep what we need to merge
keep age_3grp edu_4cat share_edu_age

tempfile pop_estimates
save `pop_estimates'

************************************************************		
* SECTION 2 - WEIGHTS FOR: AGE, MARITAL STATUS, EDU, EMPLOYMENT
************************************************************

* Now open our dataset and create weights
	use "$data/RCT wave 3/Final/Combined_allwaves_final.dta", clear
	
* Create vars to match structure of comparison stats
	gen age_3grp = 1 if inrange(age_BL, 15,29)
	replace age_3grp = 2 if inrange(age_BL, 30,44)
	replace age_3grp = 3 if age_BL>=45 & age_BL!=.
	lab var age_3grp "Age grouping for reweighting"
	
	
	egen edu_4cat = group(less_than_primary_BL elementary_BL highschool_BL ///
	any_tertiary_edu_BL)
	
	egen employment = group(employed_BL unemployed_BL)
	

	
* Calculate shares for each var
	keep if age_3grp!=. & edu_4cat!=. 
	
	count 
	global tot = r(N)

	* age-edu groups
	bysort age_3grp edu_4cat: gen samp_eduage_count = _N		// count Ns by category		
	gen share_samp_eduage = samp_eduage_count/$tot			 	// sample shares
	
	* employment
	bysort employment: gen employment_count = _N				// count Ns by category
	gen employment_share = employment_count/$tot 				// sample shares
	
* Now merge in shares from GASTAT
merge m:1 age_3grp edu_4cat using `pop_estimates'

* Create weights
	* age-edu
	gen age_edu_weight = share_edu_age/share_samp_eduage
	
	* employment (created using KSA MoH and GASTAT stats - Table A2 in paper)
	gen emp_weight = 0.135/employment_share if employed_BL==1
	replace emp_weight = 0.062/employment_share if unemployed_BL==1
	replace emp_weight = (1-0.135-0.062)/employment_share if LF_BL==0
	

* now just keep weight vars and merge to dataset
	keep participantid age_edu_weight emp_weight

	merge 1:1 participantid using "$data/RCT wave 3/Final/Combined_allwaves_final.dta"
	drop _merge
	
* label weights 
	lab var age_edu_weight "Weight: Age and Edu"
	lab var emp_weight "Weight: Employment"

* save final data set
	save "$data/RCT wave 3/Final/Combined_allwaves_final.dta", replace
	
	
	