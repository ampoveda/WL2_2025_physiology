#load library(tidyverse)
# Read in seed mass data. read.csv()
# Make histogram plot seedmass |< ggplot(aes(Mass)) + geom_histogram()
#ggsave("figures/SeedMass_Histogram.png", units="in", width=5,height=5)

library(tidyverse)
library(stringr)
library(lubridate)
Seedmass_data <- read_csv("Data/UCD_2024_SeedMass_A1.csv") %>%
  mutate(date.meas = mdy(date.meas))

Seedmass_data |> ggplot(aes(Mass)) + geom_histogram()
ggsave("figures/SeedMass_Histogram.png", units="in", width=5,height=5)

Davis_Popcodes <- read_csv("Data/UCD_Genotypes_2023_2024.csv") %>%
  mutate(pop = str_extract(pop.id, "^[^-]+")) %>% #Create a new column with only the pop code, removing everythign after the - in the pop.id column
  rename(Plant_type = 'Plant Type') %>% #renaming the Plant type column to remove the space for easier recalling 
  select(- c("Plant_type", "pop.id", "mf", "rep", "rack", "bed", "row", "column")) #deselecting all of the columns we don't need to join

Seedmass_data <- Seedmass_data %>%
  left_join(Davis_Popcodes, by="unique.ID") #joins in the pop column from the Davis_Popcodes data set by matching the unique id's


ggplot(Seedmass_data, aes(x=date.meas, y=Mass, color=pop))+
  geom_point()

ggplot(Seedmass_data, aes(x=pop, y=Mass, color = date.meas)) +
  geom_point() +
  theme(axis.text.x = element_text(angle = 45, hjust=1))

ggplot(Seedmass_data, aes(x=Mass, fill = pop))+
  geom_histogram()
ggsave("figures/SeedMass_Histogram.png", units="in", width=5,height=5)

ggplot(Seedmass_data, aes(x=Mass, fill = date.meas))+
  geom_histogram()

Seedmass_summary <- Seedmass_data %>%
  group_by(date.meas)%>%
  summarize(total.mass = sum(Mass, na.rm = TRUE))

ggplot(Seedmass_summary, aes(x=date.meas, y=total.mass, group=1)) +
  geom_line() +
  geom_point() +
  theme(axis.text.x = element_text(angle = 45, hjust=1))
ggsave("figures/SeedMass_Variance.png")

