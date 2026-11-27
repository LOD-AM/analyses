# Element symbols for ChEBI IRIs, from knowledge-graph tools/chebi.tsv (ids verified against ChEBI)
# at exactly the knowledge-graph commit the release was built with (its manifest names it).
element_symbols <- function(cfg = read_release_config(), dir = file.path("data", "release", cfg$version)) {
  manifest <- file.path(dir, "release-manifest.json")
  check_sha256(manifest, cfg$manifest_sha256, "release manifest")   # fetch_release() first
  commit <- jsonlite::read_json(manifest)$knowledge_graph$commit
  if (is.null(commit) || !grepl("^[0-9a-f]{40}$", commit)) stop("the release manifest names no knowledge-graph commit", call. = FALSE)
  dest <- file.path(dir, paste0("chebi-", commit, ".tsv"))
  if (!file.exists(dest)) {
    download_to(paste0("https://raw.githubusercontent.com/LOD-AM/knowledge-graph/", commit, "/tools/chebi.tsv"), dest)
  }
  t <- utils::read.delim(dest, header = FALSE, comment.char = "#", quote = "", col.names = c("id", "label", "symbol"),
                         colClasses = "character", encoding = "UTF-8")
  stats::setNames(t$symbol, paste0("http://purl.obolibrary.org/obo/", t$id))
}
