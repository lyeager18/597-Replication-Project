/******************************************************************************

* Purpose: Anonymize IP address in Qudra link dataset

Notes: This do file takes the raw data and creates an anonymized ID for the 
IP address. We include the anonymized version of the dataset in the replication 
package and therefore this do file is not run as part of the Master.do and is
included only for reference.
*******************************************************************************/


* pull in data
import excel "$data/RCT wave 3/Raw/Qudra Follow-up_September 21, 2022_14.47.xlsx", ///
	sheet("Qudra Follow-up_September 21, 2") firstrow clear
	
	
set seed 20190228

gen random = runiform(1000000, 9999999)

bysort IPAddress: egen IPanon = max(random)
lab var IPanon "Anonymized IP address ID"


drop IPAddress random


export excel using "/Users/kendalswanson/Library/CloudStorage/OneDrive-DukeUniversity/saudi_women_driving/data/RCT wave 3/Raw/Qudra Follow-up_September 21, 2022_14.47.xlsx", firstrow(variables) replace
