# Summary per context (Royal Tomb, Palace Hoard) and element of the reported mass fractions (wt %).
# Values: only measurements with a value. Not detected and upper limits are counted, never treated
# as 0 or as the limit. Finds without an analysis are not in the query result and not counted.
analyse <- function(data, out_dir) {
  data$value <- suppressWarnings(as.numeric(data$value))
  symbols <- element_symbols()
  stat <- function(f, v) if (length(v) > 0) signif(f(v), 6) else NA_real_
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
      mean = stat(mean, v),
      sd = if (length(v) > 1) signif(stats::sd(v), 6) else NA_real_,
      median = stat(stats::median, v),
      min = stat(min, v),
      max = stat(max, v)
    )
  })
  summary <- do.call(rbind, rows)
  if (anyNA(summary$symbol)) stop("an element is not in knowledge-graph tools/chebi.tsv", call. = FALSE)
  summary <- summary[order(summary$context, -summary$values, summary$symbol), ]
  path <- file.path(out_dir, "summary.csv")
  utils::write.csv(summary, path, row.names = FALSE, na = "")
  list(used_records = unique(data$record), files = path)
}
