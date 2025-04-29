/**************************************************************************
 * Do File to Clean and Concord Mexico Trade Data with NAICS-HS Mapping
 * Author:        Lance Cu Pangilinan
 * Last Modified: 04/17/2025
 *
 * Purpose:
 *   1. Load HS-to-NAICS concordance from Excel and save as Stata dataset.
 *   2. Import and concatenate Mexico import data for selected years.
 *   3. Merge HS6-level trade flows with NAICS concordance.
 *   4. Fill missing NAICS-year pairs with zero trade values.
 *   5. Aggregate and export final matched dataset.
 *
 * Inputs:
 *   - impconcord17.xls (HS–NAICS concordance spreadsheet)
 *   - C_A_484_<year>*.txt (Mexico trade raw exports/imports)
 *   - CAT_ACTECONOMICA.csv (industry classification master list)
 *
 * Outputs:
 *   - hs_naics_concordance.dta
 *   - mexico_trade.dta
 *   - mexico_temp.dta
 *   - mexico_matched.dta
 **************************************************************************/

/*--------------------------------------------------------------------------
 SECTION 1: Load HS-to-NAICS Concordance
  - Reads Excel file mapping HS6 codes to 3-digit NAICS
  - Saves cleaned concordance for later merges
 ---------------------------------------------------------------------------*/
cd "C:\Users\lcp38\Downloads\Thesis\Datos\Cleaned_Indiv"
import excel "C:\Users\lcp38\Downloads\Thesis\Datos\Cleaned_Indiv\impconcord17.xls", \
    sheet("impconcord17") firstrow clear

// Extract only the first 3 digits of NAICS and first 6 of HS
gen naics3 = substr(naics, 1, 3)
gen hs6    = substr(commodity, 1, 6)

// Deduplicate HS6-NAICS3 pairs
bysort hs6 (naics3): keep if _n == 1

// Drop columns not needed downstream
drop descriptn abbreviatn unit_qy1 unit_qy2 end_use sitc usda hitech

// Save cleaned concordance
save "hs_naics_concordance.dta", replace


/*--------------------------------------------------------------------------
 SECTION 2: Import and Concatenate Mexico Imports
  - Loops over selected years to read partnercode=156 & flowcode=M
  - Initializes or appends to temporary dataset
 ---------------------------------------------------------------------------*/

global raw_dir "C:\Users\lcp38\Downloads\Thesis\Datos\Trade"
local years "1990 2000 2010 2015 2019"
 //* Iterate through each trade year
foreach yr of local years {
    // Determine file suffix by year convention
    if "`yr'" == "1990" {
        local file = "C_A_484_`yr'01_H0_O.txt"
    }
    else if "`yr'" == "2019" {
        local file = "C_A_484_`yr'01_H4_O.txt"
    }
    else {
        local file = "C_A_484_`yr'01_H0_D.txt"
    }

    // Import raw data
    import delimited "`raw_dir'/`file'", clear

    // Keep only Mexican imports: partnercode 156, flow=M
    keep if partnercode == 156 & flowcode == "M"

    // Remove totals and non-six-digit codes
    drop if cmdcode == "TOTAL"
    drop if strlen(cmdcode) < 6

    // Initialize or append to temp dataset
    if "`yr'" == "1990" {
        save temp_mexico, replace
    }
    else {
        append using temp_mexico
        save temp_mexico, replace
    }
}

// Finalize Mexico import file
use temp_mexico, clear
keep period reportercode partnercode cmdcode fobvalue
rename cmdcode hs6
save "mexico_trade.dta", replace


/*--------------------------------------------------------------------------
 SECTION 3: Merge HS6 Trade with NAICS Concordance
  - Ensures each HS6 observation has a valid NAICS3 mapping
 ---------------------------------------------------------------------------*/

use "hs_naics_concordance.dta", clear
merge m:1 hs6 using "mexico_trade.dta"

// Retain only fully matched observations
keep if _merge == 3
drop _merge
save "mexico_temp.dta", replace


/*--------------------------------------------------------------------------
 SECTION 4: Fill Missing NAICS-Year Pairs with Zeros
  - Uses industry master list to identify gaps
  - Expands to create zero-trade records for missing years
 ---------------------------------------------------------------------------*/

import delimited "C:\Users\lcp38\Downloads\Thesis\Data\Catalogs\indivcat\CAT_ACTECONOMICA.csv", clear

// Prepare 3-digit NAICS codes from master list
tostring llave_acteconomica, gen(naics3)
drop llave_exportadora

// Merge trade temp with industry master	t
merge 1:m naics3 using "mexico_temp.dta"
rename _merge _merge_concord
keep naics3 period fobvalue reporter

// Preserve complete matched data
preserve
    // Identify NAICS codes missing in any period
    keep if missing(period)
    keep naics3
    duplicates drop

    // Generate zero-valued rows for all specified years
    gen reportercode = 484
    gen fobvalue     = 0
    expand `=wordcount("`years'")'
    local idx=1
    foreach yr of local years {
        replace period = `yr' if mod(_n, `=wordcount("`years'")') == `idx'
        local ++idx
    }
    tempfile filled_rows
    save `filled_rows', replace
restore

// Append zero-filled records and clean
drop if missing(period)
append using `filled_rows'


/*--------------------------------------------------------------------------
 SECTION 5: Aggregate and Export Final Matched Dataset
  - Sums fobvalue by NAICS3 and year
  - Renames and adjusts period labels
 ---------------------------------------------------------------------------*/

sort naics3 period
collapse (sum) fobvalue, by(naics3 period)
rename naics3 Ind3D

destring Ind3D, replace

// Shift 2019 label to 2020 for pre-COVID series
replace period = 2020 if period == 2019

save "mexico_matched.dta", replace
