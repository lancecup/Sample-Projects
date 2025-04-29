/**************************************************************************
 * Do-file to construct dependent variables for wage convergence analysis
 * Author:        Lance Cu Pangilinan
 * Last Modified: 04/17/2025
 *
 * Purpose:
 *   1. Estimate residuals of log labor income net of age & education effects
 *   2. Aggregate these residuals at the local labor-market level
 *   3. Construct convergence metrics (P90–P10, P90–P50, etc.)
 *   4. Prepare final dependent-variable datasets by subgroup (all, male, female)
 **************************************************************************/

/*-------------------------------------------------------------------------- 
 SECTION 1: Load and prepare individual‐level microdata 
  - Inputs: datospersonas.dta (demographics, weights, LL M codes)
  - Outputs: researn<year>.dta (residuals by year), residinc.dta (all years)
 ---------------------------------------------------------------------------*/

// Define root directory for constructed data
global constructeddata "../../Datos"

// Load cleaned individual‐level dataset
use "$constructeddata/Cleaned_Indiv/datospersonas.dta", clear

// Retain only variables needed for residual wage estimation
keep year municip_key hhid weight_hh ID_PERSONA person_num weight_in ///
     empstat labforce schoolyrs sex age age2 llm

// Simplify person ID name
rename ID_PERSONA id

// Restrict sample to employed, labor-force participants aged 15+
keep if labforce == 2 & empstat == 1

// Merge in real income and log income from the income file
merge 1:1 year id using "$constructeddata/Cleaned_Indiv/indiv_income", nogen

// Clean sentinel values: mark age 999 as missing
replace age  = .  if age  == 999
replace age2 = .  if age2 == 98      // extended age‐group missing code
replace age2 = 24 if age2 == 25      // collapse 85+ into 80+ group

// Create binary male indicator: 1 = male, 0 = female, missing if unknown
gen male = 1 if sex == 1
replace male = 0 if sex == 2
replace male = . if sex == 9

// Recode years of schooling into four categories, missing if 99
gen educ_categories = 1 if (schoolyrs <= 6  | schoolyrs == 91)
replace educ_categories = 2 if inrange(schoolyrs, 7, 12)
replace educ_categories = 3 if inrange(schoolyrs, 13, 15)
replace educ_categories = 4 if inrange(schoolyrs, 16, 18)
replace educ_categories = . if schoolyrs == 99

// Label the education categories
label var educ_categories "Years of schooling"
label define educ_categories_lbl ///
    1 "At most 6"      ///
    2 "7 to 12"         ///
    3 "13 to 15"        ///
    4 "16 or more"
label values educ_categories educ_categories_lbl


/*-------------------------------------------------------------------------- 
 SECTION 2: Year‐by‐year regression to compute residuals
  - Controls: age groups; and age × education interactions
  - Stores residuals in researn<year>.dta files
 ---------------------------------------------------------------------------*/

local years "1990 2000 2010 2015 2020"

foreach yr of local years {
    preserve
        // Subset to the current year
        keep if year == `yr'
        di as text "Processing year `yr'"

        // Regress log income on age dummies, by gender
        reg loginc i.age2 [fweight = weight_in] if male == 1
        predict resAge_m if e(sample), resid
        reg loginc i.age2 [fweight = weight_in] if male == 0
        predict resAge_f if e(sample), resid

        // Regress log income on age × education interactions, by gender
        reg loginc i.age2##educ_categories [fweight = weight_in] if male == 1
        predict resAgeEduc_m if e(sample), resid
        reg loginc i.age2##educ_categories [fweight = weight_in] if male == 0
        predict resAgeEduc_f if e(sample), resid

        // Combine residuals into unified variables
        gen resinc_age    = resAge_m
        replace resinc_age    = resAge_f    if male == 0
        gen resinc_ageedu = resAgeEduc_m
        replace resinc_ageedu = resAgeEduc_f if male == 0

        // Keep only necessary variables for the year file
        keep year id person_num weight_in municip_key male age2 ///
             schoolyrs realinc loginc resinc_age resinc_ageedu llm

        // Label the new residual variables
        label var resinc_age    "Residual log income (age controlled)"
        label var resinc_ageedu "Residual log income (age & education)"

        // Save the yearly residual file
        save "$constructeddata/Cleaned_Indiv/researn`yr'.dta", replace
    restore
}

/*-------------------------------------------------------------------------- 
 Combine all yearly residual files into one panel dataset
 ---------------------------------------------------------------------------*/

// Initialize with 1990
use "$constructeddata/Cleaned_Indiv/researn1990.dta", clear
erase "$constructeddata/Cleaned_Indiv/researn1990.dta"

// Append subsequent years
foreach yr in 2000 2010 2015 2020 {
    append using "$constructeddata/Cleaned_Indiv/researn`yr'.dta"
    erase "$constructeddata/Cleaned_Indiv/researn`yr'.dta"
}

