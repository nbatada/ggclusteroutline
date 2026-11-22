library(ggclusteroutline)
fit <- function(d,h=NULL) compute_cluster_outlines(d,"x","y","id",method="islands",bandwidth=h,cache=FALSE)
d <- read.csv(system.file("extdata","pbmc700.csv",package="ggclusteroutline"))
d$id <- d$leiden
p <- fit(d)
q <- subset(p,cluster=="4")
stopifnot(length(unique(q$component))==2,nrow(attr(p,"diagnostics"))==5,
          all(attr(p,"diagnostics")$unresolved_points==0L))
# Dense overlap is permitted; disconnected rare members and isolated points remain visible.
core <- expand.grid(x=c(0,.1,.2),y=c(0,.1,.2))
g <- rbind(transform(core,id="a"),transform(core,id="b"),
           data.frame(x=c(4,4.1,4.15,9),y=c(3.9,4.1,4,9),id="a"))
p <- fit(g,.4)
a <- subset(p,cluster=="a")
stopifnot(length(unique(a$component))==3,identical(sort(unique(a$type)),c("point","polygon")),
          all(attr(p,"diagnostics")$assigned_points==c(13,9)))
b <- subset(p,cluster=="b")
stopifnot(all(sp::point.in.polygon(core$x,core$y,b$x,b$y)>0))
set.seed(419)
shuffled <- fit(g[sample(nrow(g)),],.4)
cols <- c("cluster","component","x","y")
ordered <- function(z) {z<-z[do.call(order,z[cols]),cols];rownames(z)<-NULL;z}
stopifnot(identical(ordered(unique(p[cols])),ordered(unique(shuffled[cols]))))
