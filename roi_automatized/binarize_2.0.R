#!/usr/bin/env Rscript
args <-  commandArgs(trailingOnly = TRUE)

## program...
roi_values <-  read.table(args[1])

# libraries
library(dplyr)
library(ggplot2)

# viusalize
plot <- roi_values %>%
  filter(V1 > 10) %>%
  ggplot(aes(x = V1)) +
  geom_density()

ggsave(filename = "density_plot", plot = plot, device = "png")

# editing
roi_mask <- roi_values %>%
  mutate(V1 = ifelse(V1 >= as.numeric(args[2]), 1, 0))

table(roi_mask)

filename <- paste("binary_mask_", as.character(args[3]), "_" , as.character(args[2]) , ".txt", sep = "")

# example filename: "binary_mask_015_60.txt
# in bash: "binary_mask_${id}_${treshold}.txt"

write.table(roi_mask, file = filename, row.names = FALSE, col.names = FALSE)


