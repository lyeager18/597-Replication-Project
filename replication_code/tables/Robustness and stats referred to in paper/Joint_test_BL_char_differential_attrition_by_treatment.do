/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		Robustness - Regressing attrition on baseline characteristics 
							 interacted with treatment status

Table footnotes: This is a joint test of whether baseline characteristics 
differentially affect attrition by treatment. Data from administrative records 
and baseline survey. Statistics reported for the subsample who started the endline 
survey. "Likely to drive soon after ban is lifted" variables are binary response 
indicators based on the following scale for whether the respondent would be likely 
to drive once the ban on female driving would be lifted (it was lifted partway 
through the baseline): unlikely to drive, somewhat likely, likely but not at first, 
and likely.
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"

	
		
global balance age_BL single married divorced_separated husb_influence_kids   ///
	one_child_BL mult_children_BL hh_more18_w owns_car_BL cars_num driving_likely_BL  ///
	elementary_BL highschool_BL any_tertiary_edu_BL  ///
	employed_BL unemployed_BL on_job_search_BL ever_employed_BL  work_experience_BL
		
gen attrit = 0 if endline_start_w3==1
replace attrit = 1 if endline_start_w3==0
lab var attrit "Attrited"


		
		
reghdfe attrit c.age_BL##treatment single##treatment married##treatment divorced_separated##treatment ///
	husb_influence_kids##treatment one_child_BL##treatment mult_children_BL##treatment ///
	c.hh_more18_w##treatment owns_car_BL##treatment ib1.cars_num##treatment ///
	driving_likely_BL##treatment elementary_BL##treatment highschool_BL##treatment ///
	any_tertiary_edu_BL##treatment employed_BL##treatment unemployed_BL##treatment ///
	on_job_search_BL##treatment ever_employed_BL##treatment  c.work_experience_BL##treatment, ///
	absorb(randomization_cohort2)  vce(cluster file_nbr)
est sto attrit

			
test c.age_BL#1.treatment 1.single#1.treatment 1.married#1.treatment ///
	1.divorced_separated#1.treatment 1.husb_influence_kids#1.treatment   ///
	1.one_child_BL#1.treatment 1.mult_children_BL#1.treatment c.hh_more18_w#1.treatment ///
	1.owns_car_BL#1.treatment 2.cars_num#1.treatment 3.cars_num#1.treatment ///
	4.cars_num#1.treatment 5.cars_num#1.treatment 1.driving_likely_BL#1.treatment  ///
	1.elementary_BL#1.treatment 1.highschool_BL#1.treatment 1.any_tertiary_edu_BL#1.treatment  ///
	1.employed_BL#1.treatment 1.unemployed_BL#1.treatment 1.on_job_search_BL#1.treatment ///
	1.ever_employed_BL#1.treatment  c.work_experience_BL#1.treatment 
	
estadd scalar fval = `r(F)'
estadd scalar f_pval = `r(p)' 

	esttab attrit ///
		using "$output_rct/robustness/Joint_test_BL_char_differential_attrition_by_treatment.tex", ///
		label se scalars("fval F-test" "f_pval Prob $>$ F" ) ///
		nogaps nobaselevels keep(1.treatment#c.age_BL 1.single#1.treatment 1.married#1.treatment ///
	1.divorced_separated#1.treatment 1.husb_influence_kids#1.treatment   ///
	1.one_child_BL#1.treatment 1.mult_children_BL#1.treatment 1.treatment#c.hh_more18_w ///
	1.owns_car_BL#1.treatment 2.cars_num#1.treatment 3.cars_num#1.treatment ///
	4.cars_num#1.treatment 5.cars_num#1.treatment 1.driving_likely_BL#1.treatment  ///
	1.elementary_BL#1.treatment 1.highschool_BL#1.treatment 1.any_tertiary_edu_BL#1.treatment  ///
	1.employed_BL#1.treatment 1.unemployed_BL#1.treatment 1.on_job_search_BL#1.treatment ///
	1.ever_employed_BL#1.treatment  1.treatment#c.work_experience_BL ) ///
		b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		replace  varwidth(25) modelwidth(12) fragment nonotes
 
