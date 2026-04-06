/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table 1, Panels A & B - Stacked: driving, mobility, labor market outcomes,
									and independent decision making
				
Table footnotes: 
Panel A, Column 5 and 6 outcomes are set to zero for 24 observations in which the 
respondent reported making no trips outside the home in the previous 7 days. The 
outcome in Panel B, Column 4 indicates whether the respondent is employed and 
applied for at least one job in the previous month (a more general measure of 
search beyond job applications was not collected for employed respondents); five
individuals responded to work status but not to the applications measure, 
leading to the variation in sample size between columns. Results for unemployment 
are similar if we redefine unemployed to include only those who applied for at 
least one job in the previous month. The outcomes in Panel B, Columns 5 and 6 and 
in Panel C, Columns 3 and 4 are weighted indices of sets of standardized outcomes 
described as follows using the swindex command developed by Schwab et al. (2020). 
For Panel B, Column 5, respondents were asked to rate their own level of agreement 
(using a 5 point Likert scale) for the following statements: `Women can be equally 
good business executives', `It's ok for a woman to have priorities outside the 
home', `Children are OK if a mother works', `It's OK to put my own needs above 
those of my family', and `The Government should allow a national women's soccer 
team'. Responses were transformed into binary indicators for above median response. 
Respondents were also asked what the ideal age is for a woman to have her first 
child. These outcomes are reported in Table A12, Panel A. For Panel B, Column 6, 
women were asked about the number of people they spoke with and met in the previous 
7 days. These outcomes are reported in Table A12, Panel B. For Panel C, Columns 
1 and 2, respondents were asked to rate their level of agreement (on a 5 point 
Likert scale) with the following statements: "If I wanted to meet with a friend 
outside of my home, I could do so without seeking approval / permission from anyone 
in my household first" and "I can make a purchase of 1000 SAR without needing to 
take permission from any member of my family" (1000 SAR is roughly equivalent to 
265 USD, in 2021 dollars), respectively. Responses were transformed into binary 
indicators for above median response. For Panel C, Columns 3 and 4, respondents 
were asked to think about a group and report what share of that group (`none`, 
`a minority', `about half', `a majority', or `all') they think would `somewhat' 
or `completely' agree with the following statements: `Women can be equally good 
business executives', `It's ok for a woman to have priorities outside the home', 
and `Children are OK if a mother works'. Responses were transformed into binary 
indicators for above median response. Second order beliefs questions are indexed 
for one female reference group (female community members) in Column 3 and two male 
reference groups: male family members and male community members in Column 4. The 
components of the second order attitudes indices are reported in Table A16; in 
Panel B and C of that table, we additionally report the indices separately for male 
family members and male community. Variations in sample size are due to drop-off 
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
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
	
* shorten var name for storage
	rename share_trips_unaccomp_w3 share_unaccomp
	
	
* Set global for table outcomes
	global 	drive_mob s_train_bi_w3 license_w3 drive_any_mo_bi_w3 ///
			M4_1_TEXT share_unaccomp no_trips_unaccomp_w3 
			
	global 	lab employed_w3  unemployed_w3 not_in_LF_w3 ///
			empl_jobsearch_w3 ga_1st_order_binary_sw social_contact_sw
			

* Run models

	*  Cohort FEs, PAP controls, baseline employment
		foreach var in $drive_mob $lab {	

			reghdfe `var' treatment  $controls if endline_start_w3==1, ///
			absorb(randomization_cohort2   )  vce(cluster file_nbr)
			est sto `var'

			
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

	* Panel A: Drive training, license and mobility
		esttab $drive_mob ///
		using "$output_rct/Table_1_Panel_A.tex", ///
		 label se scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
		 nogaps nobaselevels ///
		 keep(treatment) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		 mtitles("\shortstack{Started\\driver's\\training}" ///
		 "\shortstack{Received\\license}" "\shortstack{Any driving in\\past month}" ///
		"\shortstack{Number of\\times left\\house in\\last 7 days}" ///
		"\shortstack{Share of trips\\made without\\male chaperone}" ///
		"\shortstack{Always travels\\with male\\chaperone}") ///
		 replace  varwidth(25) modelwidth(12) fragment nonotes
		 	
			 
	* Panel B: Economic and financial agency
		esttab $lab using ///
		"$output_rct/Table_1_Panel_B.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean"  "pval P-value $\beta = 0$") ///
		nobaselevels keep(treatment) nogaps  b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles( "\shortstack{Employed}" ///
		"\shortstack{Unemployed}" ///
		"\shortstack{Out of\\labor force}" ///
		"\shortstack{On the job\\search}" ///
		"\shortstack{Index: Own\\attitudes\\towards women\\working}" ///
		"\shortstack{Index:\\Social\\contact}") ///
		fragment varwidth(25) modelwidth(15) replace
		
	
		
