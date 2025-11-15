here::i_am(
  "scripts/analysis-regression.R"
)

# load necessary libraries
library(gtsummary)

# read the data
dat <- read.csv(
  here::here("covid_sub.csv")
)

# create the outcome variable
dat$death <- ifelse(is.na(dat$DATE_DIED) == T, 0, 1)



# fit the regression model
# pick binary variable between sex and patient type.

# The terminal or Docker can set WHICH_CONFIG = "patient_type"
WHICH_CONFIG <- Sys.getenv("WHICH_CONFIG", "default")

cfg <- config::get(
  file = here::here("config.yml"),
  config = WHICH_CONFIG
)

binary_var <- cfg$binary_variable

message("Using configuration: ", WHICH_CONFIG)
message("Binary variable: ", binary_var)

# fit logistic regression model
formula_str <- paste0("death ~ AGE + ", binary_var)
fit <- glm(as.formula(formula_str), data = dat, family = binomial)

primary_regression_table <- 
  tbl_regression(fit) |>
  add_global_p()

# save the results as RDS file in /output
saveRDS(fit, here::here("output/regression-model.rds"))
saveRDS(primary_regression_table, here::here("output/regression-model-table.rds"))


