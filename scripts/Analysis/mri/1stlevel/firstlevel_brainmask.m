function firstlevel_brainmask(options,subj)

for sub = subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    if options.spinal
        mask_folder = fullfile(options.path.mridir, name , 'epi-run2');
        mask_folder2 = fullfile(options.path.mridir, name , 'epi-run3');
        mask_folder3 = fullfile(options.path.mridir, name , 'epi-run4');
        mask_folder4 = fullfile(options.path.mridir, name , 'epi-run5');
        input_file = 't2_reg_coarse_seg.nii';
        mask_file = [name '-spinalmask.nii'];
    else
        mask_folder = fullfile(options.path.mridir, name ,'t1_corrected');
        input_file = fullfile(mask_folder,['inv_nlin_c1' name '-t1_corrected.nii']);
        %artifact_mask_file = fullfile(options.path.mridir, name ,'epi-run1','ArtefictMask.nii');
        mask_file = [name '-brainmask-v2.nii'];
    end
    
    b = 1;
    
    % First thresholding of mask
    if options.spinal
        input_file1 = fullfile(mask_folder,input_file);
        input_file2 = fullfile(mask_folder2,input_file);
        input_file3 = fullfile(mask_folder3,input_file);
        input_file4 = fullfile(mask_folder4,input_file);
        matlabbatch{b}.spm.util.imcalc.input = {input_file1 input_file2 input_file3 input_file4}';
        matlabbatch{b}.spm.util.imcalc.output = mask_file;
        matlabbatch{b}.spm.util.imcalc.outdir = {mask_folder};
        matlabbatch{b}.spm.util.imcalc.expression = '(i1+i2+i3+i4)>0';
        b = b + 1;
    else
        matlabbatch{b}.spm.util.imcalc.input = {input_file};
        matlabbatch{b}.spm.util.imcalc.output = mask_file;
        matlabbatch{b}.spm.util.imcalc.outdir = {mask_folder};
        matlabbatch{b}.spm.util.imcalc.expression = 'i1>0.2';
        b = b + 1;
    end
    
    % Smoothing with 2 mm
%     if options.spinal
%         matlabbatch{b}.spm.spatial.smooth.data = {fullfile(mask_folder,input_file)};
%     else
        matlabbatch{b}.spm.spatial.smooth.data = {fullfile(mask_folder,mask_file)};
%     end
    matlabbatch{b}.spm.spatial.smooth.fwhm = [2 2 2];
    matlabbatch{b}.spm.spatial.smooth.dtype = 0;
    matlabbatch{b}.spm.spatial.smooth.im = 0;
    matlabbatch{b}.spm.spatial.smooth.prefix = 's_';
    b = b + 1;
    
    % Final thresholding
%     if options.spinal
%         matlabbatch{b}.spm.util.imcalc.input = {fullfile(mask_folder,['s_' input_file])};
%     else
        matlabbatch{b}.spm.util.imcalc.input = {fullfile(mask_folder,['s_' mask_file])};
%     end
    matlabbatch{b}.spm.util.imcalc.output = mask_file;
    matlabbatch{b}.spm.util.imcalc.outdir = {mask_folder};
    matlabbatch{b}.spm.util.imcalc.expression = 'i1>0';

    spm_jobman('run', matlabbatch);
    
    clear matlabbatch
    
    delete(fullfile(mask_folder,['s' mask_file]))
    delete(fullfile(mask_folder,['s_' mask_file]))
    delete(fullfile(mask_folder,['s_' input_file]))
    
end

end