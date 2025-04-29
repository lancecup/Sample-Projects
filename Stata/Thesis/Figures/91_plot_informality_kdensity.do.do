//=============================================================================
// 1. Set working directory and load the Informalidad dataset
//    - The CD command points to the folder containing the Stata file.
//    - `use …, clear' replaces any data in memory with this dataset.
//=============================================================================
cd "/Users/lance/Library/Mobile Documents/com~apple~CloudDocs/Thesis/Data/PUG_Agregados_Stata/Informalidad"
use Informalidad, clear


//=============================================================================
// 2. Kernel density of overall informality rate for three census years
//    - `kdensity Informalidad_TasaT if Año == XXXX': estimate density for each year.
//    - Line options specify color, width, and pattern for visual distinction.
//    - Legend is ordered and positioned to label "2000", "2010", and "2020".
//    - Axis titles and source note improve readability and attribution.
//=============================================================================
twoway ///
    (kdensity Informalidad_TasaT if Año == 2000, lcolor(blue)        lwidth(medthin) lpattern(solid))   ///
    (kdensity Informalidad_TasaT if Año == 2010, lcolor(red)         lwidth(medthin) lpattern(dash))    ///
    (kdensity Informalidad_TasaT if Año == 2020, lcolor(green)       lwidth(medthin) lpattern(longdash)),///
    legend(order(1 "2000" 2 "2010" 3 "2020") pos(4) ring(0) col(1))    ///
    xtitle("Informality Rate")                                         ///
    ytitle("Density")                                                 ///
    note("Source: INEGI's Census of Population and Housing 2000, 2010, 2020")

// Export the plot as a PDF into the project's Graphs folder
graph export "../../../Graphs/kdensity_informal.pdf", replace


//=============================================================================
// 3. Kernel density by gender and year in a single combined plot
//    - Overlay male (M) and female (F) densities for 2000, 2010, and 2020.
//    - Six `kdensity' calls: three for Informalidad_TasaM, three for Informalidad_TasaF.
//    - Custom line colors, widths, and patterns differentiate series.
//    - Legend entries labeled "M 2000", "F 2020", etc., and positioned optimally.
//=============================================================================
twoway ///
    (kdensity Informalidad_TasaM if Año == 2000, lcolor(navy)       lwidth(medium) lpattern(solid))   ///
    (kdensity Informalidad_TasaM if Año == 2010, lcolor(maroon)      lwidth(medium) lpattern(dash))    ///
    (kdensity Informalidad_TasaM if Año == 2020, lcolor(forest_green)lwidth(medium) lpattern(longdash)) ///
    (kdensity Informalidad_TasaF if Año == 2000, lcolor(purple)      lwidth(medium) lpattern(solid))   ///
    (kdensity Informalidad_TasaF if Año == 2010, lcolor(teal)        lwidth(medium) lpattern(dash))    ///
    (kdensity Informalidad_TasaF if Año == 2020, lcolor(brown)       lwidth(medium) lpattern(longdash)), ///
    legend(order(1 "M 2000" 2 "M 2010" 3 "M 2020" 4 "F 2000" 5 "F 2010" 6 "F 2020") ///
           pos(10) ring(0) col(1))                                     ///
    xtitle("Informality Rate")                                         ///
    ytitle("Density")                                                 ///
    note("Source: INEGI's Census of Population and Housing 2000, 2010, 2020")


//=============================================================================
// 4. Reshape the data for faceted density plots by gender
//    - `gen id = _n' creates a unique row identifier.
//    - `reshape long Informalidad_Tasa, i(id) j(sex) string': stack M/F into one column.
//    - Recode `sex' from variable names ("TasaM", "TasaF") to human-readable labels.
//    - Drop any residual combined total ("T") if present.
//=============================================================================
gen id = _n

reshape long Informalidad_Tasa, i(id) j(sex) string

replace sex = "Male"   if sex == "TasaM"
replace sex = "Female" if sex == "TasaF"

drop if sex == "T"      // remove any unwanted total-category rows
replace sex = "Male"   if sex == "M"
replace sex = "Female" if sex == "F"


//=============================================================================
// 5. Kernel density plots separated by gender (faceted by `by()')
//    - Single `kdensity tasa' call per year, with line styling.
//    - `by(sex, title() … subtitle(, nobox))' creates panels for Male vs. Female.
//    - Common legend for the three years, custom axis labels, and x-axis ticks.
//=============================================================================
rename Informalidad_Tasa tasa

twoway ///
    (kdensity tasa if Año == 2000, lcolor(navy)       lpattern(solid)    lwidth(medium)) ///
    (kdensity tasa if Año == 2010, lcolor(cranberry)   lpattern(dash)     lwidth(medium)) ///
    (kdensity tasa if Año == 2020, lcolor(olive)       lpattern(longdash) lwidth(medium)), ///
    by(sex, title("Kernel Density of Informality Rate by Gender")         ///
           note("Source: INEGI Census 2000, 2010, 2020")                 ///
           subtitle(, nobox))                                          ///
    legend(order(1 "2000" 2 "2010" 3 "2020") pos(6) rowgap(1))          ///
    xtitle("Informality Rate")                                         ///
    ytitle("Density")                                                 ///
    xlab(0.2(.2)1)
