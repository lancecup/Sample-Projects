/*==========================================================================
 * Regression Analysis: China Shock Effects on Local Income Dispersion
 * Author:         Lance Cu Pangilinan
 * Last updated:   05/05/2025
 *
 * Purpose:
 *   - Merge regression controls with ADH-style exposure data
 *   - First-difference log income dispersion metrics
 *   - Estimate OLS and 2SLS models using both static and dynamic strategies
 *   - Visualize predicted import exposure (IPW)
 *
 * Input:
 *   - indep.dta         (exposure + income metrics)
 *   - vulnerability.dta (LLM-level population data)
 *   - flfp.dta          (female labor force participation)
 *   - manu1990.dta      (baseline manufacturing share)
 *
 * Output:
 *   - regression.dta    (full regression panel)
 *   - ipwkdens.pdf      (density plot)
 *==========================================================================*/

cd "/Users/lance/Documents/GitHub/YaleThesis/Datos/Cleaned_Indiv"

use depvars_N, clear
merge 1:1 llm year using "indep.dta"

* Create discrete time variable for panel setup
gen time = .
replace time = 1 if year == 1990
replace time = 2 if year == 2000
replace time = 3 if year == 2010
replace time = 4 if year == 2015
replace time = 5 if year == 2020

label define year_lbl 1 "1990" 2 "2000" 3 "2010" 4 "2015" 5 "2020"
label values time year_lbl

* Drop unused inequality metrics
drop wtm_resinc_age wtm_resinc_ageedu sd_rincage sd_rincageedu ///
     resinc_age_p90_10 resinc_ageedu_p90_10 resinc_age_p90_50 ///
     resinc_ageedu_p90_50 resinc_age_p50_10 resinc_ageedu_p50_10 ///
     resinc_age_iqr resinc_ageedu_iqr

* Declare panel structure
xtset llm time

* First-differences of outcome variables
gen d_sd_loginc      = D.sd_loginc
gen d_loginc_iqr     = D.loginc_iqr
gen d_loginc_p90_p10 = D.loginc_p90_10
gen d_loginc_p50_p10 = D.loginc_p50_p10
gen d_loginc_p90_p50 = D.loginc_p90_50

* Drop first time period (missing diffs)
drop if missing(d_sd_loginc)
drop _merge

* Rename exposure variables
rename ADH_Exposure_kusd      local_exp
rename foreign_ADH_Exposure   for_exp

order llm time, first
save "regression.dta", replace

//-------------------------------------------------------------------------
// 1. Add controls: population, FLFP, and manufacturing base
//-------------------------------------------------------------------------
use "/Users/lance/.../Vulnerabilidad.dta", clear
rename (MTL Año Num_PobT Num_PobActT) (llm year pop pop_act)
keep llm year pop
save "vuln.dta", replace

use "/Users/lance/.../Demograficos_Nivel.dta", clear
rename (MTL Año ActivoF_EdadTrabajoF) (llm year flfp)
keep llm year flfp
save "flfp.dta", replace

* Compute manufacturing employment share in 1990
use "/Users/lance/.../LongBartikNacional.dta", clear
rename EmpleoTot_MTL totalemp
keep MTL Año totalemp
merge 1:1 MTL Año using ".../LongBartikNacional_Manuf.dta", keepusing(EmpleoTot_MTL)
replace EmpleoTot_MTL = 0 if EmpleoTot_MTL == .

by MTL: gen manu1990 = EmpleoTot_MTL / totalemp if Año == 1990
bysort MTL (Año): gen manu1990_fill = .
bysort MTL (Año): replace manu1990_fill = manu1990[1] if Año == 1990
bysort MTL (Año): replace manu1990_fill = manu1990_fill[_n-1] if missing(manu1990_fill)
replace manu1990 = manu1990_fill if missing(manu1990)
drop manu1990_fill _merge EmpleoTot_MTL
rename (MTL Año) (llm year)
save "manu1990.dta", replace

//-------------------------------------------------------------------------
// 2. Merge all control variables to regression panel
//-------------------------------------------------------------------------
use "regression.dta", clear
merge 1:1 llm year using "vuln.dta", nogen
merge 1:1 llm year using "flfp.dta", nogen
merge 1:1 llm year using "manu1990.dta", nogen

drop if time == .
xtset llm time

* Create time dummies
tabulate time, generate(time_)
drop time_1

//-------------------------------------------------------------------------
// 3. Run regressions
//-------------------------------------------------------------------------

* --- OLS Baseline Models ---
ivreg2 d_sd_loginc local_exp, cluster(llm)
ivreg2 d_sd_loginc local_exp pop totalemp flfp manu1990, cluster(llm)
ivreg2 d_sd_loginc local_exp time_*, cluster(llm)
ivreg2 d_sd_loginc local_exp time_* pop totalemp flfp manu1990, cluster(llm)

* --- 2SLS using lagged foreign exposure as instrument ---
ivreg2 d_sd_loginc (local_exp = for_exp) time_*, first cluster(llm)
ivreg2 d_sd_loginc (local_exp = for_exp) time_* pop totalemp flfp manu1990, first cluster(llm)

* --- Alternative inequality outcomes ---
ivreg2 d_loginc_iqr     (local_exp = for_exp) time_* pop totalemp flfp manu1990, first cluster(llm)
ivreg2 d_loginc_p90_p10 (local_exp = for_exp) time_* pop totalemp flfp manu1990, first cluster(llm)
ivreg2 d_loginc_p50_p10 (local_exp = for_exp) time_* pop totalemp flfp manu1990, first cluster(llm)
ivreg2 d_loginc_p90_p50 (local_exp = for_exp) time_* pop totalemp flfp manu1990, first cluster(llm)


//-------------------------------------------------------------------------
// 4. Dynamics: Predict fitted values and plot exposure density
//-------------------------------------------------------------------------
reg local_exp for_exp time_* pop totalemp flfp manu1990, vce(cluster llm)
predict ipw

scatter ipw sd_loginc

* Kernel Density of Fitted IPW
kdensity ipw, ///
    kernel(epanechnikov) ///
    bwidth(0.3051) ///
    n(200) ///
    lwidth(medium) ///
    lcolor(navy) ///
    title("Kernel Density of Predicted Import Exposure") ///
    subtitle("LLMs, 1990–2020") ///
    xtitle("Fitted ΔIPW") ///
    ytitle("Density") ///
    xlabel(0(2)20) ///
    ylabel(0(.05).30) ///
    legend(off)

graph export "ipwkdens.pdf", replace

scatter ipw d_loginc_p50_p10

//-------------------------------------------------------------------------
// 5. Manual 2SLS: Short, Medium, Long-Term Effects
//-------------------------------------------------------------------------
gen ipw1 = L.local_exp
gen ipw2 = L2.local_exp
gen ipw3 = L3.local_exp

gen z1 = L.for_exp
gen z2 = L2.for_exp
gen z3 = L3.for_exp

ivregress 2sls d_sd_loginc (ipw1     = z1),     pop totalemp flfp manu1990, vce(cluster llm) first
ivregress 2sls d_sd_loginc (ipw1 ipw2 = z1 z2), pop totalemp flfp manu1990, vce(cluster llm) first
ivregress 2sls d_sd_loginc (ipw1 ipw2 ipw3 = z1 z2 z3), ///
    pop totalemp flfp manu1990, vce(cluster llm) first

ivregress 2sls d_loginc_iqr (ipw1 ipw2 ipw3 = z1 z2 z3), ///
    pop totalemp flfp manu1990, vce(cluster llm) first
