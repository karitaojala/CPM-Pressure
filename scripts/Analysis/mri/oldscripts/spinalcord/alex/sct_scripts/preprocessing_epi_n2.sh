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
tpldir=${basedir}PAM50

#log dir
logdir=${basedir}logs/

#save copy of .sh file in log dir
filepath=$(readlink -f $0)
filename=$( basename "$( readlink -f "$0" )"  .sh)
savefile=${filename}$(date '+_%Y_%m_%d_%H%M%S.sh')

cp ${filepath} ${logdir}${savefile}

#array that lists all subs and runs in which registration problems occured
pbl=("problems")

listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 51 52 54 55 56 57 58 59 60 61 62 65 66 67 68 70 71 72 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 90 91 93 94 95 96 97 98 99)

#subjects to exclude from analysis
exclude=( )

for i in "${exclude[@]}"; do
	listofSubs=(${listofSubs[@]//*$i*})
done


exept1=(9 15 19 22 24 31 35 38 52 55 56 65 76 77 92 ) 
exept2=(4 7 8 10 14 18 40 42 66 74 88 96 97  ) 

for subject in ${listofSubs[@]}; do

subdir=${basedir}Sub`printf %02d ${subject}`

echo "Sub${subject}"


t1dir=${subdir}/T1


# fmri
# ===========================================================================================
cd ${t1dir} || exit


#register mean of mean to t2    
if [[ " ${exept1[*]} " == *" ${subject} "*  ]]; then
	sct_register_multimodal -i PAM50_t2_crop_1vl_reg.nii -d mean_of_mean.nii -iseg PAM50_cord_crop_1vl_reg.nii -dseg mean_of_mean_seg.nii -param step=1,type=seg,algo=slicereg,metric=MI,smooth=2,poly=2,iter=20,gradStep=0.2 -x spline
elif [[ " ${exept2[*]} " == *" ${subject} "*  ]]; then
	sct_register_multimodal -i PAM50_t2_crop_1vm_reg.nii -d mean_of_mean.nii -iseg PAM50_cord_crop_1vm_reg.nii -dseg mean_of_mean_seg.nii -param step=1,type=im,algo=rigid,metric=MI,smooth=1,iter=20,gradStep=0.2,init=centermass:step=2,type=seg,algo=slicereg,metric=MeanSquares,smooth=2,poly=2,iter=20,gradStep=0.2 -x spline 
else
	sct_register_multimodal -i PAM50_t2_crop_1vm_reg.nii -d mean_of_mean.nii -iseg PAM50_cord_crop_1vm_reg.nii -dseg mean_of_mean_seg.nii -param step=1,type=seg,algo=slicereg,metric=MeanSquares,smooth=2,poly=2,iter=20,gradStep=0.2,init=centermass -x spline || pbl=( "${pbl[@]}" "Sub${subject}" )
fi

if [[ " ${exept1[*]} " == *" ${subject} "*  ]]; then
	mv warp_mean_of_mean2PAM50_t2_crop_1vl_reg.nii.gz warp_mean_of_mean2PAM50_t2_crop_1v_reg.nii.gz
else
	mv warp_mean_of_mean2PAM50_t2_crop_1vm_reg.nii.gz warp_mean_of_mean2PAM50_t2_crop_1v_reg.nii.gz
fi

done

echo ${pbl[@]}
