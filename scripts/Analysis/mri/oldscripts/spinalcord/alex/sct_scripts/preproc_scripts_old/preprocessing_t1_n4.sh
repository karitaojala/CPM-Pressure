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

listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99)
#4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51
# 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99)

exclude=(   )

for i in "${exclude[@]}"; do
	listofSubs=(${listofSubs[@]//*$i*})
done

echo ${listofSubs[@]}

for subject in "${listofSubs[@]}"; do

echo "Sub${subject}"

subdir=${basedir}Sub`printf %02d ${subject}`

targetdir=${subdir}/T1/

# t1
# ===========================================================================================
 cd "$targetdir" || exit


# warp templates to native space
sct_apply_transfo -i ${tpldir}PAM50_t1_crop_1vm.nii -d t1.nii -w warp_template2anat.nii.gz
sct_apply_transfo -i ${tpldir}PAM50_t2_crop_1vm.nii -d t1.nii -w warp_template2anat.nii.gz
sct_apply_transfo -i ${tpldir}PAM50_cord_crop_1vm.nii -d t1.nii -w warp_template2anat.nii.gz
sct_apply_transfo -i ${tpldir}PAM50_levels_crop_1vm.nii -d t1.nii -w warp_template2anat.nii.gz

sct_apply_transfo -i ${tpldir}PAM50_t1_crop_1vl.nii -d t1.nii -w warp_template2anat.nii.gz
sct_apply_transfo -i ${tpldir}PAM50_t2_crop_1vl.nii -d t1.nii -w warp_template2anat.nii.gz
sct_apply_transfo -i ${tpldir}PAM50_cord_crop_1vl.nii -d t1.nii -w warp_template2anat.nii.gz
sct_apply_transfo -i ${tpldir}PAM50_levels_crop_1vl.nii -d t1.nii -w warp_template2anat.nii.gz

#~ sct_apply_transfo -i ${tpldir}PAM50_t1_crop_5v.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ${tpldir}PAM50_t2_crop_5v.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ${tpldir}PAM50_cord_crop_5v.nii -d t1.nii -w warp_template2anat.nii.gz
#~ sct_apply_transfo -i ${tpldir}PAM50_levels_crop_5v.nii -d t1.nii -w warp_template2anat.nii.gz


done


