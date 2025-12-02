# COVID-19 Mortality Analysis (Group 9)

This project analyzes the relationship between COVID-19 mortality and patient characteristics, specifically focusing on **Age** and a configurable binary variable (e.g., **Sex** or **Patient Type**).

## Project Structure
- `scripts/`: Contains R scripts for data analysis.
- `output/`: Stores generated tables, plots, and models.
- `config.yml`: Configuration file to switch between analysis variables.
- `report.rmd`: RMarkdown source for the final HTML report.
- `Makefile`: Automates the analysis pipeline.

## Installation

To install the required R packages for this project, run:

```bash
make install
```

This command uses `renv` to restore the project library from `renv.lock`.

## Configuration (`config.yml`)
The analysis is dynamic and can be run for different grouping variables defined in `config.yml`.
- **default**: Analyzes differences by **SEX** (Male vs Female).
- **patient_type**: Analyzes differences by **PATIENT_TYPE** (Inpatient vs Outpatient).

## How to Run

You can use `make` to run the entire analysis pipeline.

### 1. Run Default Analysis (by Sex)
```bash
make all
```
This will generate `report_default.html`.

### 2. Run Analysis by Patient Type
```bash
make all CONFIG=patient_type
```
This will generate `report_patient_type.html`.

### 3. Run Individual Steps
You can run specific parts of the analysis:
```bash
make tables      # Only generate summary tables
make tests       # Only run difference tests
make timeplot    # Only generate the time plot
make regression  # Only run regression analysis
make clean       # Remove all output files
```

## Analysis Modules

### Analysis 1: Summary Statistics
- `scripts/01_table.R`: Generates a summary table (`Table_1_*.rds`) for death count and patient age, stratified by the selected binary variable.

### Analysis 2: Difference Tests
- `scripts/02_tests.R`: Performs statistical tests:
  - Two-sample t-test (mean age difference).
  - Two-sample t-test (death proportion difference).
  - Outputs `analysis2_results.rds` and summary CSVs.

### Analysis 3: Timeplot
- `scripts/03_timeplot.R`: Generates a time-series plot (`time_plot.png`) of death counts grouped by the selected variable.

### Analysis 4: Logistic Regression
- `scripts/04_regression.R`: Fits a logistic regression model (`death ~ age + variable`) and saves the model objects.
