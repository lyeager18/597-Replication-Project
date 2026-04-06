/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness 	- 	Alternate Table 3, Panel A; Inclusion of marital 
							status dummies
							
Table Footnotes: This is an alternate version of Table 3, Panel A, where we include
marital status controls (they are not included in our main specifications for this
Panel because of collinearity with the Has Husband/Co-Parent indicator that is 
interacted in the model.) Variations in sample size are due to drop-off from telephone survey; 
order of survey modules was randomized. Outcomes are defined as described in Table 
1. All estimates include individual and household controls: age (above median 
dummy), education level (less than a high school degree), household size (number 
of members), number of cars owned (indicators for one car and for more than one
car), an indicator for baseline labor force participation, and strata fixed effects. 
SEs are clustered at household level. We replace missing control values with 0 and 
include missing dummies for each, except for the interaction control. As such, Ns 
are lower relative to Table 1. Four respondents are missing values for marital 
status (and therefore missing values for whether they have a husband or co-parent), 
and one respondent is missing a value for labor force participation at baseline. 
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
	
* shorten var name for storage
	rename share_trips_unaccomp_w3 share_unaccomp
	
* Set global for table outcomes
	global hte_outcome license_w3 employed_w3 not_in_LF_w3 G1_3_abovemed

* Run models
			   
		* (1) Cohort FEs, PAP controls, baseline employment, HTE husband influence 	   
		foreach outcome in $hte_outcome {		
			
			reghdfe `outcome' treatment##i.husb_influence_kids  $controls_HTEhusb ///
				single married widowed, absorb(randomization_cohort2)  vce(cluster file_nbr)
			eststo `outcome'
				 
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
		}
		
* Write to latex
	 
	esttab $hte_outcome using ///
		"$output_rct/robustness/Alt_Table_3_Panel_A_MarStatusCtrls.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *husb_influence_kids) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Received\\license}" "\shortstack{Employed}" ///
		"\shortstack{Not in LF}"  ///
		"\shortstack{Allowed to\\make purchase\\w/o permission}") ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.husb_influence_kids "$\beta\textsubscript{2}$: Has husband/co-parent" ///
		1.treatment#1.husb_influence_kids ///
		"$\beta\textsubscript{3}$: Treatment x Has husband/co-parent") ///	
		replace   fragment nonotes 
			
			
		 * Add total effects	
		esttab $hte_outcome using ///
		"$output_rct/robustness/Alt_Table_3_Panel_A_MarStatusCtrls.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		

	