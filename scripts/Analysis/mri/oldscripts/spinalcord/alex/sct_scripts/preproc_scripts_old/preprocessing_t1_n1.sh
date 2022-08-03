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

logdir=${basedir}logs/

filepath=$(readlink -f $0)
filename=$( basename "$( readlink -f "$0" )"  .sh)
savefile=${filename}$(date '+_%Y_%m_%d_%H%M%S.sh')

cp ${filepath} ${logdir}${savefile}

exit
	
#array that lists all subs and runs in which registration problems occured
pbl=("problems")

listofSubs=(4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99)
 
# 4 5 7 8 9 10 12 13 14 15 16 17 18 19 20 21 22 23 24 28 29 30 31 32 33 35 36 37 38
# 39 40 41 42 43 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 65 66 67 68 70
#71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 93 94 95 96 97 98 99

for subject in ${listofSubs[@]}; do

echo "Sub${subject}"

subdir=${basedir}Sub`printf %02d ${subject}`

targetdir=${subdir}/T1/
if [ ! -d ${targetdir} ]; then
	mkdir -p ${targetdir}	
fi

cd ${subdir}/T1_raw || exit
cp $(ls ${subdir}/T1_raw | egrep -e "sTRIO.*.nii" | head -1) ${targetdir}t1.nii

# t1
# ===========================================================================================
 cd "$targetdir" || exit

# segmentation based on deep learning, works better than propseg
if [[ ${subject} == 61 || ${subject} == 37 ]];then 
	sct_propseg -i t1.nii -c t1 -qc ~/qc_multiSubj -min-contrast 30
elif [[ ${subject} == 42 ]]; then
	sct_propseg -i t1.nii -c t1 -qc ~/qc_multiSubj -radius 2.3
elif [[ ${subject} == 30 || ${subject} == 65 ]]; then
	sct_propseg -i t1.nii -c t1 -qc ~/qc_multiSubj -radius 3.4 -min-contrast 20
elif [[ ${subject} == 29 ]]; then
	sct_propseg -i t1.nii -c t1 -qc ~/qc_multiSubj -radius 3 -min-contrast 30
else
	sct_deepseg_sc -i t1.nii -c t1 -qc ~/qc_multiSubj 
fi

# find spinal vertebrae
sct_label_vertebrae -i t1.nii -s t1_seg.nii -c t1 -qc ~/qc_multiSubj || pbl=( "${pbl[@]}" "Sub${subject}" )


done

echo ${pbl[@]}