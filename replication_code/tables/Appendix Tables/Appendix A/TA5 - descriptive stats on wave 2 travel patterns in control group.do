/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 	Table A5	 - 	Descriptive stats on wave 2 travel patterns in 
							controls group
				
				
Table footnotes: Descriptive statistics from detailed travel diary collected as 
part of the interim follow-up. Control group sample only. Respondents may report 
multiple trips and/or multiple modes for each trip, so means for trip purposes 
and modes can sum to greater than 1.			
********************************************************************************
********************************************************************************
*******************************************************************************/
eststo clear


* RUN THESE DO FILES FIRST:

	do "$rep_code/1 - Pull in data.do"



* Table globals, conditional vars, and re-labeling

label variable trip_any_w2 "Any trip yesterday"
lab variable mean_trip_duration_w2 "Mean one-way trip duration mins $|$ any trip yesterday"
lab var trip_duration_work_cond_w2 "One-way commute duration  mins $|$ any commute to work yesterday"
label variable trip_any_leisure_friendscond_w2 "Leisure to meet friends"
label variable trip_any_leisure_relcond_w2 "Leisure to meet relatives"
label variable trip_any_leisure_parkcond_w2 "Leisure to park or movies"
label variable trip_any_leisure_mealcond_w2 "Leisure for meal"
label variable trip_any_pers_govtcond_w2 "Errands - personal business"
label variable trip_any_pers_healthcond_w2 "Errands - health"
label variable trip_any_shopping_hhcond_w2 "Errands - HH shopping"
label variable trip_any_shopping_perscond_w2 "Errands - personal shopping"
label variable trip_any_pickdropcond_w2 "Pick or drop someone"
label variable trip_any_unicond_w2 "University commute"
label variable trip_any_workcond_w2 "Work commute"
label variable trip_mode_buscond_w2 "Bus provided by university or employer"
label variable trip_mode_footcond_w2 "Walking"
label variable trip_mode_car_drivercond_w2 "Drove herself"
label variable trip_mode_car_familycond_w2 "Car - family member driving"
label variable trip_mode_car_paiddrivercond_w2 "Car with paid driver"
label variable trip_mode_car_poolingcond_w2 "Car pooling"
label variable trip_mode_hailingcond_w2 "Ride-hailing (e.g. Uber)"
label variable trip_mode_taxicond_w2 "Taxi"
label variable trip_mode_othercond_w2 "Other mode"



global 	travelvarsPanelB trip_any_leisure_friendscond_w2 trip_any_leisure_relcond_w2 ///
		trip_any_leisure_parkcond_w2 trip_any_leisure_mealcond_w2 trip_any_pers_govtcond_w2 ///
		trip_any_pers_healthcond_w2 trip_any_shopping_hhcond_w2 ///
		trip_any_shopping_perscond_w2 trip_any_pickdropcond_w2 trip_any_unicond_w2 ///
		trip_any_workcond_w2

global travelvarsPanelC	trip_mode_buscond_w2 trip_mode_footcond_w2 trip_mode_car_drivercond_w2 ///
		trip_mode_car_familycond_w2 trip_mode_car_paiddrivercond_w2 ///
		trip_mode_car_poolingcond_w2 trip_mode_hailingcond_w2 trip_mode_taxicond_w2 ///
		trip_mode_othercond_w2



* Table
estpost summarize trip_any_w2 tripnb_yesterday_w2 mean_trip_duration_w2 ///
		trip_duration_work_cond_w2  if treatment==0 
esttab using "$output_descr/tables/Table_A5_Section_1.tex" , tex ///
	cells("count(label(N)) mean(fmt(2) label(Mean)) sd(fmt(2) label(SD)) min(label(Min)) max(label(Max))") ///
	replace label nonum frag nogaps noobs
	
estpost summarize $travelvarsPanelB  if treatment==0 
esttab using "$output_descr/tables/Table_A5_Section_2.tex" , tex ///
	cells("count mean(fmt(2)) sd(fmt(2)) min max") replace label nonum frag nogaps ///
	mlabels(none) collabels(none) noobs nolines
	
estpost summarize $travelvarsPanelC  if treatment==0 
esttab using "$output_descr/tables/Table_A5_Section_3.tex" , tex ///
	cells("count mean(fmt(2)) sd(fmt(2)) min max") replace label nonum frag nogaps ///
	mlabels(none) collabels(none) noobs nolines



