library(ggclusteroutline)
d <- data.frame(x=c(0,1,1),y=c(0,0,1),id=c("a","a","a"))
f <- function(...) compute_cluster_outlines(d,"x","y","id",...)
for (args in list(list(mass=1),list(grid_size=25.3),list(grid_size=513),
                  list(clusters=c("a","a")),list(clusters="missing"),list(cache=NA),
                  list(bandwidth=Inf),list(component="absent"))) {
  stopifnot(inherits(try(do.call(f,args),silent=TRUE),"try-error"))
}
