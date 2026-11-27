# Run a SPARQL query file on the release files with Python rdflib (scripts/sparql.py): the same
# engine as knowledge-graph's query tests, with full SPARQL 1.1 (property paths, aggregates).
# No server is needed: the analysis reads exactly the files of the pinned release.

python <- function() Sys.getenv("LODAM_PYTHON", "python3")

sparql <- function(query_file, files) {
  script <- file.path(repo_root(), "scripts", "sparql.py")
  out <- tempfile(fileext = ".json")
  on.exit(unlink(out))
  status <- system2(python(), c("-I", shQuote(script), shQuote(query_file), shQuote(files)), stdout = out)
  if (!identical(status, 0L)) stop("SPARQL failed for ", query_file, " (see the message above)", call. = FALSE)
  res <- jsonlite::fromJSON(out, simplifyDataFrame = TRUE)
  if (length(res$rows) == 0) {
    return(as.data.frame(setNames(replicate(length(res$vars), character(), simplify = FALSE), res$vars)))
  }
  df <- as.data.frame(res$rows, stringsAsFactors = FALSE)
  df[setdiff(res$vars, names(df))] <- NA   # a variable unbound in every row
  df[res$vars]
}

run_query <- function(files, query_file) {
  res <- sparql(query_file, files)
  if (!"record" %in% names(res)) {
    stop(query_file, ": the query must return the analysed LOD-AM records as ?record", call. = FALSE)
  }
  res
}
