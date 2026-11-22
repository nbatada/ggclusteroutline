# Reproduce the M1a gate and exercise the actual ggforce layer on the same full map.
library(ggclusteroutline)
library(ggplot2)
d <- read.csv(system.file("extdata","pbmc700.csv",package="ggclusteroutline"))
p <- compute_cluster_outlines(d,"x","y","leiden",clusters=4,method="tight")
m <- split(p,p$path)
in_ring <- sapply(m,function(r) sp::point.in.polygon(d$x,d$y,r$x,r$y)>0)
manual <- read.csv("research/leiden-reference/cells.csv")
target <- subset(manual,leiden==4)
area <- function(r) { j <- c(2:nrow(r),1L); abs(sum(r$x*r$y[j]-r$y*r$x[j]))/2 }
manual_area <- sum(vapply(split(target,target$x<3),function(r)area(r[chull(r$x,r$y),]),numeric(1)))
stopifnot(ncol(in_ring)==2,identical(rowSums(in_ring)>0,d$leiden==4),
          abs(sum(vapply(m,area,numeric(1)))-manual_area)<1e-8)
g <- ggplot(d,aes(x,y))+geom_point(size=.3)+
  ggforce::geom_mark_hull(data=subset(d,leiden==4),colour="#C23B22",
    fill=NA,expand=grid::unit(0,"mm"),radius=grid::unit(0,"mm"))+coord_equal()
svg <- tempfile(fileext=".svg")
ggsave(svg,g,width=4,height=4)
polys <- xml2::xml_find_all(xml2::read_xml(svg),"//*[local-name()='polygon' and contains(@style,'#C23B22')]")
stopifnot(length(polys)==1L)
cat("PBMC: two native rings; 48/48 selected; 0/652 others; area",manual_area,"; ggforce: one polygon\n")
