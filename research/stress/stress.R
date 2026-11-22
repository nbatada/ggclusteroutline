# Additional M0 shape cases. Inputs and axis limits are shared across methods within each row.
library(ggplot2)
library(patchwork)
set.seed(11022)
out <- "research/stress"
cloud <- function(n, cx = 0, cy = 0, sx = .32, sy = sx, group = "A") {
  data.frame(x = rnorm(n,cx,sx), y = rnorm(n,cy,sy), group)
}
angle <- runif(150, 0, 2*pi)
radius <- sqrt(runif(150))
disk <- data.frame(x = radius*cos(angle), y = radius*sin(angle), group = "A")
ellipse <- transform(disk, y = y/3 + .35*x)
cases <- list(
  Disk = disk, Ellipse = ellipse,
  Dumbbell = rbind(cloud(90,-1),cloud(90,1),data.frame(x=seq(-1,1,length.out=22),y=rnorm(22,0,.04),group="A")),
  Adjacent = rbind(cloud(90,-.73), cloud(90,.73,group="B")),
  Overlap = rbind(cloud(90,-.16), cloud(90,.16,group="B")),
  Tail = rbind(cloud(150),data.frame(x=seq(.45,2.8,length.out=18),y=rnorm(18,0,.05),group="A")),
  Outliers = rbind(cloud(150),data.frame(x=c(-2,2.8),y=c(2.3,1),group="A")),
  `Unequal density` = rbind(cloud(135,-1.2),cloud(15,1.2,sx=.20)),
  `Anisotropic axes` = transform(ellipse,x=x*100)
)
all_points <- do.call(rbind,lapply(names(cases),function(k) transform(cases[[k]],case=k)))
write.csv(all_points,file.path(out,"points.csv"),row.names=FALSE)
make_row <- function(k) {
  d <- cases[[k]]
  limits <- function(x) extendrange(x, f = .23)
  xr <- limits(d$x)
  yr <- limits(d$y)
  h <- do.call(rbind,lapply(split(d,d$group),function(g) g[chull(g$x,g$y),]))
  common <- ggplot(d,aes(x,y,group=group,colour=group)) + geom_point(size=.75,alpha=.46) +
    scale_colour_manual(values=c(A="#2A688B",B="#B7521B")) +
    coord_cartesian(xlim=xr,ylim=yr,expand=FALSE) +
    theme_void(base_size=10) + theme(legend.position="none",plot.margin=margin(5,7,5,7))
  list(common + geom_polygon(data=h,fill=NA,linewidth=.5),
       common + ggforce::geom_mark_hull(expand=0,radius=0,fill=NA,linewidth=.5),
       common + ggdensity::geom_hdr_lines(probs=.90,xlim=xr,ylim=yr,alpha=1,linewidth=.5))
}
for (page in 1:3) {
  panels <- list()
  for (k in names(cases)[(page*3-2):(page*3)]) {
    row <- make_row(k)
    row[[1]] <- row[[1]] + ylab(k) + theme(axis.title.y=element_text(size=10,face="bold",angle=90))
    if (!length(panels)) {
      labels <- c("Convex hull","ggforce · zero padding","ggdensity · 90% mass")
      row <- Map(function(p,t) p+ggtitle(t), row, labels)
    }
    panels <- c(panels,row)
  }
  plate <- wrap_plots(panels,ncol=3) + plot_annotation(
    title="Outlines on shared coordinates",subtitle="Each row uses the same observations, colours and axis limits across methods.")
  for (ext in c("png","svg"))
    ggsave(file.path(out,sprintf("plate-%d.%s",page,ext)),plate,width=9,height=6.6,dpi=140,bg="white")
}
