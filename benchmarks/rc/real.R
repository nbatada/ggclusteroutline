# Replay on the exact CellStyle inputs. Only aggregate measurements are exported.
library(ggclusteroutline)
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==4L)
dataset <- match.arg(args[1],c("Yost","NSCLC"))
source_file <- args[2]
reference_dir <- args[3]
out <- args[4]
expected <- c(NSCLC="70252cbb298755f47f9800fd801e6538b1460a94e3ca64fe96c36f100312dbf6",
              Yost="99e334048a079fd0c36c8e4ea099352558adba191589ad4fa50a31857f8506af")
stopifnot(digest::digest(file=source_file,algo="sha256")==expected[[dataset]])
d <- read.csv(source_file)
stopifnot(!anyDuplicated(d$cell_id),nrow(d)==if(dataset=="Yost") 33106L else 622791L)
h <- .012*max(diff(range(d$x)),diff(range(d$y)))
# NSCLC's stored profile explicitly rounded the original float span.
if(dataset=="NSCLC") h <- 0.2389929696
compute <- function() compute_cluster_outlines(d,"x","y","leiden",method="territory",bandwidth=h,
                                              mass=.97,grid_size=256L)
cold <- system.time(p <- compute())["elapsed"]
warm <- system.time(again <- compute())["elapsed"]
stopifnot(identical(p,again))
ref <- read.csv(file.path(reference_dir,"territory-paths.csv"))
hull <- read.csv(file.path(reference_dir,"ggforce-paths.csv"))
contains <- function(paths,id) {
  sub <- paths[as.character(paths$cluster)==id,]
  inside <- logical(nrow(d))
  for (r in split(sub,sub$path)) {
    box <- which(d$x>=min(r$x) & d$x<=max(r$x) & d$y>=min(r$y) & d$y<=max(r$y))
    inside[box] <- xor(inside[box],sp::point.in.polygon(d$x[box],d$y[box],r$x,r$y)>0)
  }
  inside
}
ids <- sort(unique(as.character(d$leiden)))
results <- lapply(ids,function(id) {
  ours <- contains(p,id)
  theirs <- contains(ref,id)
  ggforce <- contains(hull,id)
  member <- d$leiden==id
  data.frame(dataset,id,members=sum(member),rings=length(unique(p$path[p$cluster==id])),
    rc_own=sum(ours&member),rc_other=sum(ours&!member),cellstyle_own=sum(theirs&member),
    cellstyle_other=sum(theirs&!member),rc_vs_cellstyle_disagreements=sum(ours!=theirs),
    ggforce_own=sum(ggforce&member),ggforce_other=sum(ggforce&!member))
})
write.csv(do.call(rbind,results),file.path(out,paste0(dataset,"-containment.csv")),row.names=FALSE)
write.csv(data.frame(dataset,n=nrow(d),k=length(ids),vertices=nrow(p),cold_s=as.numeric(cold),
                     cached_s=as.numeric(warm)),file.path(out,paste0(dataset,"-timing.csv")),row.names=FALSE)
summary <- do.call(rbind,results)
allowed <- if(dataset=="Yost") 1L else 0L
stopifnot(sum(summary$rc_vs_cellstyle_disagreements)<=allowed,
          sum(summary$ggforce_own)==nrow(d),
          sum(summary$rc_own)==if(dataset=="Yost")22515L else 395316L)
