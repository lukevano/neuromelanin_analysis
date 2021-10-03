# Neuromelanin Analysis

#### This analysis pipeline was designed under the supervision of Dr Stephen Kaar and Dr Rong Ye. This script packages together FMRIB Software Library (FSL) and Advanced Normalization Tools (ANTs) to allow automatic processing of Neuromelanin-sensitive MRI data.

### Download the most up to date code: https://github.com/lukevano/neuromelanin_analysis/

### For any queries please e-mail: drlukevano@gmail.com

### NM script 01/Oct/2021 V2.0

### V1.0 = Initial commit. Some issues with NM-MRI normalization as brain extraction tool (BET) sometimes leaving too much soft tissue around the brainstem.
### V2.0 = robustfov added to pipeline for cropping of the T1 data (removing the neck and lower head). This cropped T1 is then used for BET. -R (robust) brain centre estimation option added to the BET.

## WARNING

### Running code for a subject with delete ALL of the data in that subject's working and output folders. Suppress the relevant sections of code with # if not wanting to delete this data. Before running make sure all paths correct. Code will not do anything outside of NM folder but may delete files and folders in this directory so double check path!!!!

## Steps:

### 1. Collect T1 and NM-MRI dcm/nii data
### 2. Make project directory and NM directory inside this. In NM directory make the following directories: data, output, code, templates, working, results
### 3. In the data folder make a subject folder and in this make a session folder. Example: proj_name/NM/data/sub-001/ses-000
### 4. If dealing with dcm data- make t1_dcm and nm_dcm and put the t1 and nm dcm data into the respective folders. If you already have the t1 and nm nii/nii.gz files just put these directly in the session folder.
### 5. Put brain template (must be brain and not full head) and masks in the templates folder. You will need to change the nm_script to make sure that your template and masks are correctly mapped to the code. We have been using mask from the following collection: https://neurovault.org/collections/3145/
### 6. When calling the script specify which participant data you would like to analysis. To call script use the following command: bash path_proj_dir/NM/code/nm_script_v2.sh sub-001 sub-002 ...

## Explaination:

### The results from the initial processing of the t1 will be saved in the data folder. c_t1 = cropped t1, c_t1_brain = the BET output. The results from the co-registrtion and transformation steps will be saved in the working folder. The normalized nm data will be stored in the output folder. The mean signal intensity of the normalized nm voxels that are inside the masks will be recorded in the results/nm_results.txt (this will not delete the previously recordered results so can analyse the each participant one at a time if you like)

## Troubleshooting:

### The main source of erroneous results will be poor brain extraction or poor NM-MRI image. As the NM-MRI sequences are relatively long in duration significant movement may mean that the NM-MRI image is uninterpretable and the image will need to be discarded. If the brain extraction is the issue then look at the following page for troubleshooting: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/BET/UserGuide. Take a look at the c_t1_brain image. If too much brain has been removed you can decrease -f 0.5 to -f 0.2 in the code. If not enough brain has been removed increase -f. -g will alter how much brain is removed from the top or bottom of the image- positive values give larger brain outline at bottom, smaller at top (values between -1 and 1 may be used).

## Dependencies:

### Make sure you FSL and ANTs downloaded:
### https://fsl.fmrib.ox.ac.uk/fsl/fslwiki
### http://stnava.github.io/ANTs/
