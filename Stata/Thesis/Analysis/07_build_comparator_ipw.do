/*==========================================================================
* ADH-Style China Shock with Lagged Employment Shares
* Author:         Lance Cu Pangilinan
* Last updated:   04/17/2025
*
* Purpose:
*   - Compute local labor-market (LLM) exposure to China import shocks 
*     using lagged employment shares (ADH methodology).
*   - Generate per-worker shock measures in both USD and kUSD.
*   - Exclude base year and specified LLMs, then save final "indep.dta".
*==========================================================================*/

//-------------------------------------------------------------------------
* 0.  Housekeeping
*    - Clear memory, disable pagination
*    - Define global paths to input microdata and trade data
//-------------------------------------------------------------------------
clear all
set more off

* Path to cleaned individual‐level microdata (datospersonas.dta)
global constructeddata  "../"

* Path to matched China‐Mexico trade data (multi_matched.dta)
global tradadata       "../"


//-------------------------------------------------------------------------
* 1.  Employment Setup
*    - Load person‐weights for employed, in‐labor‐force individuals
*    - Compute national (L_ujt) and local (L_ijt) employment by industry
*    - Derive total LLM employment (L_it) and industry share_nat
*    - Shift all employment measures forward one period to create lagged shares
//-------------------------------------------------------------------------
use year llm Ind3D weight_in empstat labforce ///
    using "$constructeddata/Cleaned_Indiv/datospersonas.dta", clear

* Keep only employed individuals aged 15+ (labforce==2 & empstat==1)
keep if labforce == 2 & empstat == 1

* 1a. National employment by industry × year (L_ujt)
preserve
collapse (sum) L_ujt = weight_in, by(Ind3D year)
tempfile nat_emp
save `nat_emp'
restore

* 1b. Local employment by LLM × industry × year (L_ijt) and total by LLM-year (L_it)
collapse (sum) L_ijt = weight_in, by(llm Ind3D year)
bysort llm year: egen L_it = total(L_ijt)

* 1c. Merge national totals and compute industry share of national employment
merge m:1 Ind3D year using `nat_emp', nogen
gen share_nat = L_ijt / L_ujt

* 1d. Create lagged employment variables by shifting one period forward
gen year_lagged = .
replace year_lagged = 2000 if year == 1990
replace year_lagged = 2010 if year == 2000
replace year_lagged = 2015 if year == 2010
replace year_lagged = 2020 if year == 2015
drop if missing(year_lagged)   // drop original base-year rows

* Rename variables to indicate lagged reference
rename (L_ijt L_it share_nat) (L_ijt_lag L_it_lag share_nat_lag)

* Prepare for merge by resetting `year' to the lagged period
keep llm Ind3D year_lagged L_ijt_lag L_it_lag share_nat_lag
rename year_lagged year
tempfile emp_lagged
save `emp_lagged'


//-------------------------------------------------------------------------
* 2.  Import Change Computation
*    - Load average FOB values by industry from multi_matched.dta
*    - Compute first‐difference in average FOB (dM) by industry
//-------------------------------------------------------------------------
use "$tradadata/Cleaned_Indiv/other/multi_matched.dta", clear
rename period year

* Calculate change in FOB imports: ΔM_jt = avg_fobvalue_t − avg_fobvalue_{t−1}
bysort Ind3D (year): gen dM = avg_fobvalue - avg_fobvalue[_n-1]
replace dM = . if year == 1990    // Base-year differences undefined

keep Ind3D year dM
tempfile dimports
save `dimports'


//-------------------------------------------------------------------------
* 3.  Build ADH Shock Using Lagged Employment Shares
*    - Merge ΔM with lagged employment shares
*    - Compute contribution: share_nat_lag × (dM / L_it_lag)
*    - Sum contributions to get LLM×year‐level shock
*    - Scale to kUSD per worker
//-------------------------------------------------------------------------
use `dimports', clear
merge 1:m Ind3D year using `emp_lagged', keep(3) nogen

* Calculate industry‐specific contribution to LLM shock
gen contrib = share_nat_lag * (dM / L_it_lag)
replace contrib = . if year == 1990   // No shock in base year

* Aggregate to LLM × year
collapse (sum) ADH_Exposure_level = contrib, by(llm year)

* Convert from USD to thousands of USD per worker
gen ADH_Exposure_kusd = ADH_Exposure_level / 1000

* Label and order output variables for clarity
order llm year ADH_Exposure_level ADH_Exposure_kusd
label var ADH_Exposure_level "ADH Chinashock (USD per worker, lagged employment)"
label var ADH_Exposure_kusd   "ADH Chinashock (kUSD per worker, lagged employment)"

* Save the shock dataset
save "${constructeddata}/Cleaned_Indiv/adh_mexico_llm_discrete_lagged.dta", replace

* Provide summary statistics by year
tabstat ADH_Exposure_kusd, by(year) stat(n mean sd min max)


//-------------------------------------------------------------------------
* 4.  Post-Processing & Final Merges
*    - Rename shock variable for downstream regression use
*    - Merge with level‐change shock dataset
*    - Exclude base year and specific LLMs, then save final indep.dta
//-------------------------------------------------------------------------
rename ADH_Exposure_kusd foreign_ADH_Exposure
drop ADH_Exposure_level
save "${constructeddata}/Cleaned_Indiv/adh_mexico_llm_discrete_lagged.dta", replace

* Merge in delta‐level shock version for comparison
merge 1:1 llm year using "${constructeddata}/Cleaned_Indiv/adh_mexico_llm_delta_level.dta"

* Drop base-year observations and LLMs with insufficient data
drop if year == 1990
drop if llm == 603 | llm == 688 | llm == 747

* Clean up merge indicator and redundant variables
drop _merge
drop ADH_Exposure_level

* Save the final independent dataset for analysis
save "indep.dta", replace
