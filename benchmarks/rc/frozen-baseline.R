library(ggclusteroutline)
library(ggplot2)
options(device=function(...) grDevices::pdf(NULL))
args <- commandArgs(trailingOnly=TRUE)
method <- match.arg(args[1],c("package","base"))
set.seed(193)
g <- rep(1:100,each=1000)
d <- data.frame(x=g%%10*4+rnorm(1e5),y=g%/%10*4+rnorm(1e5),id=as.character(g),
                component="supplied")
t <- system.time({
  if(method=="package"){
    paths <- compute_cluster_outlines(d,"x","y","id",component="component",cache=FALSE)
    layer <- geom_cluster_outline(data=paths)
  } else {
    paths <- do.call(rbind,lapply(split(d,d$id),function(q) {
      h <- chull(q$x,q$y)
      q[c(h,h[1L]),]
    }))
    layer <- geom_path(data=paths,aes(group=id),linewidth=.5,colour="#C23B22")
  }
  p <- ggplot(d,aes(x,y))+geom_point(size=.1)+layer+coord_equal()+theme_void()
  png(tempfile(fileext=".png"),width=720,height=720,type="cairo")
  print(p)
  dev.off()
})
cat(t[["elapsed"]],"\n")
