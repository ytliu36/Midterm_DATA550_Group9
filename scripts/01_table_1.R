library(dplyr)
library(gtsummary)

here::i_am("scripts/01_table_1.R")

# Read data
dat <- read.csv(here::here("covid_sub.csv"))

# Default config if env variable not set
WHICH_CONFIG <- Sys.getenv("WHICH_CONFIG")
if (WHICH_CONFIG == "") WHICH_CONFIG <- "default"
config_list <- config::get(config = WHICH_CONFIG)

# Convert string column name to symbol
group_var <- rlang::sym(config_list$binary_variable)

# Clean data
dat <- dat %>%
  mutate(DEATH = ifelse(is.na(DATE_DIED), FALSE, TRUE)) %>%
  filter(
    !is.na(DEATH),
    !is.na(AGE),
    !is.na(!!group_var)    
  )

# Make table
tbl <- dat %>%
  select(DEATH, AGE, !!group_var) %>%
  tbl_summary(
    by = !!group_var,
    type = list(
      all_continuous() ~ "continuous",
      all_categorical() ~ "categorical"
    ),
    statistic = list(
      all_continuous() ~ "{mean} ± {sd}",
      all_categorical() ~ "{n} ({p}%)"
    ),
    missing = "ifany"
  ) %>%
  add_p() %>%
  add_overall()

# Save output
saveRDS(tbl, here::here("output", paste0("Table_1_", WHICH_CONFIG, ".rds")))

