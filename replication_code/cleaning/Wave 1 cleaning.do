***** REMEMBER TO RUN SETTINGS.DO FILE FIRST ******

/******************************************************************************

               First analysis of Uber and Wusool Intervention             

Purpose:  1- Prepare a balance table for the four treatment groups
                                           
Created: July 14, 2019 by Hussain Alshammasi                                   
Last edited: June 16, 2020 by Adam Soliman
*******************************************************************************/
clear all
set more off


**************************************************************************
* Import Exel data:
*                                                      
* The dataset was shared by Chaza in Excel format which combines data    
* from baseline and some administrative data for Alnahda beneficiaries.  
* The treatment indicator is in variables driving_ct and wusool_ct.
* "None" indicates not being randomized to the treatment or control sample.
* Randomization was done by Chaza. Find code in:
* Dropbox\EPoD Female Transport\4. Surveys\DoFiles\Randomization code-20180827
* 
* The 4 treatment groups are:
*      1- Driving Treatment Wusool Control
*      2- Driving Treatment Wusool Treatment
*      3- Driving Control Wusool Treatment
*      4- Driving Control Wusool Control
*
*
**************************************************************************

/* bring in the exclusion sheet to merge later
import excel "RCT admin and wave 1/Data/Exclusion sheet.xlsx", sheet("Sheet1") cellrange(A1:F1096) firstrow clear
drop if new_id == .
save "RCT admin and wave 1/Data/Exclusion_sheet.dta", replace
*/

import excel "${data}/RCT admin and wave 1/Raw/deidentified commute dataset-20191017.xlsx", ///
sheet("Full Uber dataset") cellrange(A1:CG1114) firstrow clear

