/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table B8	-	job search (PAP)


Table footnotes: All outcomes reported in this table were collected during the 
interim follow-up. Variations in sample size are due to drop-off from telephone 
survey. All estimates include individual and household controls: age (above median 
dummy), education level (less than a high school degree), marital status (indicators 
for married, never-married, and widowed), household size (number of members), number
of cars owned (indicators for one car and for more than one car), an indicator for 
baseline labor force participation, and strata fixed effects. SEs are clustered at 
household level. We replace missing control values with 0 and include missing 
dummies for each. * p < 0.1 ** p < 0.05 *** p < 0.01				
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"



global pap_jobsearch jobsearch_w2 careerfair_w2 jobhuntprop_w2 jh_travel_w2 ///
	lowestsalary_txt_w2 jobapplied_lastm_w2 job_interview_w2 job_interviewattend_w2 ///
	takejob_15mins_w2 takejob_30mins_w2

			
		* Cohort FEs, PAP controls, HTE husband influence	
		foreach var of global pap_jobsearch {		
			reghdfe `var' driving_T##wusool_T $controls, ///
			absorb(group_strata)  vce(cluster file_nbr)
			eststo `var'_1

			* grab control mean
			sum `var' if e(sample) & treatment==0
			estadd scalar cmean = r(mean)	
		}
		
		


* Write to latex
	* Panel A
	esttab jobsearch_w2_1 careerfair_w2_1 jobhuntprop_w2_1 jh_travel_w2_1 ///
		lowestsalary_txt_w2_1 using ///
		"$output_rct/Table_B8_Panel_A.tex", ///
		label se scalars(N "cmean Control Group Mean" ) nogaps nobaselevels ///
		keep( *wusool_T *driving_T) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Looking for\\a job}" ///
		"\shortstack{Attended a career\\fair in last 3\\months}" ///
		"\shortstack{Proportion of\\job search activities\\taken in the last\\month}" ///
		"\shortstack{Travel to search\\(visited a job center\\or employers in person)}" ///
		"\shortstack{Self-reported\\reservation wage}") ///
		coeflabels(1.driving_T "$\beta\textsubscript{1}$: Driving training" 1.wusool_T "$\beta\textsubscript{2}$: Rideshare subsidy" ///
		1.driving_T#1.wusool_T "$\beta\textsubscript{3}$: Driving training x Rideshare subsidy") ///
		replace nonotes fragment
	
	* Panel B
	esttab jobapplied_lastm_w2_1 job_interview_w2_1 job_interviewattend_w2_1 ///
		takejob_15mins_w2_1 takejob_30mins_w2_1 using ///
		"$output_rct/Table_B8_Panel_B.tex", ///
		label se scalars(N "cmean Control Group Mean" ) nogaps nobaselevels ///
		keep( *wusool_T *driving_T) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
		mtitles("\shortstack{Job applications}" ///
		"\shortstack{Interview invitations}" ///
		"\shortstack{Interviews attended}" ///
		"\shortstack{Willing to take a\\job for 3000 SAR\\15 minutes away}" ///
		"\shortstack{Willing to take a\\job for 3000 SAR\\30 minutes away}") ///
		coeflabels(1.driving_T "$\beta\textsubscript{1}$: Driving training" 1.wusool_T "$\beta\textsubscript{2}$: Rideshare subsidy" ///
		1.driving_T#1.wusool_T "$\beta\textsubscript{3}$: Driving training x Rideshare subsidy") ///
		replace nonotes fragment
		
	