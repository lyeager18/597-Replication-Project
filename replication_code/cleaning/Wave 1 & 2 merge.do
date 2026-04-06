***** REMEMBER TO RUN SETTINGS.DO FILE FIRST ******

/******************************************************************************
Purpose: Merge wave 1 and wave 2
                                           
Created: June 17, 2020
*******************************************************************************/
clear all
set more off

**************************************************************************

use "${data}/RCT admin and wave 1/Final/Wave1.dta", clear


merge 1:1 participantid using "${data}/RCT wave 2/Final/Wave2.dta"
drop _merge


save "${data}/RCT wave 2/Final/Combined_waves1and2_final.dta", replace 

