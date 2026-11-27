# Load the release into one RDF graph and run a SPARQL query file on it (no server needed:
# the analysis reads exactly the files of the pinned release).

load_release <- function(files) {
  g <- rdflib::rdf()
  for (f in files) rdflib::rdf_parse(f, format = "turtle", rdf = g)
  g
}

run_query <- function(graph, query_file) {
  query <- paste(readLines(query_file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  res <- as.data.frame(rdflib::rdf_query(graph, query))
  if (!"record" %in% names(res)) {
    stop(query_file, ": the query must return the analysed LOD-AM records as ?record", call. = FALSE)
  }
  res
}
