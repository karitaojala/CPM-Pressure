#!/bin/bash


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

#array that lists all subs and runs in which registration problems occured
pbl=("problems")

listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99)
# 4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38
# 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70
#71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99
#  

#subjects to exclude from analysis
exclude=(21 49 73 )

for i in "${exclude[@]}"; do
	listofSubs=(${listofSubs[@]//*$i*})
done

#subjects with excluded runs
lessruns6=(50 53 69 89)
lessruns7=(63 92)

exept1=(22 59 68 72 81 86 96 97) 
exept2=(51 61 74)
exept3=(53 )
exept4=(19 28 37 40 48 58) 
exept5=(13 45 46 55)
exept6=(10 )
exept7=(50 )


for subject in ${listofSubs[@]}; do


subdir=${basedir}Sub`printf %02d ${subject}`

echo "Sub${subject}"

t1dir=${subdir}/T1
if [ ! -d ${t1dir} ]; then
	mkdir -p ${t1dir}
fi

for run in {1..8}; do

if [[ ${run} > 7 &&  " ${lessruns7[*]} " == *" ${subject} "* ]];then
	:
elif [[ ${run} > 6 &&  " ${lessruns6[*]} " == *" ${subject} "* ]];then
	:
else	

targetdir=${subdir}/Run${run}/sct/
if [ ! -d ${targetdir} ]; then
	mkdir  ${targetdir}
fi



# fmri
# ===========================================================================================

cd ${targetdir} || exit


echo ${run}

#copy mean epi to new folder
mean_epi=../realign_sess/meanfTRIO*.nii
cp ${mean_epi} fmri_moco_mean.nii 

#create mask for 1st session mean
if [ ${run} == 1 ];then
	sct_get_centerline -i fmri_moco_mean.nii -c t2
	sct_create_mask -i fmri_moco_mean.nii -p centerline,fmri_moco_mean_centerline.nii.gz -size 65mm -f cylinder -o mask_fmri_spm_65mm.nii
	cp fmri_moco_mean.nii fmri_moco_mean_1st.nii
fi

#coregister session means to first session
if [[ " ${exept1[*]} " == *" ${subject} "*  ]]; then 
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -param step=1,type=im,algo=affine,metric=MeanSquares,smooth=0,gradStep=0.5,init=geometric -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
elif [[ " ${exept2[*]} " == *" ${subject} "* ]]; then 
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -m ../../Run1/sct/mask_fmri_spm_65mm.nii -param step=1,type=im,algo=affine,metric=MeanSquares,smooth=0,gradStep=0.8,init=geometric -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
elif [[ " ${exept3[*]} " == *" ${subject} "* ]]; then 
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -m ../../Run1/sct/mask_fmri_spm_65mm.nii -param step=1,type=im,algo=affine,metric=MI,smooth=1,gradStep=0.2 -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
elif [[ " ${exept4[*]} " == *" ${subject} "* ]]; then 
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -m ../../Run1/sct/mask_fmri_spm_65mm.nii -param step=1,type=im,algo=affine,metric=CC,smooth=0,gradStep=0.6 -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
elif [[ " ${exept5[*]} " == *" ${subject} "* ]]; then 
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -m ../../Run1/sct/mask_fmri_spm_65mm.nii -param step=1,type=im,algo=affine,metric=CC,smooth=0,gradStep=0.5,init=centermass -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
elif [[ " ${exept6[*]} " == *" ${subject} "* ]]; then 
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -param step=1,type=im,algo=affine,metric=MI,smooth=0,gradStep=0.3 -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
elif [[ " ${exept7[*]} " == *" ${subject} "* ]]; then 
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -m ../../Run1/sct/mask_fmri_spm_65mm.nii -param step=1,type=im,algo=affine,metric=CC,smooth=0,gradStep=0.8,init=centermass -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
else
	sct_register_multimodal -i fmri_moco_mean.nii -d ../../Run1/sct/fmri_moco_mean_1st.nii -m ../../Run1/sct/mask_fmri_spm_65mm.nii -param step=1,type=im,algo=affine,metric=MeanSquares,smooth=0,gradStep=0.5,init=geometric -x spline || pbl=( "${pbl[@]}" "Sub${subject}" "Run$run") 
fi

#concatenate session means
if [ ${run} == 1 ];then
	cp fmri_moco_mean_reg.nii ${t1dir}/fmri_concat_means.nii
else
	sct_image -i ${t1dir}/fmri_concat_means.nii,fmri_moco_mean_reg.nii -concat t -o ${t1dir}/fmri_concat_means.nii
fi

fi
done

cd ${t1dir} || exit

#calculate mean of all session means
sct_maths -i fmri_concat_means.nii -mean t -o mean_of_mean.nii 

#segment spinal cord
sct_deepseg_sc -i mean_of_mean.nii -c t2s -centerline cnn 

done

echo ${pbl[@]}
