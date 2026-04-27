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

View(environmental_raw)

#The names of MAR2013-2016 were changed in excel due to the program change it 
# to march-2013. now they are MAG2012-2016. So we need to restore the original names

environmental_raw |> 
mutate(Code = recode(Code,
    "MAG2012" = "MAR2012",
"MAG2013" = "MAR2013",
"MAG2014" = "MAR2014",
"MAG2015" ="MAR2015",
"MAG2016" ="MAR2016"
)) -> environmental_raw

environmental_raw  <- 
environmental_raw|> 
mutate(Code = as.factor(Code))

#Creating the reservoir_id to pass from code to 
#reservoir name only "MEQ2015" to "MEQ"

environmental_raw <- 
environmental_raw  |>  
  extract(
    col = Code,
    into = c("reservoir_id", "Year"),
    regex = "^([A-Za-z]+)([0-9]{4})$",
    remove = FALSE,
    convert = TRUE
  )  |> 
  mutate(reservoir_id = as.factor(reservoir_id)) |> 
  mutate(Year = as.factor(Year))


#Ok now we have the environmental dataset in a wide format
#In case any new variable is added in future samplings 
#to avoid to modify the db structure is needed to pass it to a long format

environmental_long  <- 
environmental_raw   |>  
tidyr::pivot_longer(
    cols = -c("Sampling_id", #the PK
    where(is.factor)), # selecting all categorical columns
    names_to = "Variable",
    values_to = "Value"
)


#Fixing some names in the db 

environmental_long |> 
mutate(Variable = recode(Variable,
    "Temp" = "Temperature",
    "Phytoplankton" = "Phyto_abundance",
    "Fito.Biomasa" = "Phyto_biomass",
    "Phycocianin" = "Phycocyanin",
    "Conduct" = "Conductivity",
    "Amonium" = "Ammonium",
    "SS" = "Suspended_solids",
    "Photic.Zone" = "Photic_zone",
    "reservoir.percentage" = "Reservoir_percentage",
    "volume.max" = "Volume_max"
)) -> environmental_long_db

View(environmental_long_db)

#Ok now looks okay

#Zooplankton -------

zooplankton_raw <- read.csv("Master_files/zooplankton.csv",
 header = TRUE)

View(zooplankton_raw)

#Due the dataframe structure is mandatory to arrange it
#to have a similar structure as environmental data 
#to assing the reservoir_id


zooplankton_raw  |>
#We removed the unnecesary columns for now
 select(-c("Body.Weight":"Group")) |>
 #Transposte
 t() |>
 as.data.frame() |> 
 #first column as column names 
 janitor::row_to_names(row_number = 1)  |>
 #Not sure why are more columns so we will keep the necessary
select(c("Acanthocyclops americanus":"Dresseina polymorpha")) |> 
#rownames to columns
tibble::rownames_to_column() |>
#renaming the first column
rename("Code" = "rowname")  |> 
#now to long format
tidyr::pivot_longer(
    cols = -c("Code"),
    names_to = "Species",
    values_to = "Abundance"
)  |> 
#removing all NAs
na.omit(Abundance) -> zooplankton_long

View(zooplankton_long)

#adding the rest of infomation categorical
left_join(
  zooplankton_long,
  zooplankton_raw |> select(Species, Body.Weight:Group), 
  by = "Species"
)  -> zooplankton_long

#Final dataframe
left_join(
    zooplankton_long,
    environmental_long_db  |> select(Sampling_id, Code)  |> 
    distinct(Code, .keep_all = TRUE), # To removes duplicates
    by = "Code"
) |> 
# re arrange columns
relocate(Sampling_id,
 .before = Code)  |> 
 relocate(c(Species, Abundance),
 .after = Group)  |> 
 #Obtaining biomass
 mutate(Abundance = as.numeric(Abundance))  |> 
 mutate(Biomass = Abundance * Body.Weight) |> 
 #removing zeros in the abundance (should not be there)
 filter(Abundance > 0) -> zooplankton_long_db

View(zooplankton_long_db)

#Ok now both dataframes are in long format and looks ok
