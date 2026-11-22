# Baseline: precompute a selected hull by supplied facet key, then reuse across colours.
library(ggplot2)
d <- palmerpenguins::penguins
d <- d[complete.cases(d[c("bill_length_mm","bill_depth_mm","species","island","body_mass_g","flipper_length_mm")]),]
chosen <- subset(d,species == "Adelie")
h <- do.call(rbind,lapply(split(chosen,chosen$island),function(g)
  g[chull(g$bill_length_mm,g$bill_depth_mm), ]))
layers <- function(measure) {
  p <- ggplot(d,aes(bill_length_mm,bill_depth_mm)) + facet_wrap(~island) +
    geom_point(aes(colour=.data[[measure]])) +
    geom_polygon(data=h, aes(group=species), colour="black", fill=NA)
  b <- ggplot_build(p)
  hull <- b$data[[2]][c("x","y","group","PANEL")]
  keys <- b$layout$layout[c("PANEL","island")]
  hull$island <- keys$island[match(hull$PANEL,keys$PANEL)]
  stopifnot(identical(as.character(hull$island),as.character(h$island)),
            identical(hull$x,h$bill_length_mm), identical(hull$y,h$bill_depth_mm))
  hull
}
mass <- layers("body_mass_g")
flipper <- layers("flipper_length_mm")
stopifnot(identical(mass,flipper), length(unique(mass$PANEL)) == 3L)
write.csv(mass,"research/field/reused-facet-vertices.csv",row.names=FALSE)
