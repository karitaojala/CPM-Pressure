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

PATH=~/sct/bin:/common/apps/ants-2.2/bin:$PATH

basedir=/projects/crunchie/remi3/

export TMPDIR=${basedir}tmp


listofSubs=(74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99)
#4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70 71 72 73 
for subject in ${listofSubs[@]}; do

echo "Sub${subject}"

if [[ ${#subject} < 2 ]]; then
	subdir=${basedir}Sub0${subject}
else
	subdir=${basedir}Sub${subject}
fi

for run in {1..8}; do

targetdir=${subdir}/Run$run/sct/
if [ ! -d ${targetdir} ]; then
	mkdir  ${targetdir}
	
fi

t1dir=${subdir}/T1
cp ${subdir}/Run$run/spinal/fTRIO_*.nii ${targetdir}

# fmri
# ===========================================================================================

cd $targetdir || exit




done

#sct_image -i $t1dir/fmri_concat_means.nii,mean_moco_3d.nii -concat t -o $t1dir/fmri_concat_means.nii
#mean_epi=${subdir}/Run1/sct/fmri_moco_mean.nii
#~ cd $t1dir || exit

#~ sct_fmri_moco -i fmri_concat_means.nii  -param metric=CC,poly=1,smooth=1
#antsMotionCorr -d 3 -o [moco_means,moco_means.nii,mean_of_mean.nii] -m GC[${mean_epi}, fmri_concat_means.nii , 1 , 32 , Regular, 0.2 ] -t Rigid[ 0.1 ] -i 20 -u 1 -e 1 -s 0 -f 1 -n 10 -w 1 -v 1


#rm fTRIO_*.nii 

# Segment spinal cord manually
# Since these data have very poor cord/CSF contrast, it is difficult to segment the cord properly
# and hence in this case we do it manually. The file is called: fmri_crop_moco_mean_seg_manual.nii.gz

#sct_register_multimodal -i fmri_crop_moco_mean.nii -d ../../HR/PAM50_t2s_reg.nii 

# Register template->fmri
#sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d fmri_moco_mean.nii -dseg fmri_moco_mean_seg.nii -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5 -initwarp ../../HR_sct/warp_template2anat.nii.gz -initwarpinv ../../HR_sct/warp_anat2template.nii.gz
#sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2s.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d fmri_moco_mean.nii -dseg fmri_moco_mean_seg.nii -param step=1,type=seg,algo=slicereg,smooth=3,metric=CC:step=2,type=seg,algo=bsplinesyn,metric=CC,smooth=0,iter=3,slicewise=0 -initwarp ../../HR_sct/warp_template2anat.nii.gz -initwarpinv ../../HR_sct/warp_anat2template.nii.gz
#sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d fmri_moco_mean.nii -dseg fmri_moco_mean_seg.nii -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2:step=2,type=im,algo=bsplinesyn,metric=MeanSquares,iter=5,gradStep=0.5 -initwarp ../../HR_sct/warp_template2anat.nii.gz -initwarpinv ../../HR_sct/warp_anat2template.nii.gz

#

# Rename warping fields for clarity
#mv warp_PAM50_t2s2fmri_crop_moco_mean.nii.gz warp_templates2fmri.nii.gz
#mv warp_fmri_crop_moco_mean2PAM50_t2s.nii.gz warp_fmri2templates.nii.gz

# Warp template and spinal levels (here we don't need the WM atlas)
#sct_warp_template -d fmri_crop_moco_mean.nii -w warp_templates2fmri.nii.gz -a 0 -s 1

#~ # Note, once you have computed fMRI statistics in the subject's space, you can use
#~ # warp_fmri2template.nii.gz to bring the statistical maps on the template space, for group analysis.
#~ cd ..


done
#cd $t1dir || exit
#~ sct_maths -i fmri_concat_means.nii -mean t -o fmri_mean_of_mean.nii
#~ rm fmri_concat_means.nii

#~ sct_get_centerline -i fmri_mean_of_mean.nii -c t2s
#~ sct_create_mask -i fmri_mean_of_mean.nii -p centerline,fmri_mean_of_mean_centerline_optic.nii -size 10mm
#~ mv mask_fmri_mean_of_mean.nii mask_fmri_mean_of_mean_10mm.nii
#~ sct_create_mask -i fmri_mean_of_mean.nii -p centerline,fmri_mean_of_mean_centerline_optic.nii -size 35mm
#~ mv mask_fmri_mean_of_mean.nii mask_fmri_mean_of_mean_35mm.nii
#~ sct_create_mask -i fmri_mean_of_mean.nii -p centerline,fmri_mean_of_mean_centerline_optic.nii -size 55mm
#~ mv mask_fmri_mean_of_mean.nii mask_fmri_mean_of_mean_55mm.nii
#~ sct_create_mask -i fmri_mean_of_mean.nii -p centerline,fmri_mean_of_mean_centerline_optic.nii -size 75mm
#~ mv mask_fmri_mean_of_mean.nii mask_fmri_mean_of_mean_75mm.nii


#~ sct_propseg -i fmri_mean_of_mean.nii -c t2s

#sct_register_multimodal -i ../../HR_sct/PAM50_t2_reg.nii -d ${subdir}/Run1/sct/fmri_moco_mean.nii -iseg ../../HR_sct/Sub0${subject}_T1_seg.nii -dseg ${subdir}/Run1/sct/mask_fmri_mean.nii -param step=1,type=seg,algo=affine,slicewise=1,metric=MeanSquares,smooth=3:step=2,type=seg,algo=syn,metric=MeanSquares,smooth=1,iter=10


#sct_register_multimodal -i T2/t2.nii -d fmri_mean_of_mean.nii -iseg T2/t2_seg.nii -dseg fmri_mean_of_mean_seg.nii -param step=1,type=seg,algo=rigid,metric=MI,smooth=2:step=2,type=im,algo=affine,metric=MI,smooth=1
#~ sct_apply_transfo -i fmri_mean_of_mean.nii -d t2_reg.nii -w warp_fmri_mean_of_mean2t2.nii.gz 
#sct_apply_transfo -i fmri_mean_of_mean_seg.nii -d t2_reg.nii -w warp_fmri_mean_of_mean2t2.nii.gz 
#sct_apply_transfo -i mask_fmri_mean_of_mean.nii -d t2_reg.nii -w warp_fmri_mean_of_mean2t2.nii.gz 
#~ sct_apply_transfo -i mask_fmri_mean_of_mean_10mm.nii -d t2_reg.nii -w warp_fmri_mean_of_mean2t2.nii.gz 
#~ sct_apply_transfo -i mask_fmri_mean_of_mean_35mm.nii -d t2_reg.nii -w warp_fmri_mean_of_mean2t2.nii.gz 
#~ sct_apply_transfo -i mask_fmri_mean_of_mean_55mm.nii -d t2_reg.nii -w warp_fmri_mean_of_mean2t2.nii.gz 
#~ sct_apply_transfo -i mask_fmri_mean_of_mean_75mm.nii -d t2_reg.nii -w warp_fmri_mean_of_mean2t2.nii.gz 

#~ mv fmri_mean_of_mean_reg.nii fmri_mean_of_mean_reg2nativet2.nii

#sct_apply_transfo -i fmri_mean_of_mean_reg2nativet2.nii -d $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -w T1/warp_anat2template.nii.gz
#mv fmri_mean_of_mean_reg2nativet2_reg.nii fmri_mean_of_mean_norm2t1.nii
#sct_maths -i fmri_mean_of_mean_reg2nativet2.nii -bin 0.01 -o fmri_mean_of_mean_reg2nativet2_bin.nii

#sct_crop_image -i T2/t2.nii -mesh fmri_mean_of_mean_reg2nativet2.nii -o T2/t2_seg_crop.nii 
##sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d fmri_mean_of_mean_reg2nativet2.nii -dseg T1/PAM50_cord_crop_crop_reg.nii -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=1:step=2,type=im,algo=bsplinesyn,metric=CC,iter=3,gradStep=0.5 -initwarp T1/warp_template2anat.nii.gz -initwarpinv T1/warp_anat2template.nii.gz


#sct_apply_transfo -i fmri_moco_mean_reg.nii -d ../../HR_sct/anat2template.nii -w ../../HR_sct/warp_anat2template.nii.gz

#done
