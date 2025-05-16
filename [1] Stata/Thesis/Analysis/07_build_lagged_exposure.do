/*==========================================================================
 * ADH-Style China Shock (Lagged Employment Shares)
 * Author:         Lance Cu Pangilinan
 * Last updated:   05/05/2025
 *
 * Purpose:
 *   - Construct local labor market (LLM) exposure to Chinese imports
 *     using *lagged* employment shares (e.g., 1990 shares applied to 2000 shocks).
 *
 * Inputs:
 *   - datospersonas.dta       (individual-level microdata with industry and LLM)
 *   - multi_matched.dta       (industry-level average imports across countries)
 *   - adh_mexico_llm_concurrent_shares.dta (for later merging)
 *
 * Output:
 *   - adh_mexico_llm_discrete_lagged.dta
 *   - indep.dta (cleaned final exposure file for use in regressions)
 *==========================================================================*/

clear all
set more off

//-------------------------------------------------------------------------
// 0. Define paths (update as needed)
//-------------------------------------------------------------------------
global constructeddata  "../"          // Path to employment microdata
global tradadata        "../"          // Path to trade data

//-------------------------------------------------------------------------
// 1. EMPLOYMENT SETUP: calculate shares from lagged year
//-------------------------------------------------------------------------
use year llm Ind3D weight_in empstat labforce ///
    using "${constructeddata}datospersonas.dta", clear

keep if labforce == 2 & empstat == 1   // Restrict to employed adults

* 1a. National employment by industry and year
preserve
collapse (sum) L_ujt = weight_in, by(Ind3D year)
tempfile nat_emp
save `nat_emp'
restore

* 1b. Local employment by LLM × industry × year
collapse (sum) L_ijt = weight_in, by(llm Ind3D year)
bysort llm year: egen L_it = total(L_ijt)

* 1c. Merge national totals and compute employment share
merge m:1 Ind3D year using `nat_emp', nogen
gen share_nat = L_ijt / L_ujt

* 1d. Shift employment *forward* to apply to next period's trade shock
gen year_lagged = .
replace year_lagged = 2000 if year == 1990
replace year_lagged = 2010 if year == 2000
replace year_lagged = 2015 if year == 2010
replace year_lagged = 2020 if year == 2015
drop if missing(year_lagged)

* 1e. Rename variables to mark them as lagged
rename (L_ijt L_it share_nat) (L_ijt_lag L_it_lag share_nat_lag)

keep llm Ind3D year_lagged L_ijt_lag L_it_lag share_nat_lag
rename year_lagged year                  // Align with trade shock years
tempfile emp_lagged
save `emp_lagged'

//-------------------------------------------------------------------------
// 2. IMPORT CHANGE: compute ∆M by industry and year
//-------------------------------------------------------------------------
use "${tradadata}multi_matched.dta", clear
rename period year

bysort Ind3D (year): gen dM = avg_fobvalue - avg_fobvalue[_n-1]
replace dM = . if year == 1990          // No change in base year

keep Ind3D year dM
tempfile dimports
save `dimports'

//-------------------------------------------------------------------------
// 3. BUILD THE LAGGED ADH SHOCK: ∑ share_{ijt−1} × (∆M / L_it−1)
//-------------------------------------------------------------------------
use `dimports', clear
merge 1:m Ind3D year using `emp_lagged', keep(3) nogen

gen contrib = share_nat_lag * (dM / L_it_lag)
replace contrib = . if year == 1990     // Drop base year

collapse (sum) ADH_Exposure_level = contrib, by(llm year)
gen ADH_Exposure_kusd = ADH_Exposure_level / 1000   // In thousands USD

* Label and organize
order llm year ADH_Exposure_level ADH_Exposure_kusd
label var ADH_Exposure_level "ADH Chinashock (USD per worker, lagged employment)"
label var ADH_Exposure_kusd   "ADH Chinashock (kUSD per worker, lagged employment)"

save "adh_mexico_llm_discrete_lagged.dta", replace

* Quick summary
tabstat ADH_Exposure_kusd, by(year) stat(n mean sd min max)

//-------------------------------------------------------------------------
// 4. CLEAN AND MERGE with concurrent shock
//-------------------------------------------------------------------------
rename ADH_Exposure_kusd foreign_ADH_Exposure
drop ADH_Exposure_level

save "adh_mexico_llm_discrete_lagged.dta", replace

merge 1:1 llm year using "adh_mexico_llm_concurrent_shares.dta"

drop if year == 1990                    // Base year not used in regressions

* Drop outlier LLMs if needed
drop if llm == 603 | llm == 688 | llm == 747
drop _merge
drop ADH_Exposure_level

save "indep.dta", replace              // Final cleaned dataset
