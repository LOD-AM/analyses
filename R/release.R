# Fetch the pinned data release (release.yml) and check every file against its manifest.
# Nothing is read that does not match: a wrong or changed file stops the run.

read_release_config <- function(path = "release.yml") {
  cfg <- read_yaml_utf8(path)
  for (key in c("version", "doi", "manifest_sha256", "source")) {
    if (is.null(cfg[[key]]) || !nzchar(cfg[[key]])) stop("release.yml: `", key, "` is missing", call. = FALSE)
  }
  if (!grepl("^10[.]5281/zenodo[.][0-9]+$", cfg$doi)) stop("release.yml: `doi` must be a Zenodo version DOI (10.5281/zenodo.<n>)", call. = FALSE)
  if (!grepl("^[0-9a-f]{64}$", cfg$manifest_sha256)) stop("release.yml: `manifest_sha256` must be 64 hex characters", call. = FALSE)
  cfg
}

check_sha256 <- function(path, want, what = basename(path)) {
  got <- digest::digest(file = path, algo = "sha256")
  if (!identical(got, want)) {
    unlink(path)
    stop(sprintf("%s: sha256 is %s, expected %s; the file was removed", what, got, want), call. = FALSE)
  }
  invisible(path)
}

download_to <- function(url, dest) {
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  part <- paste0(dest, ".part")
  on.exit(unlink(part))
  utils::download.file(url, part, mode = "wb", quiet = TRUE)
  file.rename(part, dest)
  invisible(dest)
}

# Returns the paths of the release's data files (Turtle), downloaded once into `dir` and
# checked on every call.
fetch_release <- function(cfg = read_release_config(), dir = file.path("data", "release", cfg$version)) {
  manifest <- file.path(dir, "release-manifest.json")
  if (!file.exists(manifest)) download_to(paste0(cfg$source, "/release-manifest.json"), manifest)
  check_sha256(manifest, cfg$manifest_sha256, "release manifest")
  m <- jsonlite::read_json(manifest)
  files <- vapply(m$publications$files, function(f) {
    dest <- file.path(dir, f$file)
    if (!file.exists(dest)) download_to(paste0(cfg$source, "/", f$file), dest)
    check_sha256(dest, f$sha256, f$file)
    dest
  }, character(1))
  if (length(files) == 0) stop("the release manifest lists no data files", call. = FALSE)
  files
}
