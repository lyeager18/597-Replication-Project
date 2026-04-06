/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	FIGURE A4 - TREATMENT EFFECTS ON TRAVEL FREQUENCY


Figure footnotes: This figure shows the results of a series of estimates of 
equation 1 in which the outcome variables are mutually exclusive and exhaustive 
indicators for the frequency of driving reported by the respondent in the recall 
period. Each control group bar show the control group mean, while the treatment 
bar shows the sum of the control group mean and the ITT treatment effect β1. 
Regressions include individual and household controls: age (above median dummy), 
education level (less than a high school degree), marital status (indicators for 
married, never-married, and widowed), household size (number of members), number 
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

* drop observations excluded from the RCT 
	keep if 		endline_start_w3==1

* Graph scheme

	set 			scheme plotplainblind
	

* Estimation 	
	
	* Driving freq in past month 
	forvalues i = 1 / 5 {
		
		reghdfe drive_freq_num_`i' treatment $controls, ///
					absorb(randomization_cohort2)  vce(cluster file_nbr)
					
		* add create stars for any significant mean differences
		if r(table)[4,1]<=.1 {
			local star1_`i' = "*"
		}	
				
		if r(table)[4,1]<=.05 {
			local star1_`i' = "**"
		}
		
		if r(table)[4,1]<=.01 {
			local star1_`i' = "***"
		}
		
		* grab group means
		sum drive_freq_num_`i' if e(sample) & treatment==0 
		local control1_`i' = r(mean) 
		local treat1_`i' = _b[treatment] + `control1_`i'' 	
	}	
		



	
	
* FIGURE: TREATMENT EFFECTS ON TRAVEL FREQ
	* Graph 1: Driving freq in past month 

	preserve 

	clear
	
	set				obs 10
	
	gen 			treat_status = .
	gen 			outcome_mean = .
	
	gen 			star = ""
	gen 			val = .
	
	gen 			xloc = .
	
	* set treat status and outcome category
	local 			j = 1
	local			k = .5
	
	forvalues		i = 1(2)10 {
		
		replace 		treat_status = 1 if _n==`i'
		replace 		treat_status = 2 if _n==`i' + 1
		
		
		replace 		val = `j' if _n==`i' | _n==`i' + 1
		local 			j = `j' + 1
	
		* set the x-axis locations of the bars
		replace 		xloc = `i' + `k' if _n ==`i'  
		replace 		xloc = `i' + `k' + 1 if _n ==`i' + 1 
		local			k = `k' + .5
	}
	
	* add group means and significance stars if there are any
	forvalues		i= 1 / 5 {
		
	replace			outcome_mean = `control1_`i'' if treat_status == 1 & val == `i' 
	replace			outcome_mean = `treat1_`i'' if treat_status == 2 & val == `i' 
	
	replace 		star = "`star1_`i''" if treat_status == 2 & val == `i'
	}
	
	* set height for stars and brackets 
	gen 			starloc =.
	
	forvalues		i = 1(2)10 {
		
	replace 		starloc = outcome_mean[`i'] + .01 if outcome_mean[`i']>outcome_mean[`i' + 1] ///
					& _n==`i'
	replace 		starloc = outcome_mean[`i'+1] + .01 if outcome_mean[`i'+1]>outcome_mean[`i'] ///
					& _n==`i'
	replace 		starloc = starloc[`i'] if _n==`i' + 1
					
	}
	
	* graph
			 
	graph 			twoway (bar outcome_mean  xloc if treat_status==1, color(navy)) ///
					(bar outcome_mean  xloc if treat_status==2, color(maroon)) ///
					(scatter starloc xloc, color(white%0) mlabposition(11) mlabel(star) ///
					 mlabsize(5) mlabcolor(black)) ///
					(scatteri .69 1.5 .69 2.5,  recast(line) lw(medthick)  mc(none) ///
					lc(black) lp(solid)) ///
					(scatteri .69 1.5 .69 2.5,  recast(dropline) base(.68) lw(medthick) ///
					mc(none) lc(black) lp(solid)) ///
					(scatteri .08 6.5 .08 7.5,  recast(line) lw(medthick)  mc(none) ///
					lc(black) lp(solid)) ///
					(scatteri .08 6.5 .08 7.5,  recast(dropline) base(.07) lw(medthick) ///
					mc(none) lc(black) lp(solid)) ///
					(scatteri .2 9 .2 10,  recast(line) lw(medthick)  mc(none) ///
					lc(black) lp(solid)) ///
					(scatteri .2 9 .2 10,  recast(dropline) base(.19) lw(medthick) ///
					mc(none) lc(black) lp(solid)) ///
					(scatteri .23 11.5 .23 12.5,  recast(line) lw(medthick)  mc(none) ///
					lc(black) lp(solid)) ///
					(scatteri .23 11.5 .23 12.5,  recast(dropline) base(.22) lw(medthick) ///
					mc(none) lc(black) lp(solid)), ///
					legend(order (1 "Control" 2 "Treatment")) ///
					xlabel(2 "Never" 4.5 "Once or twice a month" ///
						7 "Once a week" 9.5 "Few times a week" 12 "Every day", labsize(vsmall))  ///
					ytitle("Group Proportion") ///
					yscale(range(0 .6)) ylabel(0 0.1 0.2 0.3 0.4 0.5 0.6 .7) xtitle("")

	
	graph 			save "$output/RCT/figures/gph_files/Figure_A4" , replace
						
	graph 			export "$output/RCT/figures/Figure_A4.eps" , replace
	
	restore 
	

	
