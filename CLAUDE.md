# CLAUDE.md: LOD-AM analyses

**Public repo.** Statistical analyses (R) of LOD-AM's released data and their run records
(LOD-AM/planning#47). How a run is described: knowledge-graph `CONVENTIONS.md` "Statistical analyses";
how to work here: [README.md](README.md).

## Checks (CI `check.yml` runs all of them)
```bash
Rscript tests/testthat.R
scripts/check_runs.sh ../knowledge-graph                       # runs/*.ttl: knowledge-graph terms + shapes, with the release
out=$(mktemp -d); scripts/check_runs.sh ../knowledge-graph "$(Rscript tests/e2e_run_record.R "$out" | tail -1)"
scripts/check_shared_block.sh                                  # shared block vs knowledge-graph
```
`check_runs.sh` needs a knowledge-graph checkout after `make install` and `make fetch`. R packages: `renv`
(`renv::restore()`, system library `libuv1-dev`). Queries run in Python rdflib (`scripts/sparql.py`,
`pip install --require-hashes -r requirements.txt`): the same engine and version as knowledge-graph's tests,
with full SPARQL 1.1. R's `rdflib` (Redland) is not used: it cannot run property paths.

## Rules
- **Only released data.** Analyses read the pinned release (`release.yml`: Zenodo version DOI, manifest sha256),
  never the research database or the triplestore's current state. Every file is checked against the manifest.
  Changing the release is the owner's decision.
- **The research questions, methods and interpretations are the owner's.** Don't add or change an analysis
  without being asked; the `template` is an example and is never run.
- **Drafts live in the private `LOD-AM/analyses-lab`**; only analyses with `publish: true` in `analysis.yml` come
  here (owner, planning#54). Never push lab history to this repo: bring an analysis over as a fresh PR with its folder.
- **Run records are written by `run.R`, never by hand**, and only at a clean commit that is already pushed here
  (the record points to the code at that commit; `run.R` checks it and `publish: true`). Results go into `results/<analysis>/`, the record into `runs/`; both in one commit,
  tagged `run-<uuid>`. Never change a committed run's results or record: a new run gets a new record.
- MaRDI ids in `analysis.yml` must be in knowledge-graph `tools/mardi.tsv` first (`make verify-mardi` there);
  terms in queries follow knowledge-graph `CONVENTIONS.md` and its lookup rules (never invent a term).
- Versions are pinned: R and packages in `renv.lock`, Python rdflib in `requirements.txt` (with hashes), the release
  in `release.yml`.

## Where to resume (state 2026-11-27)
- First real analysis: `arslantepe-royal-tomb-palace-hoard` (owner's question, 2026-11-27): As, Sn, Pb, Ag, Sb
  per context, min/Q1/median/Q3/max/sd, on release 0.2.1. Its run should replace the all-zero commit in
  knowledge-graph's example (planning#47 step 2).
- Data (owner, 2026-11-27): copper-based objects have no copper values (expected); values such as 0.001 wt %
  are real values, not detection limits.
- Licences (owner, 2026-11-27): MIT for the code, CC BY 4.0 for results and run records. Analyst: the owner's ORCID iD.
- Releases (owner, planning#54): one GitHub release per published run, from its tag; Zenodo mints a version DOI.
  The link from run to DOI (an extra file next to the record, `dcterms:isPartOf` or `prov:alternateOf`) comes with
  the first DOI, together with knowledge-graph's conventions for it.

## LOD-AM project (shared block: keep identical in every repo)
Source of truth: knowledge-graph `CLAUDE.md`. Edit it there first, then copy it unchanged; CI (`scripts/check_shared_block.sh`) fails on drift.
LOD-AM = Linked Open Data for Ancient Metallurgy, a one-person research project (https://lod-am.net).
- `LOD-AM/knowledge-graph`: data model, vocabularies, converters, data. **Authority for all modelling rules** (`CONVENTIONS.md`).
- `LOD-AM/triplestore`: Apache Jena Fuseki (Docker) that serves the knowledge graph.
- `LOD-AM/ingest` (**private**): the owner's research database (dump), its checks and correction rounds; the database as a whole stays private until the owner says otherwise.
- `LOD-AM/pipeline`: the data pipeline, code only (database snapshot → R2RML/Ontop → enrichment → checks → released publications); runs on the data LXC, never with data on GitHub.
- `LOD-AM/extractor` (**private**): extracts analysis data from publications with local models on the owner's AI machine, as proposals for review that go into the research database (ingest).
- `LOD-AM/website`: Eleventy site and blog, self-hosted.
- `LOD-AM/planning` (**private**): project management for all repos: one issue per task, state in labels (see its README).
- `LOD-AM/ontologies`, `vocabularies`, `converter`: **superseded** by knowledge-graph; don't edit.

Rules for every repo:
- Base IRI `https://lod-am.net/id/`; CIDOC CRM **7.1.3**. Don't restate modelling rules elsewhere; link to knowledge-graph `CONVENTIONS.md`.
- Work on a branch and open a PR to `main`; never push to `main`. Create issues, PRs or comments only when asked.
- Domain/modelling decisions belong to the owner: raise them as `LOD-AM/planning` issues (label `modelling`) instead of deciding silently.
- Never commit secrets (passwords, SMTP credentials, `.env`, `shiro.ini`).
- English for code, docs and commits. Keep commits small and explain *why*.
- Verify before you claim: run the repo's checks and report what you ran.
- Open work lives in `LOD-AM/planning` (issues with `status:`/`area:` labels; keep them true);
  PRs reference it (`Closes LOD-AM/planning#<n>`). Each CLAUDE.md's "Where to resume" keeps only
  repo-specific notes. The owner merges PRs; after a merge, start new work from the updated `main`.
