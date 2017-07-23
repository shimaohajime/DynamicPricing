clear
set more off
//set min_memory 3G

use "C:\Users\Hajime\Dropbox\Hajime\SS progress\1. 151223 Videogame Cleaning All\NPD_data_working_FullFinalData.dta"
cd "C:\Users\Hajime\Dropbox\Hajime\SS progress\10. MPEC estimation and data\10-3-Monopoly-Mutiple-PuPl\"
/*Select samples*/
drop if Unit<5000 
/*drop the first month of the platform
drop if hwsales==marketsize
*/

/*drop the first month, adjust the age
drop if Age==0
replace Age=Age-1
*/

//drop if Unit<2000 
//keep if platformid==1 //PlaySatation
//keep if platformid==2 //Wii
//keep if platformid==3 //XB
//keep if supergenreid==2 //Adventure
//keep if supergenreid==11 //RPG
gen TotalUnitCategory = "Above2M" if TotalUnit>2e6
replace TotalUnitCategory = "1M-2M" if TotalUnit<=2e6 & TotalUnit>1e6
replace TotalUnitCategory = "500K-1M" if TotalUnit<=1e6 & TotalUnit>5e5
replace TotalUnitCategory = "200K-500K" if TotalUnit<=5e5 & TotalUnit>2e5
replace TotalUnitCategory = "100K-200K" if TotalUnit<=2e5 & TotalUnit>1e5
replace TotalUnitCategory = "Below100K" if TotalUnit<=1e5


/*Reshape data*/
rename titleid PROD
rename Unit unit
rename PriceAdj price
rename Age AGE
rename Month month
rename Year year
gen prodage=AGE
drop if price==0
drop if unit==. 
drop if price==.

*** publisher id label and values
decode publisherid, gen (publisherid_label)
order publisherid_label, a( publisherid )
tostring publisherid , gen(publisherid_number)
destring publisherid_number , replace
rename publisherid_label publisher
gen first_party=0
replace first_party=1 if publisherid==59 | publisherid==67 | publisherid==83|publisherid==84

keep PROD AGE NPD_Title t unit price hwsales marketsize prodage month year t supergenre supergenreid publisher publisherid platform platformid MH MH_index first_party TotalUnit CumUnit TotalUnitCategory
order AGE, a(PROD)


*** drop non continuous period within panel
sort PROD AGE
bys PROD: gen cont=_n-1
drop if AGE!=cont
drop cont


*** Shape a balanced panel
sort PROD t
egen last_t = max(t)
bysort PROD: egen max_t = max(t)
gen flag_disappear = 0 
replace flag_disappear = 1 if max_t<last_t 
//drop if flag_disappear==0
bysort PROD: egen max_age = max(AGE)
bysort PROD: egen min_age = min(AGE)


drop if max_age<24
drop if min_age!=0

/*balance the panel
drop if AGE>=24
*/


*** scale units ***
gen unit_scale = 100000
label variable unit_scale "Scale for units"
replace unit = unit/unit_scale
replace TotalUnit = TotalUnit/unit_scale
replace marketsize = marketsize/unit_scale
replace hwsales = hwsales/unit_scale
label variable unit "Unit Sales (by unit_scale)"
label variable marketsize "Potential Market Size : Own Platform Hardware Cumulative Sale (by unit_scale)"
label variable unit "Own Platform Hardware Sale (by unit_scale)"


/*Create ALL data*/
global fname="All"
global folder="AboveTwoYear_U5K_$fname" 
//confirmdir "AboveTwoYear_U10K_$fname" 
confirmdir $folder 
if r(confirmdir)!="0"{
//mkdir "OneHalfYear_U5K_NoPL1stM_$fname" 

mkdir $folder 
}
//preserve
do 10-3-Create_Sheets_MPEC_Test-Multiple.do 
//restore

/*Create data in folders*/
/*
levelsof TotalUnitCategory, local(PopCategory) 
foreach i of local PopCategory {
global fname="`i'"
confirmdir "TwoYear_U5K_$fname" 
if r(confirmdir)!="0"{
mkdir "TwoYear_U5K_$fname" 
}
preserve
keep if TotalUnitCategory == "`i'"
do 10-3-Create_Sheets_MPEC_Test-Multiple.do 
restore
}
*/

