analysis <- list(name = "template", label = "Test \"run\"", description = "A test.",
                 code = "analyses/template/analysis.R", query = "analyses/template/query.rq",
                 methods = c("Q7271028", "Q7266439"), software = "Q56805")
release <- list(version = "0.2.1", doi = "10.5281/zenodo.24469235", manifest_sha256 = strrep("a", 64))
project <- list(analyst = list(iri = "https://orcid.org/0000-0002-1825-0097", name = "Test Person"),
                repository = "https://github.com/LOD-AM/analyses")
records <- c("https://lod-am.net/id/analysis/00000000-0000-4000-8000-000000000002",
             "https://lod-am.net/id/analysis/00000000-0000-4000-8000-000000000001")
write <- function(...) write_run_record(analysis, records, "results/template/summary.csv", release = release,
  project = project, commit = strrep("1", 40), run_id = "11111111-2222-4333-8444-555555555555",
  ended = as.POSIXct("2026-11-27 16:00:00", tz = "UTC"), out_dir = tempfile(), ...)

test_that("the run record parses and names input, release, code, methods and software", {
  rec <- write()
  q <- function(s) {
    f <- tempfile(fileext = ".rq")
    writeLines(paste("PREFIX prov: <http://www.w3.org/ns/prov#>", "PREFIX dcterms: <http://purl.org/dc/terms/>", s), f)
    sparql(f, rec)
  }
  run <- "https://lod-am.net/id/run/11111111-2222-4333-8444-555555555555"
  expect_setequal(q("SELECT ?m WHERE { ?i prov:hadMember ?m }")$m, records)
  expect_equal(q("SELECT ?r WHERE { ?i prov:wasDerivedFrom ?r }")$r, "https://doi.org/10.5281/zenodo.24469235")
  expect_equal(q("SELECT ?h WHERE { ?r dcterms:identifier ?h }")$h, strrep("a", 64))
  plans <- q("SELECT ?p WHERE { ?a prov:hadPlan ?p }")$p
  expect_setequal(plans, c(paste0("https://github.com/LOD-AM/analyses/blob/", strrep("1", 40), "/analyses/template/analysis.R"),
                           "https://portal.mardi4nfdi.de/entity/Q7271028", "https://portal.mardi4nfdi.de/entity/Q7266439"))
  expect_equal(q("SELECT ?s WHERE { ?a prov:agent ?s . ?s a prov:SoftwareAgent }")$s, "https://portal.mardi4nfdi.de/entity/Q56805")
  expect_equal(q(sprintf("SELECT ?r WHERE { <%s> prov:generated ?r }", run))$r,
               "https://github.com/LOD-AM/analyses/blob/run-11111111-2222-4333-8444-555555555555/results/template/summary.csv")
  expect_equal(q("SELECT ?l WHERE { ?r <http://www.w3.org/2000/01/rdf-schema#label> ?l . FILTER(CONTAINS(STR(?l), 'Test')) }")$l, "Test \"run\"")
})

test_that("records outside LOD-AM, no records, no results and bad MaRDI ids are refused", {
  expect_error(write_run_record(analysis, "https://example.org/x", "r.csv", release = release, project = project,
                                commit = strrep("1", 40), out_dir = tempfile()), "not LOD-AM")
  expect_error(write_run_record(analysis, character(), "r.csv", release = release, project = project,
                                commit = strrep("1", 40), out_dir = tempfile()), "at least one record")
  expect_error(write_run_record(analysis, records, character(), release = release, project = project,
                                commit = strrep("1", 40), out_dir = tempfile()), "result file")
  expect_error(write_run_record(modifyList(analysis, list(methods = "7271028")), records, "r.csv", release = release,
                                project = project, commit = strrep("1", 40), out_dir = tempfile()), "MaRDI")
})

test_that("project.yml must name the analyst by ORCID iD", {
  p <- tempfile(fileext = ".yml")
  yaml::write_yaml(list(analyst = list(iri = "", name = "X"), repository = "r"), p)
  expect_error(read_project_config(p), "ORCID")
})
