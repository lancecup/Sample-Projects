/*==========================================================================
 * Recoding of variables into IPUMS categories
 * Author:        Lance Cu Pangilinan
 * Last modified: 04/17/2025
 *
 * Purpose:
 *   - Standardize variable names and recode categories to match IPUMS definitions.
 *   - Input dataset: merged_indiv.dta (combined Census and Intercensal data).
 *   - Output dataset: datospersonas.dta (cleaned individual-level microdata).
 *==========================================================================*/

clear                                 // Remove any existing data from memory
cap log close                         // Close any active log file, if present

//---------------------------------------------------------------------------
// Define path to the folder where cleaned data will be saved
//--------------------------------------------------------------------------- 
global constructeddata "../../../Datos"  
// `constructeddata' now points to the root output directory

//---------------------------------------------------------------------------
// Load the merged individual‐level dataset
//--------------------------------------------------------------------------- 
use "$constructeddata/Cleaned_Indiv/merged_indiv.dta", clear  



//---------------------------------------------------------------------------
// 1. Rename variables that already match IPUMS categories or need no recoding
//--------------------------------------------------------------------------- 
rename (anio ID_VIVIENDA LLAVE_MUNICIPIO FACTOR_EXP numpersona ///
        ESCOLARIDAD_ACUMULADA LLAVE_SEXO edad ingreso ///
        HORAS_TRABAJADAS MERCADO_TRABAJO_LOCAL) ///
       (year hhid municip_key weight_in person_num ///
        schoolyrs sex age income wrkhrs llm)


//---------------------------------------------------------------------------
// 2. Create weighting variables
//--------------------------------------------------------------------------- 
// In 1990 the person expansion factor (weight_in) is missing; assign default
replace weight_in = 10 if year == 1990

// Create a household weight identical to the person weight for household-level uses
gen weight_hh = weight_in



//---------------------------------------------------------------------------
// 3. Recode continuous or simple numeric variables to handle missing/top-coding
//--------------------------------------------------------------------------- 

// Age: code missing as 999, top-code all ages ≥100 to 100 (unless already missing)
replace age = 999 if age == .
replace age = 100 if age >= 100 & age != 999

// Years of schooling: code missing as 99, top-code all values ≥18 to 18
replace schoolyrs = 99 if schoolyrs == .
replace schoolyrs = 18 if schoolyrs >= 18 & schoolyrs != 99

// Hours worked: assign zero for missing values
replace wrkhrs = 0 if wrkhrs == .



//---------------------------------------------------------------------------
// 4. Create and label urban/rural indicator
//--------------------------------------------------------------------------- 
// LLAVE_TAMLOC: 1 = rural, 2–4 = various urban sizes
gen urban =        ///
    1 if LLAVE_TAMLOC == 1
replace urban = 2  ///
    if inlist(LLAVE_TAMLOC, 2, 3, 4)

label define urban 1 "Rural" 2 "Urban"
label values urban urban



//---------------------------------------------------------------------------
// 5. Create and label school attendance indicator
//--------------------------------------------------------------------------- 
// LLAVE_ASISESCOLAR: 1 = attending, 2 = not attending, 3 = NIU, 0 = missing
gen school =       ///
    1 if LLAVE_ASISESCOLAR == 1
replace school = 2 ///
    if LLAVE_ASISESCOLAR == 2
replace school = 0 ///
    if LLAVE_ASISESCOLAR == 3
replace school = 9 ///
    if LLAVE_ASISESCOLAR == 0

label define school ///
    1 "Yes" ///
    2 "No, not specified" ///
    0 "NIU (not in Universe)" ///
    9 "Unknown/missing"

label values school school



//---------------------------------------------------------------------------
// 6. Generate detailed age-group categories (IPUMS style) and label
//--------------------------------------------------------------------------- 
gen age2 = 1  if age < 5
replace age2 = 2   if age >= 5   & age < 10
replace age2 = 3   if age >= 10  & age < 15
replace age2 = 4   if age >= 15  & age < 20
replace age2 = 12  if age >= 20  & age < 25
replace age2 = 13  if age >= 25  & age < 30
replace age2 = 14  if age >= 30  & age < 35
replace age2 = 15  if age >= 35  & age < 40
replace age2 = 16  if age >= 40  & age < 45
replace age2 = 17  if age >= 45  & age < 50
replace age2 = 18  if age >= 50  & age < 55
replace age2 = 19  if age >= 55  & age < 60
replace age2 = 20  if age >= 60  & age < 65
replace age2 = 21  if age >= 65  & age < 70
replace age2 = 22  if age >= 70  & age < 75
replace age2 = 23  if age >= 75  & age < 80
replace age2 = 24  if age >= 80  & age < 85
replace age2 = 25  if age >= 85
replace age2 = 98  if age == 999  // preserve missing code

label define age2 ///
    1  "0 to 4"      2  "5 to 9"      3  "10 to 14"   4  "15 to 19" ///
    12 "20 to 24"    13 "25 to 29"    14 "30 to 34"   15 "35 to 39" ///
    16 "40 to 44"    17 "45 to 49"    18 "50 to 54"   19 "55 to 59" ///
    20 "60 to 64"    21 "65 to 69"    22 "70 to 74"   23 "75 to 79" ///
    24 "80 to 84"    25 "85+"         98 "Unknown"

