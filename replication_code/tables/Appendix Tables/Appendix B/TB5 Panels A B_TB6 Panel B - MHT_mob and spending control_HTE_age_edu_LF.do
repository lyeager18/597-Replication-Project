/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table B5, Panels A & B; Table B6, Panel B	-	Ability to leave the 
															house, Ability to make 
															purchases; multiple 
															hypothesis testing; 
															multiple HTE
								  
								  
TABLE FOOTNOTES:						
Table B5: Variations in sample size are due to drop-off from telephone 
survey; order of survey modules was randomized. Outcomes are defined as described 
in Table 1. All estimates include individual and household controls: age (above 
median dummy), education level (less than a high school degree), marital status 
(indicators for married, never-married, and widowed), household size (number of 
members), number of cars owned (indicators for one car and for more than one car), 
an indicator for baseline labor force participation, and strata fixed effects.
SEs are clustered at household level. We replace missing control values with 0 
and include missing dummies for each, except for the interaction control. As such, 
some Ns are lower relative to Table 1. 10 respondents are missing values for 
education level at baseline, with some overlap in respondents who are also missing 
values for outcomes. Four respondents are missing values marital status. * p < 0.1 
** p < 0.05 *** p < 0.01	

Table B6: Variations in sample size are due to drop-off from telephone survey; 
order of survey modules was randomized. Outcomes are defined as described in Table 
1. All estimates include individual and household controls: age (above median dummy), 
education level (less than a high school degree), household size (number of members), 
number of cars owned (indicators for one car and for more than one car), an
indicator for baseline labor force participation, and strata fixed effects. SEs 
are clustered at household level. We replace missing control values with 0 and 
include missing dummies for each, except for the interaction control. As such, 
Ns are lower relative to Table 1. Four respondents are missing values for marital 
status (and therefore missing values for whether they have a husband or co-parent), 
and one respondent is missing a value for labor force participation at baseline. 
* p < 0.1 ** p < 0.05 *** p < 0.01.
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
* Restrict data to main follow up
	keep if endline_start_w3==1

	
* Set global for table outcomes
	global 	hte_outcome G1_2_abovemed G1_3_abovemed 

	global	hte_var age_med_BL edu_nohs_BL LF_BL 
			
			
			
			
* Relabel vars for table output
	lab var	LF_BL "In LF at BL"
	lab var	age_med_BL "Above median age" 
	lab var	edu_nohs_BL "Less than HS"

* Run models
			   
		* (1) RUN MODELS FOR ALL HTE EXCEPT HAS HUSBAND/CO-PAR AND MARITAL STATUS
		
		* set local to call missing tags
		local age_med_BL_miss miss_age_PAP
		local edu_nohs_BL_miss miss_edu_category
		local LF_BL_miss miss_LF_BL
		
		* Run and store p-vals for FDR
		local i = 1
		foreach hte of global hte_var {
			
			* create a var with a standardized name for HTE var so that estimates 
			// show up in same row in table
			gen hte = `hte' if ``hte'_miss' == 0
				
			foreach outcome of global hte_outcome {

				reghdfe `outcome' treatment##hte ${controls_`hte'}, ///
				absorb(randomization_cohort2 )  vce(cluster file_nbr)
				
				* Store P-values for MHT
				
					* Beta 1
					test 1.treatment = 0 
					local p_`outcome'_b1 = r(p)
					
					* Beta 3
					test 1.treatment + 1.treatment#1.hte = 0 
					local p_`outcome'_b13 = r(p)
				

				}
				
			local i = `i' + 1
			drop hte
			
			mat `hte'_pval_b1 = (`p_G1_2_abovemed_b1' \ `p_G1_3_abovemed_b1')
			mat `hte'_pval_b13 = (`p_G1_2_abovemed_b13' \ `p_G1_3_abovemed_b13')
			
			* To check these:
			di "`hte' pvals for beta 1:"
			mat list `hte'_pval_b1
			di "`hte' pvals for  beta 1 + beta 3:"
			mat list `hte'_pval_b13
			
			}

		* Generate q-vals
		preserve
			foreach hte of global hte_var {
				foreach i in 1 13 {
					
					mat pval = `hte'_pval_b`i'
					clear
					do "$rep_code/tables/Appendix Tables/Appendix B/Anderson_2008_fdr_sharpened_qvalues.do"
					mat `hte'_qval_b`i' = qval
				}
			* To check these:
			di "`hte' qvals for beta 1:"
			mat list `hte'_qval_b1
			di "`hte' qvals for  beta 1 + beta 3:"
			mat list `hte'_qval_b13
			}
		restore
		
		* Re-run models and store scalars
		local i = 1	
		foreach hte of global hte_var {
			
			* create a var with a standardized name for HTE var so that estimates 
			// show up in same row in table
			gen hte = `hte' if ``hte'_miss' == 0
			
			local q = 1			// row of q-val corresponding to outcome
			foreach outcome of global hte_outcome {

				reghdfe `outcome' treatment##hte ${controls_`hte'}, ///
				absorb(randomization_cohort2 )  vce(cluster file_nbr)
				eststo `outcome'_hte`i'
				
				* p-val - treatment 
				test _b[1.treatment] =0
				estadd scalar b1 = r(p)
					 
				* p-val -  treatment + treatment x hte var
				test _b[1.treatment] + _b[1.treatment#1.hte]=0
				estadd scalar b1_b3 = r(p)
				
				* Store total effect for outcomes in Panel B			
				lincom 1.treatment + 1.treatment#1.hte				
				local totaleff: di %9.3f `r(estimate)'
				if `r(p)' < 0.01 {
				local star "\sym{***}"
				}
				else if `r(p)' < 0.05 {
				local star "\sym{**}"
				}
				else if `r(p)' < 0.1 {
				local star "\sym{*}"
				}
				else {
					local star ""
				}
				estadd local total_eff_b  "`totaleff'`star'"
				local aux_se: display %5.3f `r(se)'
				estadd local total_eff_se "(`aux_se')"
			
				
				* grab control means for each subgroup
				sum `outcome' if e(sample) & treatment==0 & hte==0
				estadd scalar cmean_hte = r(mean)
				
				* Q-values
				estadd scalar qval_b1 = `hte'_qval_b1[`q',1]			// beta 1
				estadd scalar qval_b13 = `hte'_qval_b13[`q',1]			// beta 1 + beta 3
				local q = `q' + 1
				

				}
				
			local i = `i' + 1
			drop hte
			}
			
			
		
		  

		   
* Write to latex
	* TABLE B5
	* PANEL A - AGE
	esttab G1_2_abovemed_hte1  G1_3_abovemed_hte1 using ///
		"$output_rct/Table_B5_Panel_A.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *hte) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Allowed to\\leave house\\w/o permission}" ///
		"\shortstack{Allowed to\\make purchase\\w/o permission}") ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.hte "$\beta\textsubscript{2}$: Above median age" ///
		1.treatment#1.hte "$\beta\textsubscript{3}$: Treatment x Above median age") ///	
		replace   fragment nonotes 
		//		scalars("htevar HTE Specification") ///	
			
		 * Add total effects	
		esttab 	G1_2_abovemed_hte1  G1_3_abovemed_hte1 using ///
		"$output_rct/Table_B5_Panel_A.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, p-val/q-val for test that total effect is different from zero 
		esttab	G1_2_abovemed_hte1  G1_3_abovemed_hte1 using ///
		"$output_rct/Table_B5_Panel_A.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte b1 qval_b1 b1_b3 qval_b13, ///
				labels("Observations" "Mean: Control, Below median age" ///
						"P-value $\beta\textsubscript{1} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} = 0$" ///
						"P-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$") ///
				fmt(0 %9.3f %9.3f))
				
	* PANEL B - EDU		 
	esttab G1_2_abovemed_hte2  G1_3_abovemed_hte2 using ///
		"$output_rct/Table_B5_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *hte) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		nomtitles ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.hte "$\beta\textsubscript{2}$: Less than HS" ///
		1.treatment#1.hte "$\beta\textsubscript{3}$: Treatment x Less than HS") ///	
		replace  fragment nonotes 
//		scalars("htevar HTE Specification") ///
			
			
		 * Add total effects	
		esttab G1_2_abovemed_hte2  G1_3_abovemed_hte2 using ///
		"$output_rct/Table_B5_Panel_B.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab G1_2_abovemed_hte2  G1_3_abovemed_hte2 using ///
		"$output_rct/Table_B5_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte b1 qval_b1 b1_b3 qval_b13, ///
				labels("Observations" "Mean: Control, Completed HS" ///
						"P-value $\beta\textsubscript{1} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} = 0$" ///
						"P-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$") ///
				fmt(0 %9.3f %9.3f))
				
		

* TABLE B6
	
		* PANEL B - In LF at BL 		 
	esttab G1_2_abovemed_hte3  G1_3_abovemed_hte3 using ///
		"$output_rct/Table_B6_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *hte) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		nomtitles ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.hte "$\beta\textsubscript{2}$: In LF at BL" ///
		1.treatment#1.hte "$\beta\textsubscript{3}$: Treatment x In LF at BL") ///	
		replace   fragment nonotes 
//		scalars("htevar HTE Specification") ///
			
			
		 * Add total effects	
		esttab G1_2_abovemed_hte3  G1_3_abovemed_hte3 using ///
		"$output_rct/Table_B6_Panel_B.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab G1_2_abovemed_hte3  G1_3_abovemed_hte3 using ///
		"$output_rct/Table_B6_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte b1 qval_b1 b1_b3 qval_b13, ///
				labels("Observations" "Mean: Control, Out of LF at BL" ///
						"P-value $\beta\textsubscript{1} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} = 0$" ///
						"P-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$") ///
				fmt(0 %9.3f %9.3f))
					
	