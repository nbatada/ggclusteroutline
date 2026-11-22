# Run from the repository root. See README.md for data provenance.
library(ggplot2)
library(patchwork)
stopifnot(packageVersion("palmerpenguins") == "0.1.1")
out <- "research/field"
df <- palmerpenguins::penguins
df$row_id <- seq_len(nrow(df))
required <- c("bill_length_mm", "bill_depth_mm", "body_mass_g", "species")
shown <- df[complete.cases(df[required]), c("row_id", required)]
selected <- subset(shown, species == "Adelie")
stopifnot(nrow(df) == 344, nrow(shown) == 342, nrow(selected) == 151)
write.csv(shown, file.path(out, "measurements.csv"), row.names = FALSE)

# The same points and mass scale remain visible when the outline selects one species.
panel <- ggplot(shown, aes(bill_length_mm, bill_depth_mm)) +
  geom_point(aes(colour = body_mass_g), size = 1.05, alpha = .8) +
  scale_colour_viridis_c(name = "Body mass (g)", option = "C") +
  coord_cartesian(xlim = c(25, 62), ylim = c(12, 24), expand = FALSE) +
  labs(x = "Bill length (mm)", y = "Bill depth (mm)") +
  theme_classic(base_size = 9) + theme(plot.title = element_text(size = 10))
ink <- "#182B32"
geom_points <- selected[chull(selected$bill_length_mm, selected$bill_depth_mm), ]
convex <- panel + geom_polygon(data = geom_points, fill = NA, colour = ink, linewidth = .5)
force <- panel + ggforce::geom_mark_hull(data = selected, fill = NA, colour = ink,
                                         linewidth = .5)
density <- panel + ggdensity::geom_hdr_lines(data = selected, probs = .90, colour = ink, alpha = 1, show.legend = FALSE,
                                             xlim = c(23,65), ylim = c(10,25), linewidth = .5)
fig <- ((convex + ggtitle("All observations · convex hull")) |
        (force + ggtitle("ggforce · default padding")) |
        (density + ggtitle("ggdensity · 90% estimated mass"))) +
  plot_layout(guides = "collect") +
  plot_annotation(title = "Adélie penguins among three species",
                  subtitle = "Each panel shows the same 342 penguins. Only the 151 Adélie observations determine the outline.") &
  theme(legend.position = "bottom")
ggsave(file.path(out, "penguins.svg"), fig, width = 10.5, height = 3.85)
ggsave(file.path(out, "penguins.png"), fig, width = 10.5, height = 3.85, dpi = 145)
ggsave(file.path(out, "penguins.pdf"), fig, width = 10.5, height = 3.85, device = cairo_pdf)
writeLines(trimws(capture.output(sessionInfo()), which = "right"), file.path(out, "session.txt"))
