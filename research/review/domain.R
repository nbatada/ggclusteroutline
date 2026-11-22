# Check when the 95% island contour can be interpreted as a closed region.
library(ggplot2)
df <- subset(read.csv("research/visual/input/islands.csv"),group == "islands")
rows <- lapply(c(2.8,4),function(bound) {
  p <- ggplot(df,aes(x,y)) + ggdensity::geom_hdr_lines(probs=.95,
         xlim=c(-bound,bound),ylim=c(-bound,bound))
  path <- ggplot_build(p)$data[[1]]
  do.call(rbind,lapply(split(path,path$group),function(r) {
    a <- r[1,c("x","y")]
    b <- r[nrow(r),c("x","y")]
    data.frame(domain_half_width=bound, path_id=r$group[1], start_x=a$x,start_y=a$y,
               end_x=b$x,end_y=b$y, closed=max(abs(a-b)) < 1e-8)
  }))
})
write.csv(do.call(rbind,rows),"research/review/domain.csv",row.names=FALSE)
