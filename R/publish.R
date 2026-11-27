# Safeguards for real runs (owner, LOD-AM/planning#54): drafts live in the private lab
# (LOD-AM/analyses-lab); only analyses meant for the knowledge graph are published here.
#   1. analysis.yml says `publish: true` (otherwise only --dry-run works);
#   2. the code commit is already on the public repository (project.yml `repository`), so the
#      code IRIs of the run record resolve, and a run from the lab is refused.

require_publishable <- function(analysis) {
  if (!isTRUE(analysis$publish)) {
    stop(analysis$name, ": analysis.yml has no `publish: true`; without it only `--dry-run` works", call. = FALSE)
  }
  invisible(TRUE)
}

# "https://github.com/LOD-AM/analyses", "git@github.com:LOD-AM/analyses.git", ".../analyses/" -> one form
normalize_remote <- function(url) {
  u <- sub("/+$", "", sub("[.]git$", "", trimws(url)))
  u <- sub("^git@github[.]com:", "https://github.com/", u)
  u <- sub("^ssh://git@github[.]com/", "https://github.com/", u)
  tolower(u)
}

# The name of the git remote that points to `repository`, or NULL.
public_remote <- function(repository) {
  for (r in system2("git", "remote", stdout = TRUE)) {
    url <- system2("git", c("remote", "get-url", r), stdout = TRUE)
    if (identical(normalize_remote(url), normalize_remote(repository))) return(r)
  }
  NULL
}

commit_is_public <- function(commit, repository, fetch = TRUE) {
  remote <- public_remote(repository)
  if (is.null(remote)) {
    stop("no git remote points to ", repository, ": real runs happen only in the public repository ",
         "(README \"Drafts in the lab\")", call. = FALSE)
  }
  if (fetch && !identical(system2("git", c("fetch", "--quiet", remote)), 0L)) {
    stop("git fetch ", remote, " failed; cannot check that the commit is public", call. = FALSE)
  }
  hits <- system2("git", c("branch", "-r", "--contains", commit, "--list", shQuote(paste0(remote, "/*"))), stdout = TRUE)
  length(hits) > 0
}

require_public_commit <- function(commit, repository, fetch = TRUE) {
  if (!commit_is_public(commit, repository, fetch = fetch)) {
    stop("commit ", substr(commit, 1, 7), " is not on ", repository, " yet: push it first, so the run record's ",
         "code IRIs resolve", call. = FALSE)
  }
  invisible(TRUE)
}
