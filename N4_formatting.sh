#!/bin/bash


#---------------- HELP ----------------#
help() {
echo "
	1st argument = folder where NIFTI files are
	2nd argument = study prefix (optional)
	3rd argument = Subjects' ID first delimiter (optional)
	4th argument = Sebjects' ID second delimiter (optional)

The 3rd and 4th argument must be included only if the ID delimiters are other than those suggested in the BIDS format (first '-' and then '_'. For example, if the file names are something like: \"sub-01_ses-1_T1w.nii.gz\" , these arguments need not be included. If the file names are rather something like: \"sub_01.bob.nii.gz\" , the third argument should be: \"_\" and the fourth: \".\"


If no prefix is provided (second argument) 'MR' will be used by default.

Examples:

> ./N4_script.sh /misc/path/to/niftidirectory MR

> ./N4_script.sh /misc/path/to/niftidirectory MR - .
 
-Eliseo
"
}

# -----------------------------------------------------------------------------------------------#

## checking if the input is valid
prefix=$2

if [[ -d $1 ]]; then
    echo "[INFO] $1 is a directory"
else
    echo "[INFO] $1 is not valid"
    help
    exit 1
fi

if [ -z "$2" ]; then
    prefix=MR
    echo "[INFO] DEFAULT PREFIX ASSIGNED: $prefix"
else
    prefix=$2	
    echo "[INFO] STUDY PREFIX IS: $prefix"  
fi


## Changing working directory & defining topdir 
topdir=$1

echo "[INFO] THE WORKING DIRECTORY IS $topdir" 

## create required dirs
mkdir ${topdir}/n4_corrected_output ${topdir}/NIFTI ${topdir}/mnc_files


## define file names
cd $topdir
for nii in *.nii.gz; do

	if [ -z "$3" ]; then
	id=`echo $nii | cut -d "-" -f 2 | cut -d "_" -f 1`

	else
	id=`echo $nii | cut -d "$3" -f 2 | cut -d "$4" -f 1`
	fi

echo "[INFO] ID $id WAS CREATED AND ADDED TO PREPROCESSING"


## process
N4BiasFieldCorrection -d 3 -i $nii -o n4_corrected_output/${id}_n4.nii.gz
echo "[INFO] n4_corrected_output/${id}_n4.nii.gz WAS CREATED"

## Converting to MINC and formatting names
nii2mnc n4_corrected_output/${id}_n4.nii.gz mnc_files/${prefix}_${id}_t1.mnc
echo "[INFO] mnc_files/${prefix}_${id}_t1.mnc WAS CREATED"

done

## Tidy
mv *.nii.gz NIFTI

echo "
____________
< All ready! >
 ------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
"




