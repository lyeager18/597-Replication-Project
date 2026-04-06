/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		Master replication file for Saudi commute project 
				
********************************************************************************
********************************************************************************
*******************************************************************************/
cap log close


/*** First, set up and run settings_rep_package.do 
     (located in saudi_women_driving/replication_code) 	*/


* Install necessary packages
local ssc_packages swindex reghdfe ihstrans winsor2 outreg2 grc1leg scto ietoolkit ///
				   blindschemes texdoc

foreach pkg in `ssc_packages' {
	cap which `pkg'
    if _rc {
        di "Installing `pkg' from SSC..."
        ssc install `pkg', replace
		if "`pkg'"=="grc1leg" {
			net install grc1leg, from( http://www.stata.com/users/vwiggins/)
		}
    }
    else {
        di "`pkg' is already installed."
    }
}



* Run cleaning files

	* Log the process
	log using "$logs/Data cleaning_`c(current_date)'.smcl", replace

	set 	seed 20190228
	set 	sortseed 20190228
	
	do		"$rep_code/cleaning/Wave 1 cleaning.do"
	do		"$rep_code/cleaning/Wave 2 cleaning.do"
	do 		"$rep_code/cleaning/Wave 1 & 2 merge.do"
	do		"$rep_code/cleaning/Wave 3 cleaning.do"
	do 		"$rep_code/cleaning/Weighting.do"
	
	log close

* Run tables and figures in the order in which they appear in paper

	* Main tables
	do		"$rep_code/tables/Main Tables/T1 PanelsAB - driving_mobility_labor_ind decision.do"
	do		"$rep_code/tables/Main Tables/T1 PanelC - Permissions_attitudes women working.do"
	do 		"$rep_code/tables/Main Tables/T2_T3 - Lic_employed_ability to purchase_multiple HTE.do"
	
	
	* Appendix figures
	// 		Figure A1: Timeline was created outside of stata
	do 		"$rep_code/figures/Appendix Figures/FA2 - 2nd order beliefs bar chart.do"
	do 		"$rep_code/figures/Appendix Figures/FA3 - Bar chart_treatment effects on trips without male chaperone.do"
	do 		"$rep_code/figures/Appendix Figures/FA4 - Bar Chart_treatment effects on travel freq.do"
	do 		"$rep_code/figures/Appendix Figures/FA5 - Saudi LFP graph.do"
	

	
	* Appendix A tables 
	//		Table A1: Legal rights of women by marital status was created outside of stata
	/*		Table A2: Comparison of experimental sample and pop. rep. stats was created 
					  outside of stata. See "$rep_code/Stats for paper.do" 
					  for generation of sample stats. 	*/
	do		"$rep_code/tables/Appendix tables/Appendix A/TA3 - Balance across arms among responders.do"	
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA4 - Balance across arms_full sample.do"	
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA5 - descriptive stats on wave 2 travel patterns in control group.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA6 - Attrition table with and without controls.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA7-TA8 - Attrition_multipleHTE.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA9 Panels A B - driv_mob_lab_inddec_nocontrols_nostrata_lee.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA9 Panel C - permissions_attitudes_nocontrols_nostrata_lee.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA10 Panels AB - driving_mobility_labor_ind decision_nocontrols.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA10 Panel C - permissions_attitudes women working_nocontrols.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA11 - labor_outcomes_weighted_age-edu_emp.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA12 - First order beliefs_soccont_swindex.do"			
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA13 - Approval of gender policy.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA14 - Civic Engagement.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA15 - Permission to purchase_weighted.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA16 - 2nd order gender attitudes_swindex_binary.do"
	do 		"$rep_code/tables/Appendix tables/Appendix A/TA17 - Employed_HTE marital robustness to treatment interactions with BL characteristics.do"



	
	* Appendix B tables
	/*		"$rep_code/tables/Appendix tables/Appendix B/Anderson_2008_fdr_sharpened_qvalues.do" generates 
			FDR corrected q-values for Tables B1-B6; it will run as part of the Table do files below	*/
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB1 - MHT_emp_unemp_empsearch.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB2 Panels AB_TB3 Panel B - MHT_emp_unemp_empsearch_HTE_age_edu_LF.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB2 Panel C - MHT_emp_unemp_empsearch_HTE_marital.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB3 Panel A - MHT_emp_unemp_empsearch_HTE_husbcopar.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB4 - MHT_mob and spending control.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB5 Panels A B_TB6 Panel B - MHT_mob and spending control_HTE_age_edu_LF.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB5 Panel C - MHT_mob and spending control_HTE_marital.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB6 Panel A - MHT_mob and spending control_HTE_husbcopar.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB7 - PAP_training_lic_commute_mobility.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB8 - PAP_job search.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB9 - wusool interaction_stacked_training_mobility_LFP.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB10 Panels A B - driving_mobility_labor_ind decision_strata.do"
	do 		"$rep_code/tables/Appendix tables/Appendix B/TB10 Panel C - permissions_attitudes women working_strata.do"
	

	* Robustness / results referenced in text
	* Log output
	log using "$logs/Robustness referred to in paper_`c(current_date)'.smcl", replace	
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Stats_for_paper.do"	// Stats referred to in text
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Joint_test_BL_char_differential_attrition_by_treatment.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Alt_T1_Panel_B_Column_2.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Alt_T3_Panel_A.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Alt_TA11_Column_2.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Alt_TA17.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Employment_Ability to purchase.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Alt_main_results_alternate_controls.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Alt_main_results_HTEhusbcopar_alternate_controls.do"

	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_T1_PanelB_Col5_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_T1_PanelC_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_T2_T3_Col4_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA9_PanelB_Col5_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA9_PanelC_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA10_PanelB_Col5_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA10_PanelC_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA12_PanelA_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA13_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA14_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA15_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TA16_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB4_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB5_PanelC_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB5PanelsAB_TB6_PanelB_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB6_PanelA_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB7_PanelA_Col6_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB9_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB10_PanelB_Col5_Likert.do"
	do 		"$rep_code/tables/Robustness and stats referred to in paper/Likert versions of index components/Alt_TB10_PanelC_Likert.do"
	log close

	
	
	
	

	






