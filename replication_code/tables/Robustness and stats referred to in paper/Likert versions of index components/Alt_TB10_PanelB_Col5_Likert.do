/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness 	- 	Alternate Table B10, Panel B, Column 5; Own Attitudes
							index; Likert version
	
Table footnotes: Alternate version of Table B10, Panel B, Column 5, where we use 
the full likert scale to generate the index outcome. Outcome variables are 
constructed as described in the notes for Table 1, except that this version does 
not transform responses into binary indicators for above median response. Variations 
in sample size are due to drop-off from telephone survey; order of survey modules 
was randomized. All estimates include individual and household controls: age 
(above median dummy), education level (less than a high school degree), marital 
status (indicators for married, never-married, and widowed), household size (number
of members), number of cars owned (indicators for one car and for more than one 
car), an indicator for baseline labor force participation, and fixed effects for 
sub-strata (as described in Section 3, Footnote 11 of the paper). SEs are clustered 
at household level. We replace missing control values with 0 and include missing 
dummies for each.  * p $<$ 0.1 ** p $<$ 0.05 *** p $<$ 0.01
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

	
	global 	lab  ga_1st_order_likert_sw 
	
* Run models
	
		* (1) Strata FEs, PAP controls, baseline employment
		foreach var in  $lab {		

			reghdfe `var' treatment  $controls, ///
			absorb(group_strata)  vce(cluster file_nbr)
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

		esttab $lab using ///
		"$output_rct/robustness/Alt_Table_B10_Panel_B_Column_5_Likert.tex", ///
		label se nonotes scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
		nobaselevels nonotes keep(treatment) ///
		nogaps nobaselevels b(%9.3f) se(%9.3f) ///
		star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Index: Own\\attitudes towards\\women working}") ///
		fragment varwidth(25) modelwidth(15) replace
		
		
