/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness 	- 	Stacked: driving, mobility, labor market outcomes,
							and independent decision making; HTE (has husband/
							co-parent)

Table footnotes: This table generates estimates for our main outcomes interacted
with 'has husband/co-parent' using an alternate set of controls: we replace the 
dichotomous controls for age and education with a series of bins for each control, 
and replace the baseline labor force participation indicator with indicators for 
baseline employment and unemployment. `Has husband/co-parent' is defined as (a) 
currently married or (b) divorced/separated with children under 18 in the household. 
Variations in sample size are due to drop-off from telephone survey; order of 
survey modules was randomized. All estimates include cohort FEs and individual 
and household control variables: age, education level, household size, number of cars
owned by household, and baseline employment. SEs are clustered at household level. 
* p < 0.1 ** p < 0.05 *** p < 0.01.								 
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* Pull in data:
	do "$rep_code/1 - Pull in data.do"
	
* Create global for controls	
global 	controls_HTE_orig i.age_4group_BL miss_age_PAP i.edu_category_BL miss_edu_category ///
		household_size miss_household_size one_car mult_cars miss_cars employed_BL ///
		unemployed_BL miss_unemployed  
		
* Imputation for missing control values
	* age (PAP version)
	gen miss_age_PAP = 0
	replace miss_age_PAP = 1 if age_4group==.
	lab var miss_age_PAP "Missing value for age (PAP version)"
	replace age_4group_BL = 0 if age_4group_BL==.
	* household_size
	gen miss_household_size = 0
	replace miss_household_size = 1 if household_size==.
	lab var miss_household_size "Missing value for household_size"
	replace household_size = 0 if household_size==.
	
	* Cars
	* create one missing tag(since missing for the same people)
	gen miss_cars = 0
	replace miss_cars = 1 if cars==.
	lab var miss_cars "Missing value for cars"	
	* dummy for one car
	replace one_car = 0 if one_car==.
	* dummy for 2+ cars
	replace mult_cars = 0 if mult_cars==.

	* Relationship status (updated categories)
	* create one missing tag (since missing for the same people)
	gen miss_relationship	= 0
	replace miss_relationship = 1 if rel_status_BL==.
	lab var miss_relationship "Missing value for relationship status"
	* married
	replace married = 0 if married==.
	* divorced/separated
	replace divorced_separated = 0 if divorced_separated==.
	* single
	replace single = 0 if single==.
	* widowed
	replace widowed = 0 if widowed==.
	
	* unemployed_BL
	gen miss_unemployed_BL = 0 
	replace miss_unemployed_BL = 1 if unemployed_BL==.
	lab var miss_unemployed_BL "Missing value for unemployed_BL"
	replace unemployed_BL = 0 if unemployed_BL==.

	* edu_category
	gen miss_edu_category = 0 
	replace miss_edu_category = 1 if edu_category==.
	lab var miss_edu_category "Missing value for edu_category"
	replace edu_category = 0 if edu_category==.
		
	
* Restrict data to main follow up
	keep if endline_start_w3==1
	
* shorten var name for storage
	rename share_trips_unaccomp_w3 share_unaccomp
	
* Set global for table outcomes
	global 	drive_mob_lab s_train_bi_w3 license_w3 drive_any_mo_bi_w3 ///
			M4_1_TEXT share_unaccomp employed_w3  unemployed_w3 not_in_LF_w3 ///
			empl_jobsearch_w3 no_trips_unaccomp_w3 G1_2_abovemed G1_3_abovemed

* Run models
			   
		foreach var of global drive_mob_lab {		

			reghdfe `var' treatment##i.husb_influence_kids_original_BL $controls_HTE_orig , ///
			absorb(randomization_cohort2 )  vce(cluster file_nbr)
			eststo `var'_1
			
			* Test total effect
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
			sum `var' if e(sample) & treatment==0 & husb_influence_kids_original_BL==0
			estadd scalar cmean_nohus = r(mean)
			
			sum `var' if e(sample) & treatment==0 & husb_influence_kids_original_BL==1
			estadd scalar cmean_hus = r(mean)
		}
		
* Write to latex

	* PANEL A		 
	esttab 	s_train_bi_w3_1 license_w3_1 drive_any_mo_bi_w3_1 M4_1_TEXT_1 ///
			share_unaccomp_1 no_trips_unaccomp_w3_1 using ///
			"$output_rct/robustness/Alt_main_results_HTE_alternatecontrols_PanelA.tex", ///
			label se nogaps nobaselevels ///
			keep(*treatment *husb_influence_kids_original_BL) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
			mtitles("\shortstack{Started driver's\\training}" ///
			"\shortstack{Received\\license}" "\shortstack{Any driving\\in past month}" ///
			"\shortstack{Number of\\times left\\house in\\last 7 days}" ///
			"\shortstack{Share of\\trips made\\without male\\chaperone}" ///
			"\shortstack{Always travels\\with male\\chaperone}") ///
			varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
			1.husb_influence_kids_original_BL "$\beta\textsubscript{2}$: Has husband/co-parent" ///
			1.treatment#1.husb_influence_kids_original_BL ///
			"$\beta\textsubscript{3}$: Treatment x Has husband/co-parent") ///
			replace  varwidth(25) modelwidth(12) fragment nonotes noobs
		 
		 * Add total effects	
		esttab	s_train_bi_w3_1 license_w3_1 drive_any_mo_bi_w3_1 M4_1_TEXT_1 ///
				share_unaccomp_1 no_trips_unaccomp_w3_1 using ///
				"$output_rct/robustness/Alt_main_results_HTE_alternatecontrols_PanelA.tex", ///
				append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
				cells(none) stats(total_eff_b total_eff_se, ///
				labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab	s_train_bi_w3_1 license_w3_1 drive_any_mo_bi_w3_1 M4_1_TEXT_1 ///
				share_unaccomp_1 no_trips_unaccomp_w3_1 using ///
				"$output_rct/robustness/Alt_main_results_HTE_alternatecontrols_PanelA.tex", ///
				append fragment nomtitles nonumbers noconstant noobs  nonotes  ///
				cells(none) stats(N  cmean_nohus cmean_hus, labels("Observations" ///
				"Mean: Control, no husband/co-parent" ///
				"Mean: Control, has husband/co-parent") ///
				fmt(0 %9.3f %9.3f))
		
		
	* PANEL B	
	esttab 	employed_w3_1 unemployed_w3_1 not_in_LF_w3_1 empl_jobsearch_w3_1 ///
			G1_2_abovemed_1 G1_3_abovemed_1 using ///
			"$output_rct/robustness/Alt_main_results_HTE_alternatecontrols_PanelB.tex", ///
			label se nogaps nobaselevels ///
			keep(*treatment *husb_influence_kids_original_BL) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
			mtitles("\shortstack{Employed}" ///
			"\shortstack{Unemployed}" ///
			"\shortstack{Out of labor\\force}" ///
			"\shortstack{On the job\\search}" ///
			"\shortstack{Allowed to\\leave the\\house without\\permission}" ///
			"\shortstack{Allowed to\\make purchase\\without\\permission}") ///
			varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
			1.husb_influence_kids_original_BL "$\beta\textsubscript{2}$: Has husband/co-parent" ///
			1.treatment#1.husb_influence_kids_original_BL "$\beta\textsubscript{3}$: Treatment x Has husband/co-parent") ///
			replace  varwidth(25) modelwidth(12) fragment nonotes noobs
		 
		 * Add total effects	
		esttab	employed_w3_1 unemployed_w3_1 not_in_LF_w3_1 empl_jobsearch_w3_1 ///
				G1_2_abovemed_1 G1_3_abovemed_1 using ///
				"$output_rct/robustness/Alt_main_results_HTE_alternatecontrols_PanelB.tex", ///
				append fragment nomtitles nonumbers noconstant noobs nogaps nonotes ///
				cells(none) stats(total_eff_b total_eff_se, ///
				labels("$\beta\textsubscript{1}$ + $\beta\textsubscript{3}$" " "))
		 
		* Add N, control mean, and p-val for test that total effect is different from zero 
		esttab	employed_w3_1 unemployed_w3_1 not_in_LF_w3_1 empl_jobsearch_w3_1 ///
				G1_2_abovemed_1 G1_3_abovemed_1 using ///
				"$output_rct/robustness/Alt_main_results_HTE_alternatecontrols_PanelB.tex", ///
				append fragment nomtitles nonumbers noconstant noobs  nonotes  ///
				cells(none) stats(N  cmean_nohus cmean_hus , ///
				labels("Observations" "Mean: Control, no husband/co-parent" ///
				"Mean: Control, has husband/co-parent") ///
				fmt(0 %9.3f %9.3f))
												
	