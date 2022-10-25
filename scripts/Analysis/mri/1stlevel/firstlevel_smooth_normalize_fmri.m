function firstlevel_smooth_normalize_fmri(options,analysis_version,modelname,subj,contrasts,run_norm,run_smooth)

for sub = subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    
    n = 0;
    
    % Retrieve flow field
    deffield_file = fullfile(options.path.mridir,name,'epi-run1','y_epi_2_template.nii');
%     flowfield_file = fullfile(mridir,name,'t1_corrected','u_rc1sub001-t1_corrected.nii');
    
    % Retrieve 1st level con images
    con_files = char(spm_select('FPList', firstlvlpath, '^con.*nii$'));
    con_files = cellstr(char(con_files));
    ess_files = char(spm_select('FPList', firstlvlpath, '^ess.*nii$'));
    ess_files = cellstr(char(ess_files));
    
    input_files = [con_files; ess_files];
    %mask_file = char(spm_select('FPList', firstlvlpath, '^mask.*nii$'));
    %con_files{end+1} = mask_file;
    
    % Normalization using nlin coreg + DARTEL
    if run_norm
        n = n + 1;
        matlabbatch{n}.spm.util.defs.comp{1}.def = {deffield_file};
        matlabbatch{n}.spm.util.defs.out{1}.pull.fnames = input_files;
        matlabbatch{n}.spm.util.defs.out{1}.pull.savedir.savesrc = 1;
        matlabbatch{n}.spm.util.defs.out{1}.pull.interp = 4;
        matlabbatch{n}.spm.util.defs.out{1}.pull.mask = 1;
        matlabbatch{n}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
        matlabbatch{n}.spm.util.defs.out{1}.pull.prefix = options.preproc.norm_prefix;
        
    end
    % Retrieve normalized 1st level con images
%     norm_con_files = char(spm_select('FPList', firstlvlpath, ['^' norm_prefix 'con.*nii$']));
%     norm_con_files = cellstr(char(norm_con_files));
    
    for con = 1:numel(contrasts)
        [fp,fn,ext] = fileparts(input_files{con});
        norm_con_files{con} = fullfile(firstlvlpath, [options.preproc.norm_prefix fn ext]);
    end
    norm_con_files = norm_con_files';
    
    % Smoothing
    if run_smooth
        n = n + 1;
        matlabbatch{n}.spm.spatial.smooth.data = norm_con_files;
        matlabbatch{n}.spm.spatial.smooth.fwhm = options.preproc.smooth_kernel;
        matlabbatch{n}.spm.spatial.smooth.prefix = options.preproc.smooth_prefix;
    end
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    clear matlabbatch con_files norm_con_files
    
end

end