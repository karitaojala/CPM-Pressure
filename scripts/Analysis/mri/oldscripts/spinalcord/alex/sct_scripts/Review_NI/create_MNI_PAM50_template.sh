PATH=~/sct/bin:$PATH

basedir=/home/tinnermann/

cd ${basedir} || exit

#~ # Pad the MNI template 
#~ sct_image -i /common/apps/fsl/data/standard/MNI152_T1_0.5mm.nii.gz -pad-asym 0,0,100,0,300,0 -o MNI152_T1_0.5mm_pad.nii.gz
#~ # Bring the PAM50_t1 template into the padded MNI space
#~ sct_register_multimodal -i /home/tinnermann/sct/data/PAM50/template/PAM50_t1.nii.gz -d MNI152_T1_0.5mm_pad.nii.gz -identity 1
#~ # Scale the intensity of the PAM50 template to match that of the MNI template (signal value estimated at 160 in the white matter of the ICBM152_0.5 template)
#~ sct_maths -i PAM50_t1_reg.nii.gz -div 6.25 -o PAM50_t1_reg_norm.nii.gz
#~ # Mask the PAM50 above a given slice
#~ sct_crop_image -i PAM50_t1_reg_norm.nii.gz -dim 2 -start 0 -end 310 -b 0 -o PAM50_t1_reg_norm_crop.nii.gz
#~ # Mask the MNI template below the same slice
#~ sct_crop_image -i MNI152_T1_0.5mm_pad.nii.gz -dim 2 -start 311 -end 644 -b 0 -o MNI152_T1_0.5mm_pad_crop.nii.gz
#~ # Add the PAM50 to the padded MNI template image
#~ sct_maths -i MNI152_T1_0.5mm_pad_crop.nii.gz -add PAM50_t1_reg_norm_crop.nii.gz -o MNI152-PAM50_T1_0.5mm.nii.gz
#~ # And the magic happens!
#~ fsleyes MNI152-PAM50_T1_0.5mm.nii.gz &



# Pad the MNI template 
sct_image -i /projects/crunchie/remi3_old/mean_skull_strip.nii -pad-asym 0,0,0,0,150,0 -o mean_skull_strip_pad.nii
#sct_image -i mean_skull_strip.nii -pad-asym 0,0,0,0,150,0 -o mean_skull_strip_pad.nii

# Bring the PAM50_t1 template into the padded MNI space
sct_register_multimodal -i /home/tinnermann/sct/data/PAM50/template/PAM50_t1.nii.gz -d mean_skull_strip_pad.nii -identity 1

# Mask the PAM50 above a given slice
sct_crop_image -i PAM50_t1_reg.nii -dim 2 -start 65 -end 150 -b 0 -o PAM50_t1_reg_crop.nii
sct_crop_image -i PAM50_t1_reg_crop.nii -dim 1 -start 40 -end 70 -b 0 -o PAM50_t1_reg_crop.nii
sct_crop_image -i PAM50_t1_reg_crop.nii -dim 0 -start 45 -end 75 -b 0 -o PAM50_t1_reg_crop.nii

# Mask the MNI template below the same slice
sct_crop_image -i mean_skull_strip_pad.nii -dim 2 -start 151 -end 270 -b 0 -o mean_skull_strip_pad_crop.nii

# Scale the intensity of the PAM50 template to match that of the MNI template (signal value estimated at 160 in the white matter of the ICBM152_0.5 template)
sct_maths -i PAM50_t1_reg_crop.nii -div 2.06 -o PAM50_t1_reg_crop_norm.nii

# Add the PAM50 to the padded MNI template image
sct_maths -i mean_skull_strip_pad_crop.nii -add PAM50_t1_reg_crop_norm.nii -o mean_skull_strip_PAM50_T1_0.5mm.nii

#~ # And the magic happens!
#~ fsleyes MNI152-PAM50_T1_0.5mm.nii.gz &