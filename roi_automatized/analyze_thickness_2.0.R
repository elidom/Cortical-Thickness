#!/usr/bin/env Rscript

args = commandArgs(trailingOnly = TRUE)

# # # # # # # # # # # # # # # # # # # # # # # # # ROI analysis
# library + info
library(RMINC)
info_subjects <- read.csv(as.character(args[4]))
length_report <- length(info_subjects$id)

# Add thickness data
info_subjects$roi_ct <- paste("roi_ct/", as.character(args[2]),"_",info_subjects$id,"_native_rms_rsl_tlink_30mm_left_",args[1],"_",args[5],".txt", sep = "")

# report for checking
names_report <- names(info_subjects)
thickness_files_report <- info_subjects$thickness

# relevel
info_subjects$group <- relevel(info_subjects$group, ref = as.character(args[8]))

# mask
mask_file <- read.table(paste("vertex_files/binary_mask_", as.character(args[1]), "_", as.character(args[5]),  ".txt", sep = ""))

# # Print Stuff for checking
print("# # # # # # # LENGTH # # # # # # # # ")
print(length_report)

print("# # # # # # # NAMES # # # # # # # # ")
print(names_report)

print("# # # # # # # CT FILES # # # # # # # # ")
print(thickness_files_report)

print("# # # # # # # ROI CT FILES # # # # # # # # ")
print(info_subjects$roi_ct)

print("# # # # # # # CT LENGTH # # # # # # # # ")
print(length(info_subjects$roi_ct))

write.csv(info_subjects, file = "new_csv.csv")

getwd()

# Linear Model
arg_6_iv <-  as.character(args[6])
class(arg_6_iv)

forml <- paste("roi_ct ~", arg_6_iv)
forml <- as.formula(forml)

vs <- vertexLm(forml, info_subjects)
#vs <- vertexLm(roi_ct ~ group, info_subjects)  # Convertir @group en args[n]
vertexFDR(vs, mask = mask_file)

write.table(x=vs[,paste("tvalue-group", as.character(args[7]), sep = "")], col.names = FALSE, row.names = FALSE, file = paste(as.character(args[1]), "_statmap.txt", sep = ""))

