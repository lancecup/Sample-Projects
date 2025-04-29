/*==========================================================================
 * ADH-Style China Shock for Mexico
 * Author:         Lance Cu Pangilinan
 * Last modified:  04/17/2025
 *
 * Purpose:
 *   - Calculate local labor market (LLM) exposure to China import shocks
 *     using ADH methodology (log changes, levels, and level changes of FOB).
 *   - Scale shocks by same-year total LLM employment to get per-worker measures.
 *   - Output datasets for various shock definitions.
 * Input:
 *   - Cleaned individual-level microdata: datospersonas.dta
 *   - China imports data: mexico_matched.dta
 * Outputs:
 *   - adh_mexico_llm_allversions_scaled_current.dta
 *   - adh_mexico_llm_delta_level.dta
 *==========================================================================*/

//-------------------------------------------------------------------------
 * Section 0: Initialization
 *   - Clear memory, turn off pagination for uninterrupted execution
//-------------------------------------------------------------------------
clear all
set more off

//-------------------------------------------------------------------------
 * Section 1: Compute 1990 Base Employment Shares by Industry and LLM
 *   - Filter to employed, in-labor-force individuals in 1990
 *   - Aggregate weights to get LLM-industry employment counts
 *   - Compute each industry's share of total LLM employment in 1990
 *   - Save base totals for later scaling
//-------------------------------------------------------------------------
global constructeddata "../"  
use year llm Ind3D weight_in empstat labforce ///
    using "$constructeddata/Cleaned_Indiv/datospersonas.dta", clear

// Keep only 1990 employed individuals aged 15+ in labor force
keep if year == 1990 & labforce == 2 & empstat == 1

// Sum person-weights to get employment by llm × industry
collapse (sum) empllm = weight_in, by(llm Ind3D)

// Compute total employment per LLM and industry share in 1990
bysort llm: egen total_emp_llm = total(empllm)
gen share1990 = empllm / total_emp_llm

// Save LLM total for potential future use
keep llm total_emp_llm
duplicates drop
tempfile emp_base
save `emp_base'

// Recreate full base shares for merging into panel
use year llm Ind3D weight_in empstat labforce ///
    using "$constructeddata/Cleaned_Indiv/datospersonas.dta", clear
keep if year == 1990 & labforce == 2 & empstat == 1
collapse (sum) empllm = weight_in, by(llm Ind3D)
bysort llm: egen total_emp_llm = total(empllm)
gen share1990 = empllm / total_emp_llm
tempfile base_shares
save `base_shares'


//-------------------------------------------------------------------------
 * Section 2: Import Chinese Trade Data and Compute Growth Measures
 *   - Load matched trade panel, compute log-FOB and level changes
 *   - Create dln_fob and dfob for each industry over time
//-------------------------------------------------------------------------
use "mexico_matched.dta", clear
rename period year

// Compute log of FOB value
gen ln_fob = ln(fobvalue)

// Compute first differences in log and level by industry
bysort Ind3D (year): gen dln_fob = ln_fob - ln_fob[_n-1]
bysort Ind3D (year): gen dfob   = fobvalue - fobvalue[_n-1]

// Set base-year differences to missing
replace dln_fob = . if year == 1990
replace dfob   = . if year == 1990

tempfile china_trade
save `china_trade'


//-------------------------------------------------------------------------
 * Section 3: Build Full Panel of LLM × Industry × Year
 *   - Create all combinations of llm, Ind3D, and census years
 *   - Merge in base shares and trade growth data
//-------------------------------------------------------------------------
// IDs for llm × industry
use `base_shares', clear
keep llm Ind3D
duplicates drop
gen dummy = 1
tempfile ids
save `ids'

// Year list
clear
input year
1990
2000
2010
2015
2020
end
gen dummy = 1
tempfile years
save `years'

// Cross-join ids × years
use `ids', clear
joinby dummy using `years'
drop dummy

// Attach base shares
merge m:1 llm Ind3D using `base_shares', nogen

// Attach trade growth measures (keep only matched panel rows)
merge m:1 Ind3D year using `china_trade', keep(3) nogen


//-------------------------------------------------------------------------
 * Section 4: Compute ADH Shock Measures
 *   - Three definitions: log-change, level (FOB), and level-change
 *   - Multiply 1990 share by each growth measure
//-------------------------------------------------------------------------
gen adh_shock_log    = share1990 * dln_fob
gen adh_shock_level  = share1990 * fobvalue
gen adh_shock_dlevel = share1990 * dfob

