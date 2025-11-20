# Default configuration
CONFIG ?= default

# Paths
SCRIPT_DIR = scripts
OUTPUT_DIR = output
REPORT = report.rmd

# Phony targets
.PHONY: all clean report tables tests timeplot regression help

# Default target
all: report

# Help target
help:
	@echo "Usage: make [target] [CONFIG=name]"
	@echo ""
	@echo "Targets:"
	@echo "  all        Run the full analysis pipeline and generate report (default)"
	@echo "  tables     Generate summary tables (Analysis 1)"
	@echo "  tests      Run statistical tests (Analysis 2)"
	@echo "  timeplot   Generate time series plot (Analysis 3)"
	@echo "  regression Run regression analysis (Analysis 4)"
	@echo "  report     Compile the RMarkdown report"
	@echo "  clean      Remove all output files"
	@echo ""
	@echo "Configuration:"
	@echo "  CONFIG     Set the configuration from config.yml (default: 'default')"
	@echo "             Example: make all CONFIG=patient_type"

# Analysis 1: Summary Statistics
tables: $(SCRIPT_DIR)/01_table.R
	WHICH_CONFIG=$(CONFIG) Rscript $<

# Analysis 2: Difference Tests
tests: $(SCRIPT_DIR)/02_tests.R
	WHICH_CONFIG=$(CONFIG) Rscript $<

# Analysis 3: Timeplot
timeplot: $(SCRIPT_DIR)/03_timeplot.R
	WHICH_CONFIG=$(CONFIG) Rscript $<

# Analysis 4: Regression
regression: $(SCRIPT_DIR)/04_regression.R
	WHICH_CONFIG=$(CONFIG) Rscript $<

# Generate Report
# The report depends on the outputs of the scripts. 
# Since filenames depend on config, we just depend on the script targets to ensure they run.
report: tables tests timeplot regression $(REPORT)
	WHICH_CONFIG=$(CONFIG) Rscript -e "rmarkdown::render('$(REPORT)', output_file = 'report_$(CONFIG).html')"

# Clean output
clean:
	rm -f $(OUTPUT_DIR)/*.rds $(OUTPUT_DIR)/*.csv $(OUTPUT_DIR)/*.png $(OUTPUT_DIR)/*.html report_*.html

