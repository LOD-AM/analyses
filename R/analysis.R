# An analysis is a folder analyses/<name>/ with
#   analysis.yml  label, description, MaRDI methods and software (ids in knowledge-graph tools/mardi.tsv)
#   query.rq      SPARQL on the release; returns the analysed records as ?record
#   analysis.R    defines analyse(data, out_dir) -> list(used_records = <IRIs>, files = <paths>)

read_analysis <- function(name, dir = "analyses") {
  if (!grepl("^[a-z0-9][a-z0-9-]*$", name)) stop("analysis names are lower case with hyphens: ", name, call. = FALSE)
  base <- file.path(dir, name)
  a <- read_yaml_utf8(file.path(base, "analysis.yml"))
  a$name <- name
  a$code <- file.path(base, "analysis.R")
  a$query <- file.path(base, "query.rq")
  for (f in c(a$code, a$query)) if (!file.exists(f)) stop("missing ", f, call. = FALSE)
  if (is.null(a$label) || !nzchar(a$label)) stop(name, "/analysis.yml: `label` is missing", call. = FALSE)
  a$methods <- unlist(a$methods) %||% character()
  a$software <- unlist(a$software) %||% character()
  a
}

# Runs the query on the release files and the analysis on its result. Result files must be
# written into out_dir; used_records must come from the query result.
perform_analysis <- function(analysis, release_files, out_dir = file.path("results", analysis$name)) {
  env <- new.env()
  sys.source(analysis$code, envir = env)
  if (!is.function(env$analyse)) stop(analysis$code, " must define analyse(data, out_dir)", call. = FALSE)
  data <- run_query(load_release(release_files), analysis$query)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  res <- env$analyse(data, out_dir)
  stray <- setdiff(res$used_records, data$record)
  if (length(stray) > 0) stop("used_records not in the query result: ", paste(head(stray, 5), collapse = ", "), call. = FALSE)
  outside <- res$files[!startsWith(normalizePath(res$files), normalizePath(out_dir))]
  if (length(outside) > 0) stop("result files outside ", out_dir, ": ", paste(outside, collapse = ", "), call. = FALSE)
  res
}
