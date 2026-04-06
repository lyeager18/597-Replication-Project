/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose:	Robustness 	-  Employment and with/without ability to spend; HTE 
						   (has husband/co-parent)



Table footnotes: This table adds an additional robustness check addressing the 
possible alternative mechanism that withdrawing from the labor force leaves married 
and divorced women with less spending autonomy simply because they have lost their 
source of independent income (discussed in section 5.3). The table shows that for 
the group with a husband/co-parent, the treatment induces a decrease in permission 
to spend without any corresponding change in the probability of work (columns 3-4). 
Outcomes are dummies for whether, at endline, the respondent was employed and 
whether she was able to make a purchase of SAR 1000 without needing permission. 
Variations in sample size are due to drop-off from telephone survey; order of 
survey modules was randomized. All estimates include individual and household 
controls: age (above median dummy), education level (less than a highschool 
degree), household size (number of members), number of cars owned (indicators for 
one car and for more than one car), an indicator for baseline labor force 
participation, and randomization cohort fixed effects. SEs are clustered at 
household level. We impute for missing control values and include missing dummies 
for each, except for the interaction control. * p < 0.1 ** p < 0.05 *** p < 0.01.					   				
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"
	
* Create dummies for employed/able to spend subgroups
gen work_spend = 0 if employed_w3!=. & G1_3_abovemed!=.
replace work_spend = 1 if employed_w3==1 & G1_3_abovemed==1
lab var work_spend "Working at EL, able to spend"

gen work_nospend = 0 if employed_w3!=. & G1_3_abovemed!=.
replace work_nospend = 1 if employed_w3==1 & G1_3_abovemed==0
lab var work_nospend "Working at EL, not able to spend"


gen nowork_spend = 0 if employed_w3!=. & G1_3_abovemed!=.
replace nowork_spend = 1 if employed_w3==0 & G1_3_abovemed==1
lab var nowork_spend "Not working at EL, able to spend"


gen nowork_nospend = 0 if employed_w3!=. & G1_3_abovemed!=.
replace nowork_nospend = 1 if employed_w3==0 & G1_3_abovemed==0
lab var nowork_nospend "Not working at EL, not able to spend"


* Set global for table outcomes

	
	global 	outcomes work_spend work_nospend nowork_spend nowork_nospend
	
	global 	outcomes_hte work_spend_hte work_nospend_hte nowork_spend_hte nowork_nospend_hte


* Run models	
	* (1) Cohort FEs, PAP controls, baseline employment
	foreach var in $outcomes {		
		
		* interacted with husb/co-par
			reghdfe `var' treatment##i.husb_influence_kids $controls_HTEhusb, ///
			absorb(randomization_cohort2 )  vce(cluster file_nbr)
			eststo `var'_hte
			
			* Store total effect 		
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
			sum `var' if e(sample) & treatment==0 & husb_influence_kids==0
			estadd scalar cmean_nohus = r(mean)
			
			sum `var' if e(sample) & treatment==0 & husb_influence_kids==1
			estadd scalar cmean_hus = r(mean)			

		}
			
	

* Write to latex

	* interacted with husb/co-par		 
	esttab 	$outcomes_hte using ///
		"$output_rct/robustness/Working and ability to spend_HTE_husb-co-par_`c(current_date)'.tex", ///
		label se nogaps nobaselevels ///
		keep(*treatment *husb_influence_kids) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Working,\\able to spend}" ///
			"\shortstack{Working,\\not able to\\spend}" ///
			"\shortstack{Not working,\\able to spend}" ///
			"\shortstack{Not working,\\not able to\\spend}") ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
			1.husb_influence_kids "$\beta\textsubscript{2}$: Has husband/co-parent" ///
			1.treatment#1.husb_influence_kids ///
		"$\beta\textsubscript{3}$: Treatment x Has husband/co-parent") ///
		replace  varwidth(25) modelwidth(12) fragment nonotes noobs
		 
		* Add total effects	
		esttab	$outcomes_hte using ///
			"$output_rct/robustness/Working and ability to spend_HTE_husb-co-par_`c(current_date)'.tex", ///
			append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
			cells(none) stats(total_eff_b total_eff_se, ///
			labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab	$outcomes_hte using ///
			"$output_rct/robustness/Working and ability to spend_HTE_husb-co-par_`c(current_date)'.tex", ///
			append fragment nomtitles nonumbers noconstant noobs  nonotes  ///
			cells(none) stats(N  cmean_nohus cmean_hus, labels("Observations" ///
			"Mean: Control, no husband/co-parent" ///
			"Mean: Control, has husband/co-parent") ///
			fmt(0 %9.3f %9.3f))
	

	
