#!/bin/bash
#


#abort on error
set -e

#add path of toolbox
PATH=~/sct/bin:$PATH

#project dir
basedir=/projects/crunchie/remi3/

#tmp dir
export TMPDIR=${basedir}tmp

#template dir
tpldir=${basedir}PAM50/

listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99)

#4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 
#4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 
#  
exclude=(   )

for i in "${exclude[@]}"; do
	listofSubs=(${listofSubs[@]//*$i*})
done
echo ${listofSubs[@]}

#subjects where vertebrae labeling did not work
exept=(8 15 21 24 29 33 37 40 43 45 47 49 62 78 84 99 )

reg1=(10 20 22 35 47 50 53 58 62 66 70 74 75 79 80 83 89 93  ) 
reg2=(45 98 ) 
reg3=(4 16 23 24 28 31 33 38 45 49 55 68 71 77 82 85 87 88 95 97 99  ) 


for subject in "${listofSubs[@]}"; do

echo "Sub${subject}"

subdir=${basedir}Sub`printf %02d ${subject}`

targetdir=${subdir}/T1/



# t1
# ===========================================================================================
 cd "$targetdir" || exit

# run labeling again with manual help in subjects where labeling did not work
for e in ${exept[@]};do
	if [[ ${subject} == ${e} ]]; then
		sct_label_vertebrae -i t1.nii -s t1_seg.nii -c t1 -initlabel label_c2c3.nii -qc ~/qc_multiSubj 
	fi
done

# label two vertebrae for registration
sct_label_utils -i t1_seg_labeled.nii -vert-body 4,6 -o t1_labels_vert.nii.gz


# normalize T1 to PAM50
if [[ " ${reg1[*]} " == *" ${subject} "* ]];then 
	sct_register_to_template -i t1.nii -s t1_seg.nii -l t1_labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=centermass,metric=Meansquares:step=2,type=im,algo=slicereg,metric=CC,shrink=2:step=3,type=im,algo=syn,metric=CC,iter=5,shrink=2
elif [[ " ${reg2[*]} " == *" ${subject} "* ]];then 
	sct_register_to_template -i t1.nii -s t1_seg.nii -l t1_labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=0:step=2,type=im,algo=syn,metric=CC,iter=5,shrink=2
elif [[ " ${reg3[*]} " == *" ${subject} "* ]];then 	
	sct_register_to_template -i t1.nii -s t1_seg.nii -l t1_labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=0:step=2,type=im,algo=syn,metric=MeanSquares 
else
	sct_register_to_template -i t1.nii -s t1_seg.nii -l t1_labels_vert.nii.gz -c t1 -param step=1,type=seg,algo=centermass,metric=MeanSquares:step=2,type=im,algo=bsplinesyn,metric=CC,iter=5,shrink=2
fi

#crop normalized T1
sct_crop_image -i anat2template.nii -dim 2 -start 750 -end 980 -o anat2template_crop.nii || echo "cropping did not work for Sub${subject}"

# Flatten cord in the right-left direction (to make nice figure)
sct_flatten_sagittal -i t1.nii -s t1_seg.nii


done


