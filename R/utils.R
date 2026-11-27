`%||%` <- function(a, b) if (is.null(a)) b else a   # base R has it only from 4.4

# YAML files are UTF-8 whatever the locale (names, labels and comments may contain any character).
read_yaml_utf8 <- function(path) {
  yaml::yaml.load(paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n"))
}

# The repository root (where run.R is), also when called from tests/testthat.
repo_root <- function() {
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "run.R"))) {
    up <- dirname(d)
    if (identical(up, d)) stop("not inside the analyses repository", call. = FALSE)
    d <- up
  }
  d
}
