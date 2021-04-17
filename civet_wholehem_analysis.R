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
info_subs$left_thickness <- paste("thickness/TA_", info_subs$id, "_native_rms_rsl_tlink_30mm_left.txt", sep = "")

# Check that there is now a new column named 'left_thickness'
names(info_sujetos)
info_sujetos$left_thickness # I recommend copying one of the results here and pasting it in the console after the 'ls' command to see if the information is correct

# relevel groups
info_subs$grupo <- relevel(info_subs$group, ref = "NT")  #Control group is called NT (Non-Therapists) in the dataframe

# Fit linear model
vs <- vertexLm(left_thickness ~ group + age + sex, info_subs)

# Create Effect Size Statistical Map (Hedges'g)
effectsize <- vertexEffectSize(vs)
head(effectsize) # take a glimpse

# Write TXT effect size map
write.table(x = effectsize[,"hedgesg-groupTA"], file = "effsize_statmap.txt", col.names = FALSE, row.names = FALSE)

# Perform FDR correction for multiple comparisons (test whole-hemisphere hypothesis)
vertexFDR(vs) 

# Write TXT t-value statistical map
write.table(x=vs[,"tvalue-groupTA"], col.names = FALSE, row.names = FALSE, file = "statistical_map_lefth.txt")
