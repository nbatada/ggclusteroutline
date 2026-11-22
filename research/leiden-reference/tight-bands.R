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
one <- transform(hull(g),band="all")
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
print(rbind(one=measure(one),two=measure(two)))
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
zoom <- ggplot(d,aes(x,y))+geom_point(colour="grey80",size=1.6)+
 geom_point(data=g,colour=ink,size=2)+coord_equal(xlim=c(-.1,6.1),ylim=c(-10.8,-5.8),expand=FALSE)+theme_map
band <- function(h) geom_polygon(data=h,aes(group=band),colour="#222F38",fill=NA,linewidth=.55)
fig <- wrap_plots(ref,zoom+labs(title="Cluster 4 membership",subtitle="Each orange point is an assigned cell"),
 zoom+band(one)+labs(title="One band",subtitle="All 48 cells together"),
 zoom+band(two)+labs(title="Two tight bands",subtitle="13 cells and 35 cells"),nrow=1)+
 plot_annotation(title="Which cells does the outline need to follow?",
 subtitle="The three close-ups show exactly the same cells and coordinates.",
 theme=theme(plot.title=element_text(size=17,face="bold")))
for(ext in c("png","pdf")) ggsave(file.path(out,paste0("tight-bands.",ext)),fig,width=12.8,height=3.75,dpi=180,bg="white")
