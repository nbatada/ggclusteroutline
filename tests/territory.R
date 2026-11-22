library(ggclusteroutline)
d <- read.csv(system.file("extdata","pbmc700.csv",package="ggclusteroutline"))
span <- max(diff(range(d$x)),diff(range(d$y)))
profiles <- list(c(.035,.90,160,15.5959646248595),c(.012,.97,256,5.32549428642056))
for (s in profiles) {
  calc <- function(data,ids) compute_cluster_outlines(data,"x","y","leiden",clusters=ids,
    method="territory",bandwidth=s[1]*span,mass=s[2],grid_size=s[3],cache=FALSE)
  z <- calc(d,"4")
  all <- calc(d,NULL)
  stopifnot(identical(z$x,all$x[all$cluster=="4"]),identical(z$y,all$y[all$cluster=="4"]))
  set.seed(997)
  perm <- calc(d[sample(nrow(d)),],"4")
  stopifnot(identical(z$x,perm$x),identical(z$y,perm$y))
  area <- sum(vapply(split(z,z$path),function(p){
    j <- c(2:nrow(p),1L)
    abs(sum(p$x*p$y[j]-p$y*p$x[j]))/2
  },numeric(1)))
  stopifnot(abs(area-s[4])<1e-8)
}
# Equal absolute densities tie by sorted label; no minority band is fabricated.
g <- expand.grid(x=seq(-1,1,length.out=8),y=seq(-1,1,length.out=8))
mix <- rbind(transform(g,id="B"),transform(g,id="A"))
p <- suppressWarnings(compute_cluster_outlines(mix,"x","y","id",method="territory"))
stopifnot(identical(unique(p$cluster),"A"), attr(p,"diagnostics")$paths[1L]>0L,attr(p,"diagnostics")$paths[2L]==0L)

# Territory diagnostics count other labels under the same even--odd rule used
# for holes, independently checked with sp's point-in-polygon result.
set.seed(293)
a <- data.frame(x = rnorm(400, 0, .4), y = rnorm(400, 0, .4), id = "A")
overlap <- rbind(a, transform(a[seq_len(60L), ], x = x + .3, id = "B"))
territory <- suppressWarnings(compute_cluster_outlines(overlap, "x", "y", "id", clusters = "A",
                                                        method = "territory", cache = FALSE))
paths <- split(territory, territory$path)
other_inside <- Reduce(xor, lapply(paths, function(path) {
  sp::point.in.polygon(overlap$x[overlap$id == "B"], overlap$y[overlap$id == "B"], path$x, path$y) > 0L
}))
diagnostics <- attr(territory, "diagnostics")
stopifnot(diagnostics$status == "ok", diagnostics$other_points == sum(other_inside),
          diagnostics$assigned_points == 369L, diagnostics$other_points == 41L,
          attr(p,"diagnostics")$other_points[2L] == 0L)
