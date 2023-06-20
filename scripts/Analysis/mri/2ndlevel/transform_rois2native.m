function transform_rois2native(options,rois,subj)

roilist = options.stats.secondlvl.roi.names(rois);
roilist = strcat(roilist,'.nii');
roilist_fp = fullfile(options.path.mridir,'2ndlevel','roimasks','final',roilist);

s = 1;

for sub = 1%subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    mean_file       = fullfile(options.path.mridir,name,'epi-run1',['meana' name '-epi-run1-brain.nii']);
    transform_file  = fullfile(options.path.mridir,name,'epi-run1','y_inv_epi_2_template.nii');
    %nlin_coreg_file = fullfile(options.path.mridir,name,'epi-run1',['y_meana' name '-epi-run1-brain.nii']);
    
    matlabbatch{s}.spm.util.defs.comp{1}.def = cellstr(transform_file);
    matlabbatch{s}.spm.util.defs.out{1}.pull.fnames = roilist_fp';
    %matlabbatch{s}.spm.util.defs.out{1}.push.weight = {''};
    matlabbatch{s}.spm.util.defs.out{1}.pull.interp = 4;
    matlabbatch{s}.spm.util.defs.out{1}.pull.mask = 1;
    matlabbatch{s}.spm.util.defs.out{1}.pull.savedir.savesrc = 1;
    %matlabbatch{s}.spm.util.defs.out{1}.push.fov.file = cellstr(mean_file);
    %matlabbatch{s}.spm.util.defs.out{1}.push.preserve = 0;
    matlabbatch{s}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
    matlabbatch{s}.spm.util.defs.out{1}.pull.prefix = 'native_';
    s = s + 1;
    
end

spm_jobman('initcfg');
spm_jobman('run',matlabbatch);

end