***** REMEMBER TO RUN SETTINGS.DO FILE FIRST ******

/******************************************************************************

Purpose:  Clean Wave 2 Data
                                           
Created: June 16, 2020
*******************************************************************************/
clear all
set more off

**************************************************************************

* get order randomizing info
import excel "${data}/RCT wave 2/Raw/block randomizer.xlsx", sheet("Sheet2")  firstrow clear
drop if _n == 1 
destring FL_17_DO_Wusool FL_17_DO_Driving FL_17_DO_Travel FL_17_DO_Traveldiaryonpaper, replace
rename ResponseId ResponseID
egen blockorder = concat(FL_17_DO_Wusool FL_17_DO_Driving FL_17_DO_Travel FL_17_DO_Traveldiaryonpaper)
replace blockorder = "" if FL_17_DO_Wusool == .
destring blockorder, replace
save "${data}/RCT wave 2/Cleaned/blockrandomizer.dta", replace 

* bring in raw data
import excel "${data}/RCT wave 2/Raw/Commute Wave 2 round 1-raw-deidentified.xlsx", ///
sheet("Commute+Endline+Survey_March+16") firstrow clear

merge 1:1 ResponseID using "${data}/RCT wave 2/Cleaned/blockrandomizer.dta"
drop _merge 

* note that there are 101 observations with same participantid of 0, and after collapse, 6 have less than 1000 as their participantID, which does not coincide with lists (participantids 0 3 9 22 77 199)
* these were just test IDs
drop if participantid < 1000

* keep variable labels before collapse
  foreach v of var * {
 	local l`v' : variable label `v'
        if `"`l`v''"' == "" {
 		local l`v' "`v'"
  	}
 }

* collapse data to last non-missing value. Note that progress and finished vars are not necessarily useful indicators, as can be flagged as having 100% progress and finished, but survey not completed (just came to goodtime = no for example)
sort participantid consent callanswered attemptnb Progress Finished goodtime 

* collapse works well, but keep in mind it takes last one, even if different response for same variable (for example, see participantid 1001 and takejob_15min variable) 
  
collapse (lastnm) StartDate EndDate Progress Finished RecordedDate UserLanguage blockorder enumeratorname participantid_ver participantgroup callbackattempts attemptnb callanswered speakingwithres reachresp reachresp_txt reachresp_txt_other goodtime goodtime_txt phonenb_best phonenb_best_txt numberused consent employed work_area work_area_txt residence_city residence_city_txt residence_area residence_area_txt monthlysalary startjob_year startjob_year_txt startjob_month startjob_month_txt attend_careerfair jobhunt_friends jobhunt_jpc jobhunt_inperson jobhunt_calledemplo jobhunt_advert jobhunt_agency jobhunt_other jobhunt_noanswer jobhunt_callended jobhunt_none jobhunt_other_txt jobsappli_lastmnth jobsappli_lastmnth_txt jobinterv_lastmnth jobinterv_lastmnth_txt jobinterv_go jobinterv_go_txt joboffers_lastmnth joboffers_lastmnth_txt joboffer_accept expectedsalary expectedsalary_txt lowestsalary lowestsalary_txt commutecost_freq commutecost_permnth commutecost_perday wusool_consider_onceprivate wusool_consider wusool_whynot wusool_whynot_txt expectcomm_ehai_freq expectcomm_ehai_amount commutemode_expec commutemode_expec_txt takejob_15min takejob_30min takejob_45min alnahda_enuminterv alnahda_enumwork alnahda_whynot alnahda_whynot_txt enum_upcomsession enum_nointeres enum_nointeres_txt anydrivingtraining sauditraining sauditraining_stop sauditraining_stop_txt drivinglicense drivinh_lastmnth driving_times driving_shopperson driving_shophh driving_work driving_uni driving_friends driving_relatives driving_leisure driving_mealout driving_health driving_gov driving_accompany driving_other driving_noanswer driving_callended driving_other_txt driving_likely concer_learnhard concer_affordcar concer_affordmaint concer_carshared concer_society concer_family concer_reputation concer_riskaccident concer_riskwithmen metro_likely metro_notlikely_why metro_notlikely_why_txt trip_yesterday lasttrip_when lasttrip_noacco_when lasttrip_relat_when lasttrip_friend_when tripnb_yesterday trip1 trip1_origin trip1_destin trip1_departime trip1_arrivtime trip1_purpose trip1_purpose_txt trip1_mode trip1_mode_txt trip1_cost trip1_cost_txt trip1_child trip1_adultfam trip1_adultother trip2 trip2_origin trip2_destin trip2_departime trip2_arrivtime trip2_purpose trip2_purpose_txt trip2_mode trip2_mode_txt trip2_cost trip2_cost_txt trip2_child trip2_adultfam trip2_adultother trip3 trip3_origin trip3_destin trip3_departime trip3_arrivtime trip3_purpose trip3_purpose_txt trip3_mode trip3_mode_txt trip3_cost trip3_cost_txt trip3_child trip3_adultfam trip3_adultother trip4 trip4_origin trip4_destin trip4_departime trip4_arrivtime trip4_purpose trip4_purpose_txt trip4_mode trip4_mode_txt trip4_cost trip4_cost_txt trip4_child trip4_adultfam trip4_adultother trip5 trip5_origin trip5_destin trip5_departime trip5_arrivtime trip5_purpose trip5_purpose_txt trip5_mode trip5_mode_txt trip5_cost trip5_cost_txt trip5_child trip5_adultfam trip5_adultother trip6 trip6_origin trip6_destin trip6_departime trip6_arrivtime trip6_purpose trip6_purpose_txt trip6_mode trip6_mode_txt trip6_cost trip6_cost_txt trip6_child trip6_adultfam trip6_adultother trip7 trip7_origin trip7_destin trip7_departime trip7_arrivtime trip7_purpose trip7_purpose_txt trip7_mode trip7_mode_txt trip7_cost trip7_cost_txt trip7_child trip7_adultfam trip7_adultother trip8 trip8_origin trip8_destin trip8_departime trip8_arrivtime trip8_purpose trip8_purpose_txt trip8_mode trip8_mode_txt trip8_cost trip8_cost_txt trip8_child trip8_adultfam trip8_adultother trip9 trip9_origin trip9_destin trip9_departime trip9_arrivtime trip9_purpose trip9_purpose_txt trip9_mode trip9_mode_txt trip9_cost trip9_cost_txt trip9_child trip9_adultfam trip9_adultother trip10 trip10_origin trip10_destin trip10_departime trip10_arrivtime trip10_purpose trip10_purpose_txt trip10_mode trip10_mode_txt trip10_cost trip10_cost_txt trip10_child trip10_adultfam trip10_adultother, by(participantid) 

* reattach labels
 foreach v of var * {
 	label var `v' "`l`v''"
 }

*** following vars dropped after collapse, as were either unnecessary or not answered (note nothing after Trip 10 in diary)
* Trip TripOriginorcloselandm TripDestinationorclose StarttimeoftripCurrent ArrivaltimeoftripCurre Purposeoftripenumeratordo JT Travelmodeoftripenumerator JV EstimatedcostoftripCurrentL JX NumberofPeopleAccompanyingy JZ KA KB KC KD KE KF KG KH KI KJ KK KL KM KN KO KP KQ KR KS KT KU KV KW KX KY KZ LA LB LC LD LE LF LG LH LI LJ LK LL LM LN LO LP LQ LR LS LT LU LV LW LX LY LZ MA MB MC MD ME MF MG MH MI MJ MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NB NC ND NE NF NG NH NI NJ NK NL NM NN NO NP NQ NR NS NT NU NV NW NX NY NZ OA OB OC OD OE OF OG OH OI OJ OK OL OM ON OO OP OQ OR OS OT OU OV OW OX OY OZ PA PB PC PD PE PF PG PH PI PJ PK PL PM PN PO PP PQ PR PS PT PU PV PW PX PY PZ QA QB QC QD QE QF QG QH QI QJ QK QL QM QN QO QP QQ QR QS QT QU QV QW QX QY QZ RA RB RC RD RE RF RG RH RI RJ RK RL RM RN RO RP RQ RR RS RT RU RV RW RX RY RZ SA SB SC SD SE SF SG SH SI SJ SK SL SM SN SO SP SQ SR SS ST SU SV SW SX SY SZ TA TB TC TD TE TF TG TH TI TJ TK TL TM TN TO TP TQ TR TS TT TU TV TW TX TY TZ UA UB UC UD UE UF UG ResponseType IPAddress Durationinseconds RecipientLastName RecipientFirstName RecipientEmail ResponseID ExternalDataReference LocationLatitude LocationLongitude DistributionChannel 


* Merge in treatment status from wave 1
save "${data}/RCT wave 2/Cleaned/Wave2_raw.dta", replace

use "${data}/RCT admin and wave 1/Final/Wave1.dta", clear

keep participantid treat

merge 1:1 participantid using "${data}/RCT wave 2/Cleaned/Wave2_raw.dta"
keep if _merge==3
drop _merge


* extract time of call 
gen sd = StartDate
gen fullstartdate=clock(sd,"MDYhm#")
format fullstartdate %tc
replace sd = "" if fullstartdate !=.
gen time=clock(sd,"DMYhms")
format time %tc
replace fullstartdate = time if fullstartdate == .
sctorezone +9, force only(fullstartdate)
gen hour = hh(fullstartdate)
gen minute = mm(fullstartdate)
gen mytime=string(hour) + ":" + string(minute)
gen starttime = clock(mytime, "hm")
format starttime %tcHH:MM
drop hour minute mytime time sd

gen timecat = 1 if starttime <= tc(11:00)
replace timecat = 2 if starttime > tc(11:00) & starttime <= tc(13:00)
replace timecat = 3 if starttime > tc(13:00) & starttime <= tc(15:00)
replace timecat = 4 if starttime > tc(15:00) & starttime <= tc(17:00)
replace timecat = 5 if starttime > tc(17:00)
label var timecat "Start Time, Categ"
label define timecat 1 "Before 11AM" 2 "11AM-1PM" 3 "1PM-3PM" 4 "3PM-5PM" 5 "After 5PM"
label values timecat timecat

* fix dates
gen startdate=date(StartDate,"MDY###")
format startdate %td
replace StartDate = "" if startdate !=.
gen startdate2=date(StartDate,"DMY###")
format startdate2 %td
replace startdate = startdate2 if startdate == .
gen dow = dow(startdate)
label variable dow "Day of Week, 0=Sun"

gen enddate=date(EndDate,"MDY###")
format enddate %td
replace EndDate = "" if enddate !=.
gen enddate2=date(EndDate,"DMY###")
format enddate2 %td
replace enddate = enddate2 if enddate == .

gen recordeddate=date(RecordedDate,"MDY###")
format recordeddate %td
replace RecordedDate = "" if recordeddate !=.
gen recordeddate2=date(RecordedDate,"DMY###")
format recordeddate2 %td
replace recordeddate = recordeddate2 if recordeddate == .

drop StartDate EndDate RecordedDate startdate2 enddate2 recordeddate2

****** create, encode, and recode important variables ******
label define yesno 0 "No" 1 "Yes"

* create intensity measure dummy (assumption that missing is 3 attempts )
gen intensive = 0 if callbackattempts == "3 attempts" | callbackattempts == ""
replace intensive = 1 if callbackattempts == "5 attempts"
label values intensive yesno
tab callbackattempts intensive
label variable intensive "Intensive Callback"

* treatment variables 
tab participantgroup
encode participantgroup, gen(group)

* answered call and consent variable dummies
gen finalanswer = (callanswered == "Answered")
label values finalanswer yesno
label var finalanswer "Answered Call"
tab callanswered finalanswer

gen fullconsent = (consent == "Yes")
replace fullconsent = . if consent == "" | consent == "Call ended / connection lost / respondent hung up the phone"
label values fullconsent yesno
tab consent fullconsent
label var fullconsent "Follow Up Consent"

* gen attrition related variables
gen participate = (consent == "Yes")
label values participate yesno
label var participate "Follow Up Participation"

gen consentall = 0 if finalanswer != .
replace consentall = 1 if fullconsent == 1
label var consentall "Consent"

* clean salaries 
gen salary_monthly = .
replace salary_monthly = 1 if monthlysalary == " Less than 3000"
replace salary_monthly = 2 if monthlysalary == " 3000 – 4999"
replace salary_monthly = 3 if monthlysalary == " 5000 – 6999"
replace salary_monthly = 4 if monthlysalary == " 7000 – 8999"
label define salary_monthly 1 "< 3000 SAR" 2 "3000 - 4999 SAR" 3 "5000 - 6999 SAR" 4 "7000 - 8999 SAR" 
label values salary_monthly salary_monthly
tab monthlysalary salary_monthly
label var salary_monthly "Monthly Salary, Cate"

***** First Stage PAP variables *****
* any drive training dummy
gen anydrivetraining = 0 if anydrivingtraining == "No"
replace anydrivetraining = 1 if anydrivingtraining == "Yes"
label values anydrivetraining yesno
tab anydrivingtraining anydrivetraining
label var anydrivetraining "Drive Training, KSA or Other"

label var attemptnb "Attempt Number Answered"

* saudi specific training categorical 
gen saudidrivetraining = 0 if sauditraining == "Noو Please explain:" | anydrivetraining == 0
replace saudidrivetraining = 1 if sauditraining == "Yes and completed successfully"
replace saudidrivetraining = 2 if sauditraining == "Yes but stopped the training for other reasons. Please explain:" | sauditraining == "Yes but failed the practical test" | sauditraining == "Yes but failed the theoretical test"
label define saudidrive 0 "No" 1 "Yes" 2 "Yes, but failed or stopped"
label values saudidrivetraining saudidrive
tab sauditraining saudidrivetraining
label var saudidrivetraining "Saudi Drive Training, Cate"

gen saudidrive = 0 if saudidrivetraining == 0 
replace saudidrive = 1 if saudidrivetraining == 1 | saudidrivetraining == 2
label values saudidrive yesno
label var saudidrive "Saudi Drive Training"


* driver's license dummy 
gen license = 0 if drivinglicense == "No" | saudidrive !=.
replace license = 1 if drivinglicense == "Yes"
label values license yesno
tab drivinglicense license
label variable license "Driver's License"

* expected cost of e-hailing services 
label var expectcomm_ehai_freq "Cost of Commute (30 min), freq"
label var expectcomm_ehai_amount "Cost of Commute (30 min), amt"
tab expectcomm_ehai_freq
tab expectcomm_ehai_amount
winsor2 expectcomm_ehai_amount, cuts(0 95) trim
label var expectcomm_ehai_amount_tr "Cost of Commute (30 min), amt tr"
gen expectcommDK = 0 if expectcomm_ehai_amount != .
replace expectcommDK = 1 if expectcomm_ehai_freq == "I don't know"
label var expectcommDK "Cost of Commute, DK dummy"


***** Job Search PAP variables *****

* employment status dummy 
gen currentlyemployed = 0 if employed == "No, I am a student and I plan to work after graduation" | employed == "No, I am a student and I’m not looking for a job" | employed == "No, I am not employed and I am looking for a job" | employed == "No, I am not employed and I’m not looking for a job"
replace currentlyemployed = 1 if employed == "Yes, I am employed and open to looking for a different job" | employed == "Yes, I am employed but not looking for a different job"
label values currentlyemployed yesno 
tab employed currentlyemployed
label var currentlyemployed "Currently Employed"

* looking for a job dummy (include last category? future questions in survey as conditional on it )
gen jobsearch = 0 if currentlyemployed != .
replace jobsearch = 1 if employed == "No, I am not employed and I am looking for a job" | employed == "Yes, I am employed and open to looking for a different job" | employed == "No, I am a student and I plan to work after graduation"
label values jobsearch yesno 
tab employed jobsearch
label var jobsearch "Searching for Job"

* career fair attendance
gen careerfair = 0 if currentlyemployed !=.
replace careerfair = . if fullconsent == . | fullconsent == 0 | attend_careerfair == "Call ended / connection lost / respondent hung up the phone"
replace  careerfair = 1  if attend_careerfair == "Yes"
label values careerfair yesno
tab attend_careerfair careerfair
label var careerfair "Attend Career Fair"

** Proportion of possible job search activities the respondent has taken in the last month
gen jh_friends = 1 if jobhunt_friends == "Asked friends, relatives to help you find a job" 
gen jh_jobcentre = 1 if jobhunt_jpc == "Visited a job centre (JPC) in person" 
gen jh_inperson = 1 if jobhunt_inperson == "Travelled to employers in person to ask about job opportunities or drop off your CV"
gen jh_calledemp = 1 if jobhunt_calledemplo == "Called or emailed employers to ask about job opportunities or send your CV" 
gen  jh_agency = 1 if jobhunt_agency == "Registered with an employment agency or job search service through the internet or on the phone"
gen jh_advert = 1 if jobhunt_advert == "Placed or answered advertisements in the newspaper or online" 
gen jh_other = 1 if jobhunt_other == "Any other step ________________________ (please specify):"
lab var jh_friends "Search activity: Asked friends/relatives to help find job"
lab var jh_jobcentre "Search activity: Visited job center"
lab var jh_inperson "Search activity: travelled to employers in person"
lab var jh_calledemp "Search activity: called or emailed employers"
lab var jh_agency "Search activity: registered with an employment agency"
lab var jh_advert "Search activity: placed/answered adverts"
lab var jh_other "Other"

*** Ignore the other category until discussion/ translation of
tab jobhunt_other_txt

* create sum and proportion
egen jobhuntsum = rowtotal(jh_friends jh_jobcentre jh_inperson jh_calledemp jh_agency jh_advert)
replace jobhuntsum = . if currentlyemployed == .
gen jobhuntprop = (jobhuntsum/6)*100
tab jobhuntsum
tab jobhuntprop
label var jobhuntprop "Job Hunt, Percent of Activities"
lab var jobhuntsum "Search activity: sum of activities taken"

* travel to search (correct zero?)
gen jh_travel = 0 if currentlyemployed !=. 
replace jh_travel = 1 if jh_jobcentre == 1 | jh_inperson == 1 
label values jh_travel yesno
tab jh_travel
label var jh_travel "Travel for Job Search"

* expected/ reservation wage
tab expectedsalary_txt
tab lowestsalary_txt
replace lowestsalary_txt = 3500 if lowestsalary_txt == 35000
gen llowestsalary_txt = log(lowestsalary_txt)
gen lexpectedsalary_txt = log(expectedsalary_txt)
label var lowestsalary_txt "Self-Reported Reservation Wage"
label var expectedsalary_txt "Expected Wage"
label var llowestsalary_txt "Log of Self-Reported Reservation Wage"
label var lexpectedsalary_txt "Log of Expected Wage"

* Number of jobs respondent applied to in last month, Interview calls, Interview attendance
gen jobapplied_lastm = 0 if jobsappli_lastmnth == "None" | jobsappli_lastmnth_txt == 0 | currentlyemployed != .
replace jobapplied_lastm = jobsappli_lastmnth_txt if jobsappli_lastmnth_txt > 0 & jobsappli_lastmnth_txt !=.
tab jobsappli_lastmnth
tab jobapplied_lastm
label var jobapplied_lastm "Jobs Applied, Cate"

gen jobintervinv_lastm = 0 if jobinterv_lastmnth_txt == . & jobinterv_lastmnth == "None" | jobapplied_lastm == 0 | jobinterv_lastmnth_txt == 0 | currentlyemployed != .
replace jobintervinv_lastm = jobinterv_lastmnth_txt if jobinterv_lastmnth_txt > 0 & jobinterv_lastmnth_txt !=.
tab jobinterv_lastmnth
tab jobintervinv_lastm
label var jobintervinv_lastm "Jobs Interviewed, Cate"

gen jobintervattend_lastm = 0 if jobinterv_go_txt == . & jobinterv_lastmnth == "None" | jobapplied_lastm == 0 | jobinterv_go_txt == 0 | currentlyemployed != .
replace jobintervattend_lastm = jobinterv_go_txt if jobinterv_go_txt > 0 & jobinterv_go_txt !=.
tab jobinterv_go_txt
tab jobintervattend_lastm
label var jobintervattend_lastm "Job Interview Attendance, Cate"

* binary versions
gen job_applied = (jobapplied_lastm > 0) if jobapplied_lastm !=.
gen job_interview = (jobintervinv_lastm > 0) if jobintervinv_lastm !=.
gen job_interviewattend = (jobintervattend_lastm > 0) if jobintervattend_lastm !=.
label values job_applied job_interview job_interviewattend yesno
label var job_applied "Job Applied"
label var job_interview "Job Interviewed"
label var job_interviewattend "Job Interview Attend"

**** how do we want to code these?
tab takejob_15min
tab takejob_30min


* put no and neutral together
gen takejob_15mins = 0 if takejob_15min == "No, definitely not" | takejob_15min == "No, probably not" | takejob_15min == "Neutral" | jobsearch == 0
replace takejob_15mins = 1 if takejob_15min == "Yes probably" | takejob_15min == "Yes, definitely"
label values takejob_15mins yesno
tab takejob_15min takejob_15mins

gen takejob_30mins = 0 if takejob_30min == "No, definitely not" | takejob_30min == "No, probably not" | takejob_30min == "Neutral" | jobsearch == 0
replace takejob_30mins = 1 if takejob_30min == "Yes probably" | takejob_30min == "Yes, definitely"
label values takejob_30mins yesno
tab takejob_30min takejob_30mins

label var takejob_15mins "Take job 15 mins away, 3000 SAR"
label var takejob_30mins "Take job 30 mins away, 3000 SAR"

***** Mobility PAP variables *****

*** can they drive without the license? Bc more driving last month than have license...
* Drove in the last month
gen drive_lastm = 0 if drivinh_lastmnth == "No" | drivinglicense == "No" | drivinglicense == "Yes"
replace drive_lastm = 1 if drivinh_lastmnth == "Yes" 
label values drive_lastm yesno
tab drivinh_lastmnth drive_lastm
label var drive_lastm "Driven in last month"

* Driving frequency: estimated number of trips per month/ week
gen drive_month = 0 if drive_lastm == 0
replace drive_month = 1 if driving_times == "Less than once a week"
replace drive_month = 2 if driving_times == "About once a week"
replace drive_month = 3 if driving_times == "A few times a week"
replace drive_month = 4 if driving_times == "Almost every day"
label define drive_month 0 "Never" 1 "< 4 times per month" 2 "4 times per month" 3 "few times per week" 4 "Almost everyday"
label values drive_month drive_month
tab driving_times drive_month
label var drive_month "Driving frequency"

* Expected likelihood of driving in the future (what should "zero" be?)
gen future_drive = 0 if driving_likely == "Not Likely"
replace future_drive = 1 if driving_likely == "Somewhat unlikely"
replace future_drive = 2 if driving_likely == "Neutral"
replace future_drive = 3 if driving_likely == "Somewhat likely"
replace future_drive = 4 if driving_likely == "Likely" | drive_lastm == 1
label define future_drive 0 "Not likely" 1 "Somewhat unlikely" 2 "Neutral" 3 "Somewhat likely" 4 "Likely"
label values future_drive future_drive
tab driving_likely future_drive
label var future_drive "Expect to Drive, Cate"

sum future_drive if treat == 0, detail
gen future_drive_med = 0 if future_drive !=.
replace future_drive_med = 1 if future_drive == 4 | drive_lastm == 1
label values future_drive_med yesno
label var future_drive_med "Expect to Drive"

* Time since most recent trip
tab lasttrip_when
gen recenttrip = 0 if lasttrip_when == "NEVER"
replace recenttrip = 1 if lasttrip_when == "More than a month ago"
replace recenttrip = 2 if lasttrip_when == "A month ago"
replace recenttrip = 3 if lasttrip_when == "More than a week ago"
replace recenttrip = 4 if lasttrip_when == "One week ago"
replace recenttrip = 5 if lasttrip_when == "Less than one week ago"
replace recenttrip = 6 if lasttrip_when == "Yesterday" | trip_yesterday == "Yes"
replace recenttrip = 7 if lasttrip_when == "Today"
label define triprecency 0 "Never" 1 "> Month" 2 "One Month" 3 "> Week" 4 "One Week" 5 "< Week" 6 "Yesterday" 7 "Today"
label values recenttrip triprecency
label var recenttrip "Recent Trip, Cate"

* dummy equivalents for regression
gen recenttripmoreweek = 0 if recenttrip == 4 | recenttrip == 5 | recenttrip == 6 | recenttrip == 7
replace recenttripmoreweek = 1 if recenttrip == 0 | recenttrip == 1 | recenttrip == 2  | recenttrip == 3
gen recenttripwithinweek = 0 if recenttrip == 0 | recenttrip == 1 | recenttrip == 2  | recenttrip == 3
replace recenttripwithinweek = 1 if recenttrip == 4 | recenttrip == 5 | recenttrip == 6 | recenttrip == 7
gen recenttripyestod = 0 if recenttrip == 0 | recenttrip == 1 | recenttrip == 2  | recenttrip == 3 | recenttrip == 4 | recenttrip == 5
replace recenttripyestod = 1 if recenttrip == 6 | recenttrip == 7
label var recenttripmoreweek "Recent Trip, GT Week"
label var recenttripwithinweek "Recent Trip, Last Week"
label var recenttripyestod "Recent Trip, Yest or Today"

* Time since the most recent trip without any family member accompanying
tab lasttrip_noacco_when
gen recenttrip_nofam = 0 if lasttrip_noacco_when == "NEVER"
replace recenttrip_nofam = 1 if lasttrip_noacco_when == "More than a month ago"
replace recenttrip_nofam = 2 if lasttrip_noacco_when == "A month ago"
replace recenttrip_nofam = 3 if lasttrip_noacco_when == "More than a week ago"
replace recenttrip_nofam = 4 if lasttrip_noacco_when == "One week ago"
replace recenttrip_nofam = 5 if lasttrip_noacco_when == "Less than one week ago"
replace recenttrip_nofam = 6 if lasttrip_noacco_when == "Yesterday"
replace recenttrip_nofam = 7 if lasttrip_noacco_when == "Today"
label values recenttrip_nofam triprecency
label var recenttrip_nofam "Recent Trip, No Fam, Cate"

* dummy equivalents for regression
gen rectripevernofam = 0 if recenttrip_nofam == 0
replace rectripevernofam = 1 if recenttrip_nofam > 0 & recenttrip_nofam !=.
gen rectripmoreweeknofam = 0 if recenttrip_nofam == 4 | recenttrip_nofam == 5 | recenttrip_nofam == 6 | recenttrip_nofam == 7
replace rectripmoreweeknofam = 1 if recenttrip_nofam == 0 | recenttrip_nofam == 1 | recenttrip_nofam == 2  | recenttrip_nofam == 3
gen rectripwithinweeknofam = 0 if recenttrip_nofam == 0 | recenttrip_nofam == 1 | recenttrip_nofam == 2  | recenttrip_nofam == 3
replace rectripwithinweeknofam = 1 if recenttrip_nofam == 4 | recenttrip_nofam == 5 | recenttrip_nofam == 6 | recenttrip_nofam == 7
gen rectripyestodnofam = 0 if recenttrip_nofam == 0 | recenttrip_nofam == 1 | recenttrip_nofam == 2  | recenttrip_nofam == 3 | recenttrip_nofam == 4 | recenttrip_nofam == 5
replace rectripyestodnofam = 1 if recenttrip_nofam == 6 | recenttrip_nofam == 7
label var rectripevernofam "Recent Trip, No Fam"
label var rectripmoreweeknofam "Recent Trip, No Fam, GT Week"
label var rectripwithinweeknofam "Recent Trip, No Fam, Last Week"
label var rectripyestodnofam "Recent Trip, No Fam, Yest or Today"


* Time since the most recent trip to visit relatives
tab lasttrip_relat_when
gen recenttrip_relat = 0 if lasttrip_relat_when == "Not applicable - e.g. parents passed away"
replace recenttrip_relat = 1 if lasttrip_relat_when == "More than a month ago"
replace recenttrip_relat = 2 if lasttrip_relat_when == "A month ago"
replace recenttrip_relat = 3 if lasttrip_relat_when == "More than a week ago"
replace recenttrip_relat = 4 if lasttrip_relat_when == "One week ago"
replace recenttrip_relat = 5 if lasttrip_relat_when == "Less than one week ago"
replace recenttrip_relat = 6 if lasttrip_relat_when == "Yesterday"
replace recenttrip_relat = 7 if lasttrip_relat_when == "Today"
label define triprecencyf 0 "NA" 1 "> Month" 2 "One Month" 3 "> Week" 4 "One Week" 5 "< Week" 6 "Yesterday" 7 "Today"
label values recenttrip_relat triprecencyf
label var recenttrip_relat "Recent Trip to Relatives, Cate"

* dummy equivalents for regression
* treating NA as .
gen rectripmoreweekrelat = 0 if recenttrip_relat == 4 | recenttrip_relat == 5 | recenttrip_relat == 6 | recenttrip_relat == 7
replace rectripmoreweekrelat = 1 if recenttrip_relat == 1 | recenttrip_relat == 2  | recenttrip_relat == 3
gen rectripwithinweekrelat = 0 if recenttrip_relat == 1 | recenttrip_relat == 2  | recenttrip_relat == 3
replace rectripwithinweekrelat = 1 if recenttrip_relat == 4 | recenttrip_relat == 5 | recenttrip_relat == 6 | recenttrip_relat == 7
gen rectripyestodrelat = 0 if recenttrip_relat == 1 | recenttrip_relat == 2  | recenttrip_relat == 3 | recenttrip_relat == 4 | recenttrip_relat == 5
replace rectripyestodrelat = 1 if recenttrip_relat == 6 | recenttrip_relat == 7
label var rectripmoreweekrelat "Recent Trip to Relatives, GT Week"
label var rectripwithinweekrelat "Recent Trip to Relatives, Last Week"
label var rectripyestodrelat "Recent Trip to Relatives, Yest or Today"

* Time since the most recent trip to visit friends
tab lasttrip_friend_when
gen recenttrip_fd = 0 if lasttrip_friend_when == "NEVER"
replace recenttrip_fd = 1 if lasttrip_friend_when == "More than a month ago"
replace recenttrip_fd = 2 if lasttrip_friend_when == "A month ago"
replace recenttrip_fd = 3 if lasttrip_friend_when == "More than a week ago"
replace recenttrip_fd = 4 if lasttrip_friend_when == "One week ago"
replace recenttrip_fd = 5 if lasttrip_friend_when == "Less than one week ago"
replace recenttrip_fd = 6 if lasttrip_friend_when == "Yesterday"
replace recenttrip_fd = 7 if lasttrip_friend_when == "Today"
label values recenttrip_fd triprecency
label var recenttrip_fd "Recent Trip to Friend, Cate"

* dummy equivalents for regression
gen rectripeverfd = 0 if recenttrip_fd == 0
replace rectripeverfd = 1 if recenttrip_fd > 0 & recenttrip_fd !=.
gen rectripmoreweekfd = 0 if recenttrip_fd == 4 | recenttrip_fd == 5 | recenttrip_fd == 6 | recenttrip_fd == 7
replace rectripmoreweekfd = 1 if recenttrip_fd == 0 | recenttrip_fd == 1 | recenttrip_fd == 2  | recenttrip_fd == 3
gen rectripwithinweekfd = 0 if recenttrip_fd == 0 | recenttrip_fd == 1 | recenttrip_fd == 2  | recenttrip_fd == 3
replace rectripwithinweekfd = 1 if recenttrip_fd == 4 | recenttrip_fd == 5 | recenttrip_fd == 6 | recenttrip_fd == 7
gen rectripyestodfd = 0 if recenttrip_fd == 0 | recenttrip_fd == 1 | recenttrip_fd == 2  | recenttrip_fd == 3 | recenttrip_fd == 4 | recenttrip_fd == 5
replace rectripyestodfd = 1 if recenttrip_fd == 6 | recenttrip_fd == 7
label var rectripeverfd "Recent Trip to Friend"
label var rectripmoreweekfd "Recent Trip to Friend, GT Week"
label var rectripwithinweekfd "Recent Trip to Friend, Last Week"
label var rectripyestodfd "Recent Trip to Friend, Yest or Today"

label values recenttripmoreweek recenttripwithinweek recenttripyestod rectripevernofam rectripmoreweeknofam rectripwithinweeknofam rectripyestodnofam rectripmoreweekrelat rectripwithinweekrelat rectripyestodrelat rectripeverfd rectripmoreweekfd rectripwithinweekfd rectripyestodfd yesno

* Any travel yesterday to any destination other than work / study commute (correct?)
tab tripnb_yesterday
label var tripnb_yesterday "Trips Yesterday"

***** Trip Diary

* trip yesterday from earlier in survey
gen trip_yest = 0 if trip_yesterday == "No" 
replace trip_yest = 1 if trip_yesterday == "Yes"
label values trip_yest yesno
tab trip_yesterday trip_yest
label var trip_yest "Trip Yesterday"

gen tripnb_yest = (tripnb_yesterday != .)
replace tripnb_yest = 0 if tripnb_yesterday == 0
replace tripnb_yest = . if consentall == 0
tab tripnb_yesterday trip_yest
tab tripnb_yest trip_yest
label var tripnb_yest "Trip Yesterday"

* for consistency, dropping non-trip diary version
drop trip_yest

****** unaccompanied trips
gen drivediaryadultfam = 0 if trip1_adultfam != . & trip1_adultfam > 0 | trip2_adultfam != . & trip2_adultfam > 0 | trip3_adultfam != . & trip3_adultfam > 0 | trip4_adultfam != . & trip4_adultfam > 0 | trip5_adultfam != . & trip5_adultfam > 0 | trip6_adultfam != . & trip6_adultfam > 0 | trip7_adultfam != . & trip7_adultfam > 0 | trip8_adultfam != . & trip8_adultfam > 0 | trip9_adultfam != . & trip9_adultfam > 0 | trip10_adultfam != . & trip10_adultfam > 0
replace drivediaryadultfam = 1 if trip1_adultfam != . & trip1_adultfam == 0 | trip2_adultfam != . & trip2_adultfam == 0 | trip3_adultfam != . & trip3_adultfam == 0 | trip4_adultfam != . & trip4_adultfam == 0 | trip5_adultfam != . & trip5_adultfam == 0 | trip6_adultfam != . & trip6_adultfam == 0 | trip7_adultfam != . & trip7_adultfam == 0 | trip8_adultfam != . & trip8_adultfam == 0 | trip9_adultfam != . & trip9_adultfam == 0 | trip10_adultfam != . & trip10_adultfam == 0
replace drivediaryadultfam = 0 if tripnb_yesterday == 0

gen drivediaryadultother = 0 if trip1_adultother != . & trip1_adultother > 0 | trip2_adultother != . & trip2_adultother > 0 | trip3_adultother != . & trip3_adultother > 0 | trip4_adultother != . & trip4_adultother > 0 | trip5_adultother != . & trip5_adultother > 0 | trip6_adultother != . & trip6_adultother > 0 | trip7_adultother != . & trip7_adultother > 0 | trip8_adultother != . & trip8_adultother > 0 | trip9_adultother != . & trip9_adultother > 0 | trip10_adultother != . & trip10_adultother > 0
replace drivediaryadultother = 1 if trip1_adultother != . & trip1_adultother == 0 | trip2_adultother != . & trip2_adultother == 0 | trip3_adultother != . & trip3_adultother == 0 | trip4_adultother != . & trip4_adultother == 0 | trip5_adultother != . & trip5_adultother == 0 | trip6_adultother != . & trip6_adultother == 0 | trip7_adultother != . & trip7_adultother == 0 | trip8_adultother != . & trip8_adultother == 0 | trip9_adultother != . & trip9_adultother == 0 | trip10_adultother != . & trip10_adultother == 0
replace drivediaryadultother = 0 if tripnb_yesterday == 0

label var drivediaryadultfam "Unacompanied Trip, without Adult Family"
label var drivediaryadultother "Unacompanied Trip, without Adult Other"

* trip diary: purpose dummy cleaning 
mvencode tripnb_yesterday trip1 trip2 trip3 trip4 trip5 trip6 trip7 trip8 trip9 trip10 if consentall == 1, mv(0) override 

gen leisure = inlist(trip1_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip2_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip3_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip4_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip5_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip6_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip7_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip8_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip9_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside") | inlist(trip10_purpose, "(Leisure) - Meet friends", "(Leisure) - Meet relatives", "(Leisure) - park, movies, etc..", "(Leisure)- Eat a meal outside")
replace leisure = . if consentall == 0
label var leisure "Leisure"

gen personalb = inlist(trip1_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip2_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip3_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip4_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip5_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip6_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip7_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip8_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip9_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") | inlist(trip10_purpose, "(Personal business) - Complete government procedures, e.g. a court appointment", "(Personal business) - Go out for health reasons, e.g. hospital/Doctor appointment, pharmacy, etc..", "(Take someone else) - Take or accompany someone else") 
replace personalb = . if consentall == 0
label var personalb "Personal Business"

gen shopping = inlist(trip1_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip2_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip3_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip1_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip4_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip5_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip6_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip7_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip8_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip1_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip9_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items") | inlist(trip10_purpose, "(Shopping) - Shop for personal items", "(Shopping) - Shop for household items")
replace shopping = . if consentall == 0
label var shopping "Shopping"

gen workcom = inlist(trip1_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip2_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip3_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip4_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip5_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip6_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip7_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip8_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip9_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute") | inlist(trip10_purpose, "(Work/School Commute) - Attend university/classes", "(Work/School Commute) - Work commute")
replace workcom = . if consentall == 0
label variable workcom "Work/School Commute"

gen tripother = inlist(trip1_purpose, "Other (please specify):", "18", "23", "27", "32") | inlist(trip2_purpose, "Other (please specify):", "18", "20") | inlist(trip3_purpose, "Other (please specify):", "19", "27") | inlist(trip5_purpose, "Other (please specify):", "23")
replace tripother = . if consentall == 0
label variable tripother "Other Purpose"

gen returnhome = inlist(trip1_purpose, "Return home") | inlist(trip2_purpose, "Return home")  | inlist(trip3_purpose, "Return home")  | inlist(trip4_purpose, "Return home")  | inlist(trip5_purpose, "Return home")  | inlist(trip6_purpose, "Return home")  | inlist(trip7_purpose, "Return home")  | inlist(trip8_purpose, "Return home")  | inlist(trip9_purpose, "Return home")  | inlist(trip10_purpose, "Return home")
replace returnhome = . if consentall == 0
label variable returnhome "Return Home"

* trip diary: mode dummy cleaning 
gen modeother = inlist(trip1_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip2_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip3_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip4_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip5_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip6_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip7_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip8_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip9_mode, "Other", "Bus provided by employer or university", "By foot (walking)") | inlist(trip10_mode, "Other", "Bus provided by employer or university", "By foot (walking)") 
replace modeother = . if consentall == 0
label var modeother "Other Mode"

gen taxi = inlist(trip1_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand") | inlist(trip2_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand") | inlist(trip3_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  | inlist(trip4_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  | inlist(trip5_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  | inlist(trip6_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  | inlist(trip7_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  | inlist(trip8_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  | inlist(trip9_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  | inlist(trip10_mode, "Taxi", "Car (as a passenger with a paid driver)", "Car pooling (shared driver)", "E-Ride hailing (Uber/Careem)", "Driver on demand")  
replace taxi = . if consentall == 0
label var taxi "Taxi"

gen carfam = inlist(trip1_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip2_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip3_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip4_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip5_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip6_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip7_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip8_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip9_mode, "Car (as a passenger with a family member or friend driving)") | inlist(trip10_mode, "Car (as a passenger with a family member or friend driving)")
replace carfam = . if consentall == 0
label variable carfam "Car with Family"

gen driver = inlist(trip1_mode, "Car (driver)") | inlist(trip2_mode, "Car (driver)") | inlist(trip3_mode, "Car (driver)") | inlist(trip4_mode, "Car (driver)") | inlist(trip5_mode, "Car (driver)") | inlist(trip6_mode, "Car (driver)") | inlist(trip7_mode, "Car (driver)") | inlist(trip8_mode, "Car (driver)") | inlist(trip9_mode, "Car (driver)") | inlist(trip10_mode, "Car (driver)")
replace driver = . if consentall == 0
label variable driver "Driver of Car"

gen driversolo = (driver == 1 & drivediaryadultfam == 1 & drivediaryadultother == 1)
replace driversolo = . if consentall == 0
gen driverfam = (driver == 1 & drivediaryadultfam == 0)
replace driverfam = . if consentall == 0
label variable driversolo "Solo Driver"
label variable driverfam "Driver with Family"

save "${data}/RCT wave 2/Cleaned/cleaned_wave2_dataset_full.dta", replace

* if desired, remove string equivalents of the above new numeric variables so as to not have duplicate variables
drop callbackattempts participantgroup callanswered consent monthlysalary attend_careerfair jobhunt_friends jobhunt_jpc jobhunt_inperson jobhunt_calledemplo jobhunt_advert jobhunt_agency jobhunt_other jobhunt_noanswer jobhunt_callended jobhunt_none jobsappli_lastmnth jobsappli_lastmnth_txt jobinterv_lastmnth jobinterv_lastmnth_txt jobinterv_go jobinterv_go_txt drivinglicense anydrivingtraining sauditraining drivinh_lastmnth driving_times driving_likely trip_yesterday lasttrip_when lasttrip_noacco_when lasttrip_relat_when lasttrip_friend_when

* ADDITIONAL CLEANING FOR WAVE 3 MERGE/FINAL ANALYSIS

* cost of commute
	gen comm_cost_mo_w2 = commutecost_permnth 
	lab var comm_cost_mo_w2 "Monthly cost of commute to work (in 2020 USD)"
	* convert to 2020 USD (exchange rate of 0.2665)
	replace comm_cost_mo_w2 = comm_cost_mo_w2*.2665
	
	gen comm_cost_day_w2 = commutecost_perday
	lab var comm_cost_day_w2 "Daily cost of commute to work (in 2020 USD)"
	* convert to 2020 USD (exchange rate of 0.2665)
	replace comm_cost_day_w2 = comm_cost_day_w2*.2665
	* now combine this with our monthly cost
	replace comm_cost_mo_w2 = 40*comm_cost_day_w2 if comm_cost_mo_w2==. & ///
		comm_cost_day_w2!=.
	
	* rename expected commute
		* convert to 2020 USD (exchange rate of 0.2665)
	gen expectcomm_w2 = expectcomm_ehai_amount_tr
	replace expectcomm_w2 = expectcomm_w2*.2665
	lab var expectcomm_w2 "Expected 30 min commute cost in 2020 USD"
	
	* Drove yesterday 
	gen drove_yest_w2 = 0 if tripnb_yesterday!=.
	

	forval i = 2/10 {
		replace drove_yest_w2 = 1 if trip`i'_mode=="Car (driver)"
	}
	lab var drove_yest_w2 "Drove yesterday (wave 2)"
	
	* fix to code bug in wave 2 cleaning: recent trips
		* to relatives
		replace rectripyestodrelat = 0 if recenttripyestod==0 & rectripyestodrelat==.
		replace rectripyestodrelat = 0 if recenttrip_relat==0 & rectripyestodrelat==.
	
		* to friends 
		replace rectripyestodfd = 0 if recenttripyestod==0 & rectripyestodfd==.
		
	* let's also make this variable for wave 2
		gen nonwork_trip_w2 = 0 if inlist(recenttrip_relat, 0,1,2,3) 
		replace nonwork_trip_w2 = 0 if inlist(recenttrip_fd, 0,1,2,3) 
		replace nonwork_trip_w2 = 1 if inlist(recenttrip_relat, 4,5,6,7) 
		replace nonwork_trip_w2 = 1 if inlist(recenttrip_fd, 4,5,6,7) 
		lab var nonwork_trip_w2 ///
		"Any visit to family or friends in past 1 week (wave 2)"
		
		* Clean travel time 

	foreach i of varlist *_arrivtime *_departime {

	replace `i' = "4:00:00PM" if `i'=="40:00PM"

	replace `i' = subinstr(`i',"١","1",.)
	replace `i' = subinstr(`i',"٢","2",.)
	replace `i' = subinstr(`i',"٣","3",.)
	replace `i' = subinstr(`i',"٤","4",.)
	replace `i' = subinstr(`i',"٥","5",.)
	replace `i' = subinstr(`i',"٦","6",.)
	replace `i' = subinstr(`i',"٧","7",.)
	replace `i' = subinstr(`i',"٨","8",.)
	replace `i' = subinstr(`i',"٩","9",.)
	replace `i' = subinstr(`i',"٠","0",.)

	replace `i' = subinstr(`i',"م","PM",.)
	replace `i' = subinstr(`i',"ص","AM",.)
	replace `i' = subinstr(`i',"س","PM",.)

	replace `i' = subinstr(`i'," ","",.)

	foreach j in ح ب ا ء  {
	replace `i' = subinstr(`i',"`j'","",.) 
	}

	replace `i' = subinstr(`i',"PMPM","PM",.)
	replace `i' = subinstr(`i',"AMAM","AM",.)
	}

	* Sometimes the enumerator wrote AM / PM in the first entry only, resulting in inconsistent time conversion - assume 7am - 7:05 implies 7am - 7:05am:  
	forvalues i = 1 / 10 {

	replace trip`i'_arrivtime = trip`i'_arrivtime + "AM" ///
		if regexm( trip`i'_departime,"AM")==1 ///
		& regexm( trip`i'_arrivtime,"AM")==0 ///
		& regexm( trip`i'_arrivtime,"PM")==0 
		
	replace trip`i'_arrivtime = trip`i'_arrivtime + "PM" ///
		if regexm( trip`i'_departime,"PM")==1 ///
		&  regexm( trip`i'_arrivtime,"AM")==0 ///
		& regexm( trip`i'_arrivtime,"PM")==0
		
	replace trip`i'_departime = trip`i'_departime + "AM" ///
		if regexm( trip`i'_arrivtime,"AM")==1 ///
		& regexm( trip`i'_departime,"AM")==0 ///
		& regexm( trip`i'_departime,"PM")==0 
		
	replace trip`i'_departime = trip`i'_departime + "PM" ///
		if regexm( trip`i'_arrivtime,"PM")==1 ///
		&  regexm( trip`i'_departime,"AM")==0 ///
		& regexm( trip`i'_departime,"PM")==0
	lab var trip`i'_arrivtime "Trip `i' arrive time (wave 2)"
	lab var trip`i'_departime "Trip `i' depart time (wave 2)"
	}

	foreach i of varlist *_arrivtime *_departime {

	* Align times from different formats (7am, 7:00am, 7:00:00am)
	gen double `i'_num1 = clock(`i', "hms")
	format `i'_num1 %tc 
	gen double `i'_num2 = clock(`i', "hm")
	format `i'_num2 %tc 
	gen double `i'_num3 = clock(`i', "h")
	format `i'_num3 %tc 

	egen double `i'_num = rowmean(`i'_num1 `i'_num2 `i'_num3) 
	format `i'_num %tc 
	drop `i'_num1 `i'_num2 `i'_num3
	}


	** Travel time = difference between arrival & departure time

	forvalues i = 1 / 10 { 

	gen trip`i'_duration = trip`i'_arrivtime_num - trip`i'_departime_num 
	replace trip`i'_duration = trip`i'_duration / 60000	                            // Rescale to minutes

	* there are 2 negative values (stata error when arrive time is AM and departure is PM)
	replace trip`i'_duration = 1440 + trip`i'_duration if trip`i'_duration<0 & trip`i'_duration!=.
	replace trip`i'_duration = 180 if trip`i'_duration>180 & trip`i'_duration<.		// Topcode very long trips
	lab var trip`i'_duration "trip`i'_duration (wave 2)"
	lab var trip`i'_arrivtime_num "Trip `i' arrive time, numeric (wave 2)"
	lab var trip`i'_departime_num "Trip `i' depart time, numeric (wave 2)"	
	}

	** Max & Mean travel time across trips (egen rowmean / rowmax) 
	rename tripnb_yesterday tripnb_yesterday_w2

	egen mean_trip_duration = rowmean(trip*duration) 
	gen mean_trip_duration_uncond = mean_trip_duration
	replace mean_trip_duration_uncond = 0 if tripnb_yesterday_w2 < . & mean_trip_duration_uncond==0 
	egen max_trip_duration = rowmax(trip*duration) 
	egen total_trip_duration = rowtotal(trip*duration) 
	replace total_trip_duration = . if trip1_duration==.

	foreach i in max_trip_duration total_trip_duration {
	replace `i' = 0 if tripnb_yesterday_w2==0 
	}



	label var mean_trip_duration "Mean one-way trip duration mins $|$ any trip yesterday (wave 2)"	//  - missing if no trip
	label var mean_trip_duration_uncond "Mean trip duration mins - 0 if no trip (wave 2)"
	label var max_trip_duration "Max trip duration mins - 0 if no trip (wave 2)"
	label var total_trip_duration "Total trip duration mins - 0 if no trip (wave 2)"

	* Clean travel mode

	foreach i in bus foot car_family car_paiddriver car_driver car_pooling hailing taxi other  {
		
	gen trip_mode_`i' = 0 if tripnb_yesterday_w2 < .
		
	}

	forvalues i = 1 / 10 {
	replace trip_mode_bus = 1 if regexm(trip`i'_mode, "Bus provided")==1
	replace trip_mode_foot = 1 if regexm(trip`i'_mode, "By foot")==1
	replace trip_mode_car_family = 1 if regexm(trip`i'_mode, "as a passenger with a family")==1
	replace trip_mode_car_paiddriver = 1 if regexm(trip`i'_mode, "as a passenger with a paid")==1
	replace trip_mode_car_driver = 1 if trip`i'_mode=="Car (driver)"
	replace trip_mode_car_pooling = 1 if regexm(trip`i'_mode, "Car pooling")==1
	replace trip_mode_hailing = 1 if regexm(trip`i'_mode, "Driver on demand")==1 | regexm(trip`i'_mode, "E-Ride hailing")==1
	replace trip_mode_other = 1 if regexm(trip`i'_mode, "Other")==1
	replace trip_mode_taxi = 1 if regexm(trip`i'_mode, "Taxi")==1
	}

	label variable trip_mode_bus "Trip yesterday - Bus provided by university or employer (wave 2)"
	label variable trip_mode_foot "Trip yesterday - Walking (wave 2)"
	label variable trip_mode_car_driver "Trip yesterday - Drove herself (wave 2)"
	label variable trip_mode_car_family "Trip yesterday - Car - family member driving (wave 2)"
	label variable trip_mode_car_paiddriver "Trip yesterday - Car with paid driver (wave 2)"
	label variable trip_mode_car_pooling "Trip yesterday - Car pooling (wave 2)"
	label variable trip_mode_hailing "Trip yesterday - Ride-hailing (e.g. Uber) (wave 2)"
	label variable trip_mode_taxi "Trip yesterday - Taxi (wave 2)"
	label variable trip_mode_other "Trip yesterday - Other mode (wave 2)"



	* Clean purpose of travel 

	foreach i in leisure_friends leisure_rel leisure_park leisure_meal ///
		pers_govt pers_health shopping_hh shopping_pers pickdrop uni work {
	gen trip_any_`i' = 0 if tripnb_yesterday_w2 < .
	}

	forvalues i = 1 / 10 {

	replace trip_any_leisure_friends = 1 if regexm(trip`i'_purpose,"Meet friends")==1
	replace trip_any_leisure_rel = 1 if regexm(trip`i'_purpose,"Meet relatives")==1
	replace trip_any_leisure_park = 1 if regexm(trip`i'_purpose,"park, movies, etc")==1
	replace trip_any_leisure_meal = 1 if regexm(trip`i'_purpose,"Eat a meal outside")==1
	replace trip_any_pers_govt = 1 if regexm(trip`i'_purpose,"Complete govern")==1
	replace trip_any_pers_health = 1 if regexm(trip`i'_purpose,"Go out for heal")==1
	replace trip_any_shopping_hh = 1 if regexm(trip`i'_purpose,"Shop for household items")==1
	replace trip_any_shopping_pers = 1 if regexm(trip`i'_purpose,"Shop for personal items")==1
	replace trip_any_pickdrop = 1 if regexm(trip`i'_purpose,"Take or accompa")==1
	replace trip_any_uni = 1 if regexm(trip`i'_purpose,"Attend unive")==1
	replace trip_any_work = 1 if regexm(trip`i'_purpose,"Work commute")==1

	}

	gen trip_duration_work = 0 if   tripnb_yesterday_w2 < . 
	gen trip_duration_driving = 0 if   tripnb_yesterday_w2 < . 

	forvalues i = 1 / 10 {
		
		replace trip_duration_work = trip_duration_work + trip`i'_duration if regexm(trip`i'_purpose,"Work commute")==1
		
		replace trip_duration_driving = trip_duration_driving + trip`i'_duration if trip`i'_mode=="Car (driver)"
		
	}

	gen trip_duration_work_cond = trip_duration_work if trip_any_work==1 
	label variable trip_duration_work_cond "One-way commute duration mins $|$ any commute to work yesterday (wave 2)"
	lab var trip_duration_work "Work commute duration (wave 2)"
	lab var trip_duration_driving "Driving duration (wave 2)"

	* Bigger purpose categories 
	egen trip_any_leisure = rowmax(trip_any_leisure*) 
	egen trip_any_errands = rowmax(trip_any_pers* trip_any_shopping*) 

	label variable trip_any_leisure_friends "Trip yesterday - Leisure to meet friends (wave 2)"
	label variable trip_any_leisure_rel "Trip yesterday - Leisure to meet relatives (wave 2)"
	label variable trip_any_leisure_park "Trip yesterday - Leisure to park or movies (wave 2)"
	label variable trip_any_leisure_meal "Trip yesterday - Leisure for meal (wave 2)"
	label variable trip_any_pers_govt "Trip yesterday - Errands - personal business (wave 2)"
	label variable trip_any_pers_health "Trip yesterday - Errands - health (wave 2)"
	label variable trip_any_shopping_hh "Trip yesterday - Errands - HH shopping (wave 2)"
	label variable trip_any_shopping_pers "Trip yesterday - Errands - personal shopping (wave 2)"
	label variable trip_any_pickdrop "Trip yesterday - Pick or drop someone (wave 2)"
	label variable trip_any_uni "Trip yesterday - University commute (wave 2)"
	label variable trip_any_work "Trip yesterday - Work commute (wave 2)"
	label variable trip_any_leisure "Trip yesterday - Any leisure trip (wave 2)"
	label variable trip_any_errands "Trip yesterday - Any errands trip (wave 2)"

	gen trip_any = tripnb_yesterday_w2 > 0 & tripnb_yesterday_w2 < .
	replace trip_any = . if  tripnb_yesterday_w2==.
	label variable trip_any "Any trip yesterday  (wave 2)"
		

	* Desc stats for paper - C group only, Wave 2 detailed travel 
	gen travel_duration_diary = .
	replace travel_duration_diary = 0 if tripnb_yesterday_w2==0 
	replace travel_duration_diary = 1 if total_trip_duration > 0 & total_trip_duration <= 15 
	replace travel_duration_diary = 2 if total_trip_duration > 15 & total_trip_duration <= 30
	replace travel_duration_diary = 3 if total_trip_duration > 30 & total_trip_duration <= 45
	replace travel_duration_diary = 4 if total_trip_duration > 45 & total_trip_duration <= 60
	replace travel_duration_diary = 5 if total_trip_duration > 60 & total_trip_duration <= 90
	replace travel_duration_diary = 6 if total_trip_duration > 90 & total_trip_duration <= 120
	replace travel_duration_diary = 7 if total_trip_duration > 120 & total_trip_duration < .
	lab var travel_duration_diary "Trip duration, category (wave 2)"

	label define frequency 0 "Did not travel" 1 "< 15 mins" 2 "16-30 mins" 3 "31 - 45 mins" 4 "45 - 60 mins" 5 "61 - 90 mins" 6 "90 - 120 mins" 7 "> 120 mins"
		
		
	* create wave 2 travel vars that are conditional on having made a trip yesterday
	global travelvars1 mean_trip_duration mean_trip_duration_uncond max_trip_duration total_trip_duration 
	global travelvars2 rectripwithinweeknofam_w2 drivediaryadultfam_w2 drivediaryadultother_w2 
	global travelvars3 trip_family_pool trip_friends_pool nonwork_trip_pool
	global travelvars4 trip_any_work trip_any_uni trip_any_pickdrop trip_any_errands trip_any_leisure // Simple purpose
	global travelvars5 trip_any_leisure_friends trip_any_leisure_rel ///
		trip_any_leisure_park trip_any_leisure_meal trip_any_pers_govt ///
		trip_any_pers_health trip_any_shopping_hh trip_any_shopping_pers ///
		trip_any_pickdrop trip_any_uni trip_any_work								// Detailed purpose

	global travelvars6 trip_duration_work trip_duration_work_cond
	global travelvars7 trip_mode_* 

	global travelvars8 ""
	foreach var of varlist $travelvars5 $travelvars7 {
		
		gen `var'cond = `var' 
		replace `var'cond = . if tripnb_yesterday_w2==0 
		global travelvars8 $travelvars8 `var'cond 
		local lab: variable label `var'
		label variable `var'cond "`lab'"
		
	}

	* Create combined travel groups
	
		* Leisure: trip_any_leisure_friendscond trip_any_leisure_relcond_w2 ///
		trip_any_leisure_parkcond_w2 trip_any_leisure_mealcond_w2		
		egen trip_all_leisure_cond = rowmax(trip_any_leisure_friendscond ///
		trip_any_leisure_relcond trip_any_leisure_parkcond ///
		trip_any_leisure_mealcond) 
		lab var trip_all_leisure_cond "Trip yesterday - Any leisure (wave 2)"
		
		* Create unconditional version
		egen trip_all_leisure = rowmax(trip_any_leisure_friends ///
		trip_any_leisure_rel trip_any_leisure_park ///
		trip_any_leisure_meal) 
		lab var trip_all_leisure "Any leisure trip; uncond. (wave 2)"
		
		* Personal errands: trip_any_pers_govtcond, trip_any_pers_healthcond, ///
		trip_any_shopping_perscond
		egen trip_personal_errands_cond = rowmax(trip_any_pers_govtcond ///
		trip_any_pers_healthcond trip_any_shopping_perscond)
		lab var trip_personal_errands_cond "Trip yesterday - Any personal errands (wave 2)"
		
		* Create unconditional version
		egen trip_personal_errands = rowmax(trip_any_pers_govt ///
		trip_any_pers_health)
		lab var trip_personal_errands "Other personal errands; uncond. (wave 2)"

		
		* HH errands: trip_any_pickdropcond trip_any_shopping_hhcond
		egen trip_HH_errands_cond = rowmax(trip_any_pickdropcond ///
		trip_any_shopping_hhcond)
		lab var trip_HH_errands_cond "Trip yesterday - Any HH errands (wave 2)"

		* Create unconditional version
		egen trip_HH_errands = rowmax(trip_any_pickdrop trip_any_shopping_hh)
		lab var trip_HH_errands "Any HH errands; uncond. (wave 2)"

		* Commute: trip_any_unicond trip_any_workcond
		egen trip_commute_cond = rowmax(trip_any_unicond trip_any_workcond)
		lab var trip_commute_cond "Trip yesterday - Any commute (wave 2)"
		
		* Create unconditional version
		egen trip_commute = rowmax(trip_any_uni trip_any_work)
		lab var trip_commute "Any commute; uncond. (wave 2)"


* Finally, add "_w2" to end of all vars
	* some already have '_w2' at the end, let's skip these
	lookfor _w2
	local suffix_vars `r(varlist)'
	* and some we don't want to include
	local 	skip_vars Institution file_nbr participantid randomization_cohort ///
			randomization_cohort2 NGO num_enrolled_HH group_strata Randomization ///
			driving_ct wusool_ct national_id hh_les18 hh_more18 driving_ct2 ///
			wusool_ct2 driving_T wusool_T driving_ctoriginal wusool_ctoriginal ///
			Excluded Exclusion household_size HH_enrolled 
	ds _all
	local full_list `r(varlist)'

	local missing_w2_suffix: list full_list - suffix_vars 
	local missing_w2_suffix: list missing_w2_suffix - skip_vars

foreach var of local missing_w2_suffix {
	rename `var' `var'_w2
}
		

save "${data}/RCT wave 2/Final/Wave2.dta", replace

