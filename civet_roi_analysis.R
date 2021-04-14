# Load libraries
library(RMINC)
library(dplyr)

# Load CSV file
info_subs <- read.csv("info_subs.csv")

# Peek into data 
head(info_sujetos)

# Tidy 
info_subs <- info_subs %>%
  mutate(sex = factor(sex),
         group = factor(group))


# Add thickness data
info_subs$roi015_thickness <- paste("thickness/TA_", info_subs$id, "_native_rms_rsl_tlink_30mm_left_roi.txt", sep = "")

# Check that there is now a new column named 'roi015_thickness'
names(info_sujetos)
info_sujetos$left_thickness # I recommend copying one of the results here and pasting it in the console after the 'ls' command to see if the information is correct

# relevel groups
info_subs$grupo <- relevel(info_subs$group, ref = "NT")  #Control group is called NT (Non-Therapists) in the dataframe

# load CIVET mask
bna015_mask <- read.table("015_civet_bin.txt")

# Fit linear model
vs <- vertexLm(roi015_thickness ~ group + age + sex, info_subs)

# Perform FDR correction for multiple comparisons (Is there a signifficant effect? see below)
vertexFDR(vs, mask = bna015_mask) 

write.table(x=vs[,"tvalue-groupTA"], col.names = FALSE, row.names = FALSE, file = "statistical_map_roi015_civet.txt")