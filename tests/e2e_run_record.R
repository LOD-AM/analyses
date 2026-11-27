# End to end: run the template analysis on the pinned release and write a run record into the
# folder given as argument, with ORCID's example iD as analyst (CI checks it with
# scripts/check_runs.sh). Never commit what it writes.
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
out <- commandArgs(trailingOnly = TRUE)[[1]]
a <- read_analysis("template")
res <- perform_analysis(a, fetch_release(), out_dir = file.path(out, "results"))
project <- list(analyst = list(iri = "https://orcid.org/0000-0002-1825-0097", name = "Josiah Carberry"),
                repository = "https://github.com/LOD-AM/analyses")
path <- write_run_record(a, res$used_records, "results/template/summary.csv", project = project,
                         commit = strrep("0", 40), out_dir = out)
cat(path, "\n")
