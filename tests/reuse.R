library(ggclusteroutline)
d <- read.csv(system.file("extdata","pbmc700.csv",package="ggclusteroutline"))
d$island <- ifelse(d$x<3,"left","right")
fit <- compute_cluster_outlines(d,"x","y","leiden",clusters="4",component="island")
stopifnot(length(unique(fit$component))==2, all(fit$type=="polygon"))
f <- tempfile()
saveRDS(fit,f)
stopifnot(identical(fit,readRDS(f)))
unlink(f)
d$sample <- rep(c("a.1","a"),length.out=nrow(d))
d$batch <- rep(c("b","1.b"),each=350)
multi <- compute_cluster_outlines(d,"x","y","leiden",clusters="4",component="island",facets=c("sample","batch"))
stopifnot(identical(attr(multi,"facet_keys"),c("sample","batch")),
          nrow(unique(multi[c("sample","batch")]))==4)
for (ix in split(seq_len(nrow(d)),interaction(d$sample,d$batch,sep="|"))) {
  sub <- d[ix,,drop=FALSE]
  one <- compute_cluster_outlines(sub,"x","y","leiden",clusters="4",component="island")
  mask <- multi$sample==sub$sample[1L] & multi$batch==sub$batch[1L]
  stopifnot(identical(one$x,multi$x[mask]),identical(one$y,multi$y[mask]))
}
