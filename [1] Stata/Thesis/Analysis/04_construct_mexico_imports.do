/*==========================================================================
 * Mexico Import Data Construction
 * Author:         Lance Cu Pangilinan
 * Last modified:  05/05/2025
 *
 * Purpose:
 *   - Build a panel of Mexican imports (HS-6) matched to NAICS 3-digit industries
 *   - Harmonize concordance data, process 5 years of trade data (1990–2019),
 *     match industries, and fill missing values with zeroes.
 *
 * Inputs:
 *   - impconcord17.xls       (HS–NAICS concordance)
 *   - C_A_484_*.txt          (UN COMTRADE import data for Mexico)
 *   - CAT_ACTECONOMICA.csv   (NAICS metadata)
 *
 * Output:
 *   - mexico_matched.dta     (Panel: NAICS3 x Year with import values)
 *==========================================================================*/

clear                                   // Clear memory
cap log close                           // Close any open log

//-------------------------------------------------------------------------
// 1. Load and prepare the HS–NAICS concordance
//-------------------------------------------------------------------------
import excel "impconcord17.xls", sheet("impconcord17") firstrow clear
                                        // Load concordance with column headers

gen naics3 = substr(naics, 1, 3)        // Extract NAICS 3-digit code
gen hs6 = substr(commodity, 1, 6)       // Extract HS-6 code

bysort hs6 (naics3): keep if _n == 1    // Keep first match per HS-6

drop descriptn abbreviatn unit_qy1 unit_qy2 end_use sitc usda hitech
                                        // Drop unused columns

save "hs_naics_concordance.dta", replace

//-------------------------------------------------------------------------
// 2. Import and stack Mexico HS-6 import data (partner: China, HS 484)
//-------------------------------------------------------------------------
local years "1990 2000 2010 2015 2019"

foreach y of local years {
    import delimited "C_A_484_`y'01_H`=cond(`y'>2000,4,cond(`y'==2000,1,0))'_O.txt", clear
                                        // Load annual data for year `y`
    keep if partnercode == 156 & flowcode == "M"
                                        // Keep imports from China only
    drop if cmdcode == "TOTAL"          // Drop aggregate rows
    drop if strlen(cmdcode) < 6         // Ensure 6-digit HS codes only
    append using combined_mexico, force // Append to growing dataset (except 1990)
    save combined_mexico, replace       // Save intermediate file
}

//-------------------------------------------------------------------------
// 3. Clean and retain key trade variables
//-------------------------------------------------------------------------
use combined_mexico, clear
keep period reportercode partnercode cmdcode fobvalue
rename cmdcode hs6

save "mexico_trade.dta", replace        // Save cleaned trade data

//-------------------------------------------------------------------------
// 4. Merge HS–NAICS concordance with trade data
//-------------------------------------------------------------------------
use hs_naics_concordance, clear
use mexico_trade, clear

merge m:1 hs6 using hs_naics_concordance
keep if _merge == 3                     // Keep only matched observations
drop _merge

save "mexico_temp.dta", replace

//-------------------------------------------------------------------------
// 5. Merge in NAICS industry metadata
//-------------------------------------------------------------------------
import delimited "CAT_ACTECONOMICA.csv", clear

tostring llave_acteconomica, gen(naics3) // Convert numeric to string for merge
drop llave_exportadora

merge 1:m naics3 using mexico_temp
rename _merge _merge_concord            // Retain merge info if needed

keep naics3 period fobvalue reporter    // Keep essential variables

//-------------------------------------------------------------------------
// 6. Fill in missing years for NAICS3 codes (with 0 import value)
//-------------------------------------------------------------------------
preserve                                // Save original dataset in memory

keep if missing(period)                // Identify NAICS3s with no year
keep naics3
duplicates drop

gen reportercode = 484
gen fobvalue = 0

expand 5                                // Create 5-year rows for each NAICS3
gen period = .
replace period = 1990 if mod(_n,5)==1
replace period = 2000 if mod(_n,5)==2
replace period = 2010 if mod(_n,5)==3
replace period = 2015 if mod(_n,5)==4
replace period = 2019 if mod(_n,5)==0

tempfile filled_rows
save `filled_rows'

restore                                 // Return to full data
drop if missing(period)                // Drop rows without year info

append using `filled_rows'             // Append constructed rows

//-------------------------------------------------------------------------
// 7. Aggregate and finalize output
//-------------------------------------------------------------------------
sort naics3 period
collapse (sum) fobvalue, by(naics3 period)
                                        // Aggregate by industry-year

rename naics3 Ind3D                     // Rename to final format
destring Ind3D, replace

replace period = 2020 if period == 2019 // Optional: relabel 2019 as pre-COVID

save "mexico_matched.dta", replace      // Final output dataset
