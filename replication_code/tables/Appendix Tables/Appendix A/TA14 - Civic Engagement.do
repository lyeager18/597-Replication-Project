/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table A14	-	Civic engagement; index and index
							components

Table footnotes: The outcome in Column 2 is constructed as follows: respondents 
were asked whether they will vote in the next municipal election (definitely no, 
probably no, unsure, probably yes, definitely yes, I do not know how to vote, or 
I do not know about any elections). The last two options were combined with 
`definitely no' to create a likert scale. Responses were then transformed into a 
binary indicator for above median response. Outcomes in Columns 3-4 are indicators 
for whether the respondent expressed interest in signing up for a given program 
during the survey. We also sent respondents a text message with a link, tied to 
their survey ID, to a prompt that provided further information about the program 
and where to apply. The text message also asked respondents to forward the link 
to any of their friends or family whom they thought might also be interested in 
the program. Column 5 is an indicator for whether anyone clicked on the link 
(respondent or friend), and Column 6 is a measure of the number of people who 
clicked the link for more information. These outcomes are estimated for all 
respondents who started the survey, with the outcome for those who did not respond 
to that question or respond to the invitation coded as zero. The outcome in Column 
1 is a weighted index of the standardized binary responses to each question using 
the swindex command developed by Schwab et al. (2020). All estimates include 
individual and household controls: age (above median dummy), education level 
(less than a high school degree), marital status (indicators for married, 
never-married, and widowed), household size (number of members), number of cars 
owned (indicators for one car and for more than one car), an indicator for baseline 
labor force participation, and strata fixed effects. SEs are clustered at household 
level. We replace missing control values with 0 and include missing dummies for 
each. Variations in sample size are due to drop-off from telephone survey; order 
of survey modules was randomized. * p < 0.1 ** p < 0.05 *** p < 0.01
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
	
* shorten var name for storage
	rename number_people_clicked ppl_clicked

* Set global for table outcomes
	global civic civ_engage_binary_sw P3_abovemed R17_scale R14_scale anyone_clicked_w3 ///
		ppl_clicked
			
* Run models
	
		* (1) Cohort FEs, PAP controls
			foreach var in $civic {		

				reghdfe `var' treatment $controls, absorb(randomization_cohort2) ///
				vce(cluster file_nbr)
				eststo `var'
				
				* grab control mean
				sum `var' if e(sample) & treatment==0
				estadd scalar cmean = r(mean)	
				
				* grab beta/control mean
				local beta: display %4.3f _b[treatment]
				local cmean: display %4.3f r(mean)
				estadd scalar b_cmean = `beta'/`cmean'
				
				* P-value 
				test treatment = 0 
				estadd scalar pval = `r(p)' 	

			}
			
			

				

* Write to latex

		esttab $civic using ///
		"$output_rct/Table_A14.tex", ///
		label se nonotes keep( treatment) b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
		scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
		mtitles("\shortstack{Index: Civic\\Engagement}" ///
		"\shortstack{Will vote in\\the next election}" ///
		"\shortstack{Expressed interest\\in signing\\up for volunteer\\program}" ///
		"\shortstack{Expressed interest\\in signing\\up for leadership\\program}" ///
		"\shortstack{Leadership\\program:\\Anyone clicked}" ///
		"\shortstack{Leadership\\program:\\Number people\\clicked}") ///
		mgroups("Index" "Index Components", pattern(1 1 0 0 0 0) ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		replace fragment modelwidth(25) varwidth(25) nogaps

	