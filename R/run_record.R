# Write the PROV-O description of one run (knowledge-graph CONVENTIONS.md "Statistical
# analyses"): the run used one collection of the records it actually used, taken from the
# pinned release; the analyst's association names the code at a commit and the MaRDI
# methods; each MaRDI software item has an association of its own.

LODAM <- "https://lod-am.net/id/"
MARDI <- "https://portal.mardi4nfdi.de/entity/"

read_project_config <- function(path = "project.yml") {
  p <- read_yaml_utf8(path)
  if (is.null(p$analyst$iri) || !grepl("^https://orcid[.]org/[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$", p$analyst$iri)) {
    stop("project.yml: analyst$iri must be the analyst's ORCID iD (https://orcid.org/…)", call. = FALSE)
  }
  if (is.null(p$analyst$name) || !nzchar(p$analyst$name)) stop("project.yml: analyst$name is missing", call. = FALSE)
  p
}

# The files a run depends on must be committed: the run record points to them at this commit.
git_commit <- function(paths = c("R", "analyses", "scripts", "release.yml", "project.yml", "renv.lock")) {
  dirty <- system2("git", c("status", "--porcelain", "--", paths), stdout = TRUE)
  if (length(dirty) > 0) {
    stop("uncommitted changes in the code or configuration; commit them first:\n", paste(dirty, collapse = "\n"), call. = FALSE)
  }
  commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
  if (!grepl("^[0-9a-f]{40}$", commit)) stop("not a git commit: ", commit, call. = FALSE)
  commit
}

ttl_string <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  paste0("\"", x, "\"")
}
iri <- function(x) paste0("<", x, ">")
mardi_qid <- function(q) {
  if (!grepl("^Q[0-9]+$", q)) stop("not a MaRDI item id: ", q, call. = FALSE)
  paste0("mardi:", q)
}

# analysis: list(name, label, description, code, query, methods, software) from analysis.yml;
# used_records: the LOD-AM IRIs the analysis actually used; results: result file paths
# (relative to the repository root). Returns the path of the Turtle file it wrote.
write_run_record <- function(analysis, used_records, results,
                             release = read_release_config(), project = read_project_config(),
                             commit = git_commit(), run_id = uuid::UUIDgenerate(),
                             ended = Sys.time(), out_dir = "runs") {
  used_records <- sort(unique(used_records))
  if (length(used_records) == 0) stop("a run must use at least one record", call. = FALSE)
  bad <- used_records[!startsWith(used_records, LODAM)]
  if (length(bad) > 0) stop("not LOD-AM records: ", paste(head(bad, 5), collapse = ", "), call. = FALSE)
  if (length(results) == 0) stop("a run must write at least one result file", call. = FALSE)
  if (length(analysis$software) == 0) stop(analysis$name, ": analysis.yml names no software (MaRDI id of R)", call. = FALSE)

  run <- paste0(LODAM, "run/", tolower(run_id))
  blob <- function(path, ref) paste0(project$repository, "/blob/", ref, "/", path)
  code <- blob(analysis$code, commit)
  query <- blob(analysis$query, commit)
  # Results are committed after the run, under the tag run-<uuid> (see README).
  result_iris <- vapply(results, blob, character(1), ref = paste0("run-", tolower(run_id)))
  software <- vapply(analysis$software, mardi_qid, character(1))
  methods <- vapply(analysis$methods %||% character(), mardi_qid, character(1))
  software_assoc <- paste0(run, "/software_", seq_along(software))
  stamp <- format(as.POSIXct(ended, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

  lines <- c(
    "@prefix prov:      <http://www.w3.org/ns/prov#> .",
    "@prefix dcterms:   <http://purl.org/dc/terms/> .",
    "@prefix rdfs:      <http://www.w3.org/2000/01/rdf-schema#> .",
    "@prefix foaf:      <http://xmlns.com/foaf/0.1/> .",
    "@prefix xsd:       <http://www.w3.org/2001/XMLSchema#> .",
    "@prefix mardi:     <https://portal.mardi4nfdi.de/entity/> .",
    "",
    sprintf("# Run of analyses/%s at commit %s (written by run.R).", analysis$name, commit),
    paste0(iri(run), " a prov:Activity ;"),
    paste0("    rdfs:label ", ttl_string(analysis$label), "@en ;"),
    if (!is.null(analysis$description)) paste0("    dcterms:description ", ttl_string(analysis$description), "@en ;"),
    paste0("    prov:used ", iri(paste0(run, "/input")), " ;"),
    paste0("    prov:generated ", paste(iri(result_iris), collapse = ", "), " ;"),
    paste0("    prov:wasAssociatedWith ", paste(c(iri(project$analyst$iri), software), collapse = ", "), " ;"),
    paste0("    prov:qualifiedAssociation ", paste(iri(c(paste0(run, "/association"), software_assoc)), collapse = ", "), " ;"),
    paste0("    prov:endedAtTime \"", stamp, "\"^^xsd:dateTime ."),
    "",
    paste0(iri(paste0(run, "/association")), " a prov:Association ;"),
    paste0("    prov:agent ", iri(project$analyst$iri), " ;"),
    paste0("    prov:hadPlan ", paste(c(iri(code), methods), collapse = ", "), " ."),
    paste0(iri(code), " a prov:Plan ."),
    if (length(methods)) paste0(methods, " a prov:Plan ."),
    paste0(iri(software_assoc), " a prov:Association ; prov:agent ", software, " ."),
    paste0(unique(software), " a prov:SoftwareAgent ."),
    paste0(iri(project$analyst$iri), " a foaf:Person ; foaf:name ", ttl_string(project$analyst$name), " ."),
    "",
    paste0(iri(paste0(run, "/input")), " a prov:Collection ;"),
    paste0("    prov:hadMember ", paste(iri(used_records), collapse = ",\n        "), " ;"),
    paste0("    prov:wasDerivedFrom ", iri(paste0("https://doi.org/", release$doi)), " ;"),
    paste0("    dcterms:source ", iri(query), " ."),
    paste0(iri(paste0("https://doi.org/", release$doi)), " a prov:Entity ;"),
    paste0("    rdfs:label ", ttl_string(paste("LOD-AM release", release$version)), "@en ;"),
    paste0("    dcterms:identifier ", ttl_string(release$manifest_sha256), " ."),
    paste0(iri(result_iris), " a prov:Entity .")
  )
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(out_dir, paste0(analysis$name, "-", tolower(run_id), ".ttl"))
  writeLines(lines, path, useBytes = TRUE)
  path
}
