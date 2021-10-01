## NM script 01/oct/2021 V2.0
# To re-download code: https://github.com/lukevano/neuromelanin_analysis/

# V2.0 = Adding head cropping as part of the script and using this image for the bet

# Make project directory and NM directory inside this. In NM directory make the following directories: data, output, code, templates, working, results
# Next subdirectory in data folder should be subject folder. Inside this should be a session folder. Inside this should be one folder for the dcm data for T1 and one for nm dcm data
# Example: sub-001 >  ses-000 > t1_dcm
# Put dcm data into t1_dcm or nm_dcm respectively
# If you already have the nii or nii.gz then just leave this in the session folder

# Put MNI and masks in the templates folder and make sure this is correctly mapped below
# Here is a good mask: https://neurovault.org/collections/3145/

# Code will make sure working and output folders are correctly labelled

# WARNING- running code for a subject with delete ALL of the data in that subject's working and output folders. Suppress with # if not wanting to delete this data.
# Before running make sure all paths correct. Code will not do anything outside of NM folder but may delete files and folders in this directory so double check path!!!!

# To call script use the following command: bash /data/project/CARDS/NM/code/nm_script_v2.sh sub-001 sub-002 ...



## Modules to load for processing

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
	/software/system/fsl/fsl-6.0.1/bin/bet $c_T1 $DIR/data/$subj/ses-000/c_t1_brain.nii.gz -f 0.5 -g 0 -m
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
