library(ggclusteroutline)
d <- read.csv(system.file("extdata","pbmc700.csv",package="ggclusteroutline"))
clear_outline_cache()
f <- function(d, ...) compute_cluster_outlines(d,"x","y","leiden",clusters="4",method="territory", ...)
first <- f(d)
env <- getFromNamespace(".outline_cache","ggclusteroutline")
stopifnot(length(env$order)==1L)
d$NKG7 <- rev(d$NKG7)
stopifnot(identical(first,f(d)),length(env$order)==1L)
d$x[1] <- d$x[1]+.01
stopifnot(identical(f(d),f(d,cache=FALSE)),length(env$order)==2L)
d$leiden[1] <- 3
invisible(f(d))
invisible(f(d,mass=.92))
invisible(f(d,grid_size=96))
stopifnot(length(env$order)==5L)
for (i in 1:17) invisible(f(d,grid_size=32L+i))
stopifnot(length(env$order)==16L,sum(env$sizes)<=16*1024^2)
clear_outline_cache()
stopifnot(!length(env$order))
bad <- d
bad$leiden[1] <- NA
stopifnot(inherits(try(f(bad),silent=TRUE),"try-error"))
bad <- d
bad$x[1] <- Inf
stopifnot(inherits(try(f(bad),silent=TRUE),"try-error"))
