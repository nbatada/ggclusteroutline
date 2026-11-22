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

# Frozen paths identify the rows and geometry columns that produced them.
origin <- attr(multi, "provenance")
stopifnot(identical(origin$coordinate_space, "linear Cartesian"),
          nchar(origin$input_sha256) == 64L,
          identical(origin$columns$facets, c("sample", "batch")),
          identical(origin$package_version, as.character(packageVersion("ggclusteroutline"))))
fingerprint <- function(d) {
  z <- compute_cluster_outlines(d,"x","y","leiden",clusters="4",component="island",
                                facets=c("sample","batch"))
  attr(z, "provenance")$input_sha256
}
d$NKG7 <- rev(d$NKG7)
stopifnot(identical(origin$input_sha256, fingerprint(d)))
d$sample[1] <- "changed"
stopifnot(!identical(origin$input_sha256, fingerprint(d)))

# Repeated local path IDs and punctuation in distinct facet tuples stay separate.
plot <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point() +
  geom_cluster_outline(multi) + ggplot2::facet_grid(sample ~ batch)
built <- ggplot2::ggplot_build(plot)$data[[2]]
stopifnot(nrow(built) == nrow(multi), length(unique(built$PANEL)) == 4L)
