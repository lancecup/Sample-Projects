/*==========================================================================
 * Combine and Process China Import Data for Selected Countries
 * Author:         Lance Cu Pangilinan
 * Last modified:  04/17/2025
 *
 * Purpose:
 *   1. Import bilateral trade flows from multiple raw text files.
 *   2. Filter to Mexican imports from China, drop aggregate/invalid codes.
 *   3. Append year-specific files into one dataset.
 *   4. Compute average FOB value across five Census years.
 *   5. Map HS6 codes to NAICS and economic activity categories.
 *   6. Ensure complete panel by filling missing period‐industry combinations.
 *   7. Save final matched dataset "multi_matched.dta".
 *==========================================================================*/

//-------------------------------------------------------------------------
* SECTION 1: Import & Append China–Mexico Import Files
//-------------------------------------------------------------------------

// Start with the first raw text file (Census 2019/01, partner = China (156), imports)
import delimited "C_A_724_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"      // Only China imports
drop if cmdcode == "TOTAL"                       // Remove aggregate TOTAL row
drop if strlen(cmdcode) < 6                      // Drop non-HS6 codes
save combined_china_trade, replace               // Initialize combined dataset

// Loop or repeat for each additional year/file
// For each file: re-import, apply same filters, then append to combined_china_trade

* 2) Italy (380)
*  1990
import delimited "C_A_380_199001_S3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
save combined_china_trade, replace

*  2000
import delimited "C_A_380_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2010
import delimited "C_A_380_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2015
import delimited "C_A_380_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2019
import delimited "C_A_380_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace


* ————————————————————————————————
* 3) Spain (724)
*  1990
import delimited "C_A_724_199001_H0.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2000
import delimited "C_A_724_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2010
import delimited "C_A_724_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2015
import delimited "C_A_724_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2019
import delimited "C_A_724_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace


* ————————————————————————————————
* 4) Ireland (372)
*  1990
import delimited "C_A_372_199001_S3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2000
import delimited "C_A_372_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2010
import delimited "C_A_372_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2015
import delimited "C_A_372_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2019
import delimited "C_A_372_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace


* ————————————————————————————————
* 5) Singapore (702)
*  1990
import delimited "C_A_702_199001_H0.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2000
import delimited "C_A_702_200001_H1.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2010
import delimited "C_A_702_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2015
import delimited "C_A_702_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2019
import delimited "C_A_702_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace


* ————————————————————————————————
* 6) Canada (124)
*  1990
import delimited "C_A_124_199001_H0_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2000
import delimited "C_A_124_200001_H1_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2010
import delimited "C_A_124_201001_H3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2015
import delimited "C_A_124_201501_H4_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2019
import delimited "C_A_124_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace


* ————————————————————————————————
* 7) Country code 586
*  1990
import delimited "C_A_586_199001_S3_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2000
import delimited "C_A_586_200001_S3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2010
import delimited "C_A_586_201001_H3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2015
import delimited "C_A_586_201501_H4.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2019
import delimited "C_A_586_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace


* ————————————————————————————————
* 8) Country code 360
*  1990
import delimited "C_A_360_199001_H0.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2000
import delimited "C_A_360_200001_H1.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2010
import delimited "C_A_360_201001_H3.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2015
import delimited "C_A_360_201501_H4.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

*  2019
import delimited "C_A_360_201901_H5_O.txt", clear
keep if partnercode == 156 & flowcode == "M"
drop if cmdcode == "TOTAL"
drop if strlen(cmdcode) < 6
append using combined_china_trade
save combined_china_trade, replace

//-------------------------------------------------------------------------
* SECTION 2: Compute Average FOB Value Across Census Years
//-------------------------------------------------------------------------

use combined_china_trade, clear
keep period cmdcode fobvalue
rename cmdcode hs6

// Sum FOB values by period and 6-digit HS code
collapse (sum) fobvalue, by(period hs6)

// Average over the five Census years
gen avg_fobvalue = fobvalue / 5

drop fobvalue
save "selected_countries_avg_china_imports.dta", replace


//-------------------------------------------------------------------------
* SECTION 3: Merge with HS → NAICS Concordance
//-------------------------------------------------------------------------

use "selected_countries_avg_china_imports.dta", clear

// Merge average imports with HS-to-NAICS mapping
merge m:1 hs6 using "../hs_naics_concordance.dta", keep(3)
drop _merge
save "multi_temp.dta", replace


//-------------------------------------------------------------------------
* SECTION 4: Merge with Economic Activity Catalog
//-------------------------------------------------------------------------

// Import NAICS→Activity catalog from CSV
import delimited ///
    "C:\Users\lcp38\Downloads\Thesis\Data\Catalogs\indivcat\CAT_ACTECONOMICA.csv", clear

// Convert numeric llave_acteconomica to string for merge
tostring llave_acteconomica, gen(naics3)
drop llave_exportadora

// Merge catalog into trade panel
merge 1:m naics3 using "multi_temp.dta"
rename _merge _merge_concord

// Retain only key variables for final matching
keep naics3 period avg_fobvalue


//-------------------------------------------------------------------------
* SECTION 5: Fill Missing Periods for Each NAICS Industry
//-------------------------------------------------------------------------

preserve

// Identify industries with no observations (missing period)
keep if missing(period)
keep naics3
duplicates drop

// Assign zero imports for missing years
gen avg_fobvalue = 0

// Expand each industry into 5 pseudo-observations
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

// Append the zero-filled observations
append using `filled_rows'

// Clean up duplicates and aggregate again
sort naics3 period
collapse (sum) avg_fobvalue, by(naics3 period)


// Final renaming and adjustments
rename naics3 Ind3D
destring Ind3D, replace
replace period = 2020 if period == 2019

// Save the fully matched NAICS-period import series
save "multi_matched.dta", replace
