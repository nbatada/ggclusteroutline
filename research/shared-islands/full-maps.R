# From the repository root, with ggclusteroutline 0.1.0 installed.
library(ggplot2)
library(ggclusteroutline)
library(patchwork)
for (study in c("NSCLC","Yost")) {
  ns <- study=="NSCLC"
  tag <- if(ns) "nsclc-tnk-bands" else "yost-bcc-tcell-bands"
  ref <- file.path(path.expand("~/git/cellstyle/design_evidence"),tag)
  src <- jsonlite::fromJSON(file.path(ref,"source.json"))
  input <- file.path("/tmp",if(ns)"cs-nsclc-bands" else "cs-yost-full-bands","cells.csv.gz")
  expected <- if(ns) "70252cbb298755f47f9800fd801e6538b1460a94e3ca64fe96c36f100312dbf6" else src$scratch_output_sha256
  stopifnot(digest::digest(file=input,algo="sha256")==expected)
  d <- read.csv(input)
  if(ns) {
    xy <- rhdf5::h5read(src$source,"obsm/X_umap")
    stopifnot(ncol(xy)==nrow(d),max(abs(xy[1,]-d$x),abs(xy[2,]-d$y))<1e-5)
  } else {
    stopifnot(digest::digest(file=src$source_counts,algo="sha256")==src$source_counts_sha256,
              digest::digest(file=src$author_tcell_metadata,algo="sha256")==src$author_metadata_sha256)
  }
  ids <- sort(unique(d$leiden))
  d$id <- factor(d$leiden,levels=ids)
  hull <- read.csv(file.path(ref,"ggforce-paths.csv"))
  h <- if(ns) .2389929696 else .012*max(diff(range(d$x)),diff(range(d$y)))
  region <- compute_cluster_outlines(d,"x","y","id",method="territory",bandwidth=h,mass=.97,grid_size=256L)
  centres <- aggregate(cbind(x,y)~id,d,median)
  pal <- setNames(grDevices::hcl.colors(length(ids),"Dark 3"),ids)
  base <- ggplot(d,aes(x,y))+coord_equal(xlim=extendrange(c(d$x,hull$x,region$x),f=.025),
    ylim=extendrange(c(d$y,hull$y,region$y),f=.025),expand=FALSE)+
    scale_colour_manual(values=pal,guide="none")+theme_void(base_size=12)+
    theme(plot.title=element_text(face="bold"),plot.margin=margin(5,6,5,6))
  ps <- if(ns) .11 else .25
  a <- base+geom_point(aes(colour=id),size=ps,stroke=0)+
    ggrepel::geom_label_repel(data=centres,aes(label=id),size=2.6,seed=17,max.overlaps=Inf,
      fill="white",colour="#222222",label.padding=grid::unit(.07,"lines"),min.segment.length=0)+ggtitle("Leiden cluster IDs")
  outline <- function(paths,title) {
    base+geom_point(colour="grey85",size=ps,stroke=0)+
      geom_path(data=paths,aes(group=interaction(cluster,path),colour=factor(cluster)),linewidth=.48)+ggtitle(title)
  }
  fig <- wrap_plots(a,outline(hull,sprintf("ggforce · %d groups",length(unique(hull$cluster)))),
    outline(region,sprintf("ggclusteroutline territory · %d groups",length(unique(region$cluster)))),nrow=1)+
    plot_annotation(title=sprintf("%s · %s cells",study,format(nrow(d),big.mark=",")),
      subtitle="Full UMAP in every panel. Each band's colour matches its Leiden group on the left.")
  ggsave(file.path("research/shared-islands",paste0(study,".png")),fig,width=13,height=4.8,dpi=175,bg="white",device=ragg::agg_png)
}