// Save the combined residuals dataset
save "$constructeddata/Cleaned_Indiv/residinc.dta", replace


/*-------------------------------------------------------------------------- 
 SECTION 3: Aggregate residuals at the local labor-market (LLM) level
  - Compute weighted mean income, employment, and SD of residuals
  - Generate national (N) dataset and commented-out gender breakdown
 ---------------------------------------------------------------------------*/

// Sort to prepare for by-processing
sort year llm

preserve
    // Weighted mean of real income in each LLM/year
    bysort year llm: egen meanw = wtmean(realinc), weight(weight_in)
    gen logmwrinc = ln(meanw)

    // Total employment in each LLM/year
    bysort year llm: egen employment = total(weight_in)
    bysort year llm: egen sum_weight = total(weight_in)

    // For both residual types, compute weighted SD
    foreach var in age ageedu {
        bysort year llm: egen wtm_resinc_`var' = wtmean(resinc_`var'), weight(weight_in)
        gen diff_sq`var'   = (resinc_`var' - wtm_resinc_`var')^2
        gen w_diff_sq`var' = diff_sq`var' * weight_in
        bysort year llm: egen sum_w_diff_sq`var' = total(w_diff_sq`var')
        gen sd_rinc`var' = sqrt(sum_w_diff_sq`var' / sum_weight)
    }

    // Drop duplicate group identifiers
    duplicates drop llm year, force

    // Retain final LLM-level variables
    keep year llm wtm_resinc_age wtm_resinc_ageedu sd_rincage sd_rincageedu ///
         meanw logmwrinc employment weight_in

    // Label for clarity
    label var llm              "Local labor market"
    label var meanw            "Weighted mean real income"
    label var wtm_resinc_age   "Mean residual (age)"
    label var wtm_resinc_ageedu"Mean residual (age & education)"
    label var logmwrinc        "Log(mean real income)"
    label var sd_rincage       "SD residual (age)"
    label var sd_rincageedu    "SD residual (age & education)"
    label var employment       "Employment headcount"

    // Move LLM identifier to front
    order llm, first

    // Save the national-level LLM dataset
    save "$constructeddata/Cleaned_Indiv/llmresid_N.dta", replace
restore

// (Optional gender-specific aggregation code is commented out in the original file)



/*-------------------------------------------------------------------------- 
 SECTION 4: Construct convergence metrics in each LLM
  - For each subgroup (all=N, female=0, male=1):
      • P90, IQR, P50, P10 for each residual and log income
      • Differences: P90–P10, P90–P50, P50–P10
 ---------------------------------------------------------------------------*/

local types "0 1 N"
foreach s of local types {
    use "$constructeddata/Cleaned_Indiv/residinc.dta", clear
    if "`s'" != "N" keep if male == `s'

    // Compute percentile and dispersion measures by LLM & year
    collapse ///
        (p90) resinc_age_p90=resinc_age   resinc_ageedu_p90=resinc_ageedu loginc_p90=loginc  ///
        (iqr) resinc_age_iqr=resinc_age   resinc_ageedu_iqr=resinc_ageedu loginc_iqr=loginc  ///
        (p50) resinc_age_p50=resinc_age   resinc_ageedu_p50=resinc_ageedu loginc_p50=loginc  ///
        (p10) resinc_age_p10=resinc_age   resinc_ageedu_p10=resinc_ageedu loginc_p10=loginc  ///
        (sd)  sd_loginc=loginc [fw=weight_in], by(llm year)

    // Full, upper, and lower tail convergence metrics
    foreach m in "" _50 _10 {
        gen resinc_age_p90`m'    = resinc_age_p90    - resinc_age`m'
        gen resinc_ageedu_p90`m' = resinc_ageedu_p90 - resinc_ageedu`m'
        gen loginc_p90`m'        = loginc_p90        - loginc`m'
    }

    // Label new variables
    label var sd_loginc          "SD of log wages"
    label var resinc_age_p90     "P90 residual (age) – P10"
    label var resinc_ageedu_p90  "P90 residual (age & edu) – P10"
    label var loginc_p90         "P90 log wage – P10"

    // Drop raw percentiles to leave only convergence measures
    drop resinc_age_p90 resinc_ageedu_p90 resinc_age_p50 resinc_ageedu_p50 ///
         resinc_age_p10 resinc_ageedu_p10 loginc_p10 loginc_p50 loginc_p90

    // Save convergence metrics for subgroup `s'
    save "$constructeddata/Cleaned_Indiv/converge_llm_`s'.dta", replace
}

// Merge convergence metrics with LLM residual aggregates and save final depvars
foreach s of local types {
    use "$constructeddata/Cleaned_Indiv/llmresid_`s'.dta", clear
    merge 1:1 llm year using "$constructeddata/Cleaned_Indiv/converge_llm_`s'.dta", nogen
    compress
    save "$constructeddata/Cleaned_Indiv/depvars_`s'.dta", replace
}
