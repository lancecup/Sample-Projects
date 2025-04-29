/*==========================================================================
* Prepare Regression Input: Merge Dependent Vars, Exposures, and Vulnerability
* Author:         Lance Cu Pangilinan
* Last updated:   04/17/2025
*==========================================================================*/

* 1. Set working directory and load dependent variables
cd "/Users/lance/Documents/GitHub/YaleThesis/Datos/Cleaned_Indiv"
use depvars_N, clear                                      // Load panel of outcome measures by LLM and year

* 2. Merge in China‐shock exposures and foreign instrument
merge 1:1 llm year using "indep.dta", nogen               // Bring in ADH exposure and IV variable

* 3. Create a time indicator corresponding to census rounds
gen time = .                                              // Initialize time
replace time = 1 if year == 1990                          // Code 1 = 1990
replace time = 2 if year == 2000                          // Code 2 = 2000
replace time = 3 if year == 2010                          // Code 3 = 2010
replace time = 4 if year == 2015                          // Code 4 = 2015
replace time = 5 if year == 2020                          // Code 5 = 2020
label define year_lbl ///
    1 "1990" 2 "2000" 3 "2010" 4 "2015" 5 "2020"
label values time year_lbl                                // Attach labels to time codes

* 4. Keep only relevant variables and rename exposures for clarity
keep llm time year sd_loginc sd_rincageedu loginc_iqr resinc_ageedu_iqr ///
     foreign_ADH_Exposure ADH_Exposure_kusd
rename ADH_Exposure_kusd local_exp                       // Rename shock per worker
rename foreign_ADH_Exposure for_exp                      // Rename IV variable
order llm time, first                                     // Bring identifiers to front
save "regression.dta", replace                            // Save intermediate regression file

* 5. Load vulnerability (population) data and merge
use "/Users/lance/Documents/GitHub/YaleThesis/Data/PUG_Agregados_Stata/Vulnerabilidad/Vulnerabilidad.dta", clear
rename (MTL Año Num_PobT Num_PobActT) (llm year pop pop_act)   // Standardize names
keep llm year pop pop_act                                  // Keep only key vars
save "vuln.dta", replace                                   // Save vulnerability file

use regression, clear
merge 1:1 llm year using "vuln.dta"                        // Merge population controls

* 6. Declare panel and generate period dummies
xtset llm time                                            // Define panel: cross‐section = LLM, time = census code
tabulate time, generate(time_)                            // Create dummy variables time_1–time_5
drop time_1                                              // Drop base‐period dummy to avoid collinearity

* 7. Run naive OLS and IV regressions
reg sd_loginc local_exp                                   // OLS: inequality vs. local exposure
xtivreg sd_loginc (local_exp = for_exp) i.time, fe         // IV: instrument local_exp with for_exp, include period FEs

* 8. First‐stage: regress local_exp on instrument and controls, predict fitted values
reg local_exp for_exp i.time pop pop_act                  // First‐stage regression
predict clean_local                                       // Save fitted exposure as clean_local

* 9. Second‐stage: regress outcomes on predicted exposure and controls
reg sd_loginc            clean_local time_* pop pop_act   // 2SLS second stage for sd_loginc
reg sd_rincageedu        clean_local time_* pop pop_act   // 2SLS for residual‐inc measure
reg loginc_iqr           clean_local time_* pop pop_act   // 2SLS for IQR of log income
reg resinc_ageedu_iqr    clean_local time_* pop pop_act   // 2SLS for IQR of residual income

* 10. Include lagged exposure effects in regressions
gen Lclean  = L.clean_local       // 1-period lag of predicted exposure
gen L2clean = L2.clean_local      // 2-period lag
gen L3clean = L3.clean_local      // 3-period lag

reg sd_loginc            Lclean L2clean L3clean time_* pop pop_act	 // Significant
reg sd_rincageedu        Lclean L2clean L3clean time_* pop pop_act   // Significant
reg loginc_iqr           Lclean L2clean L3clean time_* pop pop_act   // Significant
reg resinc_ageedu_iqr    Lclean L2clean L3clean time_* pop pop_act   // Significant
