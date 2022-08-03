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

#calculate norm session mean
sct_maths -i fmri_moco_norm.nii -mean t -o session_mean_norm_epis.nii 

done

cd ${t1dir} || exit

#calculate mean of all session means
sct_maths -i fmri_concat_means.nii -mean t -o mean_of_session_mean_norm.nii 


done

#calculate mean of all participants
sct_maths -i fmri_concat_means.nii -mean t -o mean_all_norm_epis.nii 

#calculate mean of all participants
sct_maths -i fmri_concat_means.nii -mean t -o mean_all_norm_means.nii 

echo ${pbl[@]}
