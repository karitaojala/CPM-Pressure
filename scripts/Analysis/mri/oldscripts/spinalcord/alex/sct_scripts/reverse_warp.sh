#!/bin/bash
#

# Abort on error
set -e

#add path of toolbox
PATH=~/sct/bin:$PATH

#project dir
basedir=/projects/crunchie/remi3/

#tmp dir
export TMPDIR=${basedir}tmp

#template dir
tpldir=${basedir}PAM50/

pbl=("problems")


listofSubs=(4 )
#5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99)
#)
# 56 57 58 59 60 61 62 65 66 67 68 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99)
# 4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38
# 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70
#71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99
#

#subjects to exclude from analysis
exclude=(21 49 73 )

for i in "${exclude[@]}"; do
	listofSubs=(${listofSubs[@]//*$i*})
done

lessruns6=(50 53 69 89)
lessruns7=(63 92)

for subject in ${listofSubs[@]}; do

subdir=${basedir}Sub`printf %02d ${subject}`

echo "Sub${subject}"

t1dir=${subdir}/T1/

cd ${t1dir} || exit

#~ mv warp_PAM50_t2_crop_1vm_reg2mean_of_mean.nii.gz warp_PAM50_t2_crop_1v_reg2mean_of_mean.nii.gz
#sct_apply_transfo -i ${tpldir}PAM50_csf_crop_5v.nii -d mean_of_mean_reg.nii -w warp_PAM50_t22mean_of_mean_reg.nii.gz
cp mean_of_mean.nii mean_of_mean_test.nii
sct_register_multimodal -i PAM50_csf_crop_5v_reg.nii -d mean_of_mean_test.nii -identity 1

#~ sct_concat_transfo -d mean_of_mean.nii -w warp_PAM50_t22mean_of_mean_reg.nii.gz,warp_PAM50_t2_crop_1v_reg2mean_of_mean.nii.gz -o warpfield_reverse.nii.gz
#~ sct_apply_transfo -i ${tpldir}PAM50_csf_crop_5v.nii -d mean_of_mean.nii -w warpfield_reverse.nii.gz 

for run in {1..8}; do

rundir=${subdir}/Run${run}/sct/

echo "Run${run}"

# fmri
# ===========================================================================================

if [[ ${run} > 7 &&  " ${lessruns7[*]} " == *" ${subject} "* ]];then
	:
elif [[ ${run} > 6 &&  " ${lessruns6[*]} " == *" ${subject} "* ]];then
	:
else	


cd ${rundir} || exit



#concatenate warp fields
#sct_concat_transfo -d fmri_moco_mean.nii -w ${t1dir}warp_PAM50_t22mean_of_mean_reg.nii.gz,${t1dir}warp_PAM50_t2_crop_1v_reg2mean_of_mean.nii.gz,warp_fmri_moco_mean_1st2fmri_moco_mean.nii.gz -o warpfield_reverse_run${run}.nii.gz

#sct_concat_transfo -d fmri_moco_mean.nii -w ${t1dir}warp_PAM50_t22mean_of_mean_reg.nii.gz,${t1dir}warp_PAM50_t2_crop_1v_reg2mean_of_mean.nii.gz -o warpfield_reverse_run${run}.nii.gz


#apply warp fields to csf template
#sct_apply_transfo -i ${tpldir}PAM50_csf_crop_5v.nii -d fmri_moco_mean.nii -w warpfield_reverse_run${run}.nii.gz 


fi
done 
done







