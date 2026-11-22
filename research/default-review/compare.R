# Run from the repository root with the audited 0.1.1 archive installed.
library(ggplot2)
library(ggclusteroutline)
stopifnot(packageVersion("ggclusteroutline") == "0.1.1")
out <- "research/default-review"
atlas <- function(name, expected, n) {
  file <- file.path("/tmp", name, "cells.csv.gz")
  stopifnot(digest::digest(file = file, algo = "sha256") == expected)
  d <- read.csv(file)
  stopifnot(nrow(d) == n, !anyDuplicated(d$cell_id))
  d
}
set.seed(293)
cloud <- data.frame(x=rnorm(400, 0, .4), y=rnorm(400, 0, .4), leiden="A")
pbmc <- read.csv(system.file("extdata", "pbmc700.csv", package="ggclusteroutline"))
studies <- list(
  PBMC=pbmc, Gaussian=cloud,
  Yost=atlas("cs-yost-full-bands","99e334048a079fd0c36c8e4ea099352558adba191589ad4fa50a31857f8506af",33106L),
  NSCLC=atlas("cs-nsclc-bands","70252cbb298755f47f9800fd801e6538b1460a94e3ca64fe96c36f100312dbf6",622791L)
)
metrics <- list()
png(file.path(out,"default-comparison.png"), width=1800,height=1740,res=135,type="cairo")
grid::grid.newpage()
grid::pushViewport(grid::viewport(layout=grid::grid.layout(4,4)))
for (i in seq_along(studies)) {
  d <- studies[[i]]
  name <- names(studies)[i]
  ids <- if(name=="PBMC") "4" else NULL
  labels <- if(is.null(ids)) length(unique(d$leiden)) else length(ids)
  p <- ggplot(d,aes(x,y)) + coord_equal() + theme_void(base_size=11) +
    theme(plot.margin=margin(8,6,4,6),plot.title=element_text(face="bold"))
  size <- if(nrow(d)>10000) .16 else .9
  ref <- p + geom_point(aes(colour=factor(leiden)),size=size,stroke=0,show.legend=FALSE) +
    labs(title=name,subtitle=paste(format(nrow(d),big.mark=","),"points  |",if(is.null(ids)) "all groups" else "outline group 4"))
  if(name %in% c("PBMC","Yost","NSCLC")){
    centres <- aggregate(cbind(x,y)~leiden,d,median)
    ref <- ref + geom_text(data=centres,aes(label=leiden),size=2.8,fontface="bold")
  }
  print(ref,vp=grid::viewport(layout.pos.row=i,layout.pos.col=1))
  methods <- c("tight","islands","territory")
  for(j in seq_along(methods)){
    method <- methods[j]
    band <- if(method=="territory") geom_cluster_outline(aes(group=leiden),clusters=ids) else
      geom_cluster_outline(aes(group=leiden),clusters=ids,method=method)
    plot <- p + geom_point(colour="grey78",size=size,stroke=0) + band
    g <- suppressWarnings(ggplot_build(plot))
    stopifnot(nrow(g$data[[1]])==nrow(d))
    o <- g$data[[2]]
    drawn <- length(unique(o$cluster))
    paths <- length(unique(o$group))
    metrics[[length(metrics)+1L]] <- data.frame(study=name,method,requested=labels,drawn,paths,
      polygons=length(unique(o$group[o$outline_type=="polygon"])),
      segments=length(unique(o$group[o$outline_type=="segment"])),
      singletons=length(unique(o$group[o$outline_type=="point"])))
    plot <- plot + labs(title=method,subtitle=sprintf("%d/%d groups  |  %d paths",drawn,labels,paths))
    suppressWarnings(print(plot,vp=grid::viewport(layout.pos.row=i,layout.pos.col=j+1)))
  }
}
dev.off()
write.csv(do.call(rbind,metrics),file.path(out,"counts.csv"),row.names=FALSE)
