/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table 1, Panel C - 		Ability to leave the house, Ability to make 
									purchases, Attitudes towards women working 
									(female and male social networks). Main result 
									specifications




Table footnotes: 
Panel A, Column 5 and 6 outcomes are set to zero for 24 observations in which the 
respondent reported making no trips outside the home in the previous 7 days. The 
outcome in Panel B, Column 4 indicates whether the respondent is employed and 
applied for at least one job in the previous month (a more general measure of 
search beyond job applications was not collected for employed respondents); five
individuals responded to work status but not to the applications measure, 
leading to the variation in sample size between columns. Results for unemployment 
are similar if we redefine unemployed to include only those who applied for at 
least one job in the previous month. The outcomes in Panel B, Columns 5 and 6 and 
in Panel C, Columns 3 and 4 are weighted indices of sets of standardized outcomes 
described as follows using the swindex command developed by Schwab et al. (2020). 
For Panel B, Column 5, respondents were asked to rate their own level of agreement 
(using a 5 point Likert scale) for the following statements: `Women can be equally 
good business executives', `It's ok for a woman to have priorities outside the 
home', `Children are OK if a mother works', `It's OK to put my own needs above 
those of my family', and `The Government should allow a national women's soccer 
team'. Responses were transformed into binary indicators for above median response. 
Respondents were also asked what the ideal age is for a woman to have her first 
child. These outcomes are reported in Table A12, Panel A. For Panel B, Column 6, 
women were asked about the number of people they spoke with and met in the previous 
7 days. These outcomes are reported in Table A12, Panel B. For Panel C, Columns 
1 and 2, respondents were asked to rate their level of agreement (on a 5 point 
Likert scale) with the following statements: "If I wanted to meet with a friend 
outside of my home, I could do so without seeking approval / permission from anyone 
in my household first" and "I can make a purchase of 1000 SAR without needing to 
take permission from any member of my family" (1000 SAR is roughly equivalent to 
265 USD, in 2021 dollars), respectively. Responses were transformed into binary 
indicators for above median response. For Panel C, Columns 3 and 4, respondents 
were asked to think about a group and report what share of that group (`none`, 
`a minority', `about half', `a majority', or `all') they think would `somewhat' 
or `completely' agree with the following statements: `Women can be equally good 
business executives', `It's ok for a woman to have priorities outside the home', 
and `Children are OK if a mother works'. Responses were transformed into binary 
indicators for above median response. Second order beliefs questions are indexed 
for one female reference group (female community members) in Column 3 and two male 
reference groups: male family members and male community members in Column 4. The 
components of the second order attitudes indices are reported in Table A16; in 
Panel B and C of that table, we additionally report the indices separately for male 
family members and male community. Variations in sample size are due to drop-off 
from telephone survey; order of survey modules was randomized. All estimates 
include individual and household controls: age (above median dummy), education 
level (less than a high school degree), marital status (indicators for married,
never-married, and widowed), household size (number of members), number of cars 
owned (indicators for one car and for more than one car), an indicator for baseline 
labor force participation, and strata fixed effects. SEs are clustered at household 
level. We replace missing control values with 0 and include missing dummies for 
each. * p < 0.1 ** p < 0.05 *** p < 0.01					   				
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

	* likert/cts version
	global 	permission_attitudes G1_2_abovemed G1_3_abovemed ///
			ga2nd_fcom_binary_sw ga2nd_allmen_binary_sw
			

* Run models	
		* Cohort FEs, PAP controls, baseline employment
		foreach var in $permission_attitudes {		

			reghdfe `var' treatment  $controls , ///
			absorb(randomization_cohort2  )  vce(cluster file_nbr)
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


	esttab $permission_attitudes using ///
	"$output_rct/Table_1_Panel_C.tex", ///
	label se nonotes keep(*treatment) ///
	scalars("cmean Control mean" "b_cmean $\beta$/control mean" "pval P-value $\beta = 0$") ///
	b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///	
	mtitles("\shortstack{Allowed to\\leave house\\w/o permission}" ///
		"\shortstack{Allowed to\\make purchase\\w/o permission}" ///
		"\shortstack{Female Social\\Network}" "\shortstack{Male Social\\Network}") ///
	mgroups("\shortstack{Agreement with the\\following statements}" ///
	"\shortstack{Indices: Second order attitudes\\towards women working}", pattern(1 0 1 0 0) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	varwidth(75) modelwidth(15) fragment nobaselevels nogaps replace 
	
	
