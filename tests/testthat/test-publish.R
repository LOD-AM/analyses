test_that("a real run needs publish: true", {
  expect_error(require_publishable(list(name = "x", publish = FALSE)), "publish: true")
  expect_error(require_publishable(list(name = "x")), "publish: true")
  expect_silent(require_publishable(list(name = "x", publish = TRUE)))
})

test_that("the template is not publishable, the Royal Tomb analysis is", {
  old <- setwd(root); on.exit(setwd(old))
  expect_false(read_analysis("template")$publish)
  expect_true(read_analysis("arslantepe-royal-tomb-palace-hoard")$publish)
})

test_that("remote URLs in https, ssh and .git forms are the same repository", {
  want <- normalize_remote("https://github.com/LOD-AM/analyses")
  for (u in c("https://github.com/LOD-AM/analyses.git", "git@github.com:LOD-AM/analyses.git",
              "ssh://git@github.com/LOD-AM/analyses", "https://github.com/lod-am/analyses/")) {
    expect_identical(normalize_remote(u), want)
  }
  expect_false(identical(normalize_remote("https://github.com/LOD-AM/analyses-lab"), want))
})

test_that("a commit counts as public only once it is pushed to the public repository", {
  skip_if(Sys.which("git") == "", "git not installed")
  tmp <- tempfile(); dir.create(tmp)
  public <- file.path(tmp, "public.git"); lab <- file.path(tmp, "lab.git"); work <- file.path(tmp, "work")
  git <- function(...) system2("git", c(...), stdout = FALSE, stderr = FALSE)
  git("init", "-q", "--bare", public); git("init", "-q", "--bare", lab)
  git("clone", "-q", lab, work)
  old <- setwd(work); on.exit(setwd(old))
  git("config", "user.email", "test@example.invalid"); git("config", "user.name", "Test")
  git("checkout", "-q", "-b", "main")
  writeLines("x", "f"); git("add", "f"); git("commit", "-q", "-m", "c1")
  commit <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)

  expect_error(require_public_commit(commit, public), "no git remote")       # only the lab: refused
  git("remote", "add", "public", public)
  expect_false(commit_is_public(commit, public))                             # not pushed yet
  expect_error(require_public_commit(commit, public), "push it first")
  git("push", "-q", "public", "main")
  expect_true(commit_is_public(commit, public))
  expect_silent(require_public_commit(commit, public))
})
