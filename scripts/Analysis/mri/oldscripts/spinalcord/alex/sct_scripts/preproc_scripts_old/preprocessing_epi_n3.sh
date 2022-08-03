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
tpldir=${basedir}PAM50

pbl=("problems")


listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99)
#
#56 57 58 59 60 61 62 63 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99)
#4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55
# 4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38
# 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70
#71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99
#

#subjects to exclude from analysis
exclude=(21 49 73 )

for i in "${exclude[@]}"; do
	listofSubs=(${listofSubs[@]//*$i*})
done

for subject in ${listofSubs[@]}; do

subdir=${basedir}Sub`printf %02d ${subject}`

echo "Sub${subject}"


t1dir=${subdir}/T1/


# fmri
# ===========================================================================================


cd ${t1dir} || exit


#norm mean epi to template
sct_register_multimodal -i ${tpldir}/PAM50_t2.nii -d mean_of_mean_reg.nii -param step=1,type=im,algo=syn,metric=MeanSquares -initwarp warp_template2anat.nii.gz -initwarpinv warp_anat2template.nii.gz -x spline || pbl=( "${pbl[@]}" "Sub${subject}" )

sct_crop_image -i mean_of_mean_reg_reg.nii -dim 2 -start 780 -end 860 -o mean_of_mean_reg_reg.nii 

done

echo ${pbl[@]}
