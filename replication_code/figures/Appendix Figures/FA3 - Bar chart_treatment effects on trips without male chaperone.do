/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	FIGURE A3 - TREATMENT EFFECTS ON TRIPS WITHOUT CHAPERONE


Table footnotes: This figure shows the results of a series of estimates of equation 
1 in which the outcome variables are mutually exclusive and exhaustive indicators 
for the frequency of travel. Each control group bar shows the control group mean, 
while the treatment bar shows the sum of the control group mean and the ITT 
treatment effect β1. Regressions include individual and household controls: age 
(above median dummy), education level (less than a high school degree), marital 
status (indicators for married, never-married, and widowed), household size 
(number of members), number of cars owned (indicators for one car and for more 
than one car), an indicator for baseline labor force participation, and strata
fixed effects. SEs are clustered at household level. We replace missing control 
values with 0 and include missing dummies for each. * p < 0.1 ** p < 0.05 *** p 
< 0.01.
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
	
	* Number of unaccompanied trips (trips made without male chaperone) in past week
	forvalues i = 1 / 7 {
		
		reghdfe unaccomp_trips_cat_`i' treatment $controls, ///
					absorb(randomization_cohort2)  vce(cluster file_nbr)
					
		* add create stars for any significant mean differences
		if r(table)[4,1]<=.1 {
			local star_`i' = "*"
		}	
				
		if r(table)[4,1]<=.05 {
			local star_`i' = "**"
		}
		
		if r(table)[4,1]<=.01 {
			local star_`i' = "***"
		}	
		
		
		
		* grab means and CIs
		sum unaccomp_trips_cat_`i' if e(sample) & treatment==0 
		local control_`i' = r(mean) 
		local treat_`i' = _b[treatment] + `control_`i'' 	
		local treat_`i'_lower = `treat_`i'' - (1.96 * _se[treatment])
		local treat_`i'_upper = `treat_`i'' + (1.96 * _se[treatment])
		
		
		
	}

	

	
* Graph: Number of unaccompanied trips (trips made without male chaperone) in past week

	*preserve 

	clear
	
	set				obs 14
		
	gen 			treat_status = .
	gen 			outcome_mean = .
	
	gen 			star = ""
	gen 			val = .
	
	gen 			xloc = .
	
	* set treat status and outcome category
	local 			j = 1
	local			k = .5
	
	forvalues		i = 1(2)14 {
		
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
	forvalues		i= 1 / 7 {
		
	replace			outcome_mean = `control_`i'' if treat_status == 1 & val == `i' 
	replace			outcome_mean = `treat_`i'' if treat_status == 2 & val == `i' 
	
	replace 		star = "`star_`i''" if treat_status == 2 & val == `i'
	}

	* set height for stars and brackets 
	gen 			starloc =.
	
	forvalues		i = 1(2)14 {
		
	replace 		starloc = outcome_mean[`i'] + .01 if outcome_mean[`i']>outcome_mean[`i' + 1] ///
					& _n==`i'
	replace 		starloc = outcome_mean[`i'+1] + .01 if outcome_mean[`i'+1]>outcome_mean[`i'] ///
					& _n==`i'
	replace 		starloc = starloc[`i'] if _n==`i' + 1
					
	}


	* graph
	/* NOTE: we have significance for outcome category 1 and 6, so we'll set the 
			 brackets according to that 	*/
			 
	graph 			twoway (bar outcome_mean  xloc if treat_status==1, color(navy)) ///
					(bar outcome_mean  xloc if treat_status==2, color(maroon)) ///
					(scatter starloc xloc, color(white%0) mlabposition(11) mlabel(star) ///
					 mlabsize(5) mlabcolor(black)) ///
					(scatteri .51 1.5 .51 2.5,  recast(line) lw(medthick)  mc(none) ///
					lc(black) lp(solid)) ///
					(scatteri .51 1.5 .51 2.5,  recast(dropline) base(.5) lw(medthick) ///
					mc(none) lc(black) lp(solid)) ///
					(scatteri .11 14 .11 15,  recast(line) lw(medthick)  mc(none) ///
					lc(black) lp(solid)) ///
					(scatteri .11 14 .11 15,  recast(dropline) base(.1) lw(medthick) ///
					mc(none) lc(black) lp(solid)), ///
					legend(order (1 "Control" 2 "Treatment")) ///
					xlabel(1.5 "Never" 4 "One time" 6.5 "Two times" 9 "3-5 times" ///
						11.5 "6-9 times" 14 "10-14 times" 16.5 "15+ times", labsize(vsmall))  ///
					ytitle("Group Proportion") ///
					yscale(range(0 .6)) ylabel(0 0.1 0.2 0.3 0.4 0.5 0.6) xtitle("")
					
	* save graphs as jpg
	graph 			save "$output/RCT/figures/gph_files/Figure_A3", replace
	graph 			export "$output/RCT/figures/Figure_A3.jpg" , replace

	
