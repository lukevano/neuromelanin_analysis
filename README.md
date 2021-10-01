# neuromelanin_analysis

NM script 01/oct/2021 V2.0
To re-download code: https://github.com/lukevano/neuromelanin_analysis/

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
