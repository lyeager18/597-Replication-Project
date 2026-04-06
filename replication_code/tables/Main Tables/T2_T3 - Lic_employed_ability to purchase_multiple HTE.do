/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		Tables 2 & 3 - 	HTE (AGE, EDU, BL LFP, MARITAL STATUS, HAS 
								HUSBAND/CO-PAR) FOR OUTCOMES: LICENSE, EMPLOYED,
								NOT IN LF, AND ABILITY TO MAKE PURCHASES
								  
								  
Table Footnotes:							 

Table 2: Variations in sample size are due to drop-off from telephone survey; 
order of survey modules was randomized. Outcomes are defined as described in Table 
1. In Panel C the omitted marital status category is divorced women. All estimates 
include individual and household controls: age (above median dummy), education 
level (less than a high school degree), marital status (indicators for married, 
never-married, and widowed), household size (number of members), number of cars 
owned (indicators for one car and for more than one car), an indicator for baseline 
labor force participation, and strata fixed effects. SEs are clustered at household 
level. We replace missing control values with 0 and include missing dummies for 
each, except for the interaction control. As such, some Ns are lower relative to 
Table 1. 10 respondents are missing values for education level at baseline, with 
some overlap in respondents who are also missing values for outcomes. Four 
respondents are missing values marital status. * p < 0.1 ** p < 0.05 *** p < 0.01
								 
