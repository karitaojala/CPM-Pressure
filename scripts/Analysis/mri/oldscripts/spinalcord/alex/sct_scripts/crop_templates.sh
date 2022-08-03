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


sourcedir=/home/tinnermann/sct/data/PAM50/template
targetdir=/projects/crunchie/remi3/PAM50

if [ ! -d ${targetdir} ]; then
	mkdir  ${targetdir}
fi 

cd ${targetdir} || exit

#~ cp ${sourcedir}/PAM50*.nii.gz ${targetdir}
#~ gunzip PAM50*.nii.gz

#crop templates
sct_crop_image -i PAM50_csf.nii -dim 2 -start 750 -end 980 -o PAM50_csf_crop_5v.nii 
sct_crop_image -i PAM50_t1.nii -dim 2 -start 750 -end 980 -o PAM50_t1_crop_5v.nii 
#~ sct_crop_image -i PAM50_t2.nii -dim 2 -start 750 -end 980 -o PAM50_t2_crop_5v.nii 
#~ sct_crop_image -i PAM50_cord.nii -dim 2 -start 750 -end 980 -o PAM50_cord_crop_5v.nii 
sct_crop_image -i PAM50_levels.nii -dim 2 -start 750 -end 980 -o PAM50_levels_crop_5v.nii 
#~ sct_crop_image -i PAM50_gm.nii -dim 2 -start 750 -end 980 -o PAM50_gm_crop_5v.nii 

#~ sct_crop_image -i PAM50_csf.nii -dim 2 -start 780 -end 860 -o PAM50_csf_crop_1vm.nii 
#~ sct_crop_image -i PAM50_t1.nii -dim 2 -start 780 -end 860 -o PAM50_t1_crop_1vm.nii 
#~ sct_crop_image -i PAM50_t2.nii -dim 2 -start 780 -end 860 -o PAM50_t2_crop_1vm.nii 
#~ sct_crop_image -i PAM50_cord.nii -dim 2 -start 780 -end 860 -o PAM50_cord_crop_1vm.nii 
sct_crop_image -i PAM50_levels.nii -dim 2 -start 780 -end 860 -o PAM50_levels_crop_1vm.nii 
#~ sct_crop_image -i PAM50_gm.nii -dim 2 -start 780 -end 860 -o PAM50_gm_crop_1vm.nii 

#~ sct_crop_image -i PAM50_csf.nii -dim 2 -start 775 -end 865 -o PAM50_csf_crop_1vl.nii 
#~ sct_crop_image -i PAM50_t1.nii -dim 2 -start 775 -end 865 -o PAM50_t1_crop_1vl.nii 
#~ sct_crop_image -i PAM50_t2.nii -dim 2 -start 775 -end 865 -o PAM50_t2_crop_1vl.nii 
#~ sct_crop_image -i PAM50_cord.nii -dim 2 -start 775 -end 865 -o PAM50_cord_crop_1vl.nii 
sct_crop_image -i PAM50_levels.nii -dim 2 -start 775 -end 865 -o PAM50_levels_crop_1vl.nii 
#~ sct_crop_image -i PAM50_gm.nii -dim 2 -start 775 -end 865 -o PAM50_gm_crop_1vl.nii 





