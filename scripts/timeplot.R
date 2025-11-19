here::i_am("scripts/timeplot.R")

# library load
library(tidyverse)

# data load
covid_sub <- read.csv(here::here("covid_sub.csv"))

config_list <- config::get(
  file = here::here("config.yml"),
  config = Sys.getenv("WHICH_CONFIG", "default")
)

bv <- config_list$binary_variable

death_counts_grouped <- covid_sub |> 
  mutate(DIED = if_else(!is.na(DATE_DIED), 1, 0),
         DATE_DIED = as.Date(DATE_DIED,format = "%d/%m/%Y"),
         YEAR_MONTH_DIED = floor_date(DATE_DIED, "month")) |> 
  filter(`DIED`== 1) |> 
  group_by(across(all_of(bv)), YEAR_MONTH_DIED) |> 
  summarise(death_count = n())

saveRDS(
  death_counts_grouped, 
  file =  here::here("output/death_counts_grouped.rds")
)

time_plot <- ggplot(death_counts_grouped,
                    aes(x=YEAR_MONTH_DIED,
                        y=death_count,
                        group=.data[[bv]])) +
  scale_x_date(date_breaks = "3 month",
               date_labels = "%Y-%m") +
  geom_line(aes(color=.data[[bv]], linetype=.data[[bv]])) +
  geom_point(aes(color=.data[[bv]], shape=.data[[bv]])) +
  labs(
    title = paste("Death Counts by", bv ,"Overtime"),
    x = "Year-Month",
    y = "Death Count",
    color = bv
  )

saveRDS(
  time_plot, 
  file =  here::here("output/time_plot.rds")
)