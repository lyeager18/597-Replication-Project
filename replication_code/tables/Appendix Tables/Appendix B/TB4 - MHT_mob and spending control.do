/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table B4	-	Ability to leave the house, Ability to make purchases;
							multiple hypothesis testing



Table footnotes: Outcomes were constructed as follows: respondents were asked to 
rate their level of agreement (on a 5 point Likert scale) with the following 
statements: "If I wanted to meet with a friend outside of my home, I could do 
so without seeking approval / permission from anyone in my household first" and 
"I can make a purchase of 1000 SAR without needing to take permission from any 
member of my family" (1000 SAR is roughly equivalent to 265 USD, in 2021 dollars). 
Responses were transformed into binary indicators for above median response. 
Variations in sample size are due to drop-off from telephone survey; order of 
survey modules was randomized. All estimates include individual and household 
controls: age (above median dummy), education level (less than a high school degree), 
marital status (indicators for married, never-married, and widowed), household size 
(number of members), number of cars owned (indicators for one car and for more than 
one car), an indicator for baseline labor force participation, and strata fixed
effects. SEs are clustered at household level. We replace missing control values 
with 0 and include missing dummies for each. * p < 0.1 ** p < 0.05 *** p < 0.01
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"



* Set global for table outcomes

	* likert/cts version
	global 	mob_spen  G1_2_abovemed G1_3_abovemed 
			

* Run models	
		*  Run first for q-vals: Cohort FEs, PAP controls, baseline employment
		foreach var in $mob_spen {	

			reghdfe `var' treatment  $controls if endline_start_w3==1, ///
			absorb(randomization_cohort2   )  vce(cluster file_nbr)
					
			* Store P-value for MHT
			test treatment = 0 
			local p_`var' = `r(p)'
	
		}	
		
		preserve
		mat pval = (`p_G1_2_abovemed' \ `p_G1_3_abovemed')
		
		clear
		do "$rep_code/tables/Appendix Tables/Appendix B/Anderson_2008_fdr_sharpened_qvalues.do"
		restore
		
		*  Now re-run to store for table: Cohort FEs, PAP controls, baseline employment
		local i = 1 		// set local to pull qval from matrix
		foreach var in $mob_spen {	
			
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
			
			* Q-value
			estadd scalar qval = qval[`i',1]
			local i = `i' + 1
	
		}
			
	

* Write to latex


	esttab $mob_spen using ///
	"$output_rct/Table_B4.tex", ///
	label se nonotes keep(*treatment) ///
	scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$" ///
	"qval FDR Q-value $\beta = 0$") ///
	b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
	mtitles("\shortstack{Allowed to\\leave house\\w/o permission}" ///
		"\shortstack{Allowed to\\make purchase\\w/o permission}") ///
	varwidth(75) modelwidth(15) fragment nobaselevels nogaps replace 
	
	
