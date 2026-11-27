#!/usr/bin/env bash
# Check run records with LOD-AM/knowledge-graph's own tools: terms (PROV-O, MaRDI ids in
# tools/mardi.tsv, prefixes) and the SHACL shapes, together with the pinned release and the
# knowledge-graph vocabularies (as the triplestore serves them), so every
# analysed record must exist (and be typed) in that release.
# Usage: scripts/check_runs.sh <knowledge-graph checkout> [run.ttl ...]   (default: runs/*.ttl)
set -euo pipefail
kg=$(cd "${1:?usage: scripts/check_runs.sh <knowledge-graph checkout> [run.ttl ...]}" && pwd); shift
cd "$(dirname "$0")/.."
if [ $# -eq 0 ]; then
  shopt -s nullglob; set -- runs/*.ttl; shopt -u nullglob
  if [ $# -eq 0 ]; then echo "no run records in runs/; nothing to check"; exit 0; fi
fi
mapfile -t release < <(Rscript -e 'for (f in list.files("R", "[.]R$", full.names = TRUE)) source(f); writeLines(paste0("release-file:", fetch_release()))' 2>/dev/null | sed -n "s/^release-file://p")
[ ${#release[@]} -gt 0 ] || { echo "FAIL: could not fetch the release"; exit 1; }
python3 "$kg/tools/check_terms.py" "$@"
python3 "$kg/tools/validate.py" "$@" "${release[@]}" "$kg/data"   # data/: the vocabularies the release uses
