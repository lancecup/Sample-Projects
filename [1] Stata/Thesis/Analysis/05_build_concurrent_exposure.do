/*==========================================================================
 * ADH-Style China Shock for Mexico: Concurrent Exposure Shares
 * Author:         Lance Cu Pangilinan
 * Last modified:  05/05/2025
 *
 * Purpose:
 *   - Construct local labor market (LLM) exposure to Chinese imports
 *     using dynamic industry shares and national import growth (FOB).
 *   - Normalize import shocks by 1990 LLM employment base.
 *
 * Inputs:
 *   - datospersonas.dta        (person-level microdata with industry/LLM info)
 *   - mexico_matched.dta       (imports by NAICS 3-digit and year)
 *
 * Output:
 *   - adh_mexico_llm_concurrent_shares.dta  (LLM-level import shock panel)
 *==========================================================================*/

clear all                               // Start fresh
set more off                            // Prevent output pausing

//-------------------------------------------------------------------------
// 0. Define file paths
//-------------------------------------------------------------------------
global constructeddata  "../"           // Path to microdata (employment)
global tradadata        "../"           // Path to trade data

//-------------------------------------------------------------------------
// 1. EMPLOYMENT: dynamic local & national industry shares
//-------------------------------------------------------------------------
use year llm Ind3D weight_in empstat labforce ///
    using "${constructeddata}datospersonas.dta", clear

keep if labforce == 2 & empstat == 1    // Keep only employed working-age adults

// 1a. National employment totals per industry-year (L_ujt)
preserve
collapse (sum) L_ujt = weight_in, by(Ind3D year)
tempfile nat_emp
save `nat_emp'
restore

// 1b. Local employment per LLM × industry × year (L_ijt)
collapse (sum) L_ijt = weight_in, by(llm Ind3D year)

// 1c. Total LLM employment per year (L_it)
bysort llm year: egen L_it = total(L_ijt)

// 1d. Compute industry share: share_{ijt} = L_ijt / L_ujt
merge m:1 Ind3D year using `nat_emp', nogen
gen share = L_ijt / L_ujt
drop L_ujt

tempfile panel_emp
save `panel_emp', replace              // Save dynamic share panel

// 1e. Extract base-year LLM employment totals (1990 only)
preserve
keep if year == 1990
collapse (mean) L_i1990 = L_it, by(llm)
tempfile llm_base1990
save `llm_base1990'
restore

//-------------------------------------------------------------------------
// 2. IMPORTS: compute level change in FOB value (ΔM_ucjt)
//-------------------------------------------------------------------------
use "${tradadata}mexico_matched.dta", clear
rename period year

bysort Ind3D (year): gen dM = fobvalue - fobvalue[_n-1]
replace dM = . if year == 1990         // No change in base year

keep Ind3D year dM
tempfile dimports
save `dimports', replace

//-------------------------------------------------------------------------
// 3. BUILD SHOCK: ∑ [share_{ijt} × (ΔM / L_i1990)]
//-------------------------------------------------------------------------
use `panel_emp', clear

merge m:1 Ind3D year using `dimports', keep(3) nogen   // Add import changes
merge m:1 llm using `llm_base1990', nogen              // Add base employment

gen contrib = share * (dM / L_i1990)   // Industry-level contribution
replace contrib = . if year == 1990    // Set to missing in base year

collapse (sum) ADH_Exposure_level = contrib, by(llm year)
gen ADH_Exposure_kusd = ADH_Exposure_level / 1000     // Convert to thousands USD

//-------------------------------------------------------------------------
// 4. SAVE AND SUMMARIZE
//-------------------------------------------------------------------------
order llm year ADH_Exposure_level ADH_Exposure_kusd

label var ADH_Exposure_level "ADH ΔFOB per worker (USD)"
label var ADH_Exposure_kusd   "ADH ΔFOB per worker (kUSD)"

save "adh_mexico_llm_concurrent_shares.dta", replace

// Quick descriptive stats by year
tabstat ADH_Exposure_kusd, by(year) stat(n mean sd min max)

display "==> Done! File saved as adh_mexico_llm_concurrent_shares.dta"
