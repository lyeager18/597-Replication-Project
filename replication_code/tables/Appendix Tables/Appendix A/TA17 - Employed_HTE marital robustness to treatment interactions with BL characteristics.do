/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table A17	-	Robustness of heterogeneity results (employed) 
							to treatment interactions with BL characteristics
								 

Table footnotes: Column 2 repeats the estimation in Column 1 but additionally 
controls for treatment interacted with the respondent's education, age, and the 
number of children under 18 years old in the household at baseline. `Has 
husband/co-parent' is defined as (a) currently married or (b) divorced/separated 
with children under 18 in the household. Four observations are dropped due to 
missing baseline marital status. In Column 2 an additional 15 observations are 
dropped due to missing administrative data on children in the household, and nine 
additional observations are dropped due to missing education at baseline. This 
causes a difference in sample size to Table 1. Both columns include individual 
and household controls: age (above median dummy), education level (less than a 
high school degree), household size (number of members), number of cars owned 
(indicators for one car and for more than one car), an indicator for baseline 
labor force participation, and strata fixed effects. SEs are clustered at household 
level. We replace missing control values with 0 and include missing dummies for 
each, except for the interaction controls. Marital status dummies are not included 
as a control in this table because they are highly collinear with "has 
husband/co-parent". However, results are similar if we include individual 
indicators as controls for: married; single; and widowed (divorced/separated is 
the reference group). * p < 0.1 ** p < 0.05 *** p < 0.01
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
	
keep if endline_start_w3==1
	
	
* Run models

	* (1) 	Cohort FEs, PAP controls,baseline employment, HTE husband influence
		reghdfe employed_w3 treatment##i.husb_influence_kids $controls_HTEhusb, ///
					absorb(randomization_cohort2)  vce(cluster file_nbr)
		
		eststo  employed_w3_1
		
		test _b[1.treatment] + _b[1.treatment#1.husb_influence_kids]=0
		estadd scalar b1_b3 = r(p)
		
		* grab control mean
		sum 	employed_w3 if e(sample) & treatment==0 & husb_influence_kids==0
		estadd 	scalar cmean = r(mean)	 
		
	/* (2) 	Cohort FEs, PAP controls,baseline employment, HTE husband influence and 
			treatment interactions with edu_category, age_4group, and hh_les18_w
	*/
		reghdfe employed_w3 treatment##i.husb_influence_kids treatment#i.edu_nohs_BL ///
					treatment#i.age_med_BL treatment##hh_les18_w $controls_BLcharinteract, ///
					absorb(randomization_cohort2)  vce(cluster file_nbr)
		
		eststo  employed_w3_2
		estadd	local edu "X"
		estadd	local age "X"
		estadd	local kids "X"
		
		
		
		test _b[1.treatment] + _b[1.treatment#1.husb_influence_kids]=0
		estadd scalar b1_b3 = r(p)
		
		* grab control mean
		sum 	employed_w3 if e(sample) & treatment==0 & husb_influence_kids==0
		estadd 	scalar cmean = r(mean)

	
* Write to latex
	* (1)
	esttab	employed_w3_1 employed_w3_2 using ///
			"$output_rct/Table_A17.tex", se label ///
			scalars("cmean Mean: Control, no husband/co-parent" ///
			"b1_b3 p-val: $\beta$\textsubscript{1} + $\beta$\textsubscript{3} = 0" ///
			"edu Treatment x Education" ///
			"age Treatment x Age" ///
			"kids Treatment x Number of children $<$ 18 in household at baseline") ///
			star(* 0.1 ** 0.05 *** 0.01) tex replace ///
			noomitted nocons nobaselevels mgroups("Employed", pattern(1 0) ///
			prefix(\multicolumn{@span}{c}{) suffix(})   ///
			span erepeat(\cmidrule(lr){@span})) /// ///
			nodepvars nomtitles nonotes nogaps fragment ///
			coeflabels(1.treatment "$\beta$\textsubscript{1}: Treatment" ///
			1.husb_influence_kids "$\beta$\textsubscript{2}: Has husband/co-parent" ///
			1.treatment#1.husb_influence_kids ///
			"$\beta$\textsubscript{3}: Treatment x Has husband/co-parent") ///
		keep(1.treatment 1.husb_influence_kids 1.treatment#1.husb_influence_kids)
	

			

     