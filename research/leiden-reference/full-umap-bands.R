library(ggplot2)
library(patchwork)
out <- "research/leiden-reference"
file <- file.path(out,"cells.csv")
stopifnot(digest::digest(file=file,algo="sha256")==jsonlite::fromJSON(file.path(out,"source.json"))$cell_table_sha256)
d <- read.csv(file)
g <- subset(d,leiden==4,select=c(cell_id,x,y))
# The vertical cut lies within the observed empty interval for this example.
island <- ifelse(g$x < 3,"left","right")
stopifnot(identical(as.integer(table(island)),c(13L,35L)),nrow(d)==700,!anyDuplicated(d$cell_id))
hull <- function(p) p[chull(p$x,p$y),]
two <- do.call(rbind,lapply(split(transform(g,band=island),island),hull))
measure <- function(h) {
  pieces <- split(h,h$band)
  inside <- Reduce("|",lapply(pieces,function(q) sp::point.in.polygon(d$x,d$y,q$x,q$y)>0))
  area <- sum(vapply(pieces,function(q) {
    i <- c(2:nrow(q),1)
    abs(sum(q$x*q$y[i]-q$y*q$x[i]))/2
  },numeric(1)))
  c(members=sum(inside & d$leiden==4), others=sum(inside & d$leiden!=4),area=area)
}
stopifnot(measure(two)["members"]==48, measure(two)["others"]==0)
ink <- "#B84718"
pal <- c("0"="#4A77A4","1"="#589777","2"="#8C72AA","3"="#AD8D3D","4"=ink)
labs <- aggregate(cbind(x,y)~leiden,d,median)
labs <- rbind(labs,data.frame(leiden=4,x=1.1,y=-7))
labs$y <- labs$y+1.5
theme_map <- theme_void(base_size=11)+theme(plot.title=element_text(face="bold",size=12),
 plot.subtitle=element_text(size=10),plot.margin=margin(6,8,4,8))
ref <- ggplot(d,aes(x,y))+geom_point(aes(colour=factor(leiden)),size=1,stroke=0)+
 scale_colour_manual(values=pal,guide="none")+geom_text(data=labs,aes(label=leiden),fontface="bold")+
 coord_equal()+labs(title="Saved Leiden IDs",subtitle="Full UMAP · 700 cells")+theme_map

expression_map <- ggplot(d[order(d$NKG7),],aes(x,y)) +
 geom_point(aes(colour=NKG7),size=1.2,stroke=0) +
 scale_colour_gradientn(colours=c("#C6CCD2","#A5B6D9","#667EBA","#453E92","#240F5A"),
   name="NKG7 expression",guide=guide_colourbar(barwidth=6,barheight=.45)) +
 geom_polygon(data=two,aes(group=band),colour=ink,fill=NA,linewidth=.55) +
 coord_equal() + labs(title="NKG7 expression",subtitle="Two tight bands around Leiden 4") + theme_map
b <- ggplot_build(ref)
e <- ggplot_build(expression_map)
stopifnot(nrow(b$data[[1]])==700,nrow(e$data[[1]])==700,
          identical(b$layout$panel_params[[1]]$x.range,e$layout$panel_params[[1]]$x.range),
          identical(b$layout$panel_params[[1]]$y.range,e$layout$panel_params[[1]]$y.range))
fig <- wrap_plots(ref,expression_map,nrow=1,guides="collect") &
 theme(legend.position="bottom")
for(ext in c("png","pdf")) ggsave(file.path(out,paste0("full-umap-bands.",ext)),fig,width=9,height=4.55,dpi=180,bg="white")
