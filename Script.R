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


Presidents_Age <- ggplot(presidents, aes(x = Number, y = Final_Age))+
  geom_line()+
  scale_x_discrete(labels= presidents$President)+
  theme(axis.text.x = element_text(angle = 90))
