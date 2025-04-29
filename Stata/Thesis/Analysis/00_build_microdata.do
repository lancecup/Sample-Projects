/*==========================================================================
 * Combined dataset of the 1990, 2000, 2010, 2020 Censuses and the 2015 
 * Author:         Lance Cu Pangilinan
 * Last modified:  04/17/2025
 *
 * Purpose:
 *   - Read raw text/dta files for individual-level data from five census rounds
 *     (1990, 2000, 2010, 2015 Intercensal, 2020).
 *   - Merge them into a single Stata dataset.
 *   - Prepare directory structure for downstream analyses.
 *==========================================================================*/

clear                                  // Remove any existing data from memory
cap log close                          // Close any open log, if it exists

//-------------------------------------------------------------------------
// SECTION 1: Set up folders for cleaned and derived data outputs
//-------------------------------------------------------------------------

// Create main data directory and subfolders for each data domain
mkdir "../../Datos"                    // Root data directory
mkdir "../../Datos/Insumos"            // For input shares
mkdir "../../Datos/Vulnerabilidad"     // For vulnerability indicators
mkdir "../../Datos/Demograficos"       // For demographic tables
mkdir "../../Datos/Informalidad"       // For informality measures
mkdir "../../Datos/SalariosResiduales" // For residual wage data
mkdir "../../Datos/ChoquesBartik"      // For Bartik shock calculations
mkdir "../../Datos/Ingresos_Pob15"     // For 2015 population income data
mkdir "../../Datos/Cleaned_Indiv"      // For cleaned individual‐level data

//-------------------------------------------------------------------------
// SECTION 2: Define file paths via globals for convenience
//-------------------------------------------------------------------------

global constructeddata "../../Datos" 
// `constructeddata' now points to the root data folder

global indiv "$constructeddata/PUG_Personas_Stata" 
// `indiv' points to the folder containing raw individual‐level files

//-------------------------------------------------------------------------
// SECTION 3: Import and merge 1990 individual data files
//-------------------------------------------------------------------------

// Gather a list of all .dta files whose names begin with "Informacion Personas"
local files: dir "$indiv" files "Informacion Personas *.dta"

// Load the first file (hardcoded) into memory
use `"${indiv}/Informacion Personas 1990_0.dta"', clear  

// Append all other matching files to create one merged 1990 dataset
foreach file of local files {
    // Skip the first file we've already loaded
    if "`file'" != "Informacion Personas 1990_0.dta" {
        local filepath `"${indiv}/`file'"'
        append using `"`filepath'"', force   
        // `force' ensures variables align even if byte/str length differs
    }
}

//-------------------------------------------------------------------------
// SECTION 4: Save the merged individual dataset to disk
//-------------------------------------------------------------------------

save "$constructeddata/Cleaned_Indiv/merged_indiv", replace
// Overwrite any existing merged_indiv.dta with the new combined file

// End of script excerpt. Further sections (2000, 2010, 2015, 2020 merges)
// would follow a similar structure: listing, importing, appending, saving.
