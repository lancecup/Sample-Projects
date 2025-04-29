//--------------------------------------------
// 1. Load the WGI dataset and filter to Mexico
//--------------------------------------------
use wgidataset, clear           // Load the Worldwide Governance Indicators dataset into memory, replacing any existing data
keep if countryname == "Mexico" // Retain only observations where countryname equals "Mexico"

//--------------------------------------------
// 2. Sort data by indicator and year
//--------------------------------------------
sort indicator year             // Order the data by 'indicator' and then by 'year' to prepare for encoding and plotting

//--------------------------------------------
// 3. Encode the 'indicator' string variable to numeric
//--------------------------------------------
encode indicator, gen(indicator_num) // Convert the string variable 'indicator' into a numeric code 'indicator_num'

//--------------------------------------------
// 4. Define custom value labels for each governance indicator
//--------------------------------------------
label define indicator_lbl /// 
    6 "Voice and Accountability" ///
    3 "Political Stability and Absence of Violence / Terrorism" ///
    2 "Government Efficiency" ///
    5 "Regulatory Quality" ///
    4 "Rule of Law" ///
    1 "Control of Corruption"

label values indicator_num indicator_lbl // Attach the label set 'indicator_lbl' to 'indicator_num'

//--------------------------------------------
// 5. Plot percentile ranks over time for each indicator
//--------------------------------------------
twoway ///
    (connected pctrank year if indicator_num == 1, lcolor(eltblue)) ///  // Control of Corruption
    (connected pctrank year if indicator_num == 2, lcolor(cranberry)) /// // Government Efficiency
    (connected pctrank year if indicator_num == 3, lcolor(dkgreen)) ///   // Political Stability and Absence of Violence / Terrorism
    (connected pctrank year if indicator_num == 4, lcolor(gold)) ///      // Regulatory Quality
    (connected pctrank year if indicator_num == 5, lcolor(purple)) ///    // Rule of Law
    (connected pctrank year if indicator_num == 6, lcolor(dkorange)), /// // Voice and Accountability
    ytitle("Mexico's Percentile Rank") ///    // Label for the Y-axis
    xtitle("Year") ///                        // Label for the X-axis
    xlabel(1996 2000 2010 2020 2023) ///       // Custom tick marks for key years
    note("Source: World Bank's Worldwide Governance Indicators") /// // Source attribution
    legend(order(1 "Control of Corruption" ///
                 2 "Government Efficiency" ///
                 3 "Political Stability and Absence of Violence / Terrorism" ///
                 4 "Regulatory Quality" ///
                 5 "Rule of Law" ///
                 6 "Voice and Accountability") /// // Define legend entries in matching order
           pos(6) col(2) rowgap(1))               // Position and formatting of the legend

//--------------------------------------------
// 6. Export the graph to a PDF file
//--------------------------------------------
graph export "../Graphs/connected_wgi.pdf", replace // Save the plotted graph to the specified path, overwriting any existing file
