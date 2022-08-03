#!/bin/bash
#

# Abort on error
set -e

PATH=~/sct/bin:$PATH

basedir=/projects/crunchie/remi3/

export TMPDIR=${basedir}tmp

logdir=${basedir}logs/

filepath=$(readlink -f $0)
filename=$( basename "$( readlink -f "$0" )"  .sh)
savefile=${filename}$(date '+_%Y_%m_%d_%H%M%S.sh')

cp ${filepath} ${logdir}${savefile}


sourcedir=/home/tinnermann/sct/data/PAM50/atlas
targetdir=/projects/crunchie/remi3/PAM50

 

cd ${targetdir} || exit

cp ${sourcedir}/PAM50_atlas_32.nii.gz ${targetdir}
cp ${sourcedir}/PAM50_atlas_34.nii.gz ${targetdir}

gunzip PAM50*.nii.gz

#crop templates
sct_crop_image -i PAM50_atlas_32.nii -dim 2 -start 800 -end 835 -o PAM50_atlas_32_l5.nii 
sct_crop_image -i PAM50_atlas_34.nii -dim 2 -start 800 -end 835 -o PAM50_atlas_34_l5.nii 


#~ sct_crop_image -i PAM50_csf.nii -dim 2 -start 780 -end 860 -o PAM50_csf_crop_1vm.nii 


#~ sct_crop_image -i PAM50_csf.nii -dim 2 -start 775 -end 865 -o PAM50_csf_crop_1vl.nii 





