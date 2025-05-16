Importing Inequality: China Shock Analysis Pipeline
--------------------------------------------------

This directory contains the full Stata-based pipeline—numbered 00 through 08—that
processes raw census and trade data into final, replicable 2SLS regression results for
the thesis “Importing Inequality? The China Shock and Wage Disparities in Mexico.”

Each script is self-contained and outputs intermediate datasets under `../Datos`.
Together they cover: data ingestion, variable harmonization, trade shock construction,
and baseline estimation.

================================================================================
Contents
--------------------------------------------------------------------------------
00_build_microdata.do           • Merge five INEGI Census/intercensal files
01_recode_person_vars.do        • Harmonize person-level categories (IPUMS style)
02_clean_income_dist.do         • Trim income sample (age 15+, P1/P99)
03_make_residual_wages.do       • Compute log wages, residualize, aggregate to LLM-year
04_construct_mexico_imports.do  • Import & clean Mexico’s UN-Comtrade FOB data
05_build_concurrent_exposure.do • Build ADH-style China-shock exposures for Mexico
06_stack_multicountry_trade.do  • Import & clean comparator countries’ trade data
07_build_lagged_exposure.do     • Construct foreign-export instrument (comparators)
08_run_regressions.do           • Merge all covariates, run OLS & 2SLS regressions

================================================================================
Requirements
--------------------------------------------------------------------------------
• Stata 17 or later (64-bit recommended)
• set maxvar 30000
• UN-Comtrade raw CSVs downloaded to `raw/trade_mex`
• INEGI raw person files (1990, 2000, 2010, 2015 intercensal, 2020) in `raw/census`

================================================================================
Directory Layout
--------------------------------------------------------------------------------
project_root/
│
├─ do/                       ← this folder
│   ├─ 00_build_microdata.do
│   ├─ … 
│   └─ 08_run_regressions.do
│
├─ raw/
│   ├─ census/               ← original INEGI .txt or .dta files
│   ├─ trade_mex/            ← UN-Comtrade exports/imports for Mexico
│   └─ trade_comparators/    ← UN-Comtrade for comparator countries
│
└─ Datos/                    ← created by scripts; holds all intermediate and final data
    ├─ Cleaned_Indiv/        ← merged/harmonized person‐level .dta files
    ├─ Trade/                ← cleaned trade series
    ├─ Aggregates/           ← LLM‐year aggregates, residual wages, convergence metrics
    └─ Logs/                 ← optional .smcl logs per script

================================================================================
Global Macros
--------------------------------------------------------------------------------
Each .do file expects these macros. Adjust as needed, ideally in a `profile.do`:

    global raw              "../raw"
    global constructeddata  "../Datos"

================================================================================
Execution
--------------------------------------------------------------------------------
From within the `do/` folder, run in order:

    do 00_build_microdata.do
    do 01_recode_person_vars.do
    do 02_clean_income_dist.do
    do 03_make_residual_wages.do
    do 04_construct_mexico_imports.do
    do 05_build_concurrent_exposure.do
    do 06_stack_multicountry_trade.do
    do 07_build_lagged_exposure.do
    do 08_run_regressions.do

================================================================================
Output Summary
--------------------------------------------------------------------------------
• Cleaned person data: `Datos/Cleaned_Indiv/merged_indiv.dta`
• Income sample:       `Datos/Cleaned_Indiv/Ingresos_Pob15.dta`
• Residual wages & convergence metrics:
                        `Datos/Aggregates/SalResMTL_*.dta`, `Convergencia_*.dta`
• Mexico trade:        `Datos/Trade/mexico_matched.dta`
• China-shock exposures:
                        `Datos/Cleaned_Indiv/adh_mexico_llm_*.dta`, `indep.dta`
• Foreign-export IV:    `Datos/Trade/comparator_clean.dta`, `foreign_iv.dta`
• Regression results:   `regression.dta`

================================================================================
Troubleshooting
--------------------------------------------------------------------------------
• “file not found”: verify `global raw` path and directory names.
• Memory errors: ensure 64-bit Stata and `set maxvar 30000`.
• Mismatch on merge: inspect merge keys (`llm`, `year`, `Ind3D`) for missing values.

================================================================================
Contact
--------------------------------------------------------------------------------
Lance Cu Pangilinan
Yale University, Economics Department
lance.pangilinan@yale.edu
