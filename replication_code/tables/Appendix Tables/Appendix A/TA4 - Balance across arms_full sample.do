/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose:	Table A4	-	Balance across arms in full sample; strata FEs

Table footnotes: Data from administrative records and baseline survey. "Likely to 
drive soon after ban is lifted" variables are binary response indicators based on 
the following scale for whether the respondent would be likely to drive once the 
ban on female driving would be lifted (it was lifted partway through the baseline): 
unlikely to drive, somewhat likely, likely but not at first, and likely. Estimated 
differences and p-values reported from OLS; strata FEs and household-level clustered 
SEs. To estimate the F-stat, we impute variable means for missing values.		
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear

* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"
	do "$rep_code/2 - Setting regression controls.do"

	
		
global balance age_BL single married divorced_separated husb_influence_kids   ///
	one_child_BL mult_children_BL hh_more18_w owns_car_BL cars_num driving_likely_BL  ///
	elementary_BL highschool_BL any_tertiary_edu_BL  ///
	employed_BL unemployed_BL on_job_search_BL ever_employed_BL  work_experience_BL
		
	


	* relabel for table
	lab var age_BL "Age"
	lab var married "Married"
	lab var divorced_separated "Divorced or separated"
	lab var single "Never-married"
	lab var husb_influence_kids "Has husband/co-parent"
	lab var one_child_BL "One child in the household"
	lab var mult_children_BL "Multiple children in the household"
	lab var hh_more18_w "Number of household members 18+"
	lab var owns_car_BL "Household owns car"
	lab var cars_num "Cars owned by household"
	lab var less_than_primary_BL "Highest edu: Less than primary"
	lab var elementary_BL "Highest edu: Elementary (1-5 yrs)"
	lab var highschool_BL "Highest edu: High school (6-12 yrs)"
	lab var any_tertiary_edu_BL "Highest edu: Any tertiary education (13+ yrs)"
	lab var unemployed_BL "Unemployed (searching for job)"
	lab var employed_BL "Employed" 
	lab var on_job_search_BL "On-the-job search"
	lab var ever_employed_BL "Ever employed"
	lab var  work_experience_BL "Years of experience"
	lab var driving_likely_BL "Likely to drive soon after ban is lifted"

	
* Capture estimates and stats 

	* loop over balance vars
	local i = 1

	foreach var in $balance {
		reghdfe `var' treatment, absorb(randomization_cohort2) vce(cluster file_nbr) 
		
		* var label
		global varlab_`i' "`: var label `var''"
		
		* difference and p-val
		global diff_`i' : di %6.2fc _b[treatment]
		global pval_`i' : di %6.2fc r(table)[4,1]
		
		* summary stats within group
		quietly: summarize `var' if treatment==0	// control
		global N_c_`i' = r(N)
		global Mean_c_`i' : di %6.2fc r(mean)
		global sd_c_`i' : di %6.2fc r(sd)
		
		quietly: summarize `var' if treatment==1	// treatment
		global N_t_`i' = r(N)
		global Mean_t_`i' : di %6.2fc r(mean)
		global sd_t_`i' : di %6.2fc r(sd)

		local ++i			// next row
	}

* For f-stat: zero out missing values and include dummies for missings
	foreach i of varlist $balance  {
		
		sum `i' if treatment==0 
		replace `i' = r(mean) if treatment==0 & `i'==.
		
		sum `i' if treatment==1 
		replace `i' = r(mean) if treatment==1 & `i'==.
		
	}



	* f-stat
	reghdfe treatment $balance, absorb(randomization_cohort2) vce(cluster file_nbr) ///
		nocons
	global fstat : di %6.2fc e(F)
	global fstat_pval : di %6.3fc Ftail(e(df_m), e(df_r), e(F))
	

	
	* write table to latex
	texdoc init ///
		"$output_rct/Table_A4", ///
		replace force
		
		tex 			& (1)	 & (2) 	 	 & (3) 					& (4) 	  & (5) 	   & (6) 					 & (7) 		  & (8)	 	\\
		tex				&		 & 	  		 & \underline{Control} 	&  		  &  		   & \underline{Treatment}   &  		  &   	 	\\
		tex				& N 	 & Mean		 & SD 					& N 	  & Mean	   & SD  					 & Difference & P-value  \\
		tex \midrule
		tex	$varlab_1   & $N_c_1  & $Mean_c_1  & $sd_c_1 			& $N_t_1  & $Mean_t_1  & $sd_t_1  			 & $diff_1 	  	  & $pval_1  \\
		tex	$varlab_2   & $N_c_2  & $Mean_c_2  & $sd_c_2 			& $N_t_2  & $Mean_t_2  & $sd_t_2  			 & $diff_2 	  	  & $pval_2  \\
		tex	$varlab_3   & $N_c_3  & $Mean_c_3  & $sd_c_3 			& $N_t_3  & $Mean_t_3  & $sd_t_3  			 & $diff_3 	  	  & $pval_3  \\
		tex	$varlab_4   & $N_c_4  & $Mean_c_4  & $sd_c_4 			& $N_t_4  & $Mean_t_4  & $sd_t_4  			 & $diff_4 	  	  & $pval_4  \\
		tex	$varlab_5   & $N_c_5  & $Mean_c_5  & $sd_c_5 			& $N_t_5  & $Mean_t_5  & $sd_t_5  			 & $diff_5 	  	  & $pval_5  \\
		tex	$varlab_6   & $N_c_6  & $Mean_c_6  & $sd_c_6 			& $N_t_6  & $Mean_t_6  & $sd_t_6  			 & $diff_6 	  	  & $pval_6  \\
		tex	$varlab_7   & $N_c_7  & $Mean_c_7  & $sd_c_7 			& $N_t_7  & $Mean_t_7  & $sd_t_7  			 & $diff_7 	  	  & $pval_7  \\
		tex	$varlab_8   & $N_c_8  & $Mean_c_8  & $sd_c_8 			& $N_t_8  & $Mean_t_8  & $sd_t_8  			 & $diff_8 	  	  & $pval_8  \\
		tex	$varlab_9   & $N_c_9  & $Mean_c_9  & $sd_c_9 			& $N_t_9  & $Mean_t_9  & $sd_t_9  			 & $diff_9 	  	  & $pval_9  \\
		tex	$varlab_10  & $N_c_10 & $Mean_c_10 & $sd_c_10 			& $N_t_10 & $Mean_t_10 & $sd_t_10  			 & $diff_10 	  & $pval_10  \\
		tex	$varlab_11  & $N_c_11 & $Mean_c_11 & $sd_c_11 			& $N_t_11 & $Mean_t_11 & $sd_t_11 			 & $diff_11 	  & $pval_11  \\
		tex	$varlab_12  & $N_c_12 & $Mean_c_12 & $sd_c_12 			& $N_t_12 & $Mean_t_12 & $sd_t_12  			 & $diff_12 	  & $pval_12  \\
		tex	$varlab_13  & $N_c_13 & $Mean_c_13 & $sd_c_13 			& $N_t_13 & $Mean_t_13 & $sd_t_13  			 & $diff_13 	  & $pval_13  \\
		tex	$varlab_14  & $N_c_14 & $Mean_c_14 & $sd_c_14 			& $N_t_14 & $Mean_t_14 & $sd_t_14  			 & $diff_14 	  & $pval_14  \\
		tex	$varlab_15  & $N_c_15 & $Mean_c_15 & $sd_c_15 			& $N_t_15 & $Mean_t_15 & $sd_t_15  			 & $diff_15 	  & $pval_15  \\
		tex	$varlab_16  & $N_c_16 & $Mean_c_16 & $sd_c_16 			& $N_t_16 & $Mean_t_16 & $sd_t_16  			 & $diff_16 	  & $pval_16  \\
		tex	$varlab_17  & $N_c_17 & $Mean_c_17 & $sd_c_17 			& $N_t_17 & $Mean_t_17 & $sd_t_17  			 & $diff_17 	  & $pval_17  \\
		tex	$varlab_18  & $N_c_18 & $Mean_c_18 & $sd_c_18 			& $N_t_18 & $Mean_t_18 & $sd_t_18  			 & $diff_18 	  & $pval_18  \\
		tex	$varlab_19  & $N_c_19 & $Mean_c_19 & $sd_c_19 			& $N_t_19 & $Mean_t_19 & $sd_t_19  			 & $diff_19 	  & $pval_19  \\
		tex \midrule
		tex F-test of joint significance & 	 & 	 	 & 					& 	  &  	   & 					 &  		  & $fstat	 	\\
		tex Prob $>$ F & 	 & 	 	 & 					& 	  &  	   & 					 &  		  & $fstat_pval	 	\\
		texdoc close
		

