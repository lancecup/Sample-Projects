README – Figure-generation scripts
==================================

This repository contains four self-contained Stata *.do* files that
reproduce every figure that appears in the draft **“Importing Inequality?
The China Shock and Wage Disparities in Mexico”** (April 2025).

┌── numbered workflow ───────────────────────────────────────────────┐
│ 90_plot_informality_kdensity.do     → thesis Figure 2             
│ 91_plot_llm_connectivity.do         → thesis Figure ? (commuting)
│ 92_plot_tfp_trend.do                → thesis Figure 4              	     
│ 93_plot_import_penetration.do       → thesis Figure 1 (left panel) 
└────────────────────────────────────────────────────────────────────┘

---------------------------------------------------------------------
1. Prerequisites
---------------------------------------------------------------------
* **Stata 17** (or later) with `graph export` support.
* The cleaned / constructed data written by the “00–05” pipeline:
      ../Datos/
          ├─ Cleaned_Indiv/           (person-level panel)
          ├─ Aggregates/              (LLM-level aggregates)
          └─ Trade/                   (bilateral trade values, deflators)
* Global macros used by the figure scripts  
  (change them if your folder names differ):
      global constructeddata   "../Datos"
      global figout            "../figures"

---------------------------------------------------------------------
2. Running the scripts
---------------------------------------------------------------------
From Stata’s command line or a master file:

    do 90_plot_import_penetration.do
    do 91_plot_informality_kdensity.do
    do 92_plot_llm_connectivity.do
    do 93_plot_tfp_trend.do

(They are independent; execution order does not matter.)

---------------------------------------------------------------------
3. What each script does
---------------------------------------------------------------------
• **90_plot_import_penetration.do**  
  *Input:* `Trade/un_comtrade_mexico_manu.dta` + GDP deflators  
  *Output:* `figs/fig01_import_penetration.pdf`  
  Builds the deflated manufacturing-import series, computes the
  absorption ratio, and draws the connected-line plot used in Figure 1.

• **91_plot_informality_kdensity.do**  
  *Input:* `Aggregates/Informalidad.dta`  
  *Output:* `figs/fig02_informality_kdensity.pdf`  
  Draws a kernel-density of local-labor-market informality rates for
  2000, 2010, 2020.

• **92_plot_llm_connectivity.do**  
  *Input:* `Aggregates/DemograficosLogs.dta` (or the commuting-matrix)  
  *Output:* `figs/fig_conn_llm_map.pdf`  
  Maps the 777 commuting zones and annotates their employment sizes /
  connectivity diagnostics.

• **93_plot_tfp_trend.do**  
  *Input:* `Trade/pwt_mexico_tfp.dta`  
  *Output:* `figs/fig04_tfp_trend.pdf`  
  Plots Mexico’s TFP at 2017 PPPs, 1954-2019.

---------------------------------------------------------------------
4. Troubleshooting
---------------------------------------------------------------------
* “file ___ not found” → adjust `global constructeddata`.
* “reshape long … ambiguous” → clear the workspace before running.
* Non-Latin labels may corrupt file names on Windows; switch to PNG
  export if PDF fails.

---------------------------------------------------------------------
5. Reuse
---------------------------------------------------------------------
Feel free to adapt the scripts for other countries or time periods.
Please cite the thesis draft if you reproduce the figures elsewhere.

---------------------------------------------------------------------
Contact
---------------------------------------------------------------------
Lance Cu Pangilinan  
lance.pangilinan@yale.edu
