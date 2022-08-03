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

#subejcts in which the labeling failed
listofSubs=(8 15 21 24 29 33 37 40 43 45 47 49 62 78 84 99 )
   
   
for subject in ${listofSubs[@]}; do

echo "Sub${subject}"

subdir=${basedir}Sub`printf %02d ${subject}`

targetdir=${subdir}/T1/

# t1
# ===========================================================================================
 cd "$targetdir" || exit

# if labeling of vertebrae fails, manual help is required
sct_label_utils -i t1.nii -create-viewer 3 -o label_c2c3.nii -msg "Click at the posterior tip of #C2/C3 inter-vertebral disc" 

done
