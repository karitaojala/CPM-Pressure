function firstlevel_smooth_normalize_fmri(options,analysis_version,model,subj,run_norm,run_smooth)

for sub = subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    
    for cong = 1:numel(model.congroups_1stlvl.names)
        
        n = 0;
        
        contrasts = model.contrasts_1stlvl.indices{cong};
        
        % Retrieve 1st level con images
        cn = 1;
        for con = contrasts
            con_files{cn} = char(fullfile(firstlvlpath, sprintf('con_00%02d.nii',con)));
            %con_files{cn} = char(spm_select('FPList', firstlvlpath, sprintf('^con_00%02d.*nii$',con)));
            cn = cn + 1;
        end
        
        input_files = cellstr(char(con_files));
        input_files = input_files(~cellfun('isempty',input_files));
        %mask_file = char(spm_select('FPList', firstlvlpath, '^mask.*nii$'));
        %con_files{end+1} = mask_file;
        
        if run_norm
            
            % Retrieve flow field
            deffield_file = fullfile(options.path.mridir,name,'epi-run1','y_epi_2_template.nii');
            %     flowfield_file = fullfile(mridir,name,'t1_corrected','u_rc1sub001-t1_corrected.nii');
            
            % Normalization using nlin coreg + DARTEL
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
        
        cn = 1;
        for con = 1:numel(contrasts)
            [fp,fn,ext] = fileparts(input_files{con});
            norm_con_files{cn} = fullfile(firstlvlpath, [options.preproc.norm_prefix fn ext]);
            cn = cn + 1;
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
        
        for delfile = 1:numel(norm_con_files)
            delete(char(norm_con_files{delfile})) % delete normalized only files to avoid taking up too much space
        end
        clear matlabbatch input_files con_files norm_con_files
        
    end
    
end

end