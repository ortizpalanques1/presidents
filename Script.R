# Libraries ####
library(readxl)
library(tidyverse)

# Sources ####
#Age at inauguration: https://potus.com/presidential-facts/age-at-inauguration/
#Day of inauguration: https://historyinpieces.com/research/presidential-inauguration-dates

# Read and Arrange Data ####
  
# President's Age
presidents <- read_excel("data/presidents.xlsx", sheet = "Sheet1") 
alpha <- colnames(presidents)
alpha[4] <- "Age"
colnames(presidents) <- alpha
presidents <- presidents %>% 
  mutate(AgeOnly = as.numeric(str_extract(Age, "^[:digit:]+")),
         DaysOnly = as.numeric(trimws(str_extract(Age, " [:digit:]++")))/365,
         Final_Age = AgeOnly+DaysOnly) %>% 
  arrange(Number)


# Inauguration Date
inauguration <- read_excel("data/presidents.xlsx", sheet = "Sheet2") 
# str(inauguration)
# inauguration_1 <- inauguration[grepl("/", inauguration$FIRST),]
# inauguration_2 <- inauguration[!grepl("/", inauguration$FIRST),]
# 
# inauguration_1$FIRST <- as.Date(inauguration_1$FIRST, format = '%m/%d/%Y')
# inauguration_2$FIRST <- as.Date(as.numeric(inauguration_2$FIRST), origin = '1899-12-30')
# inauguration_dates <- c(as.Date(inauguration_1$FIRST), as.Date(inauguration_2$FIRST))
# inauguration$FIRST <- as.Date(inauguration_dates)

first_column <- NULL
for(d in 1:length(inauguration$FIRST)){
  first_column[d] <- if(grepl("/", inauguration$FIRST[d])){
    as.Date(inauguration$FIRST[d], format = '%m/%d/%Y')
  } else if(!grepl("/", inauguration$FIRST[d])){
    as.Date(as.numeric(inauguration$FIRST[d]), origin = '1899-12-30')
  } else {
    NA
  }
}
first_column <- as.Date(first_column, origin = '1970-01-01')
inauguration$FIRST <- as.Date(first_column)



second_column <- NULL
for(d in 1:length(inauguration$SECOND)){
  second_column[d] <- if(grepl("/", inauguration$SECOND[d])){
    as.Date(inauguration$SECOND[d], format = '%m/%d/%Y')
  } else if(!grepl("/", inauguration$SECOND[d])){
    as.Date(as.numeric(inauguration$SECOND[d]), origin = '1899-12-30')
  } else {
    NA
  }
}
second_column <- as.Date(second_column, origin = '1970-01-01')
inauguration$SECOND <- as.Date(second_column)

inauguration$THIRD <- as.Date(inauguration$THIRD)
inauguration$FOURTH <- as.Date(inauguration$FOURTH)

# Join the data frames ####
presidents <- left_join(presidents, subset(inauguration, select = -c(PRESIDENT)), by="Number")
presidents$Inauguration_Day <- ifelse(!is.na(presidents$FIRST), 
                                      as.Date(presidents$FIRST), 
                                      as.Date(presidents$SECOND)
                                )
presidents$Inauguration_Day <- as.Date(presidents$Inauguration_Day, origin = '1970-01-01')

# Life Expectancy ####
life_expectancy <- read_excel("data/presidents.xlsx", sheet = "Sheet3") 
life_expectancy$Date <- str_extract(life_expectancy$Year, "[[:digit:]]+")
life_expectancy$Date <- paste0(life_expectancy$Date, "-01-01")
life_expectancy$Date <- as.Date(life_expectancy$Date, format = "%Y-%m-%d")

life_expectancy_US_1950_2100 <- read.csv("Data/US_Expectancy_Male_01.csv")
colnames(life_expectancy_US_1950_2100) <- c("Date", "Life_Expectancy", "Anual_Change")

life_expectancy_final <- rbind(
  data.frame(
    life_expectancy[
      life_expectancy$Date < as.Date("1951-1-1", format = "%Y-%m-%d"),
      c("Date", "Life_Expectancy")
    ]
  ),
  data.frame(
    life_expectancy_US_1950_2100[
      life_expectancy_US_1950_2100$Date >= as.Date("1950-1-1", format = "%Y-%m-%d"),
      c("Date", "Life_Expectancy")
    ]
  )
)

# Median Age ####
median_age <- read.csv("data/median_age.csv")
colnames(median_age) <- c("Year", "Median_Age", "Source")
median_age$Year <- as.character(median_age$Year)
median_age$Year <- paste0("01-01-", median_age$Year)
median_age$Year <- as.Date(median_age$Year, format = "%d-%m-%Y")

# Project Median Age ####
# Create a new value of date with origin in 1793-01-01. Using 1792-12-31 to establish the difference from the next day
days_1970_1793 <- difftime("1970-01-01","1792-12-31")
median_age$Date1793 <- as.numeric(days_1970_1973 + as.numeric(median_age$Year))
# Create the equation
project_median_age <- lm(Median_Age ~ Date1793, data=median_age) 
origin <- project_median_age$coefficients[1]
slope <- project_median_age$coefficients[2]
# Creating the matrix with projected and other values
additional_dates <- c("1775-01-01", "2035-01-01")
auxiliar_matrix <- matrix(nrow = length(additional_dates), ncol = ncol(median_age))
for(i in 1:nrow(auxiliar_matrix)){
  auxiliar_matrix[i,1] <- additional_dates[i]
  auxiliar_matrix[i,4] <- as.numeric(days_1970_1793 + as.Date(auxiliar_matrix[i,1], origin = "1970-01-01"))-1
  auxiliar_matrix[i,3] <- "Estimated"
  auxiliar_matrix[i,2] <- origin + (slope * as.numeric(auxiliar_matrix[i,4]))
}
auxiliar_dataframe <- data.frame(
  as.Date(auxiliar_matrix[,1]),
  as.numeric(auxiliar_matrix[,2]),
  auxiliar_matrix[,3],
  as.numeric(auxiliar_matrix[,4])
)
colnames(auxiliar_dataframe) <- colnames(median_age)
median_age <- rbind(median_age, auxiliar_dataframe)


# The Graph ####
Presidents_Age <- ggplot()+
  geom_area(life_expectancy_final, mapping = aes(x = Date, y = Life_Expectancy), fill = "yellow", alpha = 0.6)+
  geom_area(median_age, mapping = aes(x = Year, y = Median_Age), fill = 4, alpha = 0.5)+
  #scale_alpha_manual(values = value_alpha)+
  geom_line(presidents, mapping = aes(x = Inauguration_Day, y = Final_Age))+
  coord_cartesian(xlim = c(as.Date("1793-01-01", format = "%Y-%m-%d"), as.Date("2021-01-01", format = "%Y-%m-%d")))+
  theme(axis.text.x = element_text(angle = 90),
        legend.position="none")