// Remove base‐year entries
replace adh_shock_log    = . if year == 1990
replace adh_shock_level  = . if year == 1990
replace adh_shock_dlevel = . if year == 1990


//-------------------------------------------------------------------------
 * Section 5: Aggregate to LLM-Year Exposure
 *   - Sum contributions across industries for each llm and year
//-------------------------------------------------------------------------
collapse (sum) ///
    ADH_Exposure_log    = adh_shock_log      ///
    ADH_Exposure_level  = adh_shock_level    ///
    ADH_Exposure_dlevel = adh_shock_dlevel, by(llm year)


//-------------------------------------------------------------------------
 * Section 6: Get Current LLM Employment Totals (All Years)
 *   - Needed to scale shocks per worker
//-------------------------------------------------------------------------
use year llm weight_in empstat labforce ///
    using "$constructeddata/Cleaned_Indiv/datospersonas.dta", clear

// Keep employed, in labor force
keep if labforce == 2 & empstat == 1

// Sum weights by llm × year
collapse (sum) total_emp_llm = weight_in, by(llm year)
tempfile current_emp
save `current_emp'


//-------------------------------------------------------------------------
 * Section 7: Merge Current Employment and Scale Shocks
//-------------------------------------------------------------------------
use "$constructeddata/adh_mexico_llm_allversions.dta", clear
merge m:1 llm year using `current_emp', nogen

// Per-worker exposure measures
gen ADH_Exposure_log_pc    = ADH_Exposure_log    / total_emp_llm
gen ADH_Exposure_level_pc  = ADH_Exposure_level  / total_emp_llm
gen ADH_Exposure_dlevel_pc = ADH_Exposure_dlevel / total_emp_llm

// Save scaled exposure dataset
save "$constructeddata/adh_mexico_llm_allversions_scaled_current.dta", replace

bysort llm year: sum ADH_Exposure_level ADH_Exposure_dlevel


//-------------------------------------------------------------------------
 * Section 8: Alternative ADH Shock – Level-Change per Worker
 *   - Recompute using level changes standardized by current LLM employment
 *   - Output version for delta level shock
//-------------------------------------------------------------------------

// 8.1 Housekeeping and path definitions
clear all
set more off
global constructeddata "../"      // path to datospersonas.dta
global tradadata       "../"      // path to mexico_matched.dta

// 8.2 Employment shares: local (L_ijt), national (L_ujt), and totals (L_it)
use year llm Ind3D weight_in empstat labforce ///
    using "$constructeddata/Cleaned_Indiv/datospersonas.dta", clear
keep if labforce==2 & empstat==1

// National employment by industry and year
preserve
collapse (sum) L_ujt = weight_in, by(Ind3D year)
tempfile nat_emp
save `nat_emp'
restore

// Local employment by llm × industry × year
collapse (sum) L_ijt = weight_in, by(llm Ind3D year)
// Total LLM employment
bysort llm year: egen L_it = total(L_ijt)

// Merge in national totals and compute industry share
merge m:1 Ind3D year using `nat_emp', nogen
gen share_nat = L_ijt / L_ujt
tempfile panel_emp
save `panel_emp'

// 8.3 Imports – level change of FOB value by industry
use "$tradadata/Cleaned_Indiv/mexico_matched.dta", clear
rename period year
bysort Ind3D (year): gen dM = fobvalue - fobvalue[_n-1]
replace dM = . if year == 1990
keep Ind3D year dM
tempfile dimports
save `dimports'

// 8.4 Build shock: share_nat × (ΔM / L_it)
use `panel_emp', clear
merge m:1 Ind3D year using `dimports', keep(3) nogen
gen contrib = share_nat * (dM / L_it)
replace contrib = . if year==1990

// Aggregate to LLM-year and convert to kUSD per worker
collapse (sum) ADH_Exposure_level = contrib, by(llm year)
gen ADH_Exposure_kusd = ADH_Exposure_level / 1000

// 8.5 Finalize dataset
order llm year ADH_Exposure_level ADH_Exposure_kusd
label var ADH_Exposure_level "ADH Chinashock (USD per worker)"
label var ADH_Exposure_kusd   "ADH Chinashock (kUSD per worker)"
save "${constructeddata}/Cleaned_Indiv/adh_mexico_llm_delta_level.dta", replace

// Quick summary statistics by year
tabstat ADH_Exposure_kusd, by(year) stat(n mean sd min max)
