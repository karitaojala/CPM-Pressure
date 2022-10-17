function firstlevel_brainmask(options,subj)

for sub = subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    mask_folder = fullfile(options.path.mridir, name ,'t1_corrected');
    gm_file = fullfile(mask_folder,['c1' name '-t1_corrected.nii']);
    mask_file = [name '-brainmask.nii'];
    
    % First thresholding of GM mask from segmentation
    matlabbatch{1}.spm.util.imcalc.input = {gm_file};
    matlabbatch{1}.spm.util.imcalc.output = mask_file;
    matlabbatch{1}.spm.util.imcalc.outdir = {mask_folder};
    matlabbatch{1}.spm.util.imcalc.expression = 'i1>0.2';
    
    % Smoothing with 3 mm
    matlabbatch{2}.spm.spatial.smooth.data = {fullfile(mask_folder,mask_file)};
    matlabbatch{2}.spm.spatial.smooth.fwhm = [3 3 3];
    matlabbatch{2}.spm.spatial.smooth.dtype = 0;
    matlabbatch{2}.spm.spatial.smooth.im = 0;
    matlabbatch{2}.spm.spatial.smooth.prefix = 's_';

    % Final thresholding
    matlabbatch{3}.spm.util.imcalc.input = {fullfile(mask_folder,['s_' mask_file])};
    matlabbatch{3}.spm.util.imcalc.output = mask_file;
    matlabbatch{3}.spm.util.imcalc.outdir = {mask_folder};
    matlabbatch{3}.spm.util.imcalc.expression = 'i1>0';

    spm_jobman('run', matlabbatch);
    
    clear matlabbatch
    
    delete(fullfile(mask_folder,['s' mask_file]))
    delete(fullfile(mask_folder,['s_' mask_file]))
    
end

end