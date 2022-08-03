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
listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99)
#exept=(8 15 21 24 33 39 40 43 45 47 49 62 71 72 77 78 88)

#~ exclude=(29 30 37 42 61 65)
#~ ${listofSubs[@]/$exclude}
#~ echo listofSubs

for subject in ${listofSubs[@]}; do

echo "Sub${suject}"

if [[ ${#subject} < 2 ]]; then
	subdir=${basedir}Sub0${subject}
else
	subdir=${basedir}Sub${subject}
	#file_t1="Sub${subject}_T1"
fi

targetdir=${subdir}/T1/
if [ ! -d ${targetdir} ]; then
	mkdir -p ${targetdir}
fi
cp ${subdir}/HR_spinal/sTRIO_*.nii ${targetdir}t1.nii


# t1
# ===========================================================================================
 cd "$targetdir" || exit

#~ # segmentation based on deep learning, works better than propseg
#~ sct_deepseg_sc -i t1.nii -c t1 -qc ~/qc_multiSubj

#~ gzip t1.nii t1_seg.nii

#~ # find spinal vertebrae
#~ sct_label_vertebrae -i t1.nii.gz -s t1_seg.nii.gz -c t1 -qc ~/qc_multiSubj || echo "problems labeling vertebrae of Sub ${subject}"

gunzip t1.nii.gz t1_seg.nii.gz t1_seg_labeled.nii.gz t1_seg_labeled_discs.nii.gz || echo "no gz files found for Sub ${subject}"

#~ # if that does not work, manual help is required
#~ sct_label_utils -i t1.nii -create-viewer 3 -o label_c2c3.nii -msg "Click at the posterior tip of #C2/C3 inter-vertebral disc" 

#~ # run labeling again now with manual help
#~ sct_label_vertebrae -i t1.nii -s t1_seg.nii -c t2 -initlabel label_c2c3.nii
	

#~ if [[ ${exept[*]} =~ ${subject}  ]]; then 
	#~ # if that does not work, manual help is required
	#~ sct_label_utils -i t1.nii -create-viewer 3 -o label_c2c3.nii -msg "Click at the posterior tip of #C2/C3 inter-vertebral disc" 

	#~ # run labeling again now with manual help
	#~ sct_label_vertebrae -i t1.nii -s t1_seg.nii -c t2 -initlabel label_c2c3.nii
#~ else	
	#~ # find spinal vertebrae
	#~ sct_label_vertebrae -i t1.nii.gz -s t1_seg.nii.gz -c t1 -qc ~/qc_multiSubj || echo "problems labeling vertebrae of Sub ${subject}"
#~ fi


#~ #label two vertebrae for registration
#~ sct_label_utils -i t1_seg_labeled.nii -vert-body 4,6 -o t1_labels_vert.nii.gz

#~ #normalize T1 to PAM50
#~ sct_register_to_template -i t1.nii -s t1_seg.nii -l t1_labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=centermass,metric=MeanSquares:step=2,type=im,algo=affine,metric=MeanSquares:step=3,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,shrink=2

#~ #crop normalized T1
#~ sct_crop_image -i anat2template.nii -dim 2 -start 658 -end 980 -o anat2template_crop.nii

#~ # Flatten cord in the right-left direction (to make nice figure)
#~ sct_flatten_sagittal -i t1.nii -s t1_seg.nii

# warp templates to native space
#~ sct_apply_transfo -i ~/sct/data/PAM50/template/PAM50_t2.nii.gz -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ~/sct/data/PAM50/template/PAM50_cord.nii.gz -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ~/sct/data/PAM50/template/PAM50_levels.nii.gz -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ../../PAM50_t1_crop.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ../../PAM50_t2_crop.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ../../PAM50_t1_crop_crop.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ../../PAM50_t2_crop_crop.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ../../PAM50_cord_crop.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ../../PAM50_cord_crop_crop.nii -d t1.nii -w warp_template2anat.nii.gz

#~ mkdir ../T2
#~ mv PAM50_t2_reg.nii.gz ../T2/t2.nii.gz
#~ mv PAM50_cord_reg.nii.gz ../T2/t2_seg.nii.gz
#~ mv PAM50_levels_reg.nii.gz ../T2/t2_seg_labeled.nii.gz

#~ cd ../T2/
#~ gunzip t2.nii.gz t2_seg.nii.gz t2_seg_labeled.nii.gz


done


# Display syntax to open QC report on web browser
echo "To open Quality Control (QC) report on a web-browser, run the following:"
echo "${open_command} ${SCT_BP_QC_FOLDER}/index.html"
