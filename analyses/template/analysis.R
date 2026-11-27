# data: the query result (record, element, value). Writes one CSV into out_dir.
analyse <- function(data, out_dir) {
  data$value <- as.numeric(data$value)
  summary <- do.call(rbind, lapply(split(data$value, data$element), function(v)
    data.frame(n = length(v), mean = mean(v), sd = if (length(v) > 1) stats::sd(v) else NA_real_)))
  summary <- cbind(element = rownames(summary), summary, row.names = NULL)
  path <- file.path(out_dir, "summary.csv")
  utils::write.csv(summary, path, row.names = FALSE)
  list(used_records = unique(data$record), files = path)
}
