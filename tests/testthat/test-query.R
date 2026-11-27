test_that("a query returns the analysed records as ?record", {
  q <- tempfile(fileext = ".rq")
  writeLines(readLines(file.path(root, "analyses", "template", "query.rq")), q)
  res <- run_query(fixture, q)
  expect_setequal(res$record, c("https://lod-am.net/id/analysis/00000000-0000-4000-8000-000000000001",
                                "https://lod-am.net/id/analysis/00000000-0000-4000-8000-000000000002"))
})

test_that("a query without ?record is refused", {
  q <- tempfile(fileext = ".rq")
  writeLines("SELECT ?s WHERE { ?s ?p ?o } LIMIT 1", q)
  expect_error(run_query(fixture, q), "[?]record")
})

test_that("the template analysis computes mean and sd and uses both records", {
  old <- setwd(root); on.exit(setwd(old))
  a <- read_analysis("template")
  out <- tempfile()
  res <- perform_analysis(a, fixture, out_dir = out)
  expect_length(res$used_records, 2)
  s <- utils::read.csv(res$files)
  expect_equal(s$mean, 93)
  expect_equal(s$sd, sd(c(90.5, 95.5)))
})

test_that("SPARQL 1.1 property paths work (Redland could not run them)", {
  q <- tempfile(fileext = ".rq")
  writeLines(c("PREFIX afx: <http://purl.allotrope.org/ontologies/property#>",
               "SELECT ?record ?e WHERE { ?record afx:AFX_0000395/afx:AFX_0002816 ?e }"), q)
  expect_equal(nrow(run_query(fixture, q)), 2)
})

test_that("numbers come back as numbers, unbound variables as NA", {
  q <- tempfile(fileext = ".rq")
  writeLines(c("PREFIX qudt: <http://qudt.org/schema/qudt#>",
               "SELECT ?record ?value ?none WHERE { ?m qudt:numericValue ?value . BIND(?m AS ?record) OPTIONAL { ?m <urn:x> ?none } }"), q)
  res <- run_query(fixture, q)
  expect_type(res$value, "double")
  expect_true(all(is.na(res$none)))
})
