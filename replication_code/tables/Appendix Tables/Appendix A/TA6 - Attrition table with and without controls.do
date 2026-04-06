/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table A6	- 	Attrition (with and without controls)
				
Table footnotes: Dependent variables are indicators for whether the respondent 
began the respective module in the survey; the order of modules was randomized. 
Estimates in even numbered columns include individual and household controls: age 
(above median dummy), education level (less than a high school degree), marital 
status (indicators for married, never-married, and widowed), household size
(number of members), number of cars owned (indicators for one car and for more 
than one car), an indicator for baseline labor force participation, and strata 
fixed effects. SEs are clustered at household level. We replace missing control 
values with 0 and include missing dummies for each. * p < 0.1 ** p < 0.05 *** 
p < 0.01	
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear 


* RUN THESE DO FILES FIRST:
	
	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"


* Set global for module start indicators
	global attrition endline_start_w3 mobility_modstart employ_modstart attitudes_modstart   

	
* Run attrition models

	* Without controls
	foreach var of global attrition {
		reg `var' treatment, vce(cluster file_nbr)
		eststo `var'_noc
		
		* grab control mean
		sum `var' if treatment==0
		estadd scalar cmean = r(mean)
		
		}

	* With controls
	foreach var of global attrition {
		reg `var' treatment $controls, vce(cluster file_nbr)
		eststo `var'_c
		
		* grab control mean
		sum `var' if treatment==0
		estadd scalar cmean = r(mean)
		
		* indicate that the specification includes controls
		estadd	local controls "X"
		
		}

		
* write table to latex	
		esttab endline_start_w3_noc endline_start_w3_c mobility_modstart_noc ///
		mobility_modstart_c employ_modstart_noc ///
		employ_modstart_c attitudes_modstart_noc attitudes_modstart_c ///
		using "$output_descr/tables/Table_A6.tex", ///
		label se scalars("cmean Control Group Mean" "controls Controls") nogaps nobaselevels ///
		keep(treatment) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) nonotes ///
		mgroups("Started Endline Survey" "Started Mobility Module" "Started Employment Module" ///
		"Started Attitudes Module", pattern(1 0 1 0 1 0 1 0) ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		replace fragment varwidth(25) modelwidth(12) nomtitles
		 
	