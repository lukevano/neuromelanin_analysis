# Neuromelanin Analysis

# This script has been designed with the help of Dr Stephen Kaar and Dr Rong Ye. It packages together FMRIB Software Library (FSL) and Advanced Normalization Tools (ANTs) to allow automatic processing of Neuromelanin-sensitive MRI data.

# NM script 01/Oct/2021 V2.0
# Download the most up to date code: https://github.com/lukevano/neuromelanin_analysis/

# V1.0 = Initial commit. Some issues with NM-MRI normalization as brain extraction tool (BET) sometimes leaving too much soft tissue around the brainstem.
# V2.0 = robustfov added to pipeline for cropping of the T1 data (removing the neck and lower head). This cropped T1 is then used for BET. -R (robust) brain centre estimation option added to the BET.

# Steps:

# 1. Collect T1 and NM-MRI dcm/nii data
# 2. Make project directory and NM directory inside this. In NM directory make the following directories: data, output, code, templates, working, results
# 3. In the data folder make a subject folder and in this make a session folder. Example: proj_name/NM/data/sub-001/ses-000
# 4. If dealing with dcm data- make t1_dcm and nm_dcm and put the t1 and nm dcm data into the respective folders. If you already have the t1 and nm nii/nii.gz files just put these directly in the session folder.
# 5. Put brain template (must be brain and not full head) and masks in the templates folder. You will need to change the nm_script to make sure that your template and masks are correctly mapped to the code. We have been using mask from the following collection: https://neurovault.org/collections/3145/

# Code will make sure working and output folders are correctly labelled
# WARNING- running code for a subject with delete ALL of the data in that subject's working and output folders. Suppress the relevant sections of code with # if not wanting to delete this data. Before running make sure all paths correct. Code will not do anything outside of NM folder but may delete files and folders in this directory so double check path!!!!

# 6. When calling the script specify which participant data you would like to analysis. To call script use the following command: bash path_proj_dir/NM/code/nm_script_v2.sh sub-001 sub-002 ...

# The results from the initial processing of the t1 will be saved in the data folder. c_t1 = cropped t1, c_t1_brain = the BET output. The results from the co-registrtion and transformation steps will be saved in the working folder. The normalized nm data will be stored in the output folder. The mean signal intensity of the normalized nm voxels that are inside the masks will be recorder in the results/nm_results.txt (this will not delete the previously recordered results so can analyse the each participant one at a time if you like)

# Troubleshooting:
# The main source of erroneous results will be poor brain extraction or poor NM-MRI image. As the NM-MRI sequences are relatively long in duration significant movement may mean that the NM-MRI image is uninterpretable and the image will need to be discarded. If the brain extraction is the issue then look at the following page for troubleshooting: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/BET/UserGuide. Take a look at the c_t1_brain image. If too much brain has been removed you can decrease -f 0.5 to -f 0.2 in the code. If not enough brain has been removed increase -f. -g will alter how much brain is removed from the top or bottom of the image- positive values give larger brain outline at bottom, smaller at top (values between -1 and 1 may be used).

# Dependencies:
# Make sure you FSL and ANTs downloaded:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki
# http://stnava.github.io/ANTs/

# Modules to load for processing

module load ants
module load fsl/6.0.1

# Checking general directory structure

if [ ! -d /data/project/CARDS/NM ]
then
	echo "Error: Unable to find project directory. Ensure directory correctly organised and ensure path directories up to date."
fi

if [ ! -d /data/project/CARDS/NM/results ]
then
	echo "Error: No results directory. Ensure directory correctly organised and change the code to reflect project directory."
fi

# Mapping to directories

DIR=/data/project/CARDS/NM
TEMPLATE=$DIR/templates
SN_MASK=$TEMPLATE/CIT168_combined_sn.nii.gz
CC_MASK=$TEMPLATE/combined_CC_MNI152.nii.gz
MNI=$TEMPLATE/mni_09c/mni_09c_brain.nii
MNI_M=$TEMPLATE/mni_09c/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii
RESULTS=$DIR/results

# If issues with downloading MNI template delete # in the next two lines and just use fsl MNI but check for good co-registration!
# MNI=/software/system/fsl/fsl-6.0.1/data/standard/MNI152_T1_1mm_brain.nii.gz
# MNI_M=/software/system/fsl/fsl-6.0.1/data/standard/MNI152_T1_1mm_brain_mask.nii.gz

# For loop

for subj in $@

do

# Checking for working and output directories. Will make directories and subdirectories if not detected.

if [ ! -d $DIR/working/$subj/ses-000 ]
then
	mkdir $DIR/working/$subj
	mkdir $DIR/working/$subj/ses-000
fi

if [ ! -d $DIR/output/$subj/ses-000 ]
then
	mkdir $DIR/output/$subj
	mkdir $DIR/output/$subj/ses-000
fi

# Checking for T1 data. Will convert dcm to .nii.gz or .nii to .nii.gz if needed.

if [ ! -f $DIR/data/$subj/ses-000/t1.nii.gz ] && [ -f $DIR/data/$subj/ses-000/t1.nii ]
then
	gzip $DIR/data/$subj/ses-000/t1.nii
fi

if [ ! -f $DIR/data/$subj/ses-000/t1.nii.gz ]
then
	dcm2niix -z y -f t1 -o $DIR/data/$subj/ses-000 $DIR/data/$subj/ses-000/t1_dcm
fi

# Checking for NM data. Will convert dcm to .nii.gz or .nii to .nii.gz if needed.

if [ ! -f $DIR/data/$subj/ses-000/nm.nii.gz ] && [ -f $DIR/data/$subj/ses-000/nm.nii ]
then
	gzip $DIR/data/$subj/ses-000/nm.nii
fi

if [ ! -f $DIR/data/$subj/ses-000/nm.nii.gz ]
then
	dcm2niix -z y -f nm -o $DIR/data/$subj/ses-000 $DIR/data/$subj/ses-000/nm_dcm
fi

# path to T1

T1=$DIR/data/$subj/ses-000/t1.nii.gz

# Cropping head

if [ ! -f $DIR/data/$subj/ses-000/c_t1.nii.gz ]
then
	robustfov -i $T1 -r $DIR/data/$subj/ses-000/c_t1.nii.gz
fi

# path to cropped T1

c_T1=$DIR/data/$subj/ses-000/c_t1.nii.gz

# BET for brain extraction- Must visually check to ensure quality of extracted brain
# If too much brain removed change to -f 0.2
# Consider cropping head if issues with BET or co-reg

if [ ! -f $DIR/data/$subj/ses-000/c_t1_brain.nii.gz ]
then
	/software/system/fsl/fsl-6.0.1/bin/bet $c_T1 $DIR/data/$subj/ses-000/c_t1_brain.nii.gz -f 0.5 -g 0 -R -m
fi

# subject directories

T1_B=$DIR/data/$subj/ses-000/c_t1_brain.nii.gz
NM=$DIR/data/$subj/ses-000/nm.nii.gz
WORK=$DIR/working/$subj/ses-000
OUTPUT=$DIR/output/$subj/ses-000

# WARNING- These next if statements will delete ALL files in subject's working and output directories. Suppress with # if you don't want files removed.

if [ -f $DIR/working/$subj/ses-000/* ]
then
	rm $WORK/*
fi

if [ -f $DIR/output/$subj/ses-000/* ]
then
	rm $OUTPUT/*
fi

# co-registration of NM to T1

antsRegistrationSyNQuick.sh -d 3 -f $T1 -m $NM -t r -o $WORK/nm_to_t1.nii.gz

NM_T1=$WORK/nm_to_t1.nii.gz
NM_T1_AFF=$WORK/nm_to_t1.nii.gz0GenericAffine.mat

# co-registration of T1 to MNI

antsRegistrationSyNQuick.sh -d 3 -f $MNI -m $T1_B -t s -o $WORK/t1_to_mni.nii.gz -x $MNI_M

T1_MNI=$WORK/t1_to_mni.nii.gz
T1_MNI_WARP=$WORK/t1_to_mni.nii.gz1Warp.nii.gz 
T1_MNI_AFF=$WORK/t1_to_mni.nii.gz0GenericAffine.mat

# transformation of NM to MNI

antsApplyTransforms -d 3 -i $NM -r $MNI -t $T1_MNI_WARP -t $T1_MNI_AFF -t $NM_T1_AFF -o $OUTPUT/nm_norm.nii.gz -v

# results will be stored in nm_results.txt (this file created if not in existence).

echo $subj  >> $RESULTS/nm_results.txt
echo CC mean and SD=  >> $RESULTS/nm_results.txt

# calculating CC values

fslstats $OUTPUT/nm_norm.nii.gz -k /data/project/CARDS/NM/templates/combined_CC_MNI152.nii.gz -M -S >> $RESULTS/nm_results.txt
echo  SN mean and SD=  >> $RESULTS/nm_results.txt

# calculating SN values

fslstats $OUTPUT/nm_norm.nii.gz -k /data/project/CARDS/NM/templates/CIT168_combined_sn.nii.gz -M -S >> $RESULTS/nm_results.txt
echo ,  >> $RESULTS/nm_results.txt

done
