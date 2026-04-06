/*******************************************************************************
********************************************************************************
********************************************************************************

Purpose: 		Settings for Saudi commute project 
				
********************************************************************************
********************************************************************************
*******************************************************************************/


	/* 	Instructions to set root folder globals:
	
		Add file path to folder "saudi_women_driving". Global should be
		called "mainfolder". The Subfolder globals are set to run based on
		"mainfolder" and do not need to be edited.	*/

		global 		mainfolder "[INSERT FILE PATH TO REP PACKAGE]/saudi_women_driving"
		

	
********************************************************************************
* Subfolder globals 
********************************************************************************/

global output "$mainfolder/results"
global rep_code "$mainfolder/replication_code"
global data "$mainfolder/data"
global output_descr "$output/descriptive"
global output_rct "$output/RCT/tables"
global logs "$output/log_files"
