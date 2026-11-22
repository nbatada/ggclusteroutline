#!/usr/bin/env Rscript

library(ggplot2)
options(device = function(...) grDevices::pdf(NULL))
input <- read.csv("research/scaling/results/competitor_measurements.csv")
median_results <- aggregate(
  cbind(build_seconds, gtable_seconds, draw_seconds, total_seconds, outline_svg_path_like_elements, outline_svg_vertices) ~ method + n + groups,
  data = input,
  FUN = median
)
long <- rbind(
  transform(median_results, stage = "ggplot build", seconds = build_seconds),
  transform(median_results, stage = "gtable construction", seconds = gtable_seconds),
  transform(median_results, stage = "PNG draw", seconds = draw_seconds)
)
long$setting <- paste0("N=", format(long$n, big.mark = ","), ", K=", long$groups)
plot <- ggplot(long, aes(setting, seconds, fill = method)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  facet_wrap(~stage, scales = "free_y") +
  labs(x = NULL, y = "Median seconds across 3 runs", fill = NULL,
       title = "Bounded competitor timing on seeded synthetic Gaussian groups") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1), legend.position = "bottom")
ggsave("research/scaling/results/competitor_median_timing.png", plot, width = 10, height = 6, dpi = 180, device = ragg::agg_png)
ggsave("research/scaling/results/competitor_median_timing.svg", plot, width = 10, height = 6, device = svglite::svglite)
