# Libraries ####
library(readxl)
library(tidyverse)
library(qpdf)

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

## Number to calendar form ####
number_to_months <- function(y){
  number_of_years <- as.integer(y)
  time_in_months <- (y%%1) * 12
  number_of_months <- as.integer(time_in_months)
  number_of_days <- round((time_in_months%%1) * 30, 0)
  time_as_text <- paste0(number_of_years, " years, ", number_of_months, " months, and ", number_of_days, " days.")
  return(time_as_text)
}

## Number to calendar form. Reduced ####
number_to_months_reduced <- function(y){
  number_of_years <- as.integer(y)
  time_in_months <- (y%%1) * 12
  number_of_months <- as.integer(time_in_months)
  number_of_days <- round((time_in_months%%1) * 30, 0)
  time_as_text <- paste0(number_of_years, " Y, ", number_of_months, " M ", number_of_days, " D")
  return(time_as_text)
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


# Determine the closest and farthest US presidents to the median age ####
presidents %>% 
  mutate("Median_Age_Difference" = Final_Age - Median_Age) %>% 
  filter( min_rank(desc(Median_Age_Difference)) <= 5 | 
            min_rank(Median_Age_Difference) <= 5 ) -> df_hi_lo

df_hi_lo$Time_in_Text <- sapply(df_hi_lo$Median_Age_Difference, number_to_months)

letras <- "#f9f0e8"
df_hi_lo_graph <- df_hi_lo %>% 
  mutate("Young_Old" = ifelse(min_rank(desc(Median_Age_Difference)) <= 5 , "Close", "Far")) %>% 
  ggplot(aes(x = reorder(President, -Median_Age_Difference), y = Median_Age_Difference, fill = Young_Old))+
  geom_col()+
  geom_text(aes( y = 5, label = President), hjust = "left", colour = letras, size = 7, fontface = "bold", family = "serif")+
  scale_fill_manual( values = c('#e47200','#0f4d92'))+
  labs(title = "US Presidents and Median Age of the US Population",
       subtitle = "Closest and Farthest",
       y = "Difference with the Median Age of US Population (in Years)")+
  coord_flip()+
  theme(axis.text = element_text(colour = letras, face = "bold"),
        axis.ticks.x = element_line(colour = letras),
        axis.title.x = element_text(colour = letras, size = 16),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none",
        panel.background = element_rect(colour = "#383532", fill = "#383532"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        plot.background = element_rect(colour = "#383532", fill = "#383532"),
        plot.title = element_text(colour = letras, face = "bold", size = 19),
        plot.subtitle = element_text(colour = letras, face = "bold", size = 16),
        text = element_text(family = "serif"))
  
graph_save(output, df_hi_lo_graph, png)
graph_save(output, df_hi_lo_graph, pdf)


# Determine the youngest and oldest US presidents ####
presidents %>% 
  filter( min_rank(desc(Final_Age)) <= 5 | 
            min_rank(Final_Age) <= 5 ) -> df_hi_lo_age

df_hi_lo_age$Time_in_Text <- sapply(df_hi_lo_age$Final_Age, number_to_months)
df_hi_lo_age$Time_Reduced <- sapply(df_hi_lo_age$Final_Age, number_to_months_reduced)


df_hi_lo_age_graph <- df_hi_lo_age %>% 
  mutate("Young_Old" = ifelse(min_rank(desc(Final_Age)) <= 5 , "Close", "Far")) %>% 
  ggplot(aes(x = reorder(President, -Final_Age), y = Final_Age, fill = Young_Old))+
  geom_col()+
  geom_text(aes( y = 5, label = paste0(President, ": ", Time_Reduced)), hjust = "left", colour = letras, size = 5, fontface = "bold", family = "serif")+
  scale_fill_manual( values = c('#e47200','#0f4d92'))+
  labs(title = "US Presidents: Youngest and Oldest",
       subtitle = "At the Moment of Their First Inauguration",
       y = "Age at First Inauguration")+
  coord_flip()+
  theme(axis.text = element_text(colour = letras, face = "bold"),
        axis.ticks.x = element_line(colour = letras),
        axis.title.x = element_text(colour = letras, size = 16),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none",
        panel.background = element_rect(colour = "#383532", fill = "#383532"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        plot.background = element_rect(colour = "#383532", fill = "#383532"),
        plot.title = element_text(colour = letras, face = "bold", size = 19),
        plot.subtitle = element_text(colour = letras, face = "bold", size = 16),
        text = element_text(family = "serif"))

graph_save(output, df_hi_lo_age_graph, png)
graph_save(output, df_hi_lo_age_graph, pdf)

pdf_combine(input = c("output/Presidents_Age.pdf", "output/df_hi_lo_age_graph.pdf", "output/df_hi_lo_graph.pdf"),
            output = "output/presentation.pdf")


# Recover the ranks of the US presidents ####
## Load Ranks
presidents_ranks <- read_excel("data/presidents.xlsx", sheet = "Siena_Rank", range = cell_cols("B:C"))
presidents_ranks$Overall_Rank <- as.numeric(presidents_ranks$Overall_Rank)
presidents_ranks$Reverse_Rank <- abs(presidents_ranks$Overall_Rank - (max(presidents_ranks$Overall_Rank)+min(presidents_ranks$Overall_Rank)))

## Create new data frame for the graphic
presidents_rank_age <- presidents %>% 
  select(Number, President, Final_Age) %>% 
  left_join(presidents_ranks, by = "Number") %>% 
  na.omit()

# Graphic ####
## Obtaining the Median to separate the areas
final_age_median <- median(presidents_rank_age$Final_Age)
reverse_rank_median <- median(presidents_rank_age$Reverse_Rank)

## Named vector to colour the areas
nick_name_vector <- c("Old and Fit","Young and Unfit","Young and Fit","Old and Unfit")
nick_name_colours <- c("#4dff95", "#ff954e", "#00ff67", "#ff6700")

these_colours <- setNames(nick_name_colours, nick_name_vector)

## Data Frame with the Limits of the Areas
square_area <- data.frame(xstart = median(presidents_rank_age$Final_Age), 
                          ystart = median(presidents_rank_age$Reverse_Rank),
                          xend = c(+Inf, -Inf, -Inf, +Inf),
                          yend = c(+Inf,-Inf,+Inf,-Inf),
                          nick_name = nick_name_vector)

## The Graph
rank_age_graph <- ggplot()+
  geom_rect(data = square_area, aes(xmin = xstart, ymin = ystart, xmax = xend, ymax = yend, fill = nick_name), alpha = 0.3)+
  scale_fill_manual(values = these_colours, name = "Area")+
  geom_point(data = presidents_rank_age, aes(x = Final_Age, y = Reverse_Rank)) +
  geom_text(data = presidents_rank_age, aes(x = Final_Age, y = Reverse_Rank, label = President), 
            size = 2.5, 
            hjust = ifelse(presidents_rank_age$Final_Age <= final_age_median, 1, 0), 
            nudge_x = ifelse(presidents_rank_age$Final_Age <= final_age_median, -0.5, 0.5))+
  #geom_vline(xintercept = final_age_median)+
  #geom_hline(yintercept = reverse_rank_median)+
  scale_x_continuous(limits = c(28, 82), breaks = seq(from = 30, to = 80, by = 10))+
  labs(title = "Age and Performance. United States Presidents",
       subtitle = "Using the Siena College Research Institute's (SCRI) Survey of U.S. Presidents",
       x = "Age",
       y = "Rank")+
  theme( axis.text.x = element_text(colour = "black", face = "bold"),
         axis.text.y = element_blank(),
         axis.ticks.x = element_line(colour = "black"),
         axis.ticks.y = element_blank(),
         axis.title = element_text(colour = "black", face = "bold"),
         legend.position = "none",
         panel.background = element_blank(),
         panel.grid.minor = element_blank(),
         panel.grid.major.x = element_blank(),
         panel.grid.major.y = element_blank(),
         plot.background = element_rect(colour = "#fbfcfb", fill = "#fbfcfb"),
         plot.caption = element_text(hjust = 0, face= "italic"), #Default is hjust=1
         plot.title.position = "plot", #NEW parameter. Apply for subtitle too.
         plot.caption.position =  "plot")

graph_save(output, rank_age_graph, png)
graph_save(output, rank_age_graph, pdf)
  
  
