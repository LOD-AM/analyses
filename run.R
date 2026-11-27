#!/usr/bin/env Rscript
# Run one analysis on the pinned release and write its run record.
#   Rscript run.R <analysis>            a real run: needs `publish: true` and the code committed and pushed
#                                       to the public repository; writes runs/<analysis>-<uuid>.ttl
#   Rscript run.R <analysis> --dry-run  try it out: results into a temporary folder, no run record
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("usage: Rscript run.R <analysis> [--dry-run]", call. = FALSE)
dry <- "--dry-run" %in% args
analysis <- read_analysis(args[[1]])

if (dry) {
  out <- file.path(tempdir(), analysis$name)
  res <- perform_analysis(analysis, fetch_release(), out_dir = out)
  print(utils::head(utils::read.csv(res$files[[1]]), 5))
  message("dry run: ", length(res$used_records), " records used; results in ", out)
  quit(status = 0)
}

project <- read_project_config()
require_publishable(analysis)               # publish: true in analysis.yml
commit <- git_commit()                      # before computing: the run belongs to this commit
require_public_commit(commit, project$repository)   # pushed to the public repository
release <- read_release_config()
res <- perform_analysis(analysis, fetch_release(release))
run_id <- uuid::UUIDgenerate()
record <- write_run_record(analysis, res$used_records, res$files, release = release,
                           project = project, commit = commit, run_id = run_id)
tag <- paste0("run-", run_id)
message("wrote ", record, " (", length(res$used_records), " records, ", length(res$files), " result files)\n",
        "next: git add ", file.path("results", analysis$name), " ", record, "\n",
        "      git commit -m \"Run ", analysis$name, " (", run_id, ")\"\n",
        "      git tag ", tag, " && git push origin HEAD ", tag)
