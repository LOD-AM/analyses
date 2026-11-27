#!/usr/bin/env python3
"""Run a SPARQL query file on Turtle files and print the result as JSON (one object per row).

Usage: sparql.py <query.rq> <file.ttl> [file.ttl ...]
Python rdflib, the same engine as knowledge-graph's query tests, with full SPARQL 1.1
(property paths, aggregates). IRIs and literals become strings, numeric literals numbers,
unbound variables null. Called by R/query.R."""
import json
import sys
from decimal import Decimal

from rdflib import Graph, Literal

NUMERIC = (int, float, Decimal)


def value(term):
    if term is None:
        return None
    if isinstance(term, Literal):
        py = term.toPython()
        if isinstance(py, NUMERIC) and not isinstance(py, bool):
            return float(py) if isinstance(py, Decimal) else py
    return str(term)


def main(argv):
    if len(argv) < 2:
        sys.exit("usage: sparql.py <query.rq> <file.ttl> [file.ttl ...]")
    graph = Graph()
    for path in argv[1:]:
        graph.parse(path, format="turtle")
    with open(argv[0], encoding="utf-8") as f:
        result = graph.query(f.read())
    names = [str(v) for v in result.vars]
    rows = [{n: value(row[n]) for n in names} for row in result]
    json.dump({"vars": names, "rows": rows}, sys.stdout)


if __name__ == "__main__":
    main(sys.argv[1:])
