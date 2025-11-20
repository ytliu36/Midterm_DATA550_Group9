# Analysis 2: t tests 
#  - age mean by group
#  - death proportion (DATE_DIED != NA) by group

if (!requireNamespace("here", quietly = TRUE)) stop("Please install the 'here' package: install.packages('here')")
if (!requireNamespace("yaml", quietly = TRUE)) stop("Please install the 'yaml' package: install.packages('yaml')")
if (!requireNamespace("dplyr", quietly = TRUE)) stop("Please install the 'dplyr' package: install.packages('dplyr')")
if (!requireNamespace("broom", quietly = TRUE)) stop("Please install the 'broom' package: install.packages('broom')")

library(here)
library(yaml)
library(dplyr)
library(broom)
here::i_am("scripts/02_tests.R")

# Paths
cfg_path <- here::here("config.yml")
if (!file.exists(cfg_path)) stop("config.yml not found at: ", cfg_path)
config <- yaml::read_yaml(cfg_path)

binary_variable <- config$default$binary_variable

data_path <- here::here("covid_sub.csv")
if (!file.exists(data_path)) stop("covid_sub.csv not found at: ", data_path)
df <- read.csv(data_path, stringsAsFactors = FALSE)

# Basic checks
if (!(binary_variable %in% names(df))) stop("Binary variable not found in data: ", binary_variable)
if (!("AGE" %in% names(df))) stop("AGE column not found in data")
if (!("DATE_DIED" %in% names(df))) stop("DATE_DIED column not found in data")

# Prepare grouping variable
df$group <- as.factor(df[[binary_variable]])

# Clean data
df <- df %>%
	mutate(DEATH = ifelse(is.na(DATE_DIED), FALSE, TRUE)) %>%
	filter(
		!is.na(DEATH),
		!is.na(AGE),
		!is.na(!!binary_variable)
	)

# 1) Age t-test
age_df <- df[!is.na(df$AGE) & !is.na(df$group), , drop = FALSE]
if (length(unique(age_df$group)) < 2) stop("Not enough groups in ", binary_variable, " for AGE t-test")
age_test <- t.test(AGE ~ group, data = age_df)

# 2) Death proportion via t-test on 0/1 indicator
df$death <- ifelse(is.na(df$DATE_DIED) | df$DATE_DIED == "", 0, 1)
death_df <- df[!is.na(df$death) & !is.na(df$group), , drop = FALSE]
if (length(unique(death_df$group)) < 2) stop("Not enough groups in ", binary_variable, " for death proportion test")
death_test <- t.test(death ~ group, data = death_df)


# Save results
outdir <- here::here("output")
if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)

# Build a per-group summary table with key statistics using dplyr
summary_table <- df %>%
	group_by(group) %>%
	summarise(
		n_age = sum(!is.na(AGE)),
		mean_age = ifelse(n_age > 0, mean(AGE, na.rm = TRUE), NA_real_),
		sd_age = ifelse(n_age > 1, sd(AGE, na.rm = TRUE), NA_real_),
		n_death = sum(!is.na(death)),
		death_count = sum(death, na.rm = TRUE),
		death_prop = ifelse(n_death > 0, mean(death, na.rm = TRUE), NA_real_)
	) %>%
	ungroup()

group_levels <- levels(df$group)

# Also attach global test statistics (p-values, t-statistics, df, confidence intervals)

# Use broom to tidy test outputs and also keep computed mean/proportion diffs
age_tidy <- broom::tidy(age_test)
death_tidy <- broom::tidy(death_test)

age_p_value <- as.numeric(age_tidy$p.value)
age_conf_low <- as.numeric(age_tidy$conf.low)
age_conf_high <- as.numeric(age_tidy$conf.high)
age_t_stat <- as.numeric(age_tidy$statistic)

death_p_value <- as.numeric(death_tidy$p.value)
death_conf_low <- as.numeric(death_tidy$conf.low)
death_conf_high <- as.numeric(death_tidy$conf.high)
death_t_stat <- as.numeric(death_tidy$statistic)

# Add test summaries as columns (same values repeated for each group row so the CSV
# contains both group-level counts/means and the overall test results)


summary_table$age_t_statistic <- age_t_stat
summary_table$age_p_value <- age_p_value
summary_table$age_conf_low <- age_conf_low
summary_table$age_conf_high <- age_conf_high

summary_table$death_t_statistic <- death_t_stat
summary_table$death_p_value <- death_p_value
summary_table$death_conf_low <- death_conf_low
summary_table$death_conf_high <- death_conf_high

# Compute raw differences between the two groups (assumes exactly two levels)
if (length(group_levels) == 2) {
	mean_age_diff <- summary_table$mean_age[2] - summary_table$mean_age[1]
	death_prop_diff <- summary_table$death_prop[2] - summary_table$death_prop[1]
} else {
	mean_age_diff <- NA
	death_prop_diff <- NA
}


summary_table$mean_age_diff <- mean_age_diff
summary_table$death_prop_diff <- death_prop_diff

# Build a compact test-summary table (one row per test) using broom results + estimated diffs
test_summary <- data.frame(
	test = c("age_mean_difference", "death_proportion_difference"),
	estimate = c(
		if (length(group_levels) == 2) summary_table$mean_age[2] - summary_table$mean_age[1] else NA_real_,
		if (length(group_levels) == 2) summary_table$death_prop[2] - summary_table$death_prop[1] else NA_real_
	),
	conf_low = c(age_conf_low, death_conf_low),
	conf_high = c(age_conf_high, death_conf_high),
	t_statistic = c(age_t_stat, death_t_stat),
	p_value = c(age_p_value, death_p_value),
	stringsAsFactors = FALSE
)

# # Write CSV that other users can easily open
# csv_path <- file.path(outdir, "analysis2_summary_by_group.csv")
# write.csv(summary_table, csv_path, row.names = FALSE)

# # Write test-summary CSV (one row per test)
# tests_csv_path <- file.path(outdir, "analysis2_tests_summary.csv")
# write.csv(test_summary, tests_csv_path, row.names = FALSE)

# Save an RDS that contains the table and test objects for R Markdown display
rds_path <- file.path(outdir, "analysis2_results.rds")
saveRDS(list(
	summary_table = summary_table,
	age_test = age_test,
	death_test = death_test,
	age_stats = list(
		t_statistic = age_t_stat,
		p_value = age_p_value,
		conf_low = age_conf_low,
		conf_high = age_conf_high
	),
	death_stats = list(
		t_statistic = death_t_stat,
		p_value = death_p_value,
		conf_low = death_conf_low,
		conf_high = death_conf_high
	),
	binary_variable = binary_variable
), file = rds_path)


