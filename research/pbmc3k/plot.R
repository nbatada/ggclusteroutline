# Run from the repository root in the M0 R environment.
library(rhdf5)
library(ggplot2)
library(patchwork)
out <- "research/pbmc3k"
args <- commandArgs(trailingOnly = TRUE)
source_file <- if (length(args)) args[[1]] else path.expand("~/bioinformatics_resources/datasets/scanpy/pbmc3k_processed.h5ad")
stopifnot(digest::digest(file=source_file,algo="sha256") == "0db367b991dd95809732b218539ede489bea99113807f62ebd7ccc970025fe38")
obs <- h5read(source_file,"obs")
umap <- t(h5read(source_file,"obsm",compoundAsDataFrame=FALSE)$X_umap)
labels <- as.vector(h5read(source_file,"uns/louvain_categories"))
genes <- as.vector(h5read(source_file,"raw.var")$index)
# Legacy AnnData stores raw.X as CSR with zero-based column indices.
ptr <- as.vector(h5read(source_file,"raw.X/indptr"))
values <- as.vector(h5read(source_file,"raw.X/data"))
indices <- as.vector(h5read(source_file,"raw.X/indices"))
gene <- "NKG7"
hit <- which(indices == match(gene,genes)-1L)
rows <- findInterval(hit-1L,ptr)
expr <- numeric(nrow(obs))
expr[rows] <- values[hit]
stopifnot(sum(genes==gene)==1L, length(hit)>0, !anyDuplicated(rows),
          all(is.finite(umap)), !anyDuplicated(obs$index), nrow(umap)==nrow(obs),
          length(labels)==8, all(obs$louvain %in% 0:7), length(ptr)==nrow(obs)+1L,
          tail(ptr,1)==length(indices),length(values)==length(indices),
          max(abs(expm1(values)-round(expm1(values))))<.001)
df <- data.frame(barcode=as.vector(obs$index), x=umap[,1], y=umap[,2],
                 cluster=labels[obs$louvain+1L],NKG7=expr)
df <- df[order(df$NKG7),] # Expressing cells remain visible under overplotting.
target <- subset(df,cluster=="CD8 T cells")
stopifnot(nrow(df)==2638,nrow(target)==316)
write.csv(df,file.path(out,"points.csv"),row.names=FALSE)

ink <- "#CD4E12"
xr <- extendrange(df$x,f=.06)
yr <- extendrange(df$y,f=.06)
base <- ggplot(df,aes(x,y)) +
  geom_point(aes(colour=NKG7),size=.82,stroke=0) +
  scale_colour_gradientn(colours=c("#C5CBD1","#A9B8D3","#637EB4","#39308A","#210753"),
                         name="NKG7   log(1 + count)", guide=guide_colourbar(barwidth=9,barheight=.52)) +
  coord_equal(xlim=xr,ylim=yr,expand=FALSE) + theme_void(base_size=11) +
  theme(plot.title=element_text(face="bold",size=12,hjust=.5),
        plot.margin=margin(6,4,3,4),legend.position="bottom")
convex <- target[chull(target$x,target$y),]
plots <- list(
  base + geom_polygon(data=convex,colour=ink,fill=NA,linewidth=.55) + ggtitle("Convex hull"),
  base + ggforce::geom_mark_hull(data=target,expand=0,radius=0,colour=ink,fill=NA,linewidth=.55) + ggtitle("ggforce hull"),
  base + ggalt::geom_encircle(data=target,expand=0,spread=.03,colour=ink,fill=NA,size=1.56) + ggtitle("ggalt encircle"),
  base + ggdensity::geom_hdr_lines(data=target,probs=.95,xlim=xr,ylim=yr,alpha=1,
                                   colour=ink,linewidth=.55) + ggtitle("ggdensity 95% HDR"))
contour <- ggplot_build(plots[[4]])$data[[2]]
rings <- split(contour,contour$group)
stopifnot(length(rings)>0,all(vapply(rings,function(r)
  max(abs(r[1,c("x","y")]-r[nrow(r),c("x","y")]))<1e-7,logical(1))))
inside <- Reduce(xor,lapply(rings,function(r)
  sp::point.in.polygon(df$x,df$y,r$x,r$y)>0))
print(table(selected=df$cluster=="CD8 T cells",inside_hdr=inside))
plate <- wrap_plots(plots,nrow=1,guides="collect") +
  plot_annotation(title="CD8 T cells on the PBMC3k UMAP",
                  subtitle="Colour shows NKG7 expression in all 2,638 cells. Orange outlines use the 316 cells labelled CD8 T cells.",
                  theme=theme(plot.title=element_text(face="bold",size=17))) &
  theme(legend.position="bottom")
for (ext in c("png","pdf"))
  ggsave(file.path(out,paste0("four-methods.",ext)),plate,width=13,height=3.95,dpi=180,bg="white")
