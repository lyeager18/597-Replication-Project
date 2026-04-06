/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		Controls for regressions (where missings have been moved to 0)
				
********************************************************************************
********************************************************************************
*******************************************************************************/

// NOTE: 	DECISION TO BE MADE ON WHETHER TO UPDATE MARITAL STATUS CONTROLS TO MATCH
//			NEW CATEGORIES FOR HTE

* 	Main models

global 	controls age_med_BL_control miss_age_PAP edu_nohs_BL_control miss_edu_category ///
		married_control single_control widowed_control miss_relationship household_size_control ///
		miss_household_size one_car_control mult_cars_control miss_cars LF_BL_control miss_LF_BL
		
* HTE with 'has husband/co-parent' (drops marital status dummies)

global 	controls_HTEhusb age_med_BL_control miss_age_PAP edu_nohs_BL_control miss_edu_category ///
		household_size_control ///
		miss_household_size one_car_control mult_cars_control miss_cars LF_BL_control miss_LF_BL
		
* HTE with BL LFP (drops LF_BL_control)

global 	controls_LF_BL age_med_BL_control miss_age_PAP edu_nohs_BL_control miss_edu_category ///
		married_control single_control widowed_control miss_relationship household_size_control ///
		miss_household_size one_car_control mult_cars_control miss_cars
		
* HTE with median age (drops age_med_BL_control)

global 	controls_age_med_BL edu_nohs_BL_control miss_edu_category ///
		married_control single_control widowed_control miss_relationship household_size_control ///
		miss_household_size one_car_control mult_cars_control miss_cars LF_BL_control miss_LF_BL
		
* HTE with edu (drops edu_nohs_BL_control)
		
global 	controls_edu_nohs_BL age_med_BL_control miss_age_PAP ///
		married_control single_control widowed_control miss_relationship household_size_control ///
		miss_household_size one_car_control mult_cars_control miss_cars LF_BL_control miss_LF_BL
		
* HTE robustness to interacting treatment with baseline characteristics
global 	controls_BLcharinteract household_size_control ///
		miss_household_size one_car_control mult_cars_control miss_cars LF_BL_control miss_LF_BL




