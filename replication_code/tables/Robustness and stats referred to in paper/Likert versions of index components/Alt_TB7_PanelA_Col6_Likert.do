/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Robustness 	- 	Alternate Table B7, Panel A, Column 6; Expected 
							likelihood of driving in the future; Likert version


Table footnotes: Alternate version of Table B7, Panel A, Column 6, where we use 
the full likert scale to generate the index outcome. The outcome was constructed 
as follows: respondents who reported not driving in the previous month were asked 
"will you drive in the future? How likely are you to drive?" with a Likert 
response scale. This was also coded as "likely" if the respondent reported driving 
in the previous month. Responses were transformed into a binary indicator for
above median response. All outcomes reported in this table were collected during 
the interim follow-up. Variations in sample size are due to drop-off from telephone 
survey. All estimates include individual and household controls: age (above median 
dummy), education level (less than a high school degree), marital status (indicators 
for married, never-married, and widowed), household size (number of members), number 
of cars owned (indicators for one car and for more than one car), an indicator for 
baseline labor force participation, and strata fixed effects. SEs are clustered 
at household level. We replace missing control values with 0 and include missing 
dummies for each. * p < 0.1 ** p < 0.05 *** p < 0.01				
********************************************************************************
********************************************************************************
********************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"
	do "$rep_code/3 - Imputation for controls.do"

	

* outcomes global
global pap_mob future_drive_w2 

			
			
		foreach var of global pap_mob {		
			reghdfe `var' driving_T##wusool_T $controls, ///
			absorb(group_strata)  vce(cluster file_nbr)
			eststo `var'

			* grab control mean
			sum `var' if e(sample) & treatment==0
			estadd scalar cmean = r(mean)	
		}
		



* Write to latex
	esttab future_drive_w2  using ///
	"$output_rct/robustness/Alt_Table_B7_Panel_A_Column_6_Likert.tex", ///
	label se scalars(N "cmean Control Group Mean" ) nogaps nobaselevels ///
	keep( *wusool_T *driving_T) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
	mtitles("\shortstack{Started driver's\\training}" ///
	"\shortstack{Received\\license}" ///
	"\shortstack{Expected cost\\of commute\\on e-hailing\\including any\\discount}" ///
	"\shortstack{Drove in the\\previous month}" ///
	"\shortstack{Driving frequency:\\estimated number\\of trips per\\month}" ///
	"\shortstack{Expected\\likelihood of\\driving in the\\future}") ///
	coeflabels(1.driving_T "$\beta\textsubscript{1}$: Driving training" 1.wusool_T "$\beta\textsubscript{2}$: Rideshare subsidy" ///
	1.driving_T#1.wusool_T "$\beta\textsubscript{3}$: Driving training x Rideshare subsidy") ///
	replace nonotes fragment modelwidth(15)


	
	