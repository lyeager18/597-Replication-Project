/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table B3, Panel A	-	Job search; multiple hypothessis testing 
									HTE (Has husband/co-parent)
								  
								  
TABLE FOOTNOTES: Variations in sample size are due to drop-off from telephone survey; 
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
	global 	hte_outcome employed_w3 unemployed_w3 empl_jobsearch_w3
						
* Relabel vars for table output
	lab var	husb_influence_kids "Has husband/co-parent"


* Run models
			   
		* Run and store p-vals for FDR
		foreach outcome of global hte_outcome {
		
			reghdfe `outcome' treatment##i.husb_influence_kids  $controls_HTEhusb, ///
				absorb(randomization_cohort2)  vce(cluster file_nbr)
			
			* Store P-values for MHT
			
				* Beta 1
				test 1.treatment = 0 
				local p_`outcome'_b1 = r(p)
					
				* Beta 1 + Beta 3
				test 1.treatment + 1.treatment#1.husb_influence_kids = 0 
				local p_`outcome'_b13 = r(p)
		}
		
		mat pval_b1 = (`p_employed_w3_b1' \ `p_unemployed_w3_b1' \ `p_empl_jobsearch_w3_b1')
		mat pval_b13 = (`p_employed_w3_b13' \ `p_unemployed_w3_b13' \ `p_empl_jobsearch_w3_b13')
			
		* To check these:
		di "pvals for beta 1:"
		mat list pval_b1
		di "pvals for  beta 1 + beta 3:"
		mat list pval_b13
		
		* Generate q-vals
		preserve
			foreach i in 1 13 {
					
				mat pval = pval_b`i'
				clear
				do "$rep_code/tables/Appendix Tables/Appendix B/Anderson_2008_fdr_sharpened_qvalues.do"
				mat qval_b`i' = qval
			}
			
			* To check these:
			di "qvals for beta 1:"
			mat list qval_b1
			di "qvals for  beta 1 + beta 3:"
			mat list qval_b13

		restore
		
		* RE-RUN  MODELS FOR HAS HUSBAND/CO-PAR - STORE ESTIMATES
		local q = 1 		// row of q-val corresponding to outcome
		foreach outcome of global hte_outcome {
		
			reghdfe `outcome' treatment##i.husb_influence_kids  $controls_HTEhusb, ///
				absorb(randomization_cohort2)  vce(cluster file_nbr)
			eststo `outcome'_inf
			
			* p-val - treatment 
			test _b[1.treatment] =0
			estadd scalar b1 = r(p)
					 
			* p-val -  treatment + treatment x has husband/co-parent
			test _b[1.treatment] + _b[1.treatment#1.husb_influence_kids]=0
			estadd scalar b1_b3 = r(p)
			
			* Store total effect for outcomes in Panel B			
			lincom 1.treatment + 1.treatment#1.husb_influence_kids				
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
			sum `outcome' if e(sample) & treatment==0 & husb_influence_kids==0
			estadd scalar cmean_hte = r(mean)
				 
			* Q-values
			estadd scalar qval_b1 = qval_b1[`q',1]			// beta 1
			estadd scalar qval_b13 = qval_b13[`q',1]		// beta 1 + beta 3
			local q = `q' + 1
		}
		
		
* Write to latex
	
* TABLE B3
	  
				
	* PANEL A - Has husband/co-parent		 
	esttab employed_w3_inf unemployed_w3_inf empl_jobsearch_w3_inf using ///
		"$output_rct/Table_B3_Panel_A.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *husb_influence_kids) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Employed}" ///
				"\shortstack{Unemployed}" ///
				"\shortstack{On the job\\search}") ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.husb_influence_kids "$\beta\textsubscript{2}$: Has husband/co-parent" ///
		1.treatment#1.husb_influence_kids ///
		"$\beta\textsubscript{3}$: Treatment x Has husband/co-parent") ///	
		replace   fragment nonotes 
//		scalars("htevar HTE Specification") ///
			
			
		 * Add total effects	
		esttab employed_w3_inf unemployed_w3_inf empl_jobsearch_w3_inf using ///
		"$output_rct/Table_B3_Panel_A.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab employed_w3_inf unemployed_w3_inf empl_jobsearch_w3_inf using ///
		"$output_rct/Table_B3_Panel_A.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte b1 qval_b1 b1_b3 qval_b13, ///
				labels("Observations" "Mean: Control, No husband/co-parent" ///
						"P-value $\beta\textsubscript{1} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} = 0$" ///
						"P-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$" ///
						"FDR Q-value $\beta\textsubscript{1} + \beta\textsubscript{3} = 0$") ///
				fmt(0 %9.3f %9.3f))

	