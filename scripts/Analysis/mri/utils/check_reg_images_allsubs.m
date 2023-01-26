options = get_options();
subj = options.subj.all_subs;

% check_reg_images_allsubs(options,subj)
% 
% function check_reg_images_allsubs(options,subj)

for sub = subj
    
    fprintf('Check image registration...\n')
    name = sprintf('sub%03d',sub);
    disp(name);
    
    image1 = fullfile(options.path.mridir, name ,'t1_corrected', ['inv_nlin_c1' name '-t1_corrected.nii']);
%     image1 = fullfile(options.path.mridir, name ,'t1_corrected', 'noiseROI', ['inv_nlin_c2' name '-t1_corrected.nii']);
%     image2 = fullfile(options.path.mridir, name ,'t1_corrected', 'noiseROI', ['noiseROI_inv_nlin_c2' name '-t1_corrected.nii']);
%     image3 = fullfile(options.path.mridir, name ,'t1_corrected', 'noiseROI', ['inv_nlin_c3' name '-t1_corrected.nii']);
%     image4 = fullfile(options.path.mridir, name ,'t1_corrected', 'noiseROI', ['noiseROI_inv_nlin_c3' name '-t1_corrected.nii']);
    image2 = fullfile(options.path.mridir, name ,'epi-run1', ['meana' name '-epi-run1-brain.nii']);
%     image4 = fullfile(options.path.mridir, name ,'t1_corrected', ['c3' name '-t1_corrected.nii']);
%     image5 = fullfile(options.path.mridir, name ,'t1_corrected', [name '-t1_corrected.nii']);
%     imagelist = cellstr([image1, image2, image3]);
    
    spm_check_registration(image1,image2)
%     spm_check_registration(image1,image2,image3,image4)

end

% end