# Replays the denoising step only, from the exact upstream source in inventory.csv.
library(ggplot2)
library(magrittr)
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
source(file.path(args[1],"ggunchull","R","unchull.R"))
df <- subset(read.csv("research/stress/points.csv"),case == "Unequal density")
result <- step1_denoise(df$x, df$y, n = 10)
keep <- paste(df$x, df$y) %in% paste(result$x, result$y)
record <- aggregate(cbind(input = rep(1L,nrow(df)), retained = as.integer(keep)),
                    list(island = ifelse(df$x > 0, "right", "left")), sum)
print(record)
write.csv(record, "research/sources/unchull-denoising.csv", row.names = FALSE)
