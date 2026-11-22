# Independent check of the actual vector artwork. Run after visual/run_comparison.R.
# SVG numeric coordinates are rounded; report borderline centres as covered within 0.02 SVG units.
library(xml2)
methods <- c("convex","ggforce","ggalt","ggdensity")
cases <- c("ring","islands","crescent")
output <- "research/visual/output"
tol <- .02
records <- list()
for (case in cases) {
  reference <- NULL
  data <- read.csv(file.path("research/visual/input",paste0(case,".csv")))
  for (method in methods) {
    file <- file.path(output,paste0(case,"_",method,".svg"))
    svg <- read_xml(file)
    marks <- xml_find_all(svg,"//*[local-name()='circle']")
    x <- as.numeric(xml_attr(marks,"cx"))
    y <- as.numeric(xml_attr(marks,"cy"))
    keep <- grepl("#0072B2",xml_attr(marks,"style"),fixed=TRUE)
    stopifnot(identical(keep,data$group != "other"))
    # Fixed aspect plus ggplot layouts may translate panels on the page.
    # Compare distances between points relative to total spread.
    mapped <- cbind((x-x[1])/diff(range(x)),(y-y[1])/diff(range(y)))
    if (!is.null(reference)) stopifnot(max(abs(mapped-reference))<.0003)
    reference <- mapped
    paths <- xml_find_all(svg,"//*[contains(@style,'#D55E00') and (local-name()='polygon' or local-name()='polyline')]")
    stopifnot(length(paths)>0L)
    hits <- matrix(FALSE,sum(keep),length(paths))
    near <- rep(FALSE,sum(keep))
    closed <- logical(length(paths))
    for (j in seq_along(paths)) {
      coords <- scan(text=gsub(","," ",xml_attr(paths[[j]],"points")),quiet=TRUE)
      q <- matrix(coords,ncol=2,byrow=TRUE)
      closed[j] <- xml_name(paths[[j]])=="polygon" || max(abs(q[1,]-q[nrow(q),]))<tol
      if (!closed[j]) next
      px <- x[keep]
      py <- y[keep]
      hits[,j] <- sp::point.in.polygon(px,py,q[,1],q[,2])>0
      end <- c(2:nrow(q),1L)
      for (k in seq_len(nrow(q))) {
        dx <- q[end[k],1]-q[k,1]
        dy <- q[end[k],2]-q[k,2]
        if (dx==0 && dy==0) next
        t <- pmax(0,pmin(1,((px-q[k,1])*dx+(py-q[k,2])*dy)/(dx^2+dy^2)))
        near <- near | (px-q[k,1]-t*dx)^2+(py-q[k,2]-t*dy)^2 <= tol^2
      }
    }
    records[[length(records)+1L]] <- data.frame(case,method,target=sum(keep),paths=length(paths),
      closed_paths=sum(closed),inside_or_on=if(all(closed)) sum((rowSums(hits)%%2L==1L)|near) else NA_integer_)
  }
}
write.csv(do.call(rbind,records),"research/review/svg-coverage.csv",row.names=FALSE)
