/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		Robustness	-	Table 1, Panel C; Ability to leave the house, 
								Ability to make purchases, Attitudes towards women 
								working (female and male social networks); Likert
								versions

Table footnotes: This table is an alternate version of Table 1 Panel C in the paper,
where we use the full likert scale to generate the index outcome. In Columns 
1 and 2, respondents were asked to rate their level of agreement (on a 5 point 
Likert scale) with the following statements: "If I wanted to meet with a friend 
outside of my home, I could do so without seeking approval / permission from anyone 
in my household first" and "I can make a purchase of 1000 SAR without needing to 
take permission from any member of my family" (1000 SAR is roughly equivalent to 
265 USD, in 2021 dollars), respectively. In Columns 3 and 4, respondents 
were asked to think about a group and report what share of that group (`none`, 
`a minority', `about half', `a majority', or `all') they think would `somewhat' 
or `completely' agree with the following statements: `Women can be equally good 
business executives', `It's ok for a woman to have priorities outside the home', 
and `Children are OK if a mother works'. Second order beliefs questions are indexed 
for one female reference group (female community members) in Column 3 and two male 
reference groups: male family members and male community members in Column 4. 
Variations in sample size are due to drop-off 
from telephone survey; order of survey modules was randomized. All estimates 
include individual and household controls: age (above median dummy), education 
level (less than a high school degree), marital status (indicators for married,
never-married, and widowed), household size (number of members), number of cars 
owned (indicators for one car and for more than one car), an indicator for baseline 
labor force participation, and strata fixed effects. SEs are clustered at household 
level. We replace missing control values with 0 and include missing dummies for 
each. * p < 0.1 ** p < 0.05 *** p < 0.01					   				
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

	* likert/cts version
	global 	permission_attitudes G1_2_likert G1_3_likert ///
			ga2nd_fcom_likert_sw ga2nd_allmen_likert_sw
			

* Run models	
		* Cohort FEs, PAP controls, baseline employment
		foreach var in $permission_attitudes {		

			reghdfe `var' treatment  $controls , ///
			absorb(randomization_cohort2  )  vce(cluster file_nbr)
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
			
	

* Write to latex


	esttab $permission_attitudes using ///
	"$output_rct/robustness/Alt_Table_1_Panel_C_Likert.tex", ///
	label se nonotes keep(*treatment) ///
	scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
	b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
	mtitles("\shortstack{Allowed to leave\\the house without\\permission}" ///
		"\shortstack{Allowed to make\\purchase without\\permission}" ///
		"\shortstack{Female Social\\Network}" "\shortstack{Male Social\\Network}") ///
	mgroups("Agreement with the following statements" ///
	"\shortstack{Indices: Second order attitudes\\towards women working}", pattern(1 0 1 0) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	varwidth(75) modelwidth(15) fragment nobaselevels nogaps replace 
	
