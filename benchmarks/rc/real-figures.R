# Full-map visual validation. All cells are drawn; no zoom or resampling.
library(ggplot2)
library(ggclusteroutline)
library(patchwork)
settings <- list(Yost=c("cs-yost-full-bands","yost-bcc-tcell-bands","5","10"),
                 NSCLC=c("cs-nsclc-bands","nsclc-tnk-bands","6","7"))
for (name in names(settings)) {
  s <- settings[[name]]
  d <- read.csv(file.path("/tmp",s[1],"cells.csv.gz"))
  ids <- s[3:4]
  h <- if(name=="NSCLC") .2389929696 else .012*max(diff(range(d$x)),diff(range(d$y)))
  native <- compute_cluster_outlines(d,"x","y","leiden",clusters=ids,method="territory",
                                     bandwidth=h,mass=.97,grid_size=256L)
  directory <- file.path(Sys.getenv("CELLSTYLE",path.expand("~/git/cellstyle")),"design_evidence",s[2])
  ggforce <- read.csv(file.path(directory,"ggforce-paths.csv"))
  ggforce <- ggforce[ggforce$cluster %in% ids,]
  xlim <- extendrange(c(d$x,ggforce$x,native$x),f=.035)
  ylim <- extendrange(c(d$y,ggforce$y,native$y),f=.035)
  d$label <- factor(d$leiden,levels=sort(unique(d$leiden)))
  ink <- c("#BC460F","#294E96")
  palette <- setNames(grDevices::hcl.colors(nlevels(d$label),"Dark 3"),levels(d$label))
  palette[ids] <- ink
  centroids <- aggregate(cbind(x,y)~label,d,median)
  point_size <- if(name=="NSCLC") .10 else .20
  base <- ggplot(d,aes(x,y))+coord_equal(xlim=xlim,ylim=ylim,expand=FALSE)+theme_void(base_size=11)+
    theme(plot.title=element_text(face="bold",size=12),plot.margin=margin(6,6,5,6))
  ref <- base+geom_point(aes(colour=label),size=point_size,stroke=0,show.legend=FALSE)+
    scale_colour_manual(values=palette)+geom_label(data=centroids,aes(label=label),
      size=2.7,alpha=1,fill="white",colour="#151515",label.padding=grid::unit(.07,"lines"),linewidth=0)+ggtitle("Saved Leiden partition")
  neutral <- base+geom_point(size=point_size,stroke=0,colour="grey82")
  hull <- neutral
  territory <- neutral
  for(i in seq_along(ids)) {
    hull <- hull+geom_path(data=ggforce[ggforce$cluster==ids[i],],aes(group=path),colour=ink[i],linewidth=.55)
    territory <- territory+geom_cluster_outline(data=native,clusters=ids[i],colour=ink[i],linewidth=.55)
  }
  fig <- wrap_plots(ref,hull+ggtitle("ggforce hulls"),territory+ggtitle("Package territories"),nrow=1)+
    plot_annotation(title=sprintf("%s · %s cells",name,format(nrow(d),big.mark=",")),
                    subtitle=sprintf("Entire embedding in every panel. Orange: Leiden %s. Blue: Leiden %s.",ids[1],ids[2]))
  ggsave(file.path("benchmarks/rc",paste0(name,"-full-map.png")),fig,width=10,height=3.85,
         dpi=160,bg="white",device=ragg::agg_png)
}
