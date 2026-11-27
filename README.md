# LOD-AM analyses

Statistical analyses of the released data of [LOD-AM](https://lod-am.net) (Linked Open Data for
Ancient Metallurgy), in R. Every run is described in RDF (PROV-O) and becomes part of the LOD-AM
knowledge graph: which records it used, from which data release, with which code, methods and
software, and which results it produced. The model is in
[knowledge-graph `CONVENTIONS.md`](https://github.com/LOD-AM/knowledge-graph/blob/main/CONVENTIONS.md)
("Statistical analyses").

## How a run works
1. **The release is pinned** in `release.yml`: the version DOI of the website release on Zenodo and
   the sha256 of its manifest. The files are downloaded once into `data/` (not committed) and checked
   against the manifest on every run; a mismatch stops the run.
2. **An analysis** is a folder `analyses/<name>/`:
   - `analysis.yml`: label, description, the MaRDI methods it uses and the software (MaRDI ids)
   - `query.rq`: SPARQL 1.1 on the release; returns the analysed records as `?record`
   - `analysis.R`: defines `analyse(data, out_dir)`, writes its results into `out_dir` and returns
     `list(used_records = …, files = …)`. Only the records it really used count; records the code
     leaves out are documented by the query and the code, not in the record.
3. **A run** happens only for an analysis with `publish: true` in its `analysis.yml`, at a clean
   commit that is already pushed to this repository (`run.R` checks both):
   ```bash
   Rscript run.R <name> --dry-run     # try it out: results into a temporary folder, no record
   git push origin HEAD               # the code commit must be public first
   Rscript run.R <name>               # the real run: results/<name>/ and runs/<name>-<uuid>.ttl
   git add results/<name> runs/<name>-<uuid>.ttl
   git commit -m "Run <name> (<uuid>)"
   git tag run-<uuid> && git push origin HEAD run-<uuid>
   ```
   The record points to the code at the commit the run used, and to the results under the tag
   `run-<uuid>`. Merge pull requests with runs without squashing, so the tagged commit stays in `main`.
4. **A release** per published run, from its tag `run-<uuid>`: Zenodo archives it and mints a
   version DOI (LOD-AM/planning#54). The DOI is linked to the run afterwards; the run record itself
   never changes.

Copy `analyses/template/` for a new analysis (the template itself is never run).

## Drafts in the lab
Analyses are developed in the private repository `LOD-AM/analyses-lab`, a copy of this one (a
GitHub fork of a public repository would be public). There everything goes, `--dry-run` included.
An analysis that is meant for the knowledge graph comes here as a pull request with only its
folder (`analyses/<name>/`, plus helpers in `R/` it needs) and `publish: true`, so the lab's
history stays private. Real runs happen only here: `run.R` refuses a commit that is not on
`LOD-AM/analyses`, since the run record's code IRIs would not resolve.

## Setup
- R 4.3.3 and the packages in `renv.lock`: `Rscript -e 'renv::restore()'`.
- `libuv1-dev` (Debian/Ubuntu) for the R package `fs`.
- Python 3 with rdflib: `pip install --require-hashes -r requirements.txt`. Queries run in Python rdflib
  (`scripts/sparql.py`), the same engine and version as the knowledge-graph's query tests, so a query
  behaves here exactly as there (full SPARQL 1.1, property paths included).
- `project.yml`: the analyst's ORCID iD (the `prov:agent` of every run).

## Checks
- `Rscript tests/testthat.R`: unit tests (release check, queries, run records).
- `scripts/check_runs.sh <knowledge-graph checkout>`: every run record in `runs/` against the
  knowledge-graph's term checks and SHACL shapes, together with the pinned release and the
  knowledge-graph vocabularies, so an analysed record that is not in the release is rejected.
- CI (`.github/workflows/check.yml`) runs both, plus an end-to-end run of the template on the
  release (never committed).

## Licence
Code: MIT ([LICENSE](LICENSE)). Results in `results/` and run records in `runs/`: CC BY 4.0
([LICENSE-results.md](LICENSE-results.md)).
