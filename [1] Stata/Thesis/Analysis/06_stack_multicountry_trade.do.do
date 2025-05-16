/*==========================================================================
 * Multi-Country China Import Exposure: Raw Trade Stacking
 * Author:         Lance Cu Pangilinan
 * Last modified:  05/05/2025
 *
 * Purpose:
 *   - Import HS-6 trade data from multiple countries (with China as partner)
 *   - Stack them into one dataset
 *   - Compute average import value per HS6 over 1990–2019
 *   - Link to NAICS3 industries and prepare for shock analysis
 *
 * Output:
 *   - multi_matched.dta
 *==========================================================================*/

clear                                   // Start clean workspace

//-------------------------------------------------------------------------
// 1) Italy (reporter = 380)
//-------------------------------------------------------------------------
import delimited "C_A_380_199001_S3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
save combined_china_trade, replace

import delimited "C_A_380_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_380_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_380_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_380_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
// 2) Spain (724)
//-------------------------------------------------------------------------
import delimited "C_A_724_199001_H0.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_724_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_724_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_724_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_724_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
// 3) Canada (124)
//-------------------------------------------------------------------------
import delimited "C_A_124_199001_H0_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_124_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_124_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_124_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_124_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
// 4) Pakistan (586)
//-------------------------------------------------------------------------
import delimited "C_A_586_199001_S3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_586_200001_S3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_586_201001_H3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_586_201501_H4.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_586_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
// 5) Indonesia (360)
//-------------------------------------------------------------------------
import delimited "C_A_360_199001_H0.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_360_200001_H1.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_360_201001_H3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_360_201501_H4.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_360_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
// 6) United Arab Emirates (784)
//-------------------------------------------------------------------------
import delimited "C_A_784_199001_S2.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
save combined_china_trade, replace

import delimited "C_A_784_200001_H1.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_784_201001_H3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_784_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_784_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
// 7) Poland (616)
//-------------------------------------------------------------------------
import delimited "C_A_616_199001_S2_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
save combined_china_trade, replace

import delimited "C_A_616_200001_H1.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_616_201001_H3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_616_201501_H4.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_616_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
// 8) Brazil (076)
//-------------------------------------------------------------------------
import delimited "C_A_76_199001_H0.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
save combined_china_trade, replace

import delimited "C_A_76_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_76_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_76_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

import delimited "C_A_76_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL" | strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace


//-------------------------------------------------------------------------
// Final cleanup: keep essential variables and collapse by HS6-year
//-------------------------------------------------------------------------
use combined_china_trade, clear
keep period cmdcode fobvalue
rename cmdcode hs6

save combined_china_trade.dta, replace

collapse (sum) fobvalue, by(period hs6)
gen avg_fobvalue = fobvalue / 5        // Average across 5 years
drop fobvalue

save "selected_countries_avg_china_imports.dta", replace

//-------------------------------------------------------------------------
// Merge with HS → NAICS concordance
//-------------------------------------------------------------------------
use "selected_countries_avg_china_imports.dta", clear

merge m:1 hs6 using "hs_naics_concordance.dta", keep(3)
drop _merge
save "multi_temp.dta", replace

//-------------------------------------------------------------------------
// Merge with NAICS metadata catalog
//-------------------------------------------------------------------------
import delimited "CAT_ACTECONOMICA.csv", clear
tostring llave_acteconomica, gen(naics3)
drop llave_exportadora

merge 1:m naics3 using "multi_temp.dta"
rename _merge _merge_concord

keep naics3 period avg_fobvalue

//-------------------------------------------------------------------------
// Fill missing NAICS3 × year combinations with 0s
//-------------------------------------------------------------------------
preserve
keep if missing(period)
keep naics3
duplicates drop

gen avg_fobvalue = 0
expand 5

gen period = .
replace period = 1990 if mod(_n, 5) == 1
replace period = 2000 if mod(_n, 5) == 2
replace period = 2010 if mod(_n, 5) == 3
replace period = 2015 if mod(_n, 5) == 4
replace period = 2019 if mod(_n, 5) == 0

tempfile filled_rows
save `filled_rows'
restore

drop if missing(period)
append using `filled_rows'

//-------------------------------------------------------------------------
// Final output: format and save
//-------------------------------------------------------------------------
sort naics3 period
collapse (sum) avg_fobvalue, by(naics3 period)

rename naics3 Ind3D
destring Ind3D, replace
replace period = 2020 if period == 2019   // Label 2019 as pre-COVID

save "multi_matched.dta", replace