label values age2 age2



//---------------------------------------------------------------------------
// 7. Broad marital status (marst) and detailed (marstd) recoding
//--------------------------------------------------------------------------- 
// Broad categories: never married, married/in union, separated/divorced,
// widowed, unknown.
gen marst = 1 if inlist(LLAVE_SITUACONYUGAL, 9, 10)
replace marst = 2 if inlist(LLAVE_SITUACONYUGAL, 1, 5, 6, 7, 8)
replace marst = 3 if inlist(LLAVE_SITUACONYUGAL, 2, 3)
replace marst = 4 if LLAVE_SITUACONYUGAL == 4
replace marst = 999 if LLAVE_SITUACONYUGAL == 0

label define marst ///
    1  "Single/never married"           ///
    2  "Married/in union"               ///
    3  "Separated/divorced/spouse absent" ///
    4  "Widowed"                        ///
    999 "Unknown/missing"

label values marst marst

// Detailed marital status codes mirror IPUMS digit scheme
gen marstd = 111 if inlist(LLAVE_SITUACONYUGAL, 9, 10)
replace marstd = 211 if LLAVE_SITUACONYUGAL == 6
replace marstd = 212 if LLAVE_SITUACONYUGAL == 7
replace marstd = 213 if LLAVE_SITUACONYUGAL == 8
replace marstd = 220 if LLAVE_SITUACONYUGAL == 1
replace marstd = 335 if LLAVE_SITUACONYUGAL == 2
replace marstd = 350 if LLAVE_SITUACONYUGAL == 3
replace marstd = 411 if LLAVE_SITUACONYUGAL == 4
replace marstd = 999 if LLAVE_SITUACONYUGAL == 0

label define marstd ///
    111 "Never married, never cohabited"      ///
    211 "Married, civil"                      ///
    212 "Married, religious"                  ///
    213 "Married, civil and religious"        ///
    220 "Consensual union"                    ///
    335 "Separated"                           ///
    350 "Separated from union or marriage"    ///
    411 "Widowed from union or marriage"      ///
    999 "Unknown/missing"

label values marstd marstd



//---------------------------------------------------------------------------
// 8. Relationship to household head
//--------------------------------------------------------------------------- 
gen relate = 1 if LLAVE_PARENTESCO == 101                     // Head
replace relate = 2 if inrange(LLAVE_PARENTESCO, 201, 207)     // Spouse/partner
replace relate = 3 if inrange(LLAVE_PARENTESCO, 301, 306)     // Child
replace relate = 4 if inrange(LLAVE_PARENTESCO, 601, 629)     // Other relatives
replace relate = 5 if ///                                     
    inrange(LLAVE_PARENTESCO, 401, 420) |                    ///
    inrange(LLAVE_PARENTESCO, 501, 506) |                    ///
    inrange(LLAVE_PARENTESCO, 701, 708)                      // Non-relative
replace relate = 9 if LLAVE_PARENTESCO == 0                  // Unknown/missing

label define relate ///
    1 "Head"                       ///
    2 "Spouse/partner"             ///
    3 "Child"                      ///
    4 "Other relatives"            ///
    5 "Non-relative"               ///
    9 "Unknown"

label values relate relate



//---------------------------------------------------------------------------
// 9. Work class (broad) and detailed work class (classwkd)
//--------------------------------------------------------------------------- 
// Broad work class categories: self-employed, wage worker, unpaid, etc.
gen classwk = 1 if inlist(LLAVE_SITTRA, 4, 5)    // Self-employed
replace classwk = 2 if inlist(LLAVE_SITTRA, 1, 2, 3)  // Wage/salary
replace classwk = 3 if LLAVE_SITTRA == 6        // Unpaid
replace classwk = 9 if LLAVE_SITTRA == 0        // Unknown/missing
replace classwk = 0 if LLAVE_SITTRA == 7        // NIU (not in Universe)

label define classwk ///
    1 "Self-employed"               ///
    2 "Wage/salary worker"          ///
    3 "Unpaid worker"               ///
    9 "Unknown/missing"             ///
    0 "NIU (not in Universe)"

label values classwk classwk

// Detailed work class breakdown (IPUMS-style codes)
gen classwkd = 110  if LLAVE_SITTRA == 4         // Employer
replace classwkd = 120 if LLAVE_SITTRA == 5       // Own account
replace classwkd = 205 if inlist(LLAVE_SITTRA, 1, 3) // White/blue collar
replace classwkd = 206 if LLAVE_SITTRA == 2       // Day laborer
replace classwkd = 310 if LLAVE_SITTRA == 6       // Unpaid family worker
replace classwkd = 999 if LLAVE_SITTRA == 9       // Unknown/missing
replace classwkd = 0   if LLAVE_SITTRA == 7       // NIU

label define classwkd ///
    110 "Employer"                          ///
    120 "Working on own account"            ///
    205 "White or blue collar"             ///
    206 "Day laborer"                       ///
    310 "Unpaid family worker"              ///
    999 "Unknown/missing"                   ///
    0   "NIU (not in Universe)"

label values classwkd classwkd



//---------------------------------------------------------------------------
// 10. Primary activity status (empstat) and labor force participation (labforce)
//--------------------------------------------------------------------------- 
// Employment status: employed, unemployed, inactive, NIU, missing
gen empstat = 1 if inlist(LLAVE_ACTPRIMARIA, 1, 2)   // Employed
replace empstat = 2 if LLAVE_ACTPRIMARIA == 3       // Unemployed
replace empstat = 3 if inlist(LLAVE_ACTPRIMARIA, 4,5,6,7,8,9) // Inactive
replace empstat = 0 if LLAVE_ACTPRIMARIA == 10      // NIU
replace empstat = 9 if LLAVE_ACTPRIMARIA == 0       // Unknown/missing

label define empstat ///
    1 "Employed"                ///
    2 "Unemployed"              ///
    3 "Inactive"                ///
    0 "NIU (not in Universe)"   ///
    9 "Unknown/missing"

label values empstat empstat

// Labor force participation: yes/no by IPUMS convention
gen labforce = 2 if age >= 15 & inlist(LLAVE_ACTPRIMARIA, 1,2,3)   // In labor force
replace labforce = 1 if age >= 15 & inlist(LLAVE_ACTPRIMARIA, 4,5,6,7,8) // Not in labor force
replace labforce = 0 if age < 15 | LLAVE_ACTPRIMARIA == 10         // NIU
replace labforce = 9 if age >= 15 & LLAVE_ACTPRIMARIA == 0        // Unknown/missing

label define labforce ///
    2 "Yes, in the labor force"      ///
    1 "No, not in the labor force"   ///
    0 "NIU (Not in Universe)"        ///
    9 "Unknown/missing"

label values labforce labforce



//---------------------------------------------------------------------------
// 11. Recode economic activity into broad industry categories (indgen)
//--------------------------------------------------------------------------- 
// Categories correspond to ISIC/NAICS groupings, IPUMS codes:
gen indgen = 10  if inlist(LLAVE_ACTECONOMICA, 111,112,113,114,115,119)  // Agriculture, etc.
replace indgen = 20 if inlist(LLAVE_ACTECONOMICA, 211,212,213,219)        // Mining
replace indgen = 30 if inlist(LLAVE_ACTECONOMICA, 311–339)               // Manufacturing (many codes)
replace indgen = 40 if inlist(LLAVE_ACTECONOMICA, 221,222)               // Utilities
replace indgen = 50 if inlist(LLAVE_ACTECONOMICA, 236–239)               // Construction
replace indgen = 60 if inlist(LLAVE_ACTECONOMICA, 431–469)               // Trade
replace indgen = 70 if inlist(LLAVE_ACTECONOMICA, 721,722)               // Hotels & restaurants
replace indgen = 80 if inlist(LLAVE_ACTECONOMICA, 481–519)               // Transport & comms
replace indgen = 90 if inlist(LLAVE_ACTECONOMICA, 521–524,529)           // Financial services
replace indgen =100 if LLAVE_ACTECONOMICA == 931                         // Public administration
replace indgen =111 if inlist(LLAVE_ACTECONOMICA, 531,532,533,539,541,551,561) // Business services
replace indgen =112 if LLAVE_ACTECONOMICA == 610                         // Education
replace indgen =113 if inlist(LLAVE_ACTECONOMICA, 621,622,623,624,541)   // Health & social
replace indgen =114 if inlist(LLAVE_ACTECONOMICA, 711,712,713,811,813,812,932,562) // Other services
replace indgen =120 if LLAVE_ACTECONOMICA == 814                         // Private household
replace indgen =999 if LLAVE_ACTECONOMICA == 999                        // Unknown
replace indgen =  0 if missing(LLAVE_ACTECONOMICA)                     // NIU

label define indgen ///
    10  "Agriculture, fishing, forestry"       ///
    20  "Mining and extraction"                ///
    30  "Manufacturing"                        ///
    40  "Electricity, gas, water, waste mgmt." ///
    50  "Construction"                         ///
    60  "Wholesale and retail trade"           ///
    70  "Hotels and restaurants"               ///
    80  "Transportation, storage, comms"       ///
    90  "Financial services and insurance"     ///
    100 "Public administration and defense"    ///
    111 "Business services & real estate"      ///
    112 "Education"                            ///
    113 "Health and social work"               ///
    114 "Other services"                       ///
    120 "Private household services"           ///
    999 "Unknown"                              ///
    0   "NIU (Not in Universe)"

label values indgen indgen



//---------------------------------------------------------------------------
// 12. Final housekeeping: rename recoded vars, compress, and save output
//--------------------------------------------------------------------------- 
rename (LLAVE_ACTPRIMARIA LLAVE_ACTECONOMICA) (empstatd Ind3D)

compress       // Optimize storage by reducing variable types where possible

save "$constructeddata/Cleaned_Indiv/datospersonas", replace  
// Save the final IPUMS-styled microdata for further analysis
