/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose:	Table A9, Panel C	- 	Permissions (leave house and make purchase) and 
									second order attitudes with Lee bounds. No strata FEs; 
									no controls
	
Table footnotes: Outcome variables are constructed as described in the notes for 
Table 1 and A12. Variations in sample size are due to drop-off from telephone 
survey; order of survey modules was randomized. Because our strata are small, 
Lee bounds are unstable with the strata and control variables in our preferred 
specification, so this table includes the main point estimate and the bounds 
estimated with no controls or fixed effects. SEs are clustered at the household 
level. * p < 0.1 ** p < 0.05 *** p < 0.01.	
	
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	

	
* Set global for table outcomes
	global 	permissions_2ndattitudes G1_2_abovemed G1_3_abovemed ///
			ga2nd_fcom_binary_sw ga2nd_allmen_binary_sw
			
	* For Leebounds
	global 	permissions_2ndattitudes_lee G1_2_abovemed_lee G1_3_abovemed_lee ///
			ga2nd_fcom_binary_sw_lee ga2nd_allmen_binary_sw_lee
			

	
* Run models
	
		* (1) Strata FEs, PAP controls, baseline employment
		foreach var of global permissions_2ndattitudes {		

			reg `var' treatment if endline_start_w3==1, vce(cluster file_nbr) 
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
			
			* Now run leebounds
			bootstrap, rep(50) seed(123) cluster(file_nbr) : leebounds `var' treatment 
			 //,  tight( randomization_cohort2)
			 eststo `var'_lee 
			
			}
			


* Write to latex

	esttab $permissions_2ndattitudes using ///
	"$output_rct/Table_A9_Panel_C.tex", ///
	label se nonotes keep(*treatment) ///
	scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
	b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
	mtitles("\shortstack{Allowed to\\leave house\\w/o permission}" ///
		"\shortstack{Allowed to\\make purchase\\w/o permission}" ///
		"\shortstack{Female Social\\Network}" "\shortstack{Male Social\\Network}") ///
	mgroups("\shortstack{Agreement with the\\following statements}" ///
	"\shortstack{Indices: Second order attitudes\\towards women working}", pattern(1 0 1 0) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	varwidth(75) modelwidth(15) fragment nobaselevels nogaps replace 
	
	esttab	$permissions_2ndattitudes_lee using ///
		"$output_rct/Table_A9_Panel_C_Lee.tex", ///
		nomtitles nodepvars nolines ///
		replace star(* .1 ** .05 *** .01) se t(4) b(4) label ///
		nonotes nonum fragment nogaps nobaselevels scalar("N Observations")
	

