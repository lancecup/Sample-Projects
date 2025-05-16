README – Figure-generation Scripts
==================================

This repository contains four self-contained Stata *.do* files that
reproduce every figure appearing in the draft **“Importing Inequality?
The China Shock and Wage Disparities in Mexico”** (April 2025).

┌── Numbered Workflow ───────────────────────────────────────────────┐
│ 90_plot_informality_kdensity.do     → Figure 2                    
│ 91_plot_mexico_governance.do        → Figure 3                    
│ 92_plot_tfp_trend.do                → Figure 4                    
│ 93_plot_import_penetration.do       → Figure 1                    
└────────────────────────────────────────────────────────────────────┘

---------------------------------------------------------------------
1. Prerequisites
---------------------------------------------------------------------
* **Stata 17** (or later), with `graph export` capability.
* Cleaned/constructed data from the “00–05” pipeline:
  
      ../Datos/
      ├─ Cleaned_Indiv/           (person-level panel)
      ├─ Aggregates/              (LLM-level aggregates)
      └─ Trade/                   (bilateral trade values, deflators)

* Required global macros (edit if your folder names differ):

      global constructeddata   "../Datos"
      global figout            "../figures"

---------------------------------------------------------------------
2. Running the Scripts
---------------------------------------------------------------------
From Stata’s command line or a master do-file:

    do 93_plot_import_penetration.do
    do 90_plot_informality_kdensity.do
    do 91_plot_mexico_governance.do
    do 92_plot_tfp_trend.do

(These scripts are independent; execution order does not matter.)

---------------------------------------------------------------------
3. What Each Script Does
---------------------------------------------------------------------

• **93_plot_import_penetration.do**  
  *Input:* `Trade/un_comtrade_mexico_manu.dta`, GDP deflators  
  *Output:* `figures/fig01_import_penetration.pdf`  
  Constructs a deflated manufacturing import series, computes the
  absorption ratio, and generates the connected-line plot used in Figure 1.

• **90_plot_informality_kdensity.do**  
  *Input:* `Aggregates/Informalidad.dta`  
  *Output:* `figures/fig02_informality_kdensity.pdf`  
  Plots kernel densities of local-labor-market informality rates for
  the years 2000, 2010, and 2020.

• **91_plot_mexico_governance.do**  
  *Input:* `Aggregates/DemograficosLogs.dta` or commuting matrix  
  *Output:* `figures/fig03_governance_wgi.pdf`  
  Displays Mexico’s WGI (Worldwide Governance Indicators) trends from
  1996 to 2023.

• **92_plot_tfp_trend.do**  
  *Input:* `Trade/pwt_mexico_tfp.dta`  
  *Output:* `figures/fig04_tfp_trend.pdf`  
  Plots Mexico’s TFP at 2017 PPPs for the period 1954–2019.

---------------------------------------------------------------------
4. Troubleshooting
---------------------------------------------------------------------
* “file ___ not found” → check or update the `constructeddata` global.
* “reshape long … ambiguous” → clear the Stata workspace before running.
* On Windows, non-Latin labels may corrupt filenames. Try PNG export
  if PDF output fails.

---------------------------------------------------------------------
5. Reuse
---------------------------------------------------------------------
You may adapt these scripts for other countries or time periods.
Please cite the thesis draft if you reuse the figures in publications.

---------------------------------------------------------------------
Contact
---------------------------------------------------------------------
Lance Cu Pangilinan  
lance.pangilinan@yale.edu