Table 3: Variations in sample size are due to drop-off from telephone survey; order 
of survey modules was randomized. Outcomes are defined as described in Table 1. 
`Has husband/co-parent' is defined as (a) currently married or (b) divorced/separated 
with children under 18 in the household. All estimates include individual and 
household controls: age (above median dummy), education level (less than a high 
school degree), household size (number of members), number of cars owned (indicators 
for one car and for more than one car), an indicator for baseline labor force 
participation, and strata fixed effects. SEs are clustered at household level. 
Marital status dummies are not included as a control in Panel A because they are 
highly collinear with "has husband/co-parent". However, results are unchanged if 
we include individual indicators as controls for: never-married, married, and 
widowed (divorced is the reference group).We replace missing control values with 
0 and include missing dummies for each, except for the interaction control. As such, 
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
	global 	hte_outcome license_w3 employed_w3 not_in_LF_w3 G1_3_abovemed
	global	hte_var age_med_BL edu_nohs_BL LF_BL 
			
			
			
			
* Relabel vars for table output
	lab var	LF_BL "In LF at BL"
	lab var	age_med_BL "Above median age" 
	lab var	edu_nohs_BL "Less than HS"
	lab var	husb_influence_kids "Has husband/co-parent"
	lab var rel_status_BL "Marital status at BL"


* Run models
			   
		* (1) RUN MODELS FOR ALL HTE EXCEPT HAS HUSBAND/CO-PAR AND MARITAL STATUS
		
		* set local to call missing tags
		local age_med_BL_miss miss_age_PAP
		local edu_nohs_BL_miss miss_edu_category
		local LF_BL_miss miss_LF_BL
		
		local i = 1
		foreach hte of global hte_var {
			
			* create a var with a standardized name for HTE var so that estimates 
			// show up in same row in table
			gen hte = `hte' if ``hte'_miss' == 0
				
			foreach outcome of global hte_outcome {

				reghdfe `outcome' treatment##hte ${controls_`hte'}, ///
				absorb(randomization_cohort2 )  vce(cluster file_nbr)
				eststo `outcome'_hte`i'
				
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
				

				}
				
			local i = `i' + 1
			drop hte
			}
			
			
		
		
		* (2) RUN MODELS FOR MARITAL STATUS 
		foreach outcome of global hte_outcome {
		
			reghdfe `outcome' treatment##i.rel_status_BL  $controls_HTEhusb, ///
				absorb(randomization_cohort2)  vce(cluster file_nbr)
			eststo `outcome'_mar
				 
			* treatment + treatment x married
			test _b[1.treatment] + _b[1.treatment#2.rel_status_BL]=0
			estadd scalar b1_b5 = r(p)
			
			* treatment + treatment x never-married
			test _b[1.treatment] + _b[1.treatment#3.rel_status_BL]=0
			estadd scalar b1_b6 = r(p)
				
			* treatment + treatment x widowed or no co-parent
			test _b[1.treatment] + _b[1.treatment#4.rel_status_BL]=0
			estadd scalar b1_b7 = r(p)
				
			* grab control means across BL marital status 
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==1
			estadd scalar cmean_div = r(mean)
			
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==2
			estadd scalar cmean_mar = r(mean)
			
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==3
			estadd scalar cmean_sing = r(mean)
	
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==4
			estadd scalar cmean_wid = r(mean)	

		}
		
		* (3) RUN  MODELS FOR HAS HUSBAND/CO-PAR
		foreach outcome of global hte_outcome {
		
			reghdfe `outcome' treatment##i.husb_influence_kids  $controls_HTEhusb, ///
				absorb(randomization_cohort2)  vce(cluster file_nbr)
			eststo `outcome'_inf
				 
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
	* TABLE 2
	* PANEL A - AGE
	esttab license_w3_hte1	employed_w3_hte1 not_in_LF_w3_hte1 ///
		 G1_3_abovemed_hte1 using ///
		"$output_rct/Table_2_Panel_A.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *hte) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Received\\license}" "\shortstack{Employed}" ///
		"\shortstack{Not in LF}"  ///
		"\shortstack{Allowed to\\make purchase\\w/o permission}") ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.hte "$\beta\textsubscript{2}$: Above median age" ///
		1.treatment#1.hte "$\beta\textsubscript{3}$: Treatment x Above median age") ///	
		replace   fragment nonotes 
			
		 * Add total effects	
		esttab license_w3_hte1	employed_w3_hte1 not_in_LF_w3_hte1 ///
		 G1_3_abovemed_hte1 using ///
		"$output_rct/Table_2_Panel_A.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab license_w3_hte1	employed_w3_hte1 not_in_LF_w3_hte1 ///
		 G1_3_abovemed_hte1 using ///
		"$output_rct/Table_2_Panel_A.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte, ///
				labels("Observations" "Mean: Control, Below median age") ///
				fmt(0 %9.3f %9.3f))
				
	* PANEL B - EDU		 
	esttab license_w3_hte2 employed_w3_hte2 not_in_LF_w3_hte2 ///
		 G1_3_abovemed_hte2 using ///
		"$output_rct/Table_2_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *hte) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		nomtitles ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.hte "$\beta\textsubscript{2}$: Less than HS" ///
		1.treatment#1.hte "$\beta\textsubscript{3}$: Treatment x Less than HS") ///	
		replace  fragment nonotes 
			
			
		 * Add total effects	
		esttab license_w3_hte2 employed_w3_hte2 not_in_LF_w3_hte2 ///
		 G1_3_abovemed_hte2 using ///
		"$output_rct/Table_2_Panel_B.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab license_w3_hte2 employed_w3_hte2 not_in_LF_w3_hte2 ///
		 G1_3_abovemed_hte2 using ///
		"$output_rct/Table_2_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte, ///
				labels("Observations" "Mean: Control, Completed HS") ///
				fmt(0 %9.3f %9.3f))
				
		* PANEL C - MARITAL STATUS
		esttab license_w3_mar employed_w3_mar not_in_LF_w3_mar  ///
		G1_3_abovemed_mar using ///
		"$output_rct/Table_2_Panel_C.tex", ///
		label se nonotes nomtitles  ///
		nogaps nobaselevels nonotes keep(*treatment *rel_status_BL) ///
		drop(2.rel_status_BL 3.rel_status_BL 4.rel_status_BL) ///
		b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" 2.rel_status_BL ///
		"$\beta\textsubscript{2}$: Married" ///
		3.rel_status_BL "$\beta\textsubscript{3}$: Never-married" 4.rel_status_BL ///
		"$\beta\textsubscript{4}$: Widowed" ///
		1.treatment#2.rel_status_BL ///
		"$\beta\textsubscript{5}$: Treatment x Married" 1.treatment#3.rel_status_BL ///
		"$\beta\textsubscript{6}$: Treatment x Never-married" ///
		1.treatment#4.rel_status_BL ///
		"$\beta\textsubscript{7}$: Treatment x Widowed" ) ///
		fragment  replace noobs
		
		
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab license_w3_mar employed_w3_mar not_in_LF_w3_mar  ///
		G1_3_abovemed_mar using ///
		"$output_rct/Table_2_Panel_C.tex", ///
		append fragment nomtitles nonumbers noconstant noobs  nonotes  ///
		cells(none) stats(N cmean_div cmean_mar cmean_sing cmean_wid, ///
		labels("Observations" "Mean: Control, divorced" ///
		"Mean: Control, married" "Mean: Control, never-married" ///
		"Mean: Control, widowed" ///
		"b1_b5 p-val: $\beta\textsubscript{1}$ + $\beta\textsubscript{5}$ = 0" ///
		"b1_b6 p-val: $\beta\textsubscript{1}$ + $\beta\textsubscript{6}$ = 0" ///
		"b1_b7 p-val: $\beta\textsubscript{1}$ + $\beta\textsubscript{7}$ = 0") ///
		fmt(0 %9.3f %9.3f))

	

* TABLE 3
	
				
	* PANEL A - Has husband/co-parent		 
	esttab license_w3_inf employed_w3_inf not_in_LF_w3_inf  ///
	G1_3_abovemed_inf using ///
		"$output_rct/Table_3_Panel_A.tex", ///
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
		esttab license_w3_inf employed_w3_inf not_in_LF_w3_inf  ///
	G1_3_abovemed_inf using ///
		"$output_rct/Table_3_Panel_A.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab license_w3_inf employed_w3_inf not_in_LF_w3_inf  ///
	G1_3_abovemed_inf using ///
		"$output_rct/Table_3_Panel_A.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte, ///
				labels("Observations" "Mean: Control, No husband/co-parent") ///
				fmt(0 %9.3f %9.3f))

		* PANEL B - In LF at BL 		 
	esttab license_w3_hte3 employed_w3_hte3 not_in_LF_w3_hte3 ///
		 G1_3_abovemed_hte3 using ///
		"$output_rct/Table_3_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
		keep(*treatment *hte) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		nomtitles ///
		varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
		1.hte "$\beta\textsubscript{2}$: In LF at BL" ///
		1.treatment#1.hte "$\beta\textsubscript{3}$: Treatment x In LF at BL") ///	
		replace   fragment nonotes 
			
			
		 * Add total effects	
		esttab license_w3_hte3 employed_w3_hte3 not_in_LF_w3_hte3 ///
		 G1_3_abovemed_hte3 using ///
		"$output_rct/Table_3_Panel_B.tex", ///
		label se nogaps nobaselevels  ///
		append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
		cells(none) stats(total_eff_b total_eff_se, ///
		labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab license_w3_hte3 employed_w3_hte3 not_in_LF_w3_hte3 ///
		 G1_3_abovemed_hte3 using ///
		"$output_rct/Table_3_Panel_B.tex", ///
		label se nogaps nobaselevels noobs ///
				append fragment nomtitles nonumbers noconstant   nonotes  ///
				cells(none) stats(N  cmean_hte, ///
				labels("Observations" "Mean: Control, Out of LF at BL") ///
				fmt(0 %9.3f %9.3f))
					
	