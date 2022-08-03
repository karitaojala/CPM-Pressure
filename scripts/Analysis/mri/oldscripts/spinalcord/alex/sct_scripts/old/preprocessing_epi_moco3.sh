#!/bin/bash
#
# Example of commands to process multi-parametric data of the spinal cord.
# 
# Please note that this batch script has a lot of redundancy and should not
# be used as a pipeline for regular processing. For example, there is no need
# to process both t1 and t2 to extract CSA values. 
#
# For information about acquisition parameters, see: https://osf.io/wkdym/
# N.B. The parameters are set for these type of data. With your data, parameters 
# might be slightly different.
#
# Usage:
# 
#   [option] $SCT_DIR/batch_processing.sh
# 
#   Prevent (re-)downloading sct_example_data:
#   SCT_BP_DOWNLOAD=0 $SCT_DIR/batch_processing.sh
# 
#   Specify quality control (QC) folder (Default is ~/qc_batch_processing):
#   SCT_BP_QC_FOLDER=/user/toto/my_qc_folder $SCT_DIR/batch_processing.sh

# Abort on error
set -e

# For full verbose, uncomment the next line
# set -x

# Fetch OS type
if uname -a | grep -i  darwin > /dev/null 2>&1; then
  # OSX
  open_command="open"
elif uname -a | grep -i  linux > /dev/null 2>&1; then
  # Linux
  open_command="xdg-open"
fi

PATH=~/sct/bin:$PATH

basedir=/projects/crunchie/remi3/

export TMPDIR=${basedir}tmp3


listofSubs=(76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99)
#4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40  
#41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70 71 72 73 74 75
for subject in ${listofSubs[@]}; do

echo "Sub${subject}"

if [[ ${#subject} < 2 ]]; then
	subdir=${basedir}Sub0${subject}
else
	subdir=${basedir}Sub${subject}
fi

for run in {1..8}; do 

rundir=${subdir}/Run$run/sct/
if [ ! -d ${rundir} ]; then
	mkdir  ${rundir}	
fi

t1dir=${subdir}/T1


# fmri
# ===========================================================================================

cd $rundir || exit

# create 4d files
cp ${subdir}/Run$run/spinal/fTRIO_*.nii ${rundir}
sct_image -i fTRIO_*.nii -o fmri.nii -concat t
rm fTRIO_*.nii 

# Average all fMRI time series (to be able to do the next step)
sct_maths -i fmri.nii -mean t -o fmri_mean.nii

sct_get_centerline -i fmri_mean.nii -c t2
# Get cord centerline

# Create mask around the cord to help motion correction and for faster processing
sct_create_mask -i fmri_mean.nii -p centerline,fmri_mean_centerline.nii.gz -size 65mm -f cylinder -o mask_fmri_65mm.nii
sct_create_mask -i fmri_mean.nii -p centerline,fmri_mean_centerline.nii.gz -size 45mm -f cylinder -o mask_fmri_45mm.nii

# Motion correction
sct_fmri_moco -i fmri.nii -m mask_fmri_65mm.nii -x spline -r 0

# Copy moco warp fields to subject folder
tmp_folder=$(ls -td $TMPDIR/*/ | head -1)
targetdir=${rundir}moco_warps/
mv $tmp_folder/mat_groups/ $targetdir && echo "copying warp fields to subject folder"
rm $tmp_folder -r && echo "deleting ${tmp_folder}"

#~ # Register mean to first session mean
#~ sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean.nii -m mask_fmri_65mm.nii -param step=1,type=im,algo=affine,metric=MI,smooth=0,gradStep=0.6 -x spline

#~ if [ $run == 1 ];then
	#~ cp fmri_moco_mean_src_reg.nii $t1dir/fmri_concat_means.nii
#~ else
	#~ sct_image -i $t1dir/fmri_concat_means.nii,fmri_moco_mean_src_reg.nii -concat t -o $t1dir/fmri_concat_means.nii
#~ fi

done

#~ cd $t1dir || exit

#~ sct_maths -i fmri_concat_means.nii -mean t -o mean_of_mean.nii

done

