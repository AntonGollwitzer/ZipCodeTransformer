#Author: Anton Gollwitzer

#Please Cite As: Gollwitzer, A (2022) ZipCode Transformer (Version 1.0) [Source code]. https://github.com/AntonGollwitzer/ZipCodeTransformer 

#The following code takes U.S. zip-codes and transforms them into County-level Fips. It then adds demographic variables
#at the county level. 

#Libraries

library(dplyr)
library(data.table)
library(stringr)

#Input: 2 column csv file. Column 1: ID Column 2: Zipcode 

#Example data
#data = read.csv("ExampleInput1.csv")

#Your data
data = read.csv("YOURCSVFILEHERE.csv")

zipToFip = read.csv("ZipToFips_2010-03.csv")

fipToPoli = read.csv("Poli2020Demos.csv")

fipToDemos = read.csv("CountyDemos.csv")

#rename all ZipCode to share the same name
zipToFip = dplyr::rename(zipToFip, Zipcode = ZIP)

#rename all Fips to share the same name 
zipToFip = dplyr::rename(zipToFip, Fips = STCOUNTYFP)
fipToPoli = dplyr::rename(fipToPoli, Fips = county_fips)
fipToDemos = dplyr::rename(fipToDemos, Fips = FIPS)

#convert zip code to County Fips (and add other location info)

#Note: all.x retains cases where zipcode is missing

#Note: Some zipcodes span across 2 or more different bordering counties. 
#For these zipcodes, the code averages across demo variables in those multiple counties

data = merge(data, zipToFip, by = "Zipcode",all.x = TRUE)

#Add Political 2020 County-Level Election Results
#Politics info from: https://github.com/tonmcg/US_County_Level_Election_Results_08-20/blob/master/2020_US_County_Level_Presidential_Results.csv

data = merge(data, fipToPoli, by = "Fips",all.x = TRUE)

#Add county-level demos
#County-level info from: https://github.com/JieYingWu/COVID-19_US_County-level_Summaries/blob/master/data/counties_only.csv

data = merge(data, fipToDemos, by = "Fips",all.x = TRUE)

#reorder Final file by ID
data = data[order(data$ID),]

#Put ID as first column
data = data %>%
  select(ID, everything())

#check the data carefully to make sure everything looks correct (you will notice multiple ID cases for zipcodes
#that are in multiple bordering counties--we will fix this later in the code)

#Please make sure to check for errors in the county demographics data (I CANNOT ensure that there are not mistakes
#in this merged demographics data).
#To start to check....
describe(data)
str(data)

#Fix the participants who live in zipcodes that go across multiple boardering counties. 
#For such participants, demographic variables are averaged across the two or more counties. 
#Note: PLEASE double check that any demo variables you include are numeric and thus averaging didn't mess up
#the variable

#remove extra info and variables that can't be averaged properly (because not continuous). 
data = data %>% select(-c("CLASSFP","state_name","county_name","State","Area_Name",
                          "Rural.urban_Continuum.Code_2013",
                          "Urban_Influence_Code_2013",
                          "Economic_typology_2015"))

#find the duplicate cases
duplicateFips = data %>%
  filter(duplicated(ID) | duplicated(ID, fromLast = TRUE))

#if duplicates found then runs the duplicate averaging code below

if(nrow(duplicateFips)!=0){
  #reorder by ID for clarity
  duplicateFips = duplicateFips[order(duplicateFips$ID),]
  
  #reshape to add the extra fips and county name columns
  
  #number of Fips per ID
  duplicateFips = duplicateFips %>% group_by(ID) %>% mutate(num = 1:n())
  #reshape to wide
  duplicateFips = duplicateFips %>%
    tidyr::pivot_wider(
      names_from  = c(num), 
      values_from = c(Fips, COUNTYNAME)
    )
  
  #count number of county columns
  countCounty = length(grep(x = colnames(duplicateFips), pattern = "^COUNTYNAME_"))
  
  #get the string for the last county column name
  placeHolder = capture.output(cat("COUNTYNAME_",countCounty,sep = ""))
  
  #count number of county columns
  countCounty = length(grep(x = colnames(duplicateFips), pattern = "^Fips_"))
  
  #get the string for the last Fips column name
  placeHolder2 = capture.output(cat("Fips_",countCounty,sep = ""))
  
  #make cleaner so numeric variables are all to the right
  duplicateFips = duplicateFips %>%
    select(c("ID":"STATE","Fips_1":placeHolder), everything())
  
  #convert demos to numeric that aren't 
  duplicateFips <- duplicateFips  %>%
    mutate(across(c("votes_gop":"ARSON"), as.numeric))
  
  #collapse across the remaining rows (this will only collapse across zipcodes that have >2 counties) but will 
  #create numeric averages for all numeric variables
  duplicateFips=duplicateFips %>% group_by(ID) %>% summarize(
    across("Zipcode", first),
    across(c("STATE":placeHolder), unique),
    across(c("votes_gop":"ARSON"), list(mean = ~ mean(., na.rm = TRUE)))
  )
  
  #just replicates the values into the na cells. You can ignore the warning
  duplicateFips=setDT(duplicateFips[,])[, lapply(.SD, na.omit), by = ID]
  
  #remove the duplicates
  duplicateFips = duplicateFips[duplicated(duplicateFips), ]
  
  #add a flag variable saying zipcode with multiple counties
  duplicateFips$zipcodeWithMultipleFips = 1
  
  #remove the duplicate cases from the main data (they will be added back in after)
  data = data %>%
    filter(!(duplicated(ID) | duplicated(ID, fromLast = TRUE)))
  
  #merge the two datasets back together. 
  
  #rename Fips_1 as Fips for merge etc.
  duplicateFips = dplyr::rename(duplicateFips, Fips = Fips_1)
  duplicateFips = dplyr::rename(duplicateFips, COUNTYNAME = COUNTYNAME_1)
  
  #remove_mean for merge
  duplicateFips = duplicateFips %>% rename_with(~str_remove(., '_mean'))
  
  #merge them back together 
  data = rbind(data,duplicateFips, fill=TRUE)
  
  #update the flag variable
  data$zipcodeWithMultipleFips[is.na(data$zipcodeWithMultipleFips)] = 0
  
  
  #reorder
  data = data %>%
    select(c("ID","Zipcode","STATE", "zipcodeWithMultipleFips","Fips","Fips_2":placeHolder2,"COUNTYNAME","COUNTYNAME_2":placeHolder),everything())

  #re-sort by ID
  data = data[order(data$ID),]  
}

#save data (example data)
#write.csv(data, "OutputInput1.csv")

#save your output data
write.csv(data, "YourOutputData.csv")
