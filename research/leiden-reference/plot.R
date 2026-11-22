library(ggplot2)
library(patchwork)
out <- "research/leiden-reference"
file <- file.path(out,"cells.csv")
stopifnot(digest::digest(file=file,algo="sha256")==jsonlite::fromJSON(file.path(out,"source.json"))$cell_table_sha256)
d <- read.csv(file)
stopifnot(nrow(d)==700,!anyDuplicated(d$cell_id),all(is.finite(as.matrix(d[c("x","y","NKG7")]))))
d <- d[order(d$NKG7),]
# Only the supplied ID selects the geometry input. Exclude expression from that table.
target <- d[d$leiden==4,c("cell_id","x","y")]
stopifnot(nrow(target)==48)
h <- target[chull(target$x,target$y),]
xr <- extendrange(d$x,f=.09)
yr <- extendrange(d$y,f=.1)
ink <- "#BC460F"
pal <- c("0"="#476EA3","1"="#58967A","2"="#8C6DAD","3"="#B09044","4"=ink)
ref <- ggplot(d,aes(x,y)) + geom_point(aes(colour=factor(leiden)),size=1,stroke=0) +
  scale_colour_manual(values=pal,guide="none")
labels <- aggregate(cbind(x,y)~leiden,d,median)
# Duplicate the ID annotation at the second visible island; this only positions text.
labels <- rbind(labels, data.frame(leiden=4,x=1.1,y=-7.0))
labels$y <- labels$y+1.55
ref <- ref + geom_text(data=labels,aes(label=leiden),fontface="bold",size=4.5)
expr <- ggplot(d,aes(x,y)) + geom_point(aes(colour=NKG7),size=.96,stroke=0) +
  scale_colour_gradientn(colours=c("#C6CCD2","#ACBCDC","#6783BF","#3A3388","#200652"),
    name="NKG7 expression",guide=guide_colourbar(barwidth=8,barheight=.45))
panels <- list(ref,expr+geom_polygon(data=h,colour=ink,fill=NA,linewidth=.52),
  expr+ggforce::geom_mark_hull(data=target,expand=0,radius=0,colour=ink,fill=NA,linewidth=.52),
  expr+ggalt::geom_encircle(data=target,expand=0,spread=.03,colour=ink,fill=NA,size=1.47),
  expr+ggdensity::geom_hdr_lines(data=target,probs=.95,xlim=xr,ylim=yr,n=160,colour=ink,linewidth=.52,alpha=1))
theme_map <- theme_void(base_size=11)+theme(plot.title=element_text(size=12,face="bold",hjust=.5),
  plot.margin=margin(2,4,2,4))
titles <- c("Leiden cluster IDs","Convex hull","ggforce hull","ggalt encircle","ggdensity 95% HDR")
# Coordinate zoom crops the identical native plot. Preserve aspect ratio in the zoom so
# device-space hulls see the same ratio of x and y units.
full <- Map(function(p,t)p+coord_equal(xlim=xr,ylim=yr,expand=FALSE)+theme_map+ggtitle(t),panels,titles)
contour <- ggplot_build(full[[5]])$data[[2]]
rings <- split(contour,contour$group)
stopifnot(all(vapply(rings,function(r) max(abs(r[1,c("x","y")]-r[nrow(r),c("x","y")])) < 1e-7,logical(1))))
inside <- Reduce(xor,lapply(rings,function(r) sp::point.in.polygon(d$x,d$y,r$x,r$y)>0))
print(table(selected=d$leiden==4,inside=inside))
zoom <- lapply(panels,function(p)p+coord_equal(xlim=c(-2.2,8.2),ylim=c(-12.25,-4.2),expand=FALSE)+theme_map)
fig <- wrap_plots(c(full,zoom),ncol=5,guides="collect") +
 plot_annotation(title="Leiden cluster 4 occupies two islands on this UMAP",
 subtitle="Top: all 700 PBMCs. Bottom: the same region enlarged. Orange outlines use all 48 cells assigned to cluster 4.",
 theme=theme(plot.title=element_text(size=16,face="bold"))) & theme(legend.position="bottom")
for(ext in c("png","pdf","svg"))
 ggsave(file.path(out,paste0("leiden-comparison.",ext)),fig,width=13,height=5.9,dpi=180,bg="white")
