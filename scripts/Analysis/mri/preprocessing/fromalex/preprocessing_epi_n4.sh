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

#log dir
logdir=${basedir}logs/

#save copy of .sh file in log dir
filepath=$(readlink -f $0)
filename=$( basename "$( readlink -f "$0" )"  .sh)
savefile=${filename}$(date '+_%Y_%m_%d_%H%M%S.sh')

cp ${filepath} ${logdir}${savefile}

listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 51 52 54 55 56 57 58 59 60 61 62 65 66 67 68 70 71 72 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 90 91 93 94 95 96 97 98 99)

#subjects to exclude from analysis
exclude=( )

for i in "${exclude[@]}"; do
	listofSubs=(${listofSubs[@]//*$i*})
done

for subject in ${listofSubs[@]}; do

subdir=${basedir}Sub`printf %02d ${subject}`

echo "Sub${subject}"

t1dir=${subdir}/T1/

# fmri mean_of_mean
# ===========================================================================================
cd ${t1dir} || exit

#concatenate warp fields
sct_concat_transfo -d ${tpldir}PAM50_t1_crop_1vm.nii -w ${t1dir}warp_mean_of_mean2PAM50_t2_crop_1v_reg.nii.gz,${t1dir}warp_mean_of_mean_reg2PAM50_t2.nii.gz -o warpfield_mom2temp.nii.gz

#~ #concatenate warp fields inverse
#~ sct_concat_transfo -d ${t1dir}mean_of_mean.nii -w ${t1dir}warp_PAM50_t22mean_of_mean_reg.nii.gz,${t1dir}warp_PAM50_t2_crop_1v_reg2mean_of_mean.nii.gz -o warpfield_temp2mom.nii.gz

#apply warp fields to mean of mean and seg
sct_apply_transfo -i mean_of_mean.nii -d ${tpldir}PAM50_t1.nii -w warpfield_mom2temp.nii.gz -o mean_of_mean_norm.nii
sct_crop_image -i mean_of_mean_norm.nii -dim 2 -start 780 -end 860 -o mean_of_mean_norm.nii 

for run in {1..8}; do

rundir=${subdir}/Run${run}/sct/

echo "Run${run}"

# fmri runs
# ===========================================================================================
cd ${rundir} || exit

#create 4D file 
sct_image -i ../realign_sess/rfTRIO_*.nii -o fmri_moco.nii -concat t

#concatenate warp fields
sct_concat_transfo -d ${tpldir}PAM50_t2_crop_1vm.nii -w warp_fmri_moco_mean2fmri_moco_mean_1st.nii.gz,${t1dir}warp_mean_of_mean2PAM50_t2_crop_1v_reg.nii.gz,${t1dir}warp_mean_of_mean_reg2PAM50_t2.nii.gz -o warpfield_run${run}.nii.gz

#apply warp fields to mean session epis
sct_apply_transfo -i fmri_moco_mean.nii -d ${tpldir}PAM50_t2_crop_1vm.nii -w warpfield_run${run}.nii.gz -o fmri_moco_mean_norm.nii

#apply warp fields to all epis
sct_apply_transfo -i fmri_moco.nii -d ${tpldir}PAM50_t2_crop_1vm.nii -w warpfield_run${run}.nii.gz -o fmri_moco_norm.nii

done

done

