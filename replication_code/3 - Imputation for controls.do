/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		Imputation for regression control variables (moving missings to 0)
				
********************************************************************************
********************************************************************************
*******************************************************************************/


// NOTES: We will replace missing values for control variables with the sample mean
// We have no missing values for: employed_BL   
// Missing 1 from BLsearch, causing missing for unemployed_BL
// Missing 1 from age (and age_4group)
// Missing 19 from household_size
// Missing 4 from marital group
// Missing 12 from edu_category
// Missing 17 from cars



* age (PAP version)
gen miss_age_PAP = 0
replace miss_age_PAP = 1 if age_med_BL==.
lab var miss_age_PAP "Missing value for age (PAP version)"

gen age_med_BL_control = age_med_BL
replace age_med_BL_control = 0 if age_med_BL==.


* household_size
gen miss_household_size = 0
replace miss_household_size = 1 if household_size==.
lab var miss_household_size "Missing value for household_size"

gen household_size_control = household_size
replace household_size_control = 0 if household_size==.


* Cars

	* create one missing tag(since missing for the same people)
	gen miss_cars = 0
	replace miss_cars = 1 if cars==.
	lab var miss_cars "Missing value for cars"
	
	* dummy for one car
	gen one_car_control = one_car
	replace one_car_control = 0 if one_car==.
	

	* dummy for 2+ cars
	gen mult_cars_control = mult_cars
	replace mult_cars_control = 0 if mult_cars==.

	
	
* Relationship status (updated categories)

	* create one missing tag (since missing for the same people)
	gen miss_relationship	= 0
	replace miss_relationship = 1 if rel_status_BL==.
	lab var miss_relationship "Missing value for relationship status"
	
	
	* married
	gen married_control = married
	replace married_control = 0 if married==.


	* divorced/separated
	gen divorced_separated_control = divorced_separated
	replace divorced_separated_control = 0 if divorced_separated==.


	* single
	gen single_control = single
	replace single_control = 0 if single==.



	* widowed
	gen widowed_control = widowed
	replace widowed_control = 0 if widowed==.

	
* LF_BL
gen miss_LF_BL = 0 
replace miss_LF_BL = 1 if LF_BL==.
lab var miss_LF_BL "Missing value for LF_BL"

gen LF_BL_control = LF_BL
replace LF_BL_control = 0 if LF_BL==.


* edu_category
gen miss_edu_category = 0 
replace miss_edu_category = 1 if edu_nohs_BL==.
lab var miss_edu_category "Missing value for edu_category"

gen edu_nohs_BL_control = edu_nohs_BL
replace edu_nohs_BL_control = 0 if edu_nohs_BL==.

/* hh_les18_w (TBD this is for has husb/co-par HTE robustness to multiple interactions)
gen miss_hh_les18_w = 0
replace miss_hh_les18_w = 1 if hh_les18_w==.
lab var miss_hh_les18_w "Missing value for hh_les18_w"

gen hh_les18_w_control = hh_les18_w
replace hh_les18_w_control = 0 if hh_les18_w==.
*/

