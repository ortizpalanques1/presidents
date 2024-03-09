# Libraries ####
library(readxl)
library(tidyverse)

# Functions ####
## correlation given age ####
determine_age <- function(origin, slope, x){
  determined_age <- origin + (slope * as.numeric(days_1970_1793 + as.numeric(x)))
  return(determined_age)
}

## Theme for graphics ####
my_theme <- theme(axis.text.x = element_text(face = "bold", colour = "black"),
                  axis.text.y = element_text(face = "bold", colour = "black"),
                  legend.position = "none",
                  panel.background = element_blank(),
                  panel.grid.minor = element_blank(),
                  panel.grid.major.x = element_blank(),
                  panel.grid.major.y = element_line(colour = "grey"),
                  plot.caption = element_text(hjust = 0, face= "italic", color="#393b45"), #Default is hjust=1
                  plot.title.position = "plot", #NEW parameter. Apply for subtitle too.
                  plot.caption.position =  "plot")

## Save_graph ####
graph_save <- function(p, n, d){
  the_path <- deparse(substitute(p))
  the_name <- deparse(substitute(n))
  the_device <- deparse(substitute(d))
  ggsave(filename = paste0(the_path, "/", the_name, ".", the_device ),
         plot = n,
         device = the_device,
         units = "cm",
         height = 16,
         width = 16)
}

# Read and Arrange Data ####
## President's Age ####
presidents <- read_excel("data/presidents.xlsx", sheet = "Sheet1") 
alpha <- colnames(presidents)
alpha[4] <- "Age"
colnames(presidents) <- alpha
presidents <- presidents %>% 
  mutate(AgeOnly = as.numeric(str_extract(Age, "^[:digit:]+")),
         DaysOnly = as.numeric(trimws(str_extract(Age, " [:digit:]++")))/365,
         Final_Age = AgeOnly+DaysOnly) %>% 
  arrange(Number)

## Inauguration Date ####
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

## Join the data frames ####
presidents <- left_join(presidents, subset(inauguration, select = -c(PRESIDENT)), by="Number")
presidents$Inauguration_Day <- ifelse(!is.na(presidents$FIRST), 
                                      as.Date(presidents$FIRST), 
                                      as.Date(presidents$SECOND)
                                )
presidents$Inauguration_Day <- as.Date(presidents$Inauguration_Day, origin = '1970-01-01')
presidents <- presidents %>% 
  arrange(Final_Age) %>% 
  mutate("Index_Row" = seq(1, nrow(presidents), by = 1)) %>% 
  mutate("Five_Older" = ifelse(Index_Row >= (max(Index_Row)-4),President,NA))

## Life Expectancy ####
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

## Median Age ####
median_age <- read.csv("data/median_age.csv")
colnames(median_age) <- c("Year", "Median_Age", "Source")
median_age$Year <- as.character(median_age$Year)
median_age$Year <- paste0("01-01-", median_age$Year)
median_age$Year <- as.Date(median_age$Year, format = "%d-%m-%Y")

## Project Median Age ####
### Create a new value of date with origin in 1793-01-01. Using 1792-12-31 to establish the difference from the next day
days_1970_1793 <- difftime("1970-01-01","1792-12-31")
median_age$Date1793 <- as.numeric(days_1970_1793 + as.numeric(median_age$Year))
### Create the equation
project_median_age <- lm(Median_Age ~ Date1793, data=median_age) 
origin <- project_median_age$coefficients[1]
slope <- project_median_age$coefficients[2]
### Creating the matrix with projected and other values
additional_dates <- c("1775-01-01", "2060-01-01")
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
median_age <- median_age %>% 
  arrange(Year)

# Calculating the proportion between age at inauguration and median age and life expectancy ####
## Median Age
presidents$Median_Age <- sapply(presidents$Inauguration_Day, determine_age, origin = origin, slope = slope)
## Life expectancy
life_expectancy_final$Date1793 <- as.numeric(days_1970_1793 + as.numeric(life_expectancy_final$Date))
project_life_expectancy <- lm(Life_Expectancy ~ Date1793, data=life_expectancy_final) 
origin_life_expectancy <- project_life_expectancy$coefficients[1]
slope_life_expectancy <- project_life_expectancy$coefficients[2]
presidents$Life_Expectancy <- sapply(presidents$Inauguration_Day, determine_age, origin = origin_life_expectancy, slope = slope_life_expectancy)

# Calculating the proportion Age at Inauguration with Median Age and Life Expectancy ####
presidents$Median_Age_Ratio <- presidents$Final_Age/presidents$Median_Age
presidents$Life_Expectancy_Ratio <- presidents$Final_Age/presidents$Life_Expectancy

