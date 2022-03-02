# Zip Code Transformer
 Geo-Location Tool that Converts U.S. Zip Codes to U.S. County FIPS and Provides County FIPS Demographic Information 

County-level demographic information includes 250+ variables, including things like county population, median income, education level, density, 2020 Presidential Election results, etc.

### Description

1) Input File: CSV file like ExampleInput1.csv. 

Two columns required. 

- 1st Column: "ID"  
- 2nd Column: "Zipcode"

2) Download Files and Run ZipCodeTransformer.R (need R to run, see [here](https://www.r-project.org/)). Change the code to point to your CSV file and not the ExampleInput1.csv file. Make sure to install the necessary libraries (if not already installed).  

3) Output File: CSV file with each inputted ID and Zip Code matched to FIPS/County (one or more since Zip Codes can span across multiple bordering U.S. counties) and 250+ demographic county-level variables, for instance, county population, median income, density, 2020 Election results, etc. See Sources below for more information regarding these demographic variables.      

### Sources

Political demographics info from: 

- https://github.com/tonmcg/US_County_Level_Election_Results_08-20/blob/master/2020_US_County_Level_Presidential_Results.csv

General county-level demographics from: 

- https://github.com/JieYingWu/COVID-19_US_County-level_Summaries/blob/master/data/counties_only.csv
 
### Citation

Please Cite As: Gollwitzer, A (2022) Zip Code Transformer (Version 1.0) [Source code]. https://github.com/AntonGollwitzer/ZipCodeTransformer 

### Contact

If any bugs/issues please fix or email anton.gollwitzer@gmail.com
