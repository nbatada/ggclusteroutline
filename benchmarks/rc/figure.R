# README figure: both panels show the complete, identically scaled embedding.
library(ggclusteroutline)
library(ggplot2)
library(patchwork)
d <- read.csv(system.file("extdata","pbmc700.csv",package="ggclusteroutline"))
labels <- aggregate(cbind(x,y)~leiden,d,median)
# Repeat the text label at the second island. This annotation is never an engine input.
labels <- rbind(labels,data.frame(leiden=4,x=1.1,y=-7))
labels$y <- labels$y+1.5
pal <- c("0"="#4A77A4","1"="#589777","2"="#8C72AA","3"="#AD8D3D","4"="#B84718")
common <- theme_void(base_size=11)+theme(plot.title=element_text(face="bold",size=13),
  plot.margin=margin(8,9,4,9))
p <- ggplot(d,aes(x,y))+geom_point(aes(colour=factor(leiden)),size=1,stroke=0)+
  scale_colour_manual(values=pal,guide="none")+geom_text(data=labels,aes(label=leiden),fontface="bold")+
  coord_equal()+labs(title="Saved Leiden IDs",subtitle="Full UMAP · 700 cells")+common
q <- ggplot(d[order(d$NKG7),],aes(x,y))+geom_point(aes(colour=NKG7),size=1.2,stroke=0)+
  scale_colour_gradientn(colours=c("#C6CCD2","#A5B6D9","#667EBA","#453E92","#240F5A"),
                         guide=guide_colourbar(barwidth=6,barheight=.45))+
  geom_cluster_outline(aes(group=leiden),clusters=4,colour="#B84718",linewidth=.55)+
  coord_equal()+labs(title="NKG7 expression",subtitle="Automatic tight bands · Leiden 4")+common
b <- ggplot_build(q)
stopifnot(nrow(b$data[[1]])==700,length(unique(b$data[[2]]$group))==2)
fig <- wrap_plots(p,q,guides="collect")&theme(legend.position="bottom")
ggsave("man/figures/pbmc700.png",fig,width=9,height=4.55,dpi=180,bg="white")
ggsave("benchmarks/rc/pbmc700.pdf",fig,width=9,height=4.55,bg="white")