# Sorting President and Proportions. Descriptives ####
## Median Age ####
president_proportion_median_age <- data.frame("President" = presidents$President, 
                                              "Ratio" = presidents$Median_Age_Ratio)

president_proportion_median_age <- president_proportion_median_age[order(president_proportion_median_age$Ratio, decreasing = TRUE),]

median_age_proportion_graph <- ggplot(president_proportion_median_age, aes(x = Ratio))+
  geom_histogram(bins = 9, fill = "blue", colour = "black", alpha = 0.5)+
  labs(title = "Ratio: Age of the Presidents and Median Age",
       x = "Ratio",
       y = "Frequency")+
  my_theme

graph_save(output, median_age_proportion_graph, png)
graph_save(output, median_age_proportion_graph, pdf)

median_age_porportion_descriptives <- summary(president_proportion_median_age$Ratio)
median_age_porportion_sd <- sd(president_proportion_median_age$Ratio)

## Life Expectancy ####
president_proportion_life_expectancy <- data.frame("President" = presidents$President, 
                                              "Ratio" = presidents$Life_Expectancy_Ratio)
president_proportion_life_expectancy <- president_proportion_life_expectancy[order(president_proportion_life_expectancy$Ratio, decreasing = TRUE),]

life_expectancy_ratio <- ggplot(president_proportion_life_expectancy, aes(x = Ratio))+
  geom_histogram(bins = 9, fill = "blue", colour = "black", alpha = 0.5)+
  labs(title = "Ratio: Age of the Presidents and Life Expectancy",
       x = "Ratio",
       y = "Frequency")+
  my_theme

graph_save(output, life_expectancy_ratio, png)
graph_save(output, life_expectancy_ratio, pdf)

life_expectancy_porportion_descriptives <- summary(president_proportion_life_expectancy$Ratio)
life_expectancy_porportion_sd <- sd(president_proportion_life_expectancy$Ratio)

# Descriptive of Age at Inauguration ####
age_at_inauguration <- summary(presidents$Final_Age)
age_at_inauguration_sd <- sd(presidents$Final_Age)
presidents_age_graph <- ggplot(presidents, aes(x = Final_Age))+
  geom_histogram(bins = 9, fill = "blue", colour = "black", alpha = 0.5)+
  scale_y_continuous(breaks = seq(0, 14, by = 2))+
  labs(title = "Age of the Presidents (1789-2020)",
       x = "Age (Years)",
       y = "Frequency")+
  my_theme

graph_save(output, presidents_age_graph, png)
graph_save(output, presidents_age_graph, png)


# The Graph ####
Presidents_Age <- ggplot()+
  geom_area(life_expectancy_final, mapping = aes(x = Date, y = Life_Expectancy), fill = "yellow", alpha = 0.7)+
  geom_area(median_age[1:2,], mapping = aes(x = Year, y = Median_Age), fill = 4, alpha = 0.3)+
  geom_area(median_age[(nrow(median_age)-1):nrow(median_age),], mapping = aes(x = Year, y = Median_Age), fill = 4, alpha = 0.3)+
  geom_area(median_age[2:(nrow(median_age)-1),], mapping = aes(x = Year, y = Median_Age), fill = 4, alpha = 0.8)+
  geom_line(presidents, mapping = aes(x = Inauguration_Day, y = Final_Age))+
  geom_text(presidents, mapping = aes(x = Inauguration_Day, y = Final_Age, label = Five_Older), hjust = 0, nudge_x = 0.05, angle = 25, size = 2.5, check_overlap = TRUE)+
  coord_cartesian(xlim = c(as.Date("1793-01-01", format = "%Y-%m-%d"), as.Date("2040-01-01", format = "%Y-%m-%d")))+
  scale_y_continuous(breaks = seq(0, 100, by = 10))+
  scale_x_date(date_breaks = "20 year", date_labels = "%Y")+
  labs(title = "Age of US Presidents at Inauguration",
       subtitle = "With the Names of the Five Oldest Presidents",
       caption = "Yellow: Life Expectancy, Blue: Median Age, Light Blue: Estimated Median Age",
       x = "Year",
       y = "Age")+
  theme(axis.text.x = element_text(angle = 90, face = "bold", colour = "black"),
        axis.text.y = element_text(face = "bold", colour = "black"),
        legend.position = "none",
        panel.background = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey"),
        plot.caption = element_text(hjust = 0, face= "italic", color="#393b45"), #Default is hjust=1
        plot.title.position = "plot", #NEW parameter. Apply for subtitle too.
        plot.caption.position =  "plot")

graph_save(output, Presidents_Age, png)
graph_save(output, Presidents_Age, pdf)