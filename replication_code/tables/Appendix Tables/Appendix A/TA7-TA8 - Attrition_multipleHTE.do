/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose:	Tables A7 & A8	- 	Attrition without randomization cohort 
								FEs; interacted with multiple HTE outcomes
				
Table footnotes:

Table A7:  Dependent variables are indicators for whether the respondent began 
the respective module in the survey; the order of modules was randomized SEs are 
clustered at household level. We do not include additional controls in these 
estimations. * p < 0.1 ** p < 0.05 *** p < 0.01

Table A8:`Has husband/co-parent' is defined as (a) currently married or 
(b) divorced/separated with children under 18 in the household. Dependent variables 
are indicators for whether the respondent began the respective module in the survey; 
the order of modules was randomized. Four observations are dropped due to missing 
marital status at baseline. SEs are clustered at household level. * p < 0.1 
** p < 0.05 *** p < 0.01
				
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear 


* RUN THESE DO FILES FIRST:
	
	do "$rep_code/1 - Pull in data.do"


* Set global for module start indicators
	global attrition employ_modstart attitudes_modstart
	global hte_vars LF_BL age_med_BL edu_nohs_BL
	
* Relabel vars for table output
	lab var	LF_BL "In LF at BL"
	lab var	age_med_BL "Above median age" 
	lab var	edu_nohs_BL "Less than HS"
	lab var	husb_influence_kids "Has husband/co-parent"
	lab var rel_status_BL "Marital status at BL"

		
	* Run attrition models - no FEs, and no controls

			
	* (1) Binary HTE vars
	local i = 1
		foreach hte of global hte_vars {
			
			* create a var with a standardized name for HTE var so that estimates 
			// show up in same row in table
			gen hte = `hte'

			foreach outcome of global attrition {
				reg `outcome' treatment##hte, vce(cluster file_nbr)
				eststo `outcome'_noFE`i'

				* grab control mean
				sum `outcome' if e(sample) & treatment==0 & hte==0
				estadd scalar cmean = r(mean)

				
				* add label for the HTE var
				local x : variable label `hte'
				estadd local htevar `x'
			
			}
			local i = `i' + 1
			drop hte
		}
		
	
	* (2) Marital status (4 group)
	foreach outcome of global attrition {

		reg `outcome' treatment##i.rel_status_BL, vce(cluster file_nbr)
		eststo `outcome'_noFE4
					
		* grab control means across BL marital status 
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==1
			estadd scalar cmean_copar = r(mean)
			
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==2
			estadd scalar cmean_mar = r(mean)
			
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==3
			estadd scalar cmean_sing = r(mean)
	
			sum `outcome' if e(sample) & treatment==0 & rel_status_BL==4
			estadd scalar cmean_widnocopar = r(mean)	
		
		* add label for the HTE var
		local x : variable label rel_status_BL
		estadd local htevar `x'
	}
	
	* (3) Has husband/co-parent
		foreach outcome of global attrition {
			reg `outcome' treatment##husb_influence_kids, vce(cluster file_nbr)
			eststo `outcome'_noFE5

			* grab control mean
			sum `outcome' if e(sample) & treatment==0 & husb_influence_kids==0
			estadd scalar cmean = r(mean)

				
			* add label for the HTE var
			local x : variable label husb_influence_kids
			estadd local htevar `x'
			
			}

		
			
	* write table to latex	
	
		* TABLE A7
			esttab employ_modstart_noFE1 attitudes_modstart_noFE1  ///
			employ_modstart_noFE2 attitudes_modstart_noFE2 employ_modstart_noFE3 ///
			attitudes_modstart_noFE3 ///
			using "$output_descr/tables/Table_A7.tex", ///
			label se scalars("cmean Control Mean: HTE variable = 0" ///
			 "htevar HTE variable") nogaps nobaselevels ///
			keep(*treatment *hte) b(%9.3f) se(%9.3f) ///
			star(* 0.1 ** 0.05 *** 0.01) nonotes ///	
			mtitles("\shortstack{Started\\Employment\\Module}" ///
			"\shortstack{Started\\Attitudes\\Module}" "\shortstack{Started\\Employment\\Module}" ///
			"\shortstack{Started\\Attitudes\\Module}" ///
			"\shortstack{Started\\Employment\\Module}" ///
			"\shortstack{Started\\Attitudes\\Module}") ///
			varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
			1.hte "$\beta\textsubscript{2}$: HTE variable" ///
			1.treatment#1.hte ///
			"$\beta\textsubscript{3}$: Treatment x HTE variable") ///
			replace fragment varwidth(25) modelwidth(12)	
			
			
		* TABLE A8
		esttab employ_modstart_noFE4 attitudes_modstart_noFE4 ///
			employ_modstart_noFE5 attitudes_modstart_noFE5 ///
			using "$output_descr/tables/Table_A8.tex", ///
			label se scalars("cmean_mar Mean: Control, married" ///
			"cmean_sing Mean: Control, single" ///
			"cmean_widnocopar Mean: Control, widowed" ///
			"cmean_copar Mean: Control, divorced" "cmean Control Mean: HTE variable = 0" ///
			 "htevar HTE variable") nogaps nobaselevels ///
			keep(*treatment *husb_influence_kids *rel_status_BL) ///
			drop(2.rel_status_BL 3.rel_status_BL 4.rel_status_BL) b(%9.3f) se(%9.3f) ///
			star(* 0.1 ** 0.05 *** 0.01) nonotes ///	
			mtitles("\shortstack{Started\\Employment\\Module}" ///
			"\shortstack{Started\\Attitudes\\Module}" ///
			"\shortstack{Started\\Employment\\Module}" ///
			"\shortstack{Started\\Attitudes\\Module}") ///
			varlabels(1.treatment "$\beta\textsubscript{1}$: Treatment" ///
			1.treatment#2.rel_status_BL ///
			"$\beta\textsubscript{2}$: Treatment x Married" 1.treatment#3.rel_status_BL ///
			"$\beta\textsubscript{3}$: Treatment x Never-married" ///
			1.treatment#4.rel_status_BL ///
			"$\beta\textsubscript{4}$: Treatment x Widowed" ///
			1.husb_influence_kids "$\beta\textsubscript{5}$: Has husband/co-parent" ///
			1.treatment#1.husb_influence_kids ///
			"$\beta\textsubscript{6}$: Treatment x Has husband/co-parent") ///
			replace fragment varwidth(25) modelwidth(12)
			
	

			 
	