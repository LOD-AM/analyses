# Summary per context (Royal Tomb, Palace Hoard) and element (As, Sn, Pb, Ag, Sb, selected in the
# query) of the reported mass fractions (wt %): minimum, quartiles (R's quantile() type 7), median,
# maximum and standard deviation. Values: only measurements with a value. Not detected and upper
# limits are counted, never treated as 0 or as the limit. Finds without an analysis are not in the
# query result and not counted.
analyse <- function(data, out_dir) {
  data$value <- suppressWarnings(as.numeric(data$value))
  symbols <- element_symbols()
  q <- function(v, p) if (length(v) > 0) signif(unname(stats::quantile(v, p, type = 7)), 6) else NA_real_
  groups <- split(data, list(data$context, data$element), drop = TRUE)
  rows <- lapply(groups, function(g) {
    v <- g$value[!is.na(g$value)]
    data.frame(
      context = g$context[1],
      element = g$element[1],
      symbol = unname(symbols[g$element[1]]),
      analyses = length(unique(g$record)),
      values = length(v),
      not_detected = sum(!is.na(g$status) & endsWith(g$status, "/not_detected")),
      upper_limits = sum(!is.na(g$max)),
      min = q(v, 0),
      q1 = q(v, 0.25),
      median = q(v, 0.5),
      q3 = q(v, 0.75),
      max = q(v, 1),
      sd = if (length(v) > 1) signif(stats::sd(v), 6) else NA_real_
    )
  })
  summary <- do.call(rbind, rows)
  if (anyNA(summary$symbol)) stop("an element is not in knowledge-graph tools/chebi.tsv", call. = FALSE)
  order_symbols <- c("As", "Sn", "Pb", "Ag", "Sb")
  summary <- summary[order(summary$context, match(summary$symbol, order_symbols)), ]
  path <- file.path(out_dir, "summary.csv")
  utils::write.csv(summary, path, row.names = FALSE, na = "")
  list(used_records = unique(data$record), files = path)
}
