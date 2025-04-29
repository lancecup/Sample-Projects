//=========================================================================
// 1. Load the Penn World Table dataset (version 10.01) and clear memory
//=========================================================================
use pwt1001, clear  
//    • `use pwt1001`     : load the PWT 10.01 dataset
//    • `clear`           : drop any data already in memory before loading



//=========================================================================
// 2. Subset to Mexico only
//=========================================================================
keep if country == "Mexico"  
//    • `keep if country=="Mexico"` : retain only rows where the country code equals "Mexico"



//=========================================================================
// 3. Restrict the sample to observations from 1954 onward
//=========================================================================
drop if year < 1954  
//    • `drop if year<1954` : remove all years prior to 1954, since earlier data may be sparse or less comparable



//=========================================================================
// 4. Plot the Total Factor Productivity (TFP) index over time
//=========================================================================
twoway connected rtfpna year, ///  
    ytitle("TFP level at constant national prices (2017 = 1)") ///  // Y-axis label: fixed-price TFP index normalized to 1 in 2017  
    xtitle("Year") ///                                            // X-axis label  
    note("Source: Penn World Tables") ///                         // Footnote with data source  
    xlabel(1954 1960 1970 1980 1990 2000 2010 2019) ///            // Custom tick marks at key census/decade years  
    xscale(range(1954 2019))                                      // Force the X-axis to run from 1954 through 2019



//=========================================================================
// 5. Export the figure as a PDF for inclusion in reports
//=========================================================================
graph export "../Graphs/tfp.pdf", replace  
//    • Saves the current graph to "Graphs/tfp.pdf" (relative path)  
//    • `replace` allows overwriting an existing file of the same name
