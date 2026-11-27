# Entry point of the unit tests: Rscript tests/testthat.R (from the repository root).
library(testthat)
test_dir("tests/testthat", stop_on_failure = TRUE)
