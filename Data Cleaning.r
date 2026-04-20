# Script for Data Cleaning 

#The current scrpt is made for Ebro´s reservoirs data cleaning
#to prepare the data and it be ready to be integrated into a SQLite database

#During more than 15 years of samplings there are many reservoirs and samples
#At every sampling, at least the environmental variables were measured. 
#Therefore, the core dataset comes from the environmental variables. 
#An important point is the sampling_id variable. Which is an unique id 
#for every sampling and it will become as the Primary Key in the database. 

# Libraries -----
library(dplyr)
library(tidyr)
library(ggplot2)

#Visualizing the plots in the R session with httpgd
httpgd::hgd() #to follow the link and open a new window where the plots will be shown.
httpgd::hgd_browse() #to open a window in VScode where the plots will be shown.


getwd()


#Loading the data ----

environmental_raw <- read.csv("Master_files/environmental data.csv",
 header = TRUE)

str(environmental_raw)

#Transforming characters into factors 

environmental_raw <- environmental_raw %>%
    mutate_if(is.character, as.factor)
