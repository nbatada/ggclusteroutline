# Run from the ggclusteroutline root. Executes only the existing CellStyle geometry.
src <- path.expand("~/git/cellstyle/r/cellstyle/R")
engine <- file.path(src,"cluster-outlines.R")
stopifnot(digest::digest(file=engine,algo="sha256")=="8e481b590cbef9fe37d08dbe8d5aa943e2fbd67bc53d5bc354d6b3d3397ccd34")
source(file.path(src,"style.R"))
source(engine)
d <- read.csv("research/leiden-reference/cells.csv")
stopifnot(nrow(d)==700,sum(d$leiden==4)==48)
span <- max(diff(range(d$x)),diff(range(d$y)))
settings <- data.frame(profile=c("CellStyle defaults","NSCLC settings"),h_fraction=c(.035,.012),
                       mass=c(.90,.97),grid=c(160L,256L))
for (i in seq_len(nrow(settings))) {
  s <- settings[i,]
  geometry <- function(selected=NULL) cluster_outlines(d,"x","y","leiden",clusters=selected,
    method="territory",bandwidth=span*s$h_fraction,mass=s$mass,grid_size=s$grid)
  all_paths <- geometry()
  selected <- geometry("4")
  ref <- subset(all_paths,cluster=="4")
  stopifnot(identical(ref$x,selected$x),identical(ref$y,selected$y))
  rings <- split(selected,selected$path)
  # Both rings are disjoint outer boundaries on this specific fixture.
  hits <- sapply(rings,function(p) sp::point.in.polygon(d$x,d$y,p$x,p$y)>0)
  stopifnot(ncol(hits)==2L,all(rowSums(hits)<=1L))
  inside <- rowSums(hits)>0
  area <- sum(vapply(rings,function(p) {
    j <- c(2:nrow(p),1L)
    abs(sum(p$x*p$y[j]-p$y*p$x[j]))/2
  },numeric(1)))
  settings[i,c("rings","member_centres","other_centres","area_umap2")] <-
    list(length(rings),sum(inside & d$leiden==4),sum(inside & d$leiden!=4),area)
}
write.csv(settings,"research/territory/pbmc-reference.csv",row.names=FALSE)
