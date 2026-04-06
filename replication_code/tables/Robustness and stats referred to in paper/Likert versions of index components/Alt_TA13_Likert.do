/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness	 - 	Alternate Table A13; Approval of gender policy; index 
							and index components; Likert version

									
Table footnotes: Alternate version of Table A13, where we use the full likert 
scale to generate the index outcomes. Outcomes in Columns 2 and 3 were constructed 
as follows: respondents were asked to rate their level of agreement (using
a 5 point Likert scale from `completely disagree' to `completely agree') with the 
statements "I think the government is working enough/working fast enough to make 
changes to give women the same rights as men." and "In my day to day life, I feel 
the impact of the changes that the government is making to give women the same 
rights as men". The wording of the statement "I think the government is working 
enough/working fast enough to make changes to give women the same rights as men" 
was modified after data collection began due to sensitivity of the original wording. 
It was updated to "I think the pace of social changes that Saudi society has been 
witnessing is fast enough to give women the same rights as men and doesn't need 
to move faster." We combine responses from both versions to create the outcome 
in Column 2, and include an indicator for question version as a control in that 
model. The outcome in Column (1) is a weighted index of the standardized responses 
to each statement using the swindex command developed by Schwab et al. (2020). 
All estimates include individual and household controls: age (above median dummy),
education level (less than a highschool degree), marital status (indicators for 
married, never-married, and widowed), household size (number of members), number 
of cars owned (indicators for one car and for more than one car), an indicator 
for baseline labor force participation, and randomization cohort fixed effects. 
SEs are clustered at household level. We impute for missing control values and 
include missing dummies for each. Variations in sample size are due to drop-off 
from telephone survey; order of survey modules was randomized. 
* p < 0.1 ** p < 0.05 *** p < 0.01			
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"


* Restrict data to main follow up
	keep if endline_start_w3==1
	


* Set global for table outcomes
	global genpol gen_policy_sw P1_2_likert
			
* Run models
	
		* (1) Cohort FEs, PAP controls
			foreach var in $genpol {		

				reghdfe `var' treatment $controls, absorb(randomization_cohort2) ///
				vce(cluster file_nbr)
				eststo `var'
				
				* grab control mean
				sum `var' if e(sample) & treatment==0
				estadd scalar cmean = r(mean)	
				
				* grab beta/control mean
				local beta: display %4.3f _b[treatment]
				local cmean: display %4.3f r(mean)
				estadd scalar b_cmean = `beta'/`cmean'
				
				* P-value 
				test treatment = 0 
				estadd scalar pval = `r(p)' 	

			}
			
			
			/* (2) "Society moving fast enough" - this qn was modified part way through
				data collection, so we add a dummy for question timing	*/
				
			
				reghdfe Combined_P1_1_likert treatment question_timing $controls, ///
					absorb(randomization_cohort2) vce(cluster file_nbr)
					eststo Combined_P1_1_likert

				* grab control mean
				sum Combined_P1_1_likert if e(sample) & treatment==0
				estadd scalar cmean = r(mean)	
				
				* grab beta/control mean
				local beta: display %4.3f _b[treatment]
				local cmean: display %4.3f r(mean)
				estadd scalar b_cmean = `beta'/`cmean'
				
				* P-value 
				test treatment = 0 
				estadd scalar pval = `r(p)' 	
				
				

* Write to latex
		esttab gen_policy_sw Combined_P1_1_likert P1_2_likert ///
		using "$output_rct/robustness/Alt_Table_A13_Likert.tex", ///
		label se nonotes keep( treatment) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
		scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
		mtitles("\shortstack{Index: Approval\\of Gender Policy}" ///
		"\shortstack{Government is\\working fast\\enough to give\\women same\\rights as men}" ///	 
		"\shortstack{Feels the impact\\of changes that\\government is\\making to give\\women same rights}") ///
		mgroups("Index" "Index Components", pattern(1 1 0) ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		replace fragment modelwidth(25) varwidth(25) nogaps
		
	

	