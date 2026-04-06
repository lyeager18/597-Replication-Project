/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose:	Figure A5	-	Generate LFP figure with employed / unemployed 


Figure footnotes: Source: Estimates from Saudi LFS - GASTAT. Red vertical line 
shows the date of the driving ban repeal.				
********************************************************************************
********************************************************************************
********************************************************************************/


	use			"$data/Government admin data/gastat_lfp_levels.dta" , clear
	
	replace		time = subinstr(time, "Q", " ", .)
	
	gen			quarter = quarterly(time, "YQ")
	format		quarter %tq
	
	* Calcuate empl / unempl as percentage of the population 
	
	foreach		i in male female { 
	
	gen 		employmentlevel`i' = lfp`i' * employment`i'
	gen			unemploymentlevel`i' = lfp`i' * unemployment`i'  
	
	}
	
	* Rescale to 0-100 for graph
	
	foreach		i of varlist lfp* employment* unemployment* {
		
	replace		`i' = `i' * 100 	
		
	}
	
	
	* Local for axis labels 
	forval 		i = 2017/2023 {
	local 		x = q(`i'q1)
	local 		X "`X'`x' " 
	}
	
	twoway 		(line employmentlevelmale quarter) ///
					(line employmentlevelfemale quarter) ///
					(line unemploymentlevelfemale quarter) , ///		
					ytitle("Percentage") ///
					legend(label(1 "Male employment" ) label(2 "Female employment") label(3 "Female unemployment")) ///
					xla(`X') ///
					xline(234) 	// xline shows 2018 q3, when ban was lifted
	
	
	graph		export "$output_descr/figures/Figure_A5.eps" ,  replace 
