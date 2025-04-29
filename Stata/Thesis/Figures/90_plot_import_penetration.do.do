**************************************************************************
* Step 1: Drop obsolete columns and reduce to a single observation
**************************************************************************

// Remove legacy columns that are no longer needed
drop AD-AY

// Exclude any rows where B is missing
drop if B == .

// Create a temporary identifier for each row
gen obs = _n

// Keep only the first observation (others are duplicates or placeholders)
drop if obs != 1



**************************************************************************
* Step 2: Clean up variable names and apply a "manu_" prefix for clarity
**************************************************************************

// Loop over every variable in the dataset
foreach var of varlist _all {
    // Retrieve the variable's label (descriptive text)
    local newname : variable label `var'
    // Replace spaces in the label with underscores for a valid name
    local cleanname = subinstr("`newname'", " ", "_", .)
    // Rename the variable to have prefix "manu_" + cleaned label
    rename `var' manu_`cleanname'
}



**************************************************************************
* Step 3: Reshape manufacturing GDP data from wide to long format
**************************************************************************

// Convert manufactured GDP columns (manu_@) into a long panel with year index
reshape long manu_@, i(Industry) j(year)

// Rename the placeholder "manu_" variable to GDP for readability
rename manu_ GDP

// Save the cleaned, long-format manufacturing GDP dataset
save mexmanugdp, replace



/*************************************************************************
* Step 4: Import and merge multiple trade data text files into one file 
*************************************************************************/

// Change directory to the folder containing trade data
cd "../Data/Trade"

// Create a list of all .txt files in the directory
local files: dir . files "*.txt"
// Flag to track the first file
local firstfile = 1

// Loop through each file in the folder
foreach file in `files' {
    if `firstfile' == 1 {
        // For the first file: import and save as the base dataset
        import delimited "`file'", clear
        save "merged_trade", replace
        local firstfile = 0
    }
    else {
        // For subsequent files: import and append to the existing dataset
        import delimited "`file'", clear
        append using "merged_trade"
        save "merged_trade", replace
    }
}

// Convert the imported cmdcode (string) into a numeric variable
gen cmdnum = real(cmdcode)

// Retain only rows corresponding to manufacturing-related codes
keep if inrange(cmdnum, 16, 24) | ///
        inrange(cmdnum, 27, 38) | ///
        inrange(cmdnum, 39, 40) | ///
        inrange(cmdnum, 41, 43) | ///
        inrange(cmdnum, 50, 67) | ///
        inrange(cmdnum, 44, 47) | ///
        inrange(cmdnum, 48, 49) | ///
        inrange(cmdnum, 25, 26) | ///
        inrange(cmdnum, 68, 71) | ///
        cmdnum == 72            | ///
        inrange(cmdnum, 7401, 7406) | ///
        inrange(cmdnum, 7501, 7504) | ///
        inrange(cmdnum, 7601, 7603) | ///
        inrange(cmdnum, 7801, 7802) | ///
        inrange(cmdnum, 7901, 7903) | ///
        inrange(cmdnum, 8001, 8002) | ///
        cmdnum == 81            | ///
        cmdnum == 73            | ///
        inrange(cmdnum, 7407, 7419) | ///
        inrange(cmdnum, 7505, 7508) | ///
        inrange(cmdnum, 7604, 7616) | ///
        inrange(cmdnum, 7803, 7806) | ///
        inrange(cmdnum, 7904, 7907) | ///
        inrange(cmdnum, 8003, 8007) | ///
        inrange(cmdnum, 82, 83)       | ///
        cmdnum == 84            | ///
        inrange(cmdnum, 8501, 8507) | ///
        inrange(cmdnum, 8508, 8510) | ///
        inrange(cmdnum, 8511, 8516) | ///
        inrange(cmdnum, 8517, 8548) | ///
        inrange(cmdnum, 32422, 32423) | ///
        inrange(cmdnum, 86, 89)

// Aggregate FOB export values by year and flow code
collapse (sum) fobvalue, by(refyear flowcode)

// Reshape back to wide form: one column per flowcode
reshape wide fobvalue, i(refyear) j(flowcode) string

// Save the merged trade dataset
save tradexm, replace



/*************************************************************************
* Step 5: Normalize the world GDP deflator so that 2018 = 100
*************************************************************************/

// Keep only the United States data (serves as our benchmark)
keep if CountryName == "United States"

