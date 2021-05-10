#!/bin/bash
# GO to dir
topdir=$1

cd $topdir
echo "# # # # #working directory is `pwd `"

N4Folder=N4
reconallFolder=rcnall1
maskdir=edited_masks

SUBJECTS_DIR=$reconallFolder


for nii in $(ls $N4Folder); 
do
	### crear ID de sujetos
	id=`echo $nii | cut -d "_" -f 1`
	echo "$id created"


	### Part 1: Get transformation matrix to FS space
	## mgz --> nii

	mri_convert $reconallFolder/$id/mri/T1.mgz $reconallFolder/$id/mri/T1.nii.gz

	
	mri_convert $reconallFolder/$id/mri/brainmask.mgz $reconallFolder/$id/mri/brainmask.nii.gz


	##  Compute matrix
	flirt -in $N4Folder/$nii -ref $reconallFolder/$id/mri/T1.nii.gz -out $reconallFolder/$id/mri/T1_to_FS.nii.gz -omat $reconallFolder/$id/mri/T1_to_FS.mat

	
	### Part 2: Use matrix to transform to FS space
	## Volbrain mask --> FS space

	VolBrain_mask=$maskdir/${id}_mask.nii

	flirt -in $VolBrain_mask -ref $reconallFolder/$id/mri/T1_to_FS.nii.gz -applyxfm -init $reconallFolder/$id/mri/T1_to_FS.mat -out $reconallFolder/$id/mri/mask_vol_brain_FS.nii

	##  Multiplication
	
	fslmaths $reconallFolder/$id/mri/T1.nii.gz -mul $reconallFolder/$id/mri/mask_vol_brain_FS.nii $reconallFolder/$id/mri/brainmask_new.nii.gz
	

	## nii --> mgz
	
	mri_convert $reconallFolder/$id/mri/brainmask_new.nii.gz $reconallFolder/$id/mri/brainmask_new.mgz

	## Add metadata
	
	mri_add_xform_to_header $reconallFolder/$id/mri/transforms/talairach.auto.xfm $reconallFolder/$id/mri/brainmask_new.mgz

	### Step 3: Tidy
	## Rename originals
	
	mv $reconallFolder/$id/mri/brainmask.mgz $reconallFolder/$id/mri/brainmask.original.mgz 

	
	mv $reconallFolder/$id/mri/brainmask.auto.mgz $reconallFolder/$id/mri/brainmask.auto.original.mgz 

	
	## place new files
	mv $reconallFolder/$id/mri/brainmask_new.mgz $reconallFolder/$id/mri/brainmask.mgz

	
	cp $reconallFolder/$id/mri/brainmask.mgz $reconallFolder/$id/mri/brainmask.auto.mgz 

done
