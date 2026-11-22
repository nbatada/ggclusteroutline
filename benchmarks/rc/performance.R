library(ggclusteroutline)
library(ggplot2)
options(device=function(...) grDevices::pdf(NULL))
args <- commandArgs(trailingOnly=TRUE)
n <- as.integer(args[1]); k <- as.integer(args[2]); method <- args[3]; scope <- args[4]
set.seed(193L+n+k)
g <- rep(seq_len(k),length.out=n)
d <- data.frame(x=(g-1L)%%ceiling(sqrt(k))*4+rnorm(n,sd=.45),
                y=(g-1L)%/%ceiling(sqrt(k))*4+rnorm(n,sd=.45),id=as.character(g))
# Include the point layer in build and draw. Use one shared 96 x 96 grid in all cases.
selected <- if(scope=="one") "1" else NULL
calc <- function() compute_cluster_outlines(d,"x","y","id",clusters=selected,method=method,grid_size=96L)
measure <- function(expr) unname(system.time(force(expr))[["elapsed"]])
cold <- measure(p <- calc())
warm <- measure(q <- calc())
stopifnot(identical(p,q))
base <- ggplot(d,aes(x,y))+geom_point(size=.1)+coord_equal()+theme_void()
build <- measure(b <- ggplot_build(base + geom_cluster_outline(data=p)))
draw <- measure({
  png(tempfile(fileext=".png"),width=720,height=720,type="cairo")
  grid::grid.draw(ggplot_gtable(b)); dev.off()
})
cat(paste(n,k,method,scope,cold,warm,build,draw,nrow(p),length(unique(p$cluster)),sep=","),"\n",sep="")
