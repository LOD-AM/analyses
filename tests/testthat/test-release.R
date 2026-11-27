test_that("a file with the wrong sha256 stops the run and is removed", {
  f <- tempfile(); writeLines("x", f)
  expect_error(check_sha256(f, strrep("0", 64), "test file"), "sha256")
  expect_false(file.exists(f))
})

test_that("a matching file passes", {
  f <- tempfile(); writeLines("x", f)
  expect_silent(check_sha256(f, digest::digest(file = f, algo = "sha256")))
})

test_that("release.yml needs a Zenodo version DOI and a 64-hex manifest hash", {
  good <- list(version = "0.2.1", doi = "10.5281/zenodo.24469235", manifest_sha256 = strrep("a", 64), source = "https://x")
  write <- function(cfg) { p <- tempfile(fileext = ".yml"); yaml::write_yaml(cfg, p); p }
  expect_equal(read_release_config(write(good))$version, "0.2.1")
  expect_error(read_release_config(write(modifyList(good, list(doi = "10.1234/x")))), "Zenodo")
  expect_error(read_release_config(write(modifyList(good, list(manifest_sha256 = "abc")))), "64 hex")
  expect_error(read_release_config(write(good[-2])), "doi")
})

test_that("the pinned release.yml is valid", {
  expect_silent(read_release_config(file.path(root, "release.yml")))
})