// Clean and prefix variable names for the deflator series
foreach var of varlist _all {
    local newname : variable label `var'
    local cleanname = subinstr("`newname'", " ", "_", .)
    rename `var' gdpd_`cleanname'
}

// Reshape deflator data to long format with year index
reshape long gdpd_@, i(gdpd_Country_Code) j(year)

// Compute the average deflator in 2018 as the base (should be 100 ideally)
summarize gdpd_ if year == 2018
scalar base2018 = r(mean)

// Scale all deflator observations so that 2018 = 100
gen gdpd18 = (gdpd_ / base2018) * 100

// Drop the old deflator variables
foreach var of varlist gdpd_* {
    drop `var'
}

// Save the normalized deflator dataset
save deflate, replace



/*************************************************************************
* Step 6: Merge manufacturing GDP, trade data, and apply deflator
*************************************************************************/

// Load manufacturing GDP
use mexmanugdp, clear
rename year refyear

// Merge with trade data by year (no new observations)
merge 1:1 refyear using tradexm, nogen
save yxm, replace

// Load deflator data
use deflate, clear
rename year refyear

// Merge deflator into the combined dataset
merge 1:1 refyear using yxm, nogen

// Remove any years without manufacturing GDP observations
drop if GDP == .

// Deflate export (X) and import (M) values to 2018 prices
gen x18 = fobvalueX * (100 / gdpd18)
gen m18 = fobvalueM * (100 / gdpd18)

// Convert GDP from millions to units consistent with trade data
replace GDP = GDP * 1e6

// Compute absorption (domestic demand met by domestic production)
gen absorb = GDP - (x18 - m18)

// Import share of GDP
gen ior = fobvalueM / GDP

// Import absorption ratio (imports per unit of absorption)
gen absorbratio = fobvalueM / absorb

// Optional: Generate quick diagnostic plots
twoway connected absorbratio refyear
twoway (connected absorb refyear) (connected ior refyear)
twoway connected ior refyear
twoway connected absorb refyear

// Save the main figure data file
save mainfig, replace



/*************************************************************************
* Step 7: Process household income deciles and apply deflators
*************************************************************************/

// Import Mexico deflator series
import delimited "mexdeflate.csv", clear

// Keep only Mexico data
drop if countryname != "Mexico"

// Reshape deflator series to long format by year
reshape long yr, i(countryname) j(year)
rename yr deflator

// Save intermediate deflator file
save mexdeflate, replace

// Merge deflator with income-decile data by year
merge 1:1 year using mexdeflate, nogen
// Drop years without decile data
drop if decile1 == .

// Deflate each income decile to 2018 prices
forvalues i = 1/10 {
    gen decile`i'_18 = (decile`i' / deflator) * 100
}

// Calculate key inequality measures
gen seventhree   = decile7_18 - decile3_18       // P75 – P25 gap
gen interdecile  = decile9_18 - decile1_18       // P90 – P10 gap
gen log73        = ln(decile7_18) - ln(decile3_18) // Log gap P75/P25

// Plot inequality measures over time
twoway connected seventhree year
twoway connected interdecile year
twoway connected log73 year

// Save household income series
save hhincs, replace



/*************************************************************************
* Step 8: Final merge and generate the main combined figure
*************************************************************************/

// Load the main figure data
use mainfig, clear
rename refyear year

// Merge with household income measures
merge 1:1 year using hhincs, nogen

// Exclude the most recent year if incomplete
drop if year == 2022

// Produce combined plot: import absorption ratio on left axis,
// log income gap on right axis, with customized titles and legend
twoway ///
    (line absorbratio year, yaxis(1)) ///
    (line log73       year, yaxis(2)), ///
    ytitle("Import Absorption Ratio", axis(1)) ///
    ytitle("Relative Income Gap (Log P75–P25)", axis(2)) ///
    xtitle("Year") ///
    legend(order(1 "Mfg. Imports / Domestic Demand" ///
                 2 "Log Income Gap (D7–D3)") ///
           size(small) ///
           ring(0)   bplace(ne)   cols(1) ///
           region(lstyle(solid))) ///
    xlabel(1994(2)2019) ///
    note("Source: Household income data from CEDLAS & World Bank (SEDLAC); " ///
         "Trade & macro data from INEGI, BEA, UN Comtrade.")

// Export the final figure as a PDF
graph export "../../Graphs/importabsorb_present.pdf", as(pdf) replace