*labeling variables with first row
foreach var of varlist * {
  label variable `var' "`=`var'[1]'"
}

drop if _n == 1 //dropping explanation of variable name after variables have been labeled
drop if new_id == "" // dropping blank observations 

* drop if driving_ct == "None" & wusool_ct == "None" //these are women who were excluded from randomization




////////////////////////////////////////////////////////////////////////////////
/* THIS IS A NEW SECTION AS OF AUG 2, 2023: 

THIS IS MEANT TO RESOLVE THE DATA GENERATION INCONSISTENCIES THAT ARISE FROM 
DUPLICATES THAT, WHEN SORTED BY NEW_ID, ARE RANDOMLY SORTED WITHIN NEW_ID AND 
THEREFORE THE OBSERVATIONS THAT GET TAGGED AS A DUPLICATE CAN VARY WHEN THIS FILE
IS RE-RUN.

OBSERVATIONS FOR ALL BUT ONE PARTICIPANT CAN BE SORTED UNIQUELY BY new_id AND 
RecordedDate. FOR THE PARTICIPANT WITH TWO OBSERVATIONS THAT CANNOT BE UNIQUELY
SORTED BY RecordedDate, WE WILL CREATE AN _n VARIABLE WHICH PRESERVES THE ORDER
IN WHICH THOSE OBSERVATIONS WERE RECORDED IN THE ORIGINAL RAW DATA FILE. WE'LL 
THEN TAKE THE LAST NON-MISSING VALUE OF EACH VARIABLE ACCORDING TO RecordedDate
AND _n. THIS WILL GUARANTEE REPLICABILITY EACH TIME THIS FILE IS RUN. 
*/

	* preserve raw data order of observations
	gen raw_order = _n
	
	* test that sorting by new_id RecordedDate and raw_order gives us a unique sort
	duplicates report new_id RecordedDate raw_order
	
	if r(unique_value)!= r(N) {
		di error "Not a unique sort for duplicates"
		break
	}
	
	* sort by new_id RecordedDate and raw_order - this gives us a unique sort
	sort new_id RecordedDate raw_order
	collapse (lastnm) cohort_alnahda-old_id Institution-raw_order, by(new_id)

	


////////////////////////////////////////////////////////////////////////////////

tab driving_ct wusool_ct 
**************************************************************
*  clean and summarize treatment groups (including updates)  *
**************************************************************

tab driving_ct 

gen driving_ct2 = ""
replace driving_ct2 = "Control" if driving_ct == "Control" 
replace driving_ct2 = "Treatment" if driving_ct == "Treatment"  ///
								| driving_ct == "Treatment then none (very old, risk that her daughter filled the survey on her behalf)" 

replace driving_ct2 = "Control" if  driving_ct == "Control then treatment (May12mistake)" ///
                                  |  driving_ct == "Control then treatment (alnahdanominee)"  // People who were assigned to be in the control, but were signed up to driving anyway
								  
								  
replace driving_ct2 = "" if  driving_ct == "None then Treatment  (May12mistake)" ///
                                  |  driving_ct == "None then Treatment (May12mistake)" ///
                                  |  driving_ct == "None then Treatment(alnahdanominee)" ///
                                  |  driving_ct == "None then treatment (May12mistake)" // People who were assigned to NOT be in the experiment, but were signed up to driving anyway
								  
tab driving_ct2 	

************** signed agreement ******************
* generating an indicator for signing the driving subsidy agreement. Note that 300 people signed the agreement.
gen signed = .
replace signed = 1 if signed_agreement == "Yes" | signed_agreement == "No, but filled schedule" | signed_agreement == "No,but filled schedule"
tab signed  // total people who signed is 300.
tab driving_ct signed 
tab driving_ct2 signed  // Note that we will drop those who got the treatment but were not initially randomized to get it
													
								  
tab wusool_ct

gen wusool_ct2 = ""
replace wusool_ct2 = "Control" if wusool_ct == "Control" ///
      | wusool_ct == "Control (very old, risk that her daughter filled the survey on her behalf)" 
	  
replace wusool_ct2 = "Treatment" if wusool_ct == "Treatment"  

replace wusool_ct2 = "" if wusool_ct == "None then Control (May12mistake)" | wusool_ct == "None" 


tab wusool_ct2 

tab wusool_ct2 driving_ct2  

* generating groups in one column for later use in the balance table command
gen group = "Uber"+driving_ct2+" "+ "Wusool" +wusool_ct2
tab group

* generating treatment indicators
gen driving_T = .
replace driving_T = 0 if driving_ct2 == "Control"
replace driving_T = 1 if driving_ct2 == "Treatment"
tab driving_T 

gen wusool_T = .
replace wusool_T = 0 if wusool_ct2 == "Control"
replace wusool_T = 1 if wusool_ct2 == "Treatment"
tab wusool_T 

replace Notes = "" if new_id == "1617" //there was a mistake in the notes for this ID
								  

************ Dropping late joiners from same household ************
* There was imbalance in the number of household members in the study, possibly because
* members from the same household were added upon request after finding out that someone
* from their household was selected to treatment. We drop members from the same household
* who joined the study in a later cohort. ONLY BIG FAMILIES?


sort  Institution file_nbr new_id
by Institution file_nbr: gen HH_size = _N

quietly bysort Institution file_nbr:  gen dup_file = cond(_N==1,0,_n) //generating unique identifier for household to tab household size
replace dup_file = 0 if dup_file == 1
replace dup_file = 1 if dup_file > 0

tab HH_size if dup_file == 0


* A late joiner is a household member that is in a later  randmization cohort than the cohort of the first household member to join the study.
* Cohorts were numbered in sequence. 1.1, 1.2, 1.3, 2.1, 2.2, 3. 1 for Alnahda, 2 for Insan, 3 for Mawadah

sort Institution file_nbr randomization_cohort

quietly by Institution file_nbr: egen double min_cohort = min(randomization_cohort) //generating a variable containing the minimum cohort for each household

gen late_joiner = 0

order Institution file_nbr new_id HH_size randomization_cohort min_cohort late_joiner

replace late_joiner = 1 if randomization_cohort != min_cohort //26 participants were identified as late joiners

tab late_joiner

* drop if late_joiner == 1 \\ tag late joiners, no dropping 

**************** Treatment Given Variables *******************************

**** remove suspended from treatment and control *****

* After the randomization for treatment happened and before giving treatment, 
* some participants graduated from Alnahda beneficiary program and were no longer eligible
* to get the uber subsidy. We decided to remove them from the analysis along with everyone who
* graduated to make sure that the drop is not affected by treatment group.
* The variable Suspended_admin indicates if they graduated

tab Suspended_admin
gen Suspended = 0 //generating indicatort for graduation from Alnahda (or suspended)
replace Suspended = 1 if Suspended_admin == "إيقاف" | Suspended_admin == "طي قيد"
tab Suspended  //150 graduated
tab group if Suspended == 1 // Note that some were just control or receiving just wusool subsidy
* drop if Suspended == 1


*note these 5 get dropped after this block
*browse if new_id == "1562" | new_id == "1637" | new_id == "10584" | new_id == "10703" | new_id == "10728"

**************** Given Driving Subsidy Treatment Status *******************************
tab driving_T  //we will drop those randomized to get driving subsidy did not get it because they did not answer even with multple attempts to offer it

*We decided to drop those that did not answer from all treatment arms only if they were not from the initial randomization, ie from cohort 1.2 or above.

*5 women not given driving treatment because of no answer:
tab new_id if driving_T == 1  & invited_eventdate == "None" & signed == .  & randomization_cohort != 1.1
* drop if driving_T == 1  & invited_eventdate == "None" & signed == . & randomization_cohort != 1.1

tab driving_T 

replace signed = 0 if driving_T ==1 & signed == .
tab signed  // total signed remaining is 285.


**************** Given Wusool information Treatment Status *******************************
****** need to revisit this section
* Some did not get Wusool info over the phone or in the event even though they were supposed to. We drop them from the analysis except if they got the driving treatment
tab wusool_T


*drop those that did not get wusool info but keep those who got driving T:
tab Haveyouheardaboutthisprogra //this question asked if they heard about a transportation subsidy program
tab Doyouknowthenameoftheprog //if they said yes, this question asked if thet knew the name of the program
gen wusool_T_offered = 1 if wusool_T == 1 //generating indicator for giving wussol info treatment. Start by assuming everyone got the treatment if they were supoosed to
tab wusool_T_offered 

* The following IDs were not asked about wusool
tab new_id if wusool_T == 1  & (Haveyouheardaboutthisprogra == "" | Haveyouheardaboutthisprogra=="0") ///
                             & (Doyouknowthenameoftheprog == "" | Doyouknowthenameoftheprog=="0") & dup == 0
							 
replace wusool_T_offered = 0 if wusool_T == 1  & (Haveyouheardaboutthisprogra == "" | Haveyouheardaboutthisprogra=="0") ///
                             & (Doyouknowthenameoftheprog == "" | Doyouknowthenameoftheprog=="0") ///
							 
							 
* drop if wusool_T == 1 &  wusool_T_offered == 0 & driving_T == 0 & randomization_cohort != 1.1 //21 dropped because of not receiving wusool info and not being in the driving treatment group


tab wusool_T wusool_T_offered 

tab driving_ct2 wusool_ct2

***********************************************************
*    Cleaning variables
***********************************************************
*Data came from surveys or admin data. We use both to fill where needed.
************ Age Variable ************ 

destring age,replace
count if age == . //1 missing data (only available in category age variable)
label var age "Age"

************* Marital Status Variable based on admin and survey question ************
*admin data:
gen maritalstatus2 = ""
replace maritalstatus2 = "Divorced" if marital_admin == "مطلقة " | marital_admin == "مطلقة"
replace maritalstatus2 = "Married" if marital_admin == "متزوجه" | marital_admin == "متزوجة" ///
                                    | marital_admin == "متزوجة (سجين)" | marital_admin == "الارمله متزوجة وتسكن مع الزوج والابناء "
									
replace maritalstatus2 = "Single" if marital_admin == "عزباء"
replace maritalstatus2 = "widowed" if marital_admin == "أرملة" | marital_admin == "أرملة " | marital_admin == "ارملة" ///
                                 | marital_admin == "ارملة وتسكن مع الأبناء" 
replace maritalstatus2 = "Family of Prisinor" if marital_admin == "أسرة سجين"
replace maritalstatus2 = "abandoned" if marital_admin == "مهجورة" | marital_admin == "مهجوره "

gen married1 = .
replace married1 = 1 if maritalstatus2 == "Married" 
replace married1 = 0 if maritalstatus2 != "Married" & maritalstatus2 != ""  //marriage indicator from admin data

*Survey data:
rename ماهيحالتكالاجتماعية maritalstatus3
gen maritalstatus4 = ""
replace maritalstatus4 = "Divorced" if maritalstatus3 == "مطلقة"
replace maritalstatus4 = "Married"  if maritalstatus3 == "متزوجة"
replace maritalstatus4 = "Single"   if maritalstatus3 == "عزباء"
replace maritalstatus4 = "Prefer not to answer"  if maritalstatus3 == "أفضل عدم الإجابة على هذا السؤال"
replace maritalstatus4 = "widowed" if maritalstatus3 == "أرملة"

gen married2 = .
replace married2 = 1 if maritalstatus4 == "Married" 
replace married2 = 0 if maritalstatus4 != "Married" & maritalstatus2 != "Prefer not to answer"  //marriage indicator from survey data

gen married = . //generating a combined variable to fill from both admin and survey data as needed
replace married = 1 if married1 == 1 | married2 == 1 //if either admin or survey indicate married, we consider her married
replace married = 0 if married1 == 0 & married2 == 0 //if both admin and survey indicate not married, we consider her not married
replace married = 0 if married1 == . & married2 == 0 //if admin indicated not married but survey is missing, we consider her not married
replace married = 0 if married1 == 0 & married2 == . //if survey indicated not married but admin is missing, we consider her not married
label var married "Married"
tab married

************ Education Variable ************

*years of education (assume college = 4 years, Diploma = 2 years, Elementary =3 years, Masters =2 years, Primary = 6 years, Read&write = 1 year ,Secondary = 3 years:

*Start with Survey data (Whatisyourlevelofeducation) and fill from admin (Education) if survey data is missing or prefer not to answer:
gen education_level = Whatisyourlevelofeducation
replace education_level = Education if education_level =="" | education_level =="0" | education_level =="I prefer not to answer this question"
tab education_level

gen education2 = . //this is years of education
label var education2 "Education"

replace education2 = 18 if education_level == "Masters" | education_level == "ماجستير"  

replace education2 = 16 if education_level == "College" | education_level == "تعليم جامعي" ///
                         | education_level == "بكالوريوس" | education_level == "بكالوريوس "  ///
						 | education_level == "بكالويوس " |  education_level == "طالبة جامعية"

replace education2 = 13	if education_level == "ثاني دبلوم"

replace education2 = 14 if education_level == "Diploma" | education_level == "دبلوم" ///
                         | education_level == "شهادة دبلوم" | education_level == "كلية" | education_level == "دبلوم " ///


replace education2 = 12 if education_level == "Secondary" | education_level == "ثانوي" /// 
                         | education_level == "ثالث ثانوي" | education_level == "ثانوية" ///
						 | education_level == "متخرجة من الثانوي"

replace education2 = 11 if education_level == "ثاني ثانوية" | education_level == "ثاني ثانوي" 

replace education2 = 10 if education_level == "أولى ثانوي" | education_level == "أول ثانوي" | education_level == "أول ثانوية"

										 
replace education2 = 9 if education_level == "Elementary" | education_level == "متوسط" ///
                        | education_level == "إعدادي" | education_level == "ثالث متوسط" ///
						| education_level == "متوسطة"

replace education2 = 8 if education_level =="ثاني متوسط"					

replace education2 = 7 if education_level =="أول متوسط"					
		
replace education2 = 6 if education_level == "Primary" | education_level == "إبتدائي" ///
                        | education_level == "ابتدائي"  | education_level =="تدرس ثانوي" ///
						| education_level == "سادس ابتدائي"

						
replace education2 = 5 if education_level == "خامس ابتدائي"				
						
replace education2 = 5 if education_level == "رابع ابتدائي"				
												
replace education2 = 1 if education_level == "Read and Write" | education_level == "أقرا و أكتب" | education_level == "تقرأ وتكتب" | education_level == "خامس محو أمية"

replace education2 = 0 if education_level == "أمية" 
//12 prefer not to answer

tab education2

* The following are dummy variables for each level of education:
gen education_masters = 0
replace education_masters = 1 if education_level == "Masters" | education_level == "ماجستير" 
replace education_masters = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab education_masters

gen education_college = 0
replace education_college = 1 if education_level == "College" | education_level == "تعليم جامعي" ///
                         | education_level == "بكالوريوس" | education_level == "بكالوريوس "  ///
						 | education_level == "بكالويوس " |  education_level == "طالبة جامعية"						 
replace education_college = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab education_college


gen education_diploma = 0
replace education_diploma = 1 if education_level == "ثاني دبلوم" | education_level == "Diploma" | education_level == "دبلوم" ///
                         | education_level == "شهادة دبلوم" | education_level == "كلية" | education_level == "دبلوم " 
replace education_diploma = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab education_diploma

gen education_highschool = 0
replace education_highschool = 1 if education_level == "Secondary" | education_level == "ثانوي" /// 
                                  | education_level == "ثالث ثانوي" | education_level == "ثانوية" ///
						          | education_level == "متخرجة من الثانوي" | education_level == "ثاني ثانوية" | education_level == "ثاني ثانوي" ///
						          | education_level == "أولى ثانوي" | education_level == "أول ثانوي" | education_level == "أول ثانوية"
replace education_highschool = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab education_highschool


gen education_elementary = 0
replace education_elementary = 1 if education_level == "Elementary" | education_level == "متوسط" ///
                                  | education_level == "إعدادي" | education_level == "ثالث متوسط" ///
					            	| education_level == "متوسطة" | education_level =="ثاني متوسط"	| education_level =="أول متوسط"	
replace education_elementary = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab education_elementary

gen education_primary = 0
replace education_primary = 1 if education_level == "Primary" | education_level == "إبتدائي" ///
                        | education_level == "ابتدائي"  | education_level =="تدرس ثانوي" ///
						| education_level == "سادس ابتدائي" | education_level == "خامس ابتدائي" | education_level == "رابع ابتدائي"			
replace education_primary = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab education_primary


gen education_read = 0
replace education_read = 1 if education_level == "Read and Write" | education_level == "أقرا و أكتب" | education_level == "تقرأ وتكتب" | education_level == "خامس محو أمية"	 
replace education_read = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab education_read


gen no_education = 0
replace no_education = 1 if education_level == "0" | education_level == "أمية" 
replace no_education = . if education_level == "" | education_level == "افضل عدم الإجابة على هذا السؤال" 
tab no_education	

*The following is a dummy variable = 1 if years of education were more than 12. This was chosen because high school is 12 years of education
gen educated = .
replace educated = 0 if education2 <= 12 & education2 !=.
replace educated = 1 if education2 > 12 & education2 !=.
tab educated

************ Employment Variable ************
*Based on admin data:
gen employment1 = ""
replace employment1 = "Housewife" if Employed_admin == "ربة المنزل" | Employed_admin == "ربة منزل"
replace employment1 = "Student" if Employed_admin == "طالبة" | Employed_admin == "طالبة عن بعد" | Employed_admin == "طالبة/ موظفة" | Employed_admin == "موظفة/ طالبة"
replace employment1 = "Unemployed" if Employed_admin == "عاطلة" | Employed_admin == "لاتعمل" | Employed_admin == "لاتعمل "
replace employment1 = "Retired" if Employed_admin == "متقاعدة"
replace employment1 = "Employed" if Employed_admin == "موظفة" | Employed_admin == "تعمل"

tab employment1

*Based on survey question "are you employed":
rename هلأنتموظفة are_you_employed

gen employed = .
replace employed = 0 if ///
	are_you_employed == "No, I am not employed and I am looking for a job" | ///
	are_you_employed == "No, and I am looking for a job" | ///
	are_you_employed == "لا، أنا طالبة وأنوي العمل بعد التخرج" | ///
	are_you_employed == "لا، وأبحث عن وظيفة" | ///
	are_you_employed == "لا، ولا أبحث عن وظيفة" | ///
	are_you_employed == "لا، ولا أبحث عن وظيفة"  

replace employed = 1 if ///
	are_you_employed == "Yes, I am employed and open to looking for a different job" | ///
	are_you_employed == "Yes, and I am looking for a different job" | ///
	are_you_employed == "نعم، وأبحث عن وظيفة أخرى" | ///
	are_you_employed == "نعم، ولا أبحث عن وظيفة أخرى" 
	
*Combining admin and survey data:
replace employed = 1 if employed == . & employment1 == "Employed"
replace employed = 0 if employed == . & employment1 != "Employed"
tab employed	

************ Car Ownership Variable ************
*This was asked in the survey. How many cars does your household own?

rename كمعددالسياراتالتيتمتلكهاأسر car

replace car = "I prefer not to answer" if car ==  "أفضل عدم الإجابة على هذا السؤال"
replace car = "More than 4" if car ==  "أكثر من 4"

gen car2 = car
replace car2 = "4" if car == "More than 4" //if they answerwed more than 4, we record it as 4
replace car2 = "." if car == "I prefer not to answer"
label var car2 "Car Ownership"

destring car2,replace //making variable numeric
tab car2 //number of cars per household

*A dummy variable for car ownership
gen icar =.
replace icar = 0 if car2==0
replace icar =1 if car2 > 0 & car2!=.
label var icar "Car Ownership"
tab icar


************ Driving Likelihood Variable ************
* A question in the survey asked about the likelihood of driving
rename ماهياحتماليةقيادتكالسيارةب driving_likelihood_ar

*generating a dummy variable = 1 if likely to drive. We consider any indication of possible driving in the future to be "likely to drive"
gen driving_not_unlikely_BL = .
replace driving_not_unlikely_BL = 0 if 	driving_likelihood_ar == "أمر مستبعد" |  ///
								driving_likelihood_ar == "Somewhat unlikely"

replace driving_not_unlikely_BL = 1 if 	driving_likelihood_ar == "Likely" | ///
								driving_likelihood_ar == "Somewhat likely" | ///
								driving_likelihood_ar == "محتمل" | ///
								driving_likelihood_ar == "محتمل/ليس في البداية" ///
								| driving_likelihood_ar == "محتمل/ليس في البداية" | ///
								driving_likelihood_ar == "من الممكن/ ليس في البداية" ///
								| driving_likelihood_ar == "احتمالية قليلة"	  
lab var driving_not_unlikely_BL ///
		"Somewhat likely, likely, or likely but not at first to drive when ban lifted"
	
tab driving_not_unlikely_BL  // 14 missing.  2 observations "0" & 9 prefer not to answer & 2 "indifferent" & one from insan not surveyed

** أمر مستبعد unlikely محتمل likely محتمل/ليس في البداية" likely but not at firstمن الممكن/ ليس في البداية likely but not at first احتمالية قليلة somewhat likely

************ Driving School Registration Likelihood Variable ************


rename هلسجلتفيمدرسةالقيادة drivingschool_register //question asks have you registered to driving school. 11 missing

gen drivingschool_register2 = drivingschool_register
replace drivingschool_register2 = "Prefer not to answer" if drivingschool_register == "0" | drivingschool_register == "أفضل عدم الإجابة على هذا السؤال"
replace drivingschool_register2 = "No, but planning to" if drivingschool_register == "لا، لم اسجل لكن أنوي اقيام بذلك" 
replace drivingschool_register2 = "No, and not planning to" if drivingschool_register == "لا، ولا أنوي التسجيل" 
replace drivingschool_register2 = "Yes, I registered" if drivingschool_register == "نعم، سجلت" 


gen reg_dr = . // variable about registration to school prior to experiment start. 3 participants registered before experiment. 2 are in treatment
replace reg_dr = 1 if drivingschool_register2 == "Yes, I registered"
replace reg_dr = 0 if drivingschool_register2 != "Yes, I registered" & drivingschool_register2 != "" ///
                    & drivingschool_register2 != "Prefer not to answer" ///
					& drivingschool_register2 != "0"

gen dr_Def_No = . // variable about their intent to register before experiment
label variable dr_Def_No "Driving School Registration Intent before experiment"

replace dr_Def_No = 0 if drivingschool_register2 == "No, and not planning to" 
replace dr_Def_No = 1 if drivingschool_register2 == "No, but planning to" 


*generating new HH_size after dropping the late joiners and all other drops:

**** more of how many from hh in study 
 
order Institution file_nbr new_id
sort  Institution file_nbr new_id
by Institution file_nbr: gen HH_size2 = _N
order Institution file_nbr new_id HH_size2 randomization_cohort

tab HH_size2 
label var HH_size2 "HH Members"



***********************************************************
*    generate fixed effect variables
***********************************************************

tostring randomization_cohort, gen(randomization_cohort2)




destring new_id, replace


* create baseline searching dummy variable
tab are_you_employed
gen BLsearch = 0 if are_you_employed == "أفضل عدم الإجابة على هذا السؤال" | are_you_employed == "لا، ولا أبحث عن وظيفة" | are_you_employed == "نعم، ولا أبحث عن وظيفة أخرى" | are_you_employed == "0" 
replace BLsearch = 1 if are_you_employed == "لا، أنا طالبة وأنوي العمل بعد التخرج" | are_you_employed == "لا، وأبحث عن وظيفة" | are_you_employed == "نعم، وأبحث عن وظيفة أخرى"
label variable BLsearch "baseline job search"

***** bring in exclusion sheet and drop necessary observations
merge m:1 new_id using "${data}/RCT admin and wave 1/Raw/Exclusion_sheet.dta"
drop _merge


rename new_id participantid
replace driving_ctoriginal = "None" if driving_ctoriginal == "None "

* create dummy for missing covariates

/*
gen educationmi = (education2 ==.)
replace education2 = 0 if educationmi == 1 

gen marriedmi = (married ==.)
replace married = 0 if marriedmi == 1 

gen hhsizemi = (HH_size2 ==.)
replace HH_size2 = 0 if hhsizemi == 1 

gen carmi = (car2 ==.)
replace car2 = 0 if carmi == 1 

gen agemi = (age ==.)
replace age = 0 if agemi == 1 

gen hhsizegrmed = (HH_size2>=2)
label var hhsizegrmed "HH Size Greater/Equal to Median"
*/

***	ADDITIONAL CLEANING FOR MERGE WITH WAVE 3/FINAL ANALYSIS

rename group group_BL
rename employed employed_BL

 replace age =. if age==0
	* NOTE: there are 3 observations with age==0 
	
	gen cohort = 1 if randomization_cohort2=="1.1"
	replace cohort = 2 if randomization_cohort2=="1.2"
	replace cohort = 3 if randomization_cohort2=="1.3"
	replace cohort = 4 if randomization_cohort2=="2.1"
	replace cohort = 5 if randomization_cohort2=="2.2"
	replace cohort = 6 if randomization_cohort2=="3"
	
	* clean likert version of driving likelihood variable
	gen driving_likely_likert_BL = .
	replace driving_likely_likert_BL = 1 if driving_likelihood_ar == "أمر مستبعد"
	replace driving_likely_likert_BL = 2 if driving_likelihood_ar == "احتمالية قليلة"
	replace driving_likely_likert_BL = 3 if driving_likelihood_ar == "من الممكن/ ليس في البداية" ///
											| driving_likelihood_ar == "محتمل/ليس في البداية"
	replace driving_likely_likert_BL = 4 if driving_likelihood_ar == "محتمل"
	lab var driving_likely_likert_BL "Likert scale of likeliness to drive (w1)"
	/* Translation:  أمر مستبعد unlikely محتمل likely محتمل/ليس في البداية" likely but not at firstمن الممكن/ ليس في بداية likely but not at first احتمالية قليلة somewhat likely */
	
	* create driving likely binary using most likely ==1 and else==0
	gen driving_likely_BL = 0 if driving_likely_likert_BL!=.
	replace driving_likely_BL = 1 if driving_likely_likert_BL==4
	lab var driving_likely_BL "Likely to drive when ban is lifted"
	
	drop driving_likelihood_ar
	
		
	* create edu var 
	gen edu_category = 0 if education2<12 & education2!=.
	replace edu_category = 1 if education2==12
	replace edu_category = 2 if education2>12 & education2!=.
	lab def educat 0 "Less than secondary (<12 yrs)" 1 "Completed secondary (12 yrs)" ///
	2 "Any tertiary (>12 yrs)" 	
	lab val edu_category educat
	lab var edu_category "Education level"
	
	* Update edu vars 
	gen less_than_primary = 0
	replace less_than_primary = 1 if no_education==1 | education_read==1 | education2==0
	replace less_than_primary = . if no_education==. & education_read==. & ///
	 education_primary==. &  education_elementary==. & education_highschool==. & ///
	 education_diploma==. & education_college==. & education_masters==. & education2==.
	lab var less_than_primary "Less than primary"
	
	gen elementary = 0
	replace elementary = 1 if education_primary==1 | education_elementary==1 
	replace elementary = . if no_education==. & education_read==. & ///
	 education_primary==. & education_elementary==. & education_highschool==. & ///
	 education_diploma==. & education_college==. & education_masters==. & education2==.
	lab var elementary "Elementary (1-5 yrs)"
	
	gen highschool = 0
	replace highschool = 1 if education_highschool==1 
	replace highschool = . if no_education==. & education_read==. & ///
	 education_primary==. & education_elementary==. & education_highschool==. & ///
	 education_diploma==. & education_college==. & education_masters==. ///
	 & education2==.
	lab var highschool "Highschool (6-12 yrs)"
	
	gen any_tertiary_edu = 0 
	replace any_tertiary_edu = 1 if education_diploma==1 | education_college==1 | education_masters==1
	replace any_tertiary_edu = . if no_education==. & education_read==. & ///
	 education_primary==. & education_elementary==. & education_highschool==. & ///
	 education_diploma==. & education_college==. & education_masters==. & ///
	 education2==.
	lab var any_tertiary_edu "Any tertiary education (13+ yrs)"
	
	
	* label edu vars
	lab var no_education "No education"
	lab var education_read "Literate"
	lab var education_primary "Primary school"
	lab var education_elementary "Elementary school"
	lab var education_highschool "High school"
	lab var education_diploma "Diploma"
	lab var education_college "College"
	lab var education_masters "Masters"
	
	
	* labor force status: employed, unemployed and searching, out of labor force
	gen LF_status_BL = .
	lab var LF_status_BL "Labor force status at BL"
	replace LF_status_BL = 0 if employed_BL ==0 & BLsearch==0
	replace LF_status_BL = 1 if employed_BL ==0 & BLsearch==1
	replace LF_status_BL = 2 if employed_BL ==1 
	lab def lfstat 0 "out of LF at BL" 1 "unemployed at BL" 2 "employed at BL"
	lab val LF_status_BL lfstat
	
	* labor force status binary: out of labor force, in labor force
	gen LF_BL = . 
	replace LF_BL = 0 if employed_BL ==0 & BLsearch==0
	replace LF_BL = 1 if employed_BL ==0 & BLsearch==1
	replace LF_BL = 1 if employed_BL ==1 
	lab def lf 0 "Out of labor force at BL" 1 "In the labor force at BL" 
	lab val LF_BL lf

	
	lab var LF_BL "In labor force at BL" 
	lab var employed_BL "Employed at BL" 
	lab var BLsearch "Searching for jobs at BL"
	
	* create opposite var (to match what we have in the paper tables)
	gen not_in_LF_BL = . 
	replace not_in_LF_BL = 1 if employed_BL ==0 & BLsearch==0
	replace not_in_LF_BL = 0 if employed_BL ==0 & BLsearch==1
	replace not_in_LF_BL = 0 if employed_BL ==1 
	lab def notf 0 "In labor force at BL" 1 "Not in the labor force at BL" 
	lab val not_in_LF_BL notlf
	lab var not_in_LF_BL "Out of LF at BL"
	
	* unemployed
	gen unemployed_BL = .
	replace unemployed_BL = 0 if employed_BL ==0 & BLsearch==0
	replace unemployed_BL = 0 if employed_BL ==1 & BLsearch==0
	replace unemployed_BL = 0 if employed_BL ==1 & BLsearch==1
	replace unemployed_BL = 1 if employed_BL ==0 & BLsearch==1
	lab var unemployed_BL "Unemployed (searching for job) at BL"
	
	* on-the-job search at BL
	gen on_job_search_BL = .
	replace on_job_search_BL = 0 if employed_BL ==0
	replace on_job_search_BL = 0 if employed_BL ==1 & BLsearch==0
	replace on_job_search_BL = 1 if employed_BL ==1 & BLsearch==1
	lab var on_job_search_BL "On-the-job search at BL"
	
	* Re-create household size
	rename كمعددالأشخاصفيأسرتكالقاطن hh_les18
	rename AL hh_more18
	 
	replace hh_les18="1" if hh_les18== "1`"
	destring hh_les18, replace
	lab var hh_les18 "Number of HH members <18 (un-winsorized)"

	replace hh_more18="1" if hh_more18=="1بنت"
	destring hh_more18, replace
	replace hh_more18=0 if hh_more18==. & hh_les18!=.
	replace hh_more18 = hh_more18 + 1 if hh_more18!=.
	lab var hh_more18 "Number of HH members 18+ (un-winsorized)"

	
	* assumption 1: if hh_more18 is missing but hh_les18 is not missing, then
	* assume respondent meant to put '0' (which becomes 1 to include themselves)
	* assumption 2: if hh_les18 is missing but hh_more18 is not missing, then
	* assume respondent meant to put '0'
	replace hh_more18=1 if hh_more18==. & hh_les18!=.
	replace hh_les18=0 if hh_les18==. & hh_more18!=.
	
	* move Excluded values to missing to avoid affecting the winsorizing step
	replace hh_more18 = . if Excluded==1
	replace hh_les18 = . if Excluded==1
	
	* winsorize
	winsor2 hh_more18, cuts(0 95)
	lab var hh_more18_w "Number of HH members age 18+ (right tail winsor)" 
	
	winsor2 hh_les18, cuts(0 95)
	lab var hh_les18_w "Number of HH members age <18 (right tail winsor)" 
	
	gen household_size = hh_les18_w + hh_more18_w
	lab var household_size "Household size" 
	
	* Ratio of children to adults in the household
	gen hh_kid_adu_ratio = hh_les18_w/hh_more18_w
	lab var hh_kid_adu_ratio "Ratio of children to adults in household"
	
		* now cut this at the median
		xtile hh_kid_adult_abovemed = hh_kid_adu_ratio, nq(2)
		recode hh_kid_adult_abovemed (1 = 0) (2 = 1)
		lab var hh_kid_adult_abovemed "Ratio of children to adults in HH, split at median"
		
	* One child and multiple children
		gen one_child = 0 if hh_les18_w!=.
		replace one_child = 1 if hh_les18_w==1
		lab var one_child "One child in the household"
		
		gen mult_children = 0 if hh_les18_w!=.
		replace mult_children = 1 if hh_les18_w>1 & hh_les18_w!=.
		lab var mult_children "Multiple children in the household"
	
	* marital status 
	gen marital_admin_eng = ""
	replace marital_admin_eng = "Divorced/seperated" if marital_admin == "مطلقة " | ///
		marital_admin == "مطلقة" |marital_admin == "أسرة سجين"| ///
		marital_admin == "مهجورة" | marital_admin == "مهجوره "
	replace marital_admin_eng = "Married" if marital_admin == "متزوجه" | ///
		marital_admin == "متزوجة" | marital_admin == "متزوجة (سجين)" | ///
		marital_admin == "الارمله متزوجة وتسكن مع الزوج والابناء "							
	replace marital_admin_eng = "Never-married" if marital_admin == "عزباء"
	replace marital_admin_eng = "Widowed" if marital_admin == "أرملة" | ///
		marital_admin == "أرملة " | marital_admin == "ارملة" | marital_admin ///
		== "ارملة وتسكن مع الأبناء"
	lab var marital_admin_eng "Marital status pulled from admin data"
	
	gen marital_survey_BL = ""
	replace marital_survey_BL = "Divorced/seperated" if maritalstatus3 == "مطلقة"
	replace marital_survey_BL = "Married"  if maritalstatus3 == "متزوجة"
	replace marital_survey_BL = "Never-married"   if maritalstatus3 == "عزباء"
	replace marital_survey_BL = "Prefer not to answer"  if ///
		maritalstatus3 == "أفضل عدم الإجابة على هذا السؤال"
	replace marital_survey_BL = "Widowed" if maritalstatus3 == "أرملة"
	lab var marital_survey_BL "Marital status BL"
	
	gen relationship_status_BL = marital_survey_BL
	replace relationship_status_BL = marital_admin_eng if marital_survey_BL==""
	replace relationship_status_BL= "" if relationship_status_BL=="Prefer not to answer"
	lab var relationship_status_BL "Relationship status at BL"
	
	encode relationship_status_BL, gen(rel_status_BL)
	lab def relstatus 1 "Divorced/seperated" 2 "Married" 3 "Never-married" 4 "Widowed"
	lab val rel_status_BL relstatus
	lab var rel_status_BL "Relationship status at BL, numeric"
	
	* widowed, divorced/separated, never-married, and married dummies
	gen widowed = 1 if relationship_status_BL=="Widowed"
	replace widowed = 0 if inlist(relationship_status_BL, "Divorced/seperated", ///
		"Married", "Never-married")
	lab var widowed "Widowed"
	
	gen divorced_separated = 1 if relationship_status_BL=="Divorced/seperated"
	replace divorced_separated = 0 if ///
		inlist(relationship_status_BL, "Widowed", "Married", "Never-married")
	lab var divorced_separated "Divorced or separated"
	
	gen single = 1 if relationship_status_BL=="Never-married"
	replace single = 0 if ///
		inlist(relationship_status_BL, "Widowed", "Married", "Divorced/seperated")
	lab var single "Never-married"
	
	* fix to married var (BL version seems to be created incorrectly)
	rename married married_old
	label var married_old "Orig version w/ mistake"
	
	gen married = 1 if relationship_status_BL=="Married"
	replace married = 0 if inlist(relationship_status_BL, "Divorced/seperated", ///
		"Widowed", "Never-married")
	lab var married "Married"
	
	* dummy for husband influence (to use in HTE models)
	gen husb_influence = 0 if relationship_status_BL!=""
	replace husb_influence = 1 if inlist(relationship_status_BL, "Divorced/seperated", ///
		"Married")
	lab var husb_influence "Husband influence - married or divorced/separated"
	
	/* version of husband/co-parent that is 1 if married or divorced/separated 
	   with at least one kid under 18 in the HH (original coding of this variable)
	*/
	gen husb_influence_kids_original = 0 if relationship_status_BL!="" & hh_les18_w!=. 
	replace husb_influence_kids_original = 1 if relationship_status_BL=="Married"
	replace husb_influence_kids_original = 1 if relationship_status_BL=="Divorced/seperated" ///
	& hh_les18_w>0 & hh_les18_w!=.
	lab var husb_influence_kids_original ///
	"Husband influence - married or divorced/separated with 1+ kids in HH; Original var"
	lab def husb_infl_kids 0 "No husband/co-parent" 1 "Has husband/co-parent"
	lab val husb_influence_kids_original husb_infl_kids
	
	/* NOTE: we found a mistake in the code where single and widowed women who are
	missing a value for number of HH members under 18 have a missing value for 
	"has husband/co-parent" (ie husb_infl_kids). This mistake carried into our 
	original AER submission. These observations should have a value of 0 for this
	variable. We are preserving the original version of the variable as 
	husb_infl_kids_original and will update the variable to correct for this mistake.
	Most divorced/separated women have children, we are making the assumption that
	women who are divorced/separated and missing values for number of children in
	the household do have children as most do
	*/
	
	gen husb_influence_kids = 0 if relationship_status_BL!="" & hh_les18_w!=.
	replace husb_influence_kids = 1 if relationship_status_BL=="Married"
	replace husb_influence_kids = 1 if relationship_status_BL=="Divorced/seperated" ///
	& hh_les18_w>0 & hh_les18_w!=.
	replace husb_influence_kids = 0 if inlist(relationship_status_BL, "Never-married", ///
	"Widowed") & hh_les18_w==.
	replace husb_influence_kids = 1 if relationship_status_BL=="Divorced/seperated" & hh_les18_w==.
	lab var husb_influence_kids "Husband influence - married or divorced/separated with 1+ kids in HH"
	lab val husb_influence_kids husb_infl_kids
	

	
	/* 	version of husband influence (with kids) where we assume if hh_les18_w is
		missing, that they don't have kids [this is for a robustness check]
	*/
	gen husb_influence_kids_alt = 0 if relationship_status_BL!="" 
	replace husb_influence_kids_alt = 1 if relationship_status_BL=="Married"
	replace husb_influence_kids_alt = 1 if relationship_status_BL=="Divorced/seperated" ///
	& hh_les18_w>0 & hh_les18_w!=.
	lab var husb_influence_kids_alt "Husband influence - married or divorced/separated with 1+ kids in HH, missing kids = no kids"
	
	/* 	version of rel_status_BL to use in HTE by marital status, but create 
		categories for:
		- divorced/separated with kids
		- married
		- single
		- widowed + divorced/separated no kids
	*/
	
	gen hte_rel_status = 1 if rel_status_BL==1 & hh_les18_w>0 & hh_les18_w!=.
	replace hte_rel_status = 2 if rel_status_BL==2 
	replace hte_rel_status = 3 if rel_status_BL==3
	replace hte_rel_status = 4 if rel_status_BL==4 | (rel_status_BL==1 & hh_les18_w==0)
	* in case there are missing hh_les18_w for married or single women, move to missing
	replace hte_rel_status = . if hh_les18_w==.
	lab def status 1 "Has co-parent" 2 "Married" 3 "Never-married" 4 "Widowed or has no co-parent"
	lab val hte_rel_status status
	lab var hte_rel_status "Relationship status groups for HTE (BL)"
	
	/* 	Now let's do an alternative version of this hte relationship status var,
		similar to what we did with husb_influence_kids_alt where we assume if 
		hh_les18_w is missing, that they don't have kids
	*/
	
	gen hte_rel_status_alt = 1 if rel_status_BL==1 & hh_les18_w>0 & hh_les18_w!=.
	replace hte_rel_status_alt = 2 if rel_status_BL==2 
	replace hte_rel_status_alt = 3 if rel_status_BL==3
	replace hte_rel_status_alt = 4 if rel_status_BL==4 
	replace hte_rel_status_alt = 4 if rel_status_BL==1 & (hh_les18_w==0 | hh_les18_w==.)
	lab val hte_rel_status_alt status
	lab var hte_rel_status_alt "Relationship status groups for HTE, missing kids = no kids (BL)"
	
	
		
	
	* worked before 
	destring Intotalhowmanyyearsdidyou BD, replace
	gen ever_employed_BL = 0 if inlist(Wereyouemployedbefore, "0", "No")
	replace ever_employed_BL = 0 if Whatisyourcurrentmonthlysal=="Never been employed"
	replace ever_employed_BL = 0 if employed_BL == 0
	replace ever_employed_BL = 1 if inlist(Wereyouemployedbefore, "Yes")
	// This should be unconditional, so move currently employed to "yes"
	replace ever_employed_BL = 1 if employed_BL ==1 
	replace ever_employed_BL = 1 if (Intotalhowmanyyearsdidyou>0 & Intotalhowmanyyearsdidyou!=.)
	replace ever_employed_BL = 1 if (BD>0 & BD!=.)
	lab var ever_employed_BL "Has ever been employed"
	
	* working experience
	//NOTES: we don't know which var is public sector and which is private, so add 
	// and label as private or public
	gen work_experience_BL = Intotalhowmanyyearsdidyou
	replace work_experience_BL = work_experience_BL + BD
	winsor2 work_experience_BL, cuts(0 95)
	rename work_experience_BL work_experience_orig_BL
	lab var work_experience_orig_BL "Work experience with outliers at BL"
	rename work_experience_BL_w work_experience_BL
	// move to 0 if they've never worked before
	replace work_experience_BL = 0 if inlist(Wereyouemployedbefore, "0", "No")
	replace work_experience_BL = 0 if Whatisyourcurrentmonthlysal=="Never been employed"
	// let's make an unconditional version
	lab var work_experience_BL "Number of years worked in private or public sectors"
	// move those who have never been employed to 0
	replace work_experience_BL = 0 if ever_employed_BL==0										

	
	// let's make this conditional on ever employed
	gen work_experience_cond_BL = work_experience_BL
	replace work_experience_cond_BL = . if ever_employed_BL!=1
	lab var work_experience_cond_BL "Number of years worked in private or public sectors $|$ ever employed"
	

	
	
	* monthly salary
	replace Whatisyourcurrentmonthlysal = "Less than 3000" if ///
		Whatisyourcurrentmonthlysal=="أقل من 3000 ريال"
	replace Whatisyourcurrentmonthlysal = "I prefer not to answer this question" ///
		if Whatisyourcurrentmonthlysal=="أفضل عدم إجابة هذا السؤال"
		
	gen salary_BL_cat = Whatisyourcurrentmonthlysal
	replace salary_BL_cat = "" if inlist(Whatisyourcurrentmonthlysal, ///
		"I prefer not to answer this question", "0")
	lab var salary_BL_cat "Baseline monthly salary in ranges (string)"
	
	replace salary_BL_cat = "3000-4999" if inlist(salary_BL_cat,"3000 -4999", "3000 – 4999", ///
		"3000-4999")
	replace salary_BL_cat = "5000-6999" if inlist(salary_BL_cat, "5000 -6999", "5000 – 6999", ///
		"5000-6999")	
	 
	* make conditional monthly salaries	
	gen salary_less3k_BL = 0 if inlist(salary_BL_cat, "Less than 3000", "3000-4999", ///
	"5000-6999", "8000-8999") &  ever_employed_BL==1
	replace salary_less3k_BL = 1 if salary_BL_cat=="Less than 3000" & ///
	ever_employed_BL==1 
	lab var salary_less3k_BL "Monthly salary: less than 800 USD"
	gen salary_3kto4999_BL = 0 if inlist(salary_BL_cat, "Less than 3000", "3000-4999", ///
	"5000-6999", "8000-8999") & ever_employed_BL==1 
	replace salary_3kto4999_BL = 1 if salary_BL_cat =="3000-4999" & ///
	ever_employed_BL==1 
	lab var salary_3kto4999_BL "Monthly salary: 800-1,330 USD"
	gen salary_5kto6999_BL = 0 if inlist(salary_BL_cat, "Less than 3000", "3000-4999", ///
	"5000-6999", "8000-8999") & ever_employed_BL==1 
	replace salary_5kto6999_BL = 1 if salary_BL_cat =="5000-6999" & ///
	ever_employed_BL==1 
	lab var salary_5kto6999_BL "Monthly salary: 1,330-1,865 USD"
	gen salary_7kto8999_BL = 0 if inlist(salary_BL_cat, "Less than 3000", "3000-4999", ///
	"5000-6999", "8000-8999") & ever_employed_BL==1 
	replace salary_7kto8999_BL = 1 if salary_BL_cat=="8000-8999" & ///
	ever_employed_BL==1 
	lab var salary_7kto8999_BL "Monthly salary: 1,865-2,400 USD"		
	
	* Now make salary_BL_cat a numeric var
	rename salary_BL_cat salary_BL_cat_str
	gen salary_BL_cat = 1 if salary_BL_cat_str== "Less than 3000" &  ever_employed_BL==1
	replace salary_BL_cat = 2 if salary_BL_cat_str== "3000-4999" &  ever_employed_BL==1
	replace salary_BL_cat = 3 if salary_BL_cat_str== "5000-6999" &  ever_employed_BL==1
	replace salary_BL_cat = 4 if salary_BL_cat_str== "8000-8999" &  ever_employed_BL==1
	lab def salary 1 "Less than SAR 3000" 2 "SAR 3000-4999" 3 "SAR 5000-6999" ///
	4 "SAR 8000-8999"
	lab val salary_BL_cat salary
	lab var salary_BL_cat "Baseline monthly salary in ranges"
	
	
	* would register for training if it were less 3000 SAR
	gen wouldregister_less3000_BL = يقولونأنالتكاليفيمكنأنتصلا 
	replace wouldregister_less3000_BL = "1" if wouldregister_less3000_BL=="نعم" ///
		| wouldregister_less3000_BL=="0" | wouldregister_less3000_BL== ///
		"أفضل عدم الإجابة على هذا السؤال"
	replace wouldregister_less3000_BL = "0" if wouldregister_less3000_BL== "لا"
	lab var wouldregister_less3000_BL "Would register for training if it was <3000 SAR"
	destring wouldregister_less3000_BL, replace
	// NOTES: We made this unconditional - '0's were coded to yes, because they had previously
	// said they were interested in the training. 
	
	* create driving registration interest at BL variable
	rename drivingschool_register2 drivingschool_register2_BL
	lab var drivingschool_register2_BL "BL interest in registration (before asking about <3000 SAR cost)"
	gen interest_registration = "No" if drivingschool_register2_BL== ///
	"No, and not planning to"
	replace interest_registration = "No" if wouldregister_less3000_BL==0
	replace interest_registration = "No, but planning to" if ///
	drivingschool_register2_BL == "No, but planning to"
	replace interest_registration = "Yes" if wouldregister_less3000_BL== 1
	replace interest_registration = "Yes" if drivingschool_register2_BL == ///
	"Yes, I registered"
	lab var interest_registration "BL interest in registration, including if it cost <3000 SAR"
	
	* age - 4 groups
	gen age_4group = 1 if age>=18 & age<25
	replace age_4group = 2 if age>=25 & age<35
	replace age_4group = 3 if age>=35 & age<45
	replace age_4group = 4 if age>=45 & age!=.
	lab var age_4group "Age - 4 categories (18-24, 25-34, 35-44, 45+)"
	
	
	
	* Other labeling fixes
	* Other labelling
	lab var randomization_cohort2 "Randomization cohort"
	lab var file_nbr "Household ID"
	lab var participantid "Individual ID"
	lab var group_BL "4 category treatment status"
	lab var driving_T "Driving training"
	lab var wusool_T "Wusool subsidy"
	
	destring participantid, replace
	
* create car ownership variable
	gen owns_car = 0 if car=="0"
	replace owns_car = 1 if inlist(car, "1", "2", "3", "4", "More than 4")
	lab var owns_car "HH owns car"
	
	gen cars = 0 if car=="0"
	replace cars = 1 if car == "1" 
	replace cars = 2 if inlist(car, "2", "3", "4", "More than 4")
	lab var cars "Cars in the household"
	lab def c 0 "No cars" 1 "1 car" 2 "2+ cars"
	lab val cars c
	
		
	* dummies for one and 2+ cars
	gen one_car = 0 if car=="0"
	replace one_car = 0 if inlist(car, "2", "3", "4", "More than 4")
	replace one_car = 1 if car=="1"
	lab var one_car "Household has 1 car"
	
	gen mult_cars = 0 if car=="0" | car=="1"
	replace mult_cars = 1 if inlist(car, "2", "3", "4", "More than 4")
	lab var mult_cars "Household has 2+ cars"
	
	* clean up car variable
	gen cars_num = car
	replace cars_num = "" if car == "I prefer not to answer"
	replace cars_num = "5" if car == "More than 4"
	destring cars_num, replace
	lab def car 0 "No cars" 1 "1" 2 "2" 3 "3" 4 "4" 5 "More than 4 cars"
	lab val cars_num car
	lab var cars_num "Cars in houeshold, numeric"

	* create indicator for being from AlNahda's pool of participants
	gen AlNahda = 1 if Institution=="Alanahda"
	replace AlNahda = 0 if inlist(Institution,"Insan", "Mawaddah")
	lab def alnahda 0 "Other" 1 "Alnahda"
	lab val AlNahda alnahda
	lab var AlNahda "AlNahda beneficiary"
	
	* Create dummy for whether the respondent was enrolled with someone else in her HH
	egen num_enrolled_HH = count(participantid) if Excluded==0, by(file_nbr)
	lab var num_enrolled_HH "Number of respondents in household"
	gen HH_enrolled = 0 if num_enrolled_HH == 1 & Excluded==0
	replace HH_enrolled = 1 if num_enrolled_HH >1 & num_enrolled_HH!=. & Excluded==0
	lab var HH_enrolled "Multiple household members enrolled together"


	
	* Let's adjust household size as it conflicts with number of respondents per household
	// Assumption: If hh_more18_w < num_enrolled_HH, then adjust hh_more18_w so that
	// hh_more18_w == num_enrolled_HH
	gen hh_more18_update = 1 if hh_more18_w < num_enrolled_HH & hh_more18_w!=. ///
		& num_enrolled_HH!=. & Excluded==0
	lab var hh_more18_update "hh_more18 was < number of enrolled in the HH and was updated to reflect that"
	replace hh_more18_w = num_enrolled_HH if hh_more18_w < num_enrolled_HH & hh_more18_w!=. ///
		& num_enrolled_HH!=. & Excluded==0
		
	* now adjust household_size variable to reflect this
	replace household_size = hh_more18_w + hh_les18_w if hh_more18_update==1 & Excluded==0


	* Create dummy for whether respondent is "constrained" by having at least 1 kid in the household
	gen constrained = 1 if hh_les18_w>0 & hh_les18_w!=.
	replace constrained = 0 if hh_les18_w==0	
	lab var constrained "At least one child <18 in household"
	
	
	* CREATE NGO INSTITUTION VARIABLE
	gen NGO = 1 if Institution=="Alanahda"
	replace NGO = 2 if Institution=="Insan"
	replace NGO = 3 if Institution=="Mawaddah"
	lab var NGO "Beneficiary's NGO"
	
	
	/* NOTE: adding HTE variables:
	
	Let's create binary versions of selected controls that we want to test HTE for. */	
	
	* Age
	xtile age_med = age, nq(2)	
	recode age_med (1 = 0) (2 = 1)
	lab var age_med "Age - above median"
	
	* Education - completed highschool or above
	gen edu_nohs = 0 if inlist(edu_category,1,2) 	
	replace edu_nohs = 1 if edu_category==0	
	lab var edu_nohs "Less than highschool"
	
	* Ever married 
	gen ever_married = 0 if rel_status!=.
	replace ever_married = 1 if inlist(rel_status, 1,2,4)
	lab var ever_married "Ever-married"
		
	
* RECREATE STRATA VARIABLES
	* age
	gen age_group="Old"
	replace age_group="Young" if inrange(age, 18,24)
	replace age_group="Other" if كمعمرك=="أفضل عدم الإجابة على هذا السؤال"
	encode age_group, gen (age_group_code)
	drop age_group
	rename age_group_code age_group
	lab var age_group "Strata BL age group"

	* Number of cars
	gen car_group="Car"
	replace car_group="No car" if car=="0"
	replace car_group="Other" if car=="I prefer not to answer"
	replace car_group = "" if car==""
	encode car_group,gen (car_group_code)
	drop car_group
	rename car_group_code car_group
	lab var car_group "Strata BL car group"
	
	* Likelihood of driving
	gen drivingreg_group = 1 if inlist(drivingschool_register2_BL, ///
	"No, but planning to", "Yes, I registered")
	replace drivingreg_group = 0 if inlist(drivingschool_register2_BL, ///
	"No, and not planning to", "Prefer not to answer")
	lab var drivingreg_group "Strata BL: expressed interest in registering for training"
	
		* OLD VERSION OF LIKELIHOOD OF DRIVING VAR
		gen OLD_drivingreg_group="No,notplanning"
		replace OLD_drivingreg_group="No,planning" if drivingschool_register== ///
		"لا، لم اسجل لكن أنوي اقيام بذلك"
		replace OLD_drivingreg_group="Other" if drivingschool_register== ///
		"أفضل عدم الإجابة على هذا السؤال"
		encode OLD_drivingreg_group,gen(OLD_drivingreg_group_code)
		drop OLD_drivingreg_group
		rename OLD_drivingreg_group_code OLD_drivingreg_group
	
	* create strata
	egen group_strata = concat(drivingreg_group age_group car_group randomization_cohort2)
	lab var group_strata "Strata groups (recreated)"
	
	
* Finally, add "_BL" to end of all relevant vars
	* some already have '_BL' at the end, let's skip these
	lookfor _BL
	local suffix_vars `r(varlist)'
	* and some we don't want to include
	local 	skip_vars Institution file_nbr participantid randomization_cohort ///
			randomization_cohort2 NGO num_enrolled_HH group_strata Randomization ///
			driving_ct wusool_ct national_id hh_les18 hh_les18_w hh_more18 hh_more18_w driving_ct2 ///
			wusool_ct2 driving_T wusool_T driving_ctoriginal wusool_ctoriginal ///
			Excluded Exclusion household_size HH_enrolled married single widowed ///
			divorced_separated hte_rel_status hte_rel_status_alt husb_influence ///
			husb_influence_kids husb_influence_kids_alt cars one_car mult_cars car ///
			car2 icar cars_num BLsearch
			
	ds _all
	local full_list `r(varlist)'

	local missing_BL_suffix: list full_list - suffix_vars 
	local missing_BL_suffix: list missing_BL_suffix - skip_vars

foreach var of local missing_BL_suffix {
	rename `var' `var'_BL
}
	
* create final treatment variables (first for tables, second for estimation)
gen treat = 0 if driving_ct2 == "Control" & wusool_ct2 == "Control"
replace treat = 1 if driving_ct2 == "Treatment" 
replace treat = 2 if wusool_ct2 == "Treatment"
replace treat = 3 if driving_ct2 == "Treatment" & wusool_ct2 == "Treatment"
label define treat 0 "Control" 1 "Driving" 2 "Information" 3 "Both"
label values treat treat
label variable treat "Original treatment status"

gen uber = 1 if treat == 1 | treat == 3 
replace uber = 0 if treat == 2 | treat == 0 & treat !=.
label var uber "Free driving training"

gen wusool = 1 if treat == 2 | treat == 3 
replace wusool = 0 if treat == 1 | treat == 0 & treat !=.
label var wusool "Commute subsidy information"

* other updates
	lab def treatments_4 0 "Control" 1 "Driving Treatment Only" 2 ///
	"Subsidy Info Treatment Only" 3 "Both Treatments"
	lab val treat treatments_4
	
* Heard of Wusool program
gen subsidy_unaware_BL = 0 if Haveyouheardaboutthisprogra_BL!="" 
replace subsidy_unaware_BL = 1 if strpos(Haveyouheardaboutthisprogra_BL, "no" ) ///
	| strpos(Haveyouheardaboutthisprogra_BL, "No" )
lab var subsidy_unaware_BL "Unaware of subsidy program at BL"

save "${data}/RCT admin and wave 1/Final/Wave1.dta", replace
