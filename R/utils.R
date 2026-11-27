`%||%` <- function(a, b) if (is.null(a)) b else a   # base R has it only from 4.4

# YAML files are UTF-8 whatever the locale (names, labels and comments may contain any character).
read_yaml_utf8 <- function(path) {
  yaml::yaml.load(paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n"))
}
