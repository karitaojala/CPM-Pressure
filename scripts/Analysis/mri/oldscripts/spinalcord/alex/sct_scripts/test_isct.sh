#!/bin/bash
#

# Abort on error
set -e
set -o pipefail
set -x

#add path of toolbox
PATH=~/sct/bin:$PATH

#project dir
basedir=/projects/crunchie/remi3/

#tmp dir
export TMPDIR=${basedir}tmp


listofSubs=(4)

for subject in ${listofSubs[@]}; do

subdir=${basedir}Sub`printf %02d ${subject}`_test

echo "Sub${subject}"


for run in {1..8}; do

rundir=${subdir}/Run${run}/sct/

echo "Run${run}"


cd ${rundir} || exit


for files in {0..152};do
	
echo "File${files}"

	isct_antsRegistration \
	--verbose \
        --dimensionality 3 \
        --float 0 \
        --metric "MeanSquares[fmri_moco_norm_T0000.nii,fmri_moco_norm_T`printf %04d ${files}`.nii,1,32,Regular,0.2]" \
        --output "[X_,Warped.nii.gz]" \
        --interpolation "BSpline" \
        --winsorize-image-intensities "[0.005,0.995]" \
        --use-histogram-matching 0 \
        --transform "Rigid[1]" \
        --smoothing-sigmas 0 \
	--shrink-factors 1 \
	--convergence "[10,1.e-8]" 
	echo "RESULT = $?"

#--metric "MeanSquares[fmri_moco_norm_T0000.nii,fmri_moco_norm_T`printf %04d ${files}`.nii,1,32,Regular,0.2]" \

done

done


done
