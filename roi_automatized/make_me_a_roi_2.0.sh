#!/bin/bash
#---------------- HELP ----------------#
help() {
echo "
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #   
# # ROI Analysis for Cortical Thickness (Using CIVET and the Human Brainnetome Atlas) # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

 ____________
< Hey there! >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\  
                ||----w |
                ||     ||


This set of scripts is intended to be fed with:
a) a region from the Human Brainnetome Atlas (specifically, a region probability map),
b) cortical thickness files (outputted from CIVET) of a subjects group,
c) a cortical 3-D mesh representing the group average, and:
d) a .csv file with the variables associated with the subjects.

What this set of scripts does is:
--> convert BNA NIFTI probability map to MINC format 
--> convert it to a binary mask according to the desired treshold
--> use that mask to threshold individual CT measures
--> apply a linear model (and FDR correction) over the dataset according to the specified\ 
    dependent and independent variables.

It takes the following arguments:  

[1]: BNA probability map (e.g. 025.nii) 		
[2]: Directory where cortical thickness files (.txt, outputted from CIVET) are located
[3]: average cortical 3-D mesh (single hemisphere, e.g. lh_average.obj) 
[4]: dataframe (.csv file; important: IDs' column must be named: id 
[5]: Derired threshold for delimiting the probability map		
[6]: Predictor variable(s) (which can take the form accepted by R formulae; e.g. group+age)	
[7]: If comparing two groups, here you must input the code of the experimental group
[8]: And control group's code

Notice: You should execute these scripts from the same directory where the required files are located.

- E.D. marcoseliseo.da at gmail dot com

"
}

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
	help
	exit 1
fi


# Warm-up
echo " # # # # # # Starting pipeline # # # # # #"

echo " # # # # # # Current working dir is " $(pwd)  

id=`echo $1 | cut -d "." -f 1`

# Step 1: NIFTI 2 MINC
nii2mnc $1 ${id}_roi.mnc 
echo " # # Created file: " $(ls *.mnc*)

# Step 2: MINC to Vertex
mkdir vertex_files
volume_object_evaluate ${id}_roi.mnc ${3} vertex_files/${id}_vertex.txt
echo "# # Created file: " $(ls vertex_files)


# Step 3: use R to turn into 0's and 1's
Rscript binarize_2.0.R vertex_files/${id}_vertex.txt ${5} ${id}
mv density_plot binary_mask_${id}_${5}.txt vertex_files			

# Step 4: Multiply by thickness data (vertstats_math)
mkdir roi_ct

for file in $2/*.txt; do
	vertstats_math -mult vertex_files/binary_mask_${id}_${5}.txt $file -old_style_file $(dirname $file)/$(basename $file .txt)_${id}_${5}.txt
 
done

mv $2/*_${id}_${5}.txt roi_ct

echo " # # # # # # # # # # created files: " $(ls roi_ct/*_${id}_${5}) " # # # # # # #"

prefix=`echo $2/* | cut -d "_" -f 1 | cut -d "/" -f 2`  

echo "  # # # # # # Created PREFIX:  $prefix  # # # # # # # # #"

# Step 5: Analysis (in R)

Rscript analyze_thickness_2.0.R $id $prefix $2 $4 $5 $6 $7 $8 

# Step 6: Clean statistical map

sed -i 's/NA/0/g' ${id}_statmap.txt

echo " # # # # # # # # # # # Finished # # # # # # # # # # # # #"


# Me queda la duda: si corro el script desde otro directorio, se trabaja en el directorio desde el que se convoca???

