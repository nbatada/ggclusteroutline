# Same input and axis ranges. Only the physical aspect ratio changes.
library(ggplot2)
set.seed(11)
points <- data.frame(x = rnorm(100), y = rnorm(100))
rectangle <- ggplot(points, aes(x, y)) + theme_void() +
  scale_x_continuous(limits = c(-4,4), expand = c(0,0)) +
  scale_y_continuous(limits = c(-4,4), expand = c(0,0))
hull <- points[chull(points$x, points$y), ]
plots <- list(ggforce = rectangle + ggforce::geom_mark_hull(colour = "#A93466", fill = NA, expand = 0, radius = 0),
              convex = rectangle + geom_polygon(data = hull, colour = "#A93466", fill = NA))
rows <- list()
for (method in names(plots)) {
  for (width in c(4,8)) {
    file <- sprintf("research/device/%s-%dx4.svg", method, width)
    ggsave(file, plots[[method]], width = width, height = 4)
    xml <- xml2::read_xml(file)
    polygon <- xml2::xml_find_all(xml, "//*[local-name()='polygon' and contains(@style,'#A93466')]")
    stopifnot(length(polygon) == 1L)
    pairs <- strsplit(trimws(xml2::xml_attr(polygon,"points")), " +")[[1]]
    coords <- matrix(as.numeric(unlist(strsplit(pairs, ","))), ncol = 2, byrow = TRUE)
    rows[[length(rows)+1L]] <- data.frame(method, width_in = width, vertex = seq_len(nrow(coords)),
                                         x_panel = coords[,1]/(width*72), y_panel = 1-coords[,2]/(4*72))
  }
}
write.csv(do.call(rbind, rows), "research/device/vertices.csv", row.names = FALSE)
