## About this page

In this page I intend to summarise the usage of structural MRI workflows to estimate cortical thickness (CT) from T1-weighted MRI volumes and carry out analyses to answer interesting research questions. My main interest here is to provide a detailed tutorial on CIVET (Montreal Neurological Institute) and RMINC (https://github.com/Mouse-Imaging-Centre/RMINC) to estimate vertex-based individual cortical thickness and later carry out group comparisons and correlations. I will also try to describe -- with lesser detail -- the usage of FreeSurfer (https://surfer.nmr.mgh.harvard.edu/) for CT analyses, especially with an aim towards doing custum region of interest (ROI) analysis.

## Dataset

For the examples we will be using the Empathic Response in Psychotherapists dataset, generated by [Olalde-Mathieu et al. (2020)](https://www.biorxiv.org/content/10.1101/2020.07.01.182998v2) and the structural analysis of which were carried out in [Domínguez-Arriola et al. (2021)](https://www.biorxiv.org/content/10.1101/2021.01.02.425096v2). You can copy the NIFTI volumes as well as the behavioral and demographic information from the directory: /misc/charcot2/dominguezma/tutorial

## CIVET

[CIVET](http://www.bic.mni.mcgill.ca/ServicesSoftware/CIVET-2-1-0-Introduction) is an sMRI processing pipeline developed by The McConnell Brain Imaging Centre to more reliably extract individual cortical surfaces at the vertex-level and estimate cortical thickness in milimeters at each point of the brain cortex. Several definitions of cortical thickness are available to use in the pipeline, and users will be available to choose the one they think is most appropritate. However, there is evidence that the linked-distance definition is more accurate and reliable than other geometric cortical-thickness definitions (Lerch & Evans, 2005). 

### Preprocessing

Users could simply feed the raw volumes to the pipeline; however, I recommend customizing the preprocessing of the volumes to ensure the best quality and most accurate results. This will consist in:

* A qualitative quality control of the volumes.
* [N4 Bias Correction](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3071855/), and formatting file names.
* Generation of individual brain masks using [volBrain 1.0](https://volbrain.upv.es/).

#### Quality Control 

For this quality control I recommend the one described in [Backhausen et al. (2016)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5138230/). Please follow the steps reported in the paper. It basically consists in evaluating each volume in four different criteria, average their score, and decide -- on the basis of the individually asigned score -- whether to preserve or drop the volume for the rest of the workflow. It is important to be rigurous here because the presence of artifacts and overall bad quality can seriously bias the subsequent tissue segmentation and surface extraction.  

#### N4 Bias Field Correction and formatting file names

First, in order to run the *N4BiasFieldCorrection* algorithm ([ANTS](http://stnava.github.io/ANTs/) must be installed) you have to go to the folder where your NIFTI files are, unzip the volumes and, if you wanted to preprocess one file, run for instance: 

```bash
gunzip sub-1000_ses-1_T1w.nii.gz
N4BiasFieldCorrection -i sub-1000_ses-1_T1w.nii -o sub-1000_n4.nii
```
where -i specifies the input and -o the output name. Of course, we would ideally not want to process the volumes one by one, and would like to have the resulting volume in a dedicated directory. We may use a for loop for the former:

```bash
mkdir n4_corrected_output

for nii in *.nii; do
        id=`echo $nii | cut -d "_" -f 1` #extract subject ID
        N4BiasFieldCorrection -d 3 -i $nii -o n4_corrected_output/${id}_n4.nii #Perform correction
done
```

Finally, for the T1 volumes to be ready for the CIVET pipeline, they need to be transformed into MINC files and have a specific pattern in their names; so each file should look something like this: *PREFIX_ID_t1.mnc*, where __PREFIX__ is the study prefix (whichever we want it to be as long as it is consistently used throughout the whole workflow), __ID__ is the indivual volume's identifier, __t1__ tells CIVET that this is a T1-weighted MRI volume that needs processing, and __.mnc__ because it is a MINC file (not NIFTI anymore). For instance, here I would like to use the prefix **TA** and, so, my subject **sub-1000** should look something like this: *TA_1000_t1.mnc*. 

Let's do this in code. Suppose we are in the same directory as before -- i.e where the NIFTI files are, and where we now have a *n4_corrrected_output* folder filled with volumes. For the sake of tidyness I will move all the old NIFTI files to a new directory (since they are no longer useful; but we want them at hand as a backup) and I will create a new directory for the propperly formatted MINC volumes (note that you need to have the [MINC Toolkit](https://bic-mni.github.io/) installed -- or a virtual machine with it): 

```bash
mkdir NIFTI
mv *.nii NIFTI

mkdir mnc_files

for nii in $(ls n4_corrected_output); do
        id=`echo $nii | cut -d "_" -f 1` #extract subject ID
        nii2mnc $nii mnc_files/TA_${id}_t1.mnc
done
```

You can download or copy my script for these two last steps <a id="raw-url" href="https://github.com/elidom/structural-mri/blob/main/N4_formatting.sh" download>HERE</a>. 

#### Generation of brain masks with [volBrain 1.0](https://volbrain.upv.es/)

Even though the CIVET has implemented a brain extraction step (i.e. generation of a binary mask to be multiplied by the original image and strip out the skull, etc.), it might be safer to generate these masks ourselves with a very precise tool: [volBrain 1.0](https://volbrain.upv.es/). First, create a volBrain account (it is free!). Then, upload your NIFTI images one by one (note: they have to be compressed -- i.e. .gz termination) to the volBrain pipeline. Wait until its processing is finished (about 15 minutes; you should receive an email notification). Download the Native Space (NAT) zip file, extract the content, identify the __mask__ file (for instance: _native_mask_n_mmni_fjob293223.nii_)and save it somewhere separate. Be sure to change its name so that you can correctly associate it to its corresponding subject; in the end it will have to be similarly named to the CIVET pattern (PREFIX_ID_mask.mnc), so you might as well save it as, for instance, TA_1000_mask.nii. Before converting the masks into MINC files, carefully inspect that every mask fits the brain as perfectly as possible, so that in future steps only the cephalic mass is segmented from the volume. You can use __fsleyes__ for this, and [manually correct](https://users.fmrib.ox.ac.uk/~paulmc/fsleyes/userdoc/latest/editing_images.html) wherever needed. This quality control of the masks may take time, but it is absolutely necessary; otherwise, the reliability of the rest of the workflow would be compromised.

Finally, the mask files need to be converted into the MINC format. I will suppose that all the mask files are in one dedicated directory and are named like in the example above (e.g. TA_1000_mask.nii). Go to the directory where the masks are stored. You could transform them one by one:

```bash
nii2mnc TA_1000_mask.nii TA_1000_mask.mnc
nii2mnc TA_1001_mask.nii TA_1001_mask.mnc
```
...and so on; but of course, we always prefer to automatize the process:

```bash
for file in $(ls); do
        basename=`echo $file | cut -d "." -f 1`
        nii2mnc $file ${basename}.mnc
done

mkdir nii_masks mnc_masks
mv *.nii nii_masks
mv *.mnc mnc_masks
```
Now all the mask files should be exactly as CIVET asks them to be: PREFIX_ID_mask.mnc (e.g. TA_1001_mask.mnc). You can see the masks I generated in /misc/charcot2/dominguezma/tutorial/masks

### The CIVET pipeline

Now that everything is ready, we can put files together to have CIVET start processing the --now clean-- MRI volumes. To get a broader perspective and fine-grained detail on what CIVET does, please visit their [official website](http://www.bic.mni.mcgill.ca/ServicesSoftware/CIVET-2-1-0-Introduction). In a nutshell, what CIVET does is:

* Registration of idividual volumes to stereotaxic space
* Tissue classification (WM, GM, CSF)
* Surface extraction of left and right hemispheres separately (importantly, this is done through the fitting of a deformable model -- a polygon mesh -- to the individual cortex inner and outer surface. This polygon mesh consists of **40,962 vertices** for each hemisphere; this is important to have in mind, for it is also the number of cortical thickness estimates we are going to be working with in the statistical analysis.).
* Produces regional maps on the base of a couple atlases
* Produces a series of figures and diagrams for quality control
* (Normally, it would start with an N3 intensity normalization and generation of masks for brain extraction; however, in our case these steps will be skipped because we have provided the corrected images and our own brain masks.)

To start with, we are creating a directory specifically for our processing and create a directory therein where all the _T1_ and _mask_ volumes will be.

```bash
mkdir civet
mkdir civet/mnc_vols

mv mnc_files/*.mnc civet/mnc_vols
mv mnc_masks/*.mnc civet/mnc_vols
```
Now it is time to create a script with the specific usage that we would like CIVET to have. To gain a broader perspective visit [this website](http://www.bic.mni.mcgill.ca/ServicesSoftware/CIVET-2-1-0-Basic-Usage-of-CIVET). As specified there, in any CIVET run, we must specify:

* sourcedir <dir> : directory of source images
* targetdir <dir> : output directory
* prefix <name> : the source images prefix (name of study)
* a list of subjects to process (an enumeration or a list in a simple text file)
* an action command (like -run) 

In this case, I will assume that you are working in the C-25 Lab (INB). You have to log into the _charcot_ system, for I know for sure that CIVET is installed in that machine.

```bash
ssh charcot #and then input your password
```
Moreover, it has the greatest processing power. We will be using _GNU Parallel_ there to run the pipeline. 

Now I will assume that you are logged into _charcot_, and standing in the recently created _civet_ directory -- which for now only contains the *mnc_vols* directory with all the appropriately named _T1_ and _mask_ files. Now create here a script with the following contents:

```bash
#!/bin/bash

topdir=/misc/charcot2/dominguezma/tutorial/civet

source /misc/charcot/santosg/CIVET/civet_2_1_1/Linux-x86_64/init.sh

ls mnc_vols/*t1.mnc | cut -d "_" -f 3 | cut -d "_" -f 2 | parallel --jobs 6\
/misc/charcot2/santosg/civet-2.1.1-binaries-ubuntu-18/Linux-x86_64/CIVET-2.1.1/CIVET_Processing_Pipeline\
-sourcedir $topdir/mnc_vols\
-targetdir $topdir/target\
-prefix TA\
-N3-distance 0\
-lsq12\
-mean-curvature\
-mask-hippocampus\
-resample-surfaces\
-correct-pve\
-interp sinc\
-template 0.50\
-thickness tlink 10:30\
-area-fwhm 0:40\
-volume-fwhm 0:40\
-VBM\
-surface-atlas AAL\
-granular\
-run {}
```

Of course, you need to change the **topdir** directory accordingly. This script has the following elements:
* First, it starts by feeding the subjects' IDs into GNU parallel (`ls mnc_vols/*t1.mnc | cut -d "_" -f 3 | cut -d "_" -f 2 | parallel`) by calling each T1 volume and cutting their name into their identifier -- e.g. 999.
* Then it tells GNU parallel to run with 6 cores from the machine (`--jobs 6`); charcot has 8 cores, so here I am leaning 2 cores free. You can modify this as you want. 
* With `/misc/charcot2/santosg/civet-2.1.1-binaries-ubuntu-18/Linux-x86_64/CIVET-2.1.1/CIVET_Processing_Pipeline` we are simply calling the pipeline where it is located.
* `-sourcedir $topdir/mnc_vols` specifies where the T1 and mask volumes are located.
* `-targetdir $topdir/target` specifies where we want the output to be; this will create the directory 'target'.
* `-prefix TA` tells civet that we have chosen **TA** as our study prefix (and thus is in every volume's name).
* With `-N3-distance 0`we tell CIVET not to perform any inhomogeneities correction, since we have already done that ourselves.
* With `-thickness tlink 10:30` we tell civet to use the *tlink* geometric definition to estimate individual cortical thickness at each vertex of the cortical surface, and to perform a 10mm and 30mm FWHM diffusion kernel smoothing. For a justification on these parameters please see [Lerch & Evans (2005)](https://www.sciencedirect.com/science/article/pii/S1053811904004185?via%3Dihub).
* Finally, `-run {}` tells CIVET that the subjects we want to run are the ones fed to GNU parallel at the beginning.

For the rest of the parameters please refer to the [CIVET Usage Guide](http://www.bic.mni.mcgill.ca/ServicesSoftware/CIVET-2-1-0-Basic-Usage-of-CIVET). These are the parameters that have proven to work well and that we have used in the laboratory. Feel free to download this script <a id="raw-url" href="https://github.com/elidom/structural-mri/blob/main/run_civet.sh" download>HERE</a>.

First make sure to change the script permits with `chmod a+rwx run_civet.sh`; then, you can simply run the script `./run_civet.sh`. It will take approximately 6 hours per processing round -- i.e. if you specified `--jobs 6` it will take around 6 hours for every 6 subjects. Since we have 35 subjects in the example dataset, it should take around 36 hrs in total.

#### Output quality control

When it is finished processing the volumes we should be able to find a series of fol folders in the *target* directory: *classify, final, logs, mask, native, surfaces, temp, thickness, transforms, VBM, verify*. In the verify directory we should be able to find a set of images that serve to perform quality control, such as this one: 

![Verify Image](TA_753_verify.png)

To interpret the quality control images contained by the verify folder please refer to [this website](http://www.bic.mni.mcgill.ca/ServicesSoftware/CIVET-2-1-0-Quality-Control).

#### Visualizing the output

The *surfaces* folder contains the *.obj* tridimensional brain cortex models of the individual brain. You can see it using Display; for instance, if you are standing within the output folder of a specific subject (i.e. within the _target_ directory), you may type in the console (let us use subject 804 here as an example): 
```bash
Display surfaces/TA_804_gray_surface_left_81920.obj
```

upon which the individual cortical surface model should show up on screen:

![Surface](imgs/surface.png)

To overylay the individual thickness data to this surface, you can click on the surface in the *Objects* window, then go to the *Menu* window and click *File > Load Vertex Data*, navigate to the *thickness* directory, and load the `TA_804_native_rms_rsl_tlink_30mm_left.txt` file -- which is a simple text file with 40,962 vertices (remember that number?) corresponding to the thickness estimates in milimeters for each vertex in the mesh. These are also the files that we are meinly going to be using for the statistical tests. After opening that, the thickness map should show up in the Viewer:

![Thickness](imgs/ss1.png)

For more information on the usage of Display, please refer to the [MINC Display Guide](http://www.bic.mni.mcgill.ca/software/Display/Display.html)

### Statistical Analysis with R

#### Region of Interest Analysis

Here comes the fun part. For this you will need to have the RMINC package installed in R. If you find it difficult to install the package (which is likely to happen if you are using Ubuntu or Windows, consider using [containers or a virtual machine](https://bic-mni.github.io/#virtual-machine). First of all, I will move all the necessary cortical thickness data (from all the subjects) to one directory accesible from my R project session. So say I have my R project hosted in a directory that is next to the one where my CIVET workflow took place. Then I could move everything I need there. Suppose we are still standing in the CIVET directory.

```bash
mkdir ../rproject/thickness

cp target/*/thickness/*_native_rms_rsl_tlink_30mm_* ../rproject/thickness
```
This code will copy all the 30mm smoothed native cortical thickness resampled *(rsl)* to the MNI ICBM152 surface model to the folder in our rproject, including the files corresponding to the left hemishpere, the right hemisphere, and the asymmetry maps -- if your R project is not exactly next to your CIVET folder, please adapt the code accordingly. For more information regarding the CIVET outputs, [see here](http://www.bic.mni.mcgill.ca/ServicesSoftware/CIVET-2-1-0-Outputs-of-CIVET).

If your Region of Interest is one of the AAL Atlas regions, please follow [this tutorial](https://github.com/CobraLab/documentation/wiki/ROI-Analysis-in-CIVET) written by Dr. Garza-Villarreal and the CoBrALab. 

Otherwise, you have to get or create your ROI and have in a NIFTI format and have it registered to the MNI-152 standard space. I will give an example here getting a ROI from the [Human Brainnetome Atlas](https://atlas.brainnetome.org/bnatlas.html), which parcelates the brain in more than 240 regions based on structural connectivity. Since ours is a structural analysis, this is appropriate. You can download all the NIFTI probability maps there; to understand what they mean see [Fan et al.](https://pubmed.ncbi.nlm.nih.gov/27230218/). Since these are probability maps you have to choose a threshold to determine the extention of the ROI. The threshold you choose is somewhat arbitrary and depends on your objectives. The important thing is that we choose one *a priori* and stick to it. Here I choose 60, meaning that my ROI will be constituted by the voxels of the MNI-152 model that in at least in 60% of the subjects pertained to the corresponding region --If this did not make sense, see the link above.

Assuming that the probability maps are now stored in a directory (called BNA_PM) next to my CIVET and R-project directories, I could pick and threshold my ROI using FSL (this is one of several methods possible, but the result is the same): 

```bash 
mkdir rproject/roi

fslmaths BNA_PM/015.nii.gz -thr 60 rproject/roi/015_th.nii.gz

cd rproject/roi

nii2mnc 015_th.nii.gz 015_th.mnc
```
As tou can see from the code I chose the 015 region, which corresponds to an area of the left dorsolateral prefrontal cortex (dlPFC), and put the thresholded result in a ROI-dedicated directory within the *rproject* domain for practicity. Then we moved there and transformed the NIFTI image to a MINC volume.

Now, before projecting this ROI into the CIVET space, we need an average surface model to display our results on. You could one from your own subjects, or download a standard one [HERE](http://www.bic.mni.mcgill.ca/users/llewis/CIVET_files/CIVET_2.0.tar.gz) -- the files called `CIVET_2.0_icbm_avg_mid_sym_mc_left.obj`and `CIVET_2.0_icbm_avg_mid_sym_mc_right.obj`. Have these files at hand in your workspace. For example, I will move them to a dedicated folder (named avg_objs) in the *rproject* directory, and rename them to lh_average.obj and rh_average.obj respectively. For this tutorial we will only be using `lh_average.obj`, for the BNA_015 region of interest that I am analyzing lies on the left hemisphere. If you visualize one of these CIVET average surfaces with Display (`Display avg_objs/lh_average.obj`) you should see something like this: 

![CIVET average surface - left](imgs/avg_left.png)

Now we are ready to transform our ROI into the CIVET space using the `volume_object_evaluate` function:

```bash
volume_object_evaluate roi/015.mnc avg_objs/lh_average.obj 015_civet.txt
```
where `015_civet.txt` is the output -- yes, a simple text file with 40,962 pieces of information, each representing one vertex of the cortical model in CIVET space. However, for this to be a valid mask we need it to be constituted by 0's and 1's defining where in the CIVET space the ROI is. This is simple to achieve: we just need to replace all the numbers that are greater than 0 by 1. This could be done using *regular expression*, but since I am pretty much unfamiliar with it, I do it using R. So you can initialize R simply by typing `R` in the shell, and then do:

```R
thick <- read.csv("015_civet.csv", header = FALSE)

isgtzero <- thick > 0

thick2 <- ifelse(isgtzero == TRUE, 1, 0)

write.table(thick2, "015_civet_bin.csv", col.names = FALSE, row.names = FALSE)
```
Then, you can quit are typing q(), and a file called "015_civet_bin.csv" (*bin* meaning binarized) should be now available. This is our mask in CIVET space.

