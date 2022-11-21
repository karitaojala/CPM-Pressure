function secondlevel_contrasts_fmri_fourier(options,analysis_version,modelname,subj,copycons,estimate_model)

secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],modelname);
%conpath = fullfile(secondlvlpath,'conimages');
if ~exist(secondlvlpath, 'dir'); mkdir(secondlvlpath); end
%if ~exist(conpath, 'dir'); mkdir(conpath); end

%% Copy 1st level contrasts
if copycons
    
    for sub = subj
        
        name = sprintf('sub%03d',sub);
        disp(name);
        
        firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
        
        % Transfer CON images to 2nd level folder
        norm_con_files = char(spm_select('List', firstlvlpath, ['^' options.preproc.normsmooth_prefix 'con.*nii$']));
        norm_con_files_fp = char(spm_select('FPList', firstlvlpath, ['^' options.preproc.normsmooth_prefix 'con.*nii$']));
        
        for confile = 1:size(norm_con_files)
            newname = norm_con_files(confile,:);
            newname = [newname(1:end-4) '_' name newname(end-3:end)];
            newname = fullfile(conpath,newname);
            copyfile(norm_con_files_fp(confile,:),newname)
            %delete(norm_con_files_fp(confile,:)) % delete old file to avoid duplicates taking a lot of space
        end
        
    end
    
end

secondlvl_maskpath = fullfile(options.path.mridir,'2ndlevel','meanmasks');

con_indices = {1; 2; 3; 4; 16; 17; [3 16]; [4 17]; [5:15 18:28]; 5:15; 18:28; 29:52; 29:46; 47:52};
connames = {'PhasicStim-All' 'VAS-All' ...
    'PhasicStim-EXP' 'VAS-EXP' ...
    'PhasicStim-CON' 'VAS-CON' ...
    'PhasicStim-CON>EXP' 'VAS-CON>EXP' ...
    'TonicStim-All-Ftest' 'Tonic-EXP-Ftest' 'Tonic-CON-Ftest' ...
    'NoiseReg-All-Ftest' 'NoiseReg-Physio-Ftest' 'NoiseReg-Motion-Ftest'};

for con = 1:numel(connames)
    
    clear conlist
    
    contrastpath = fullfile(secondlvlpath,connames{con});
    if ~exist(contrastpath, 'dir'); mkdir(contrastpath); end
    
    %% 2nd level model specification
    matlabbatch{1}.spm.stats.factorial_design.dir = {contrastpath};
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {fullfile(secondlvl_maskpath,options.stats.secondlvl.mask_name)};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    %% 2nd level model estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cellstr(fullfile(contrastpath,'SPM.mat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    %% Define contrasts
    matlabbatch{3}.spm.stats.con.spmmat = {fullfile(contrastpath,'SPM.mat')};
    matlabbatch{3}.spm.stats.con.delete = options.stats.secondlvl.contrasts.delete;
    
    if con <= 6 % One-sample t-tests
        
        con_id = sprintf('%02d',con_indices{con});
        for sub = subj
            name = sprintf('sub%03d',sub);
            conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
            conlist{sub} = cellstr(spm_select('ExtFPList',conpathsub,['^*_00' con_id '.*.nii$'],1));
        end
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = conlist';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = connames{con};
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = options.stats.secondlvl.contrasts.direction;
        
    elseif con == 7 || con == 8 % Paired t-tests
        
        con_id = sprintf('%02d',con_indices{con});
        for sub = subj
            name = sprintf('sub%03d',sub);
            conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
            conlist{sub} = cellstr(spm_select('ExtFPList',conpathsub,['^*_00' con_id '.*.nii$'],1));
        end
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = conlist';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = connames{con};
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = options.stats.secondlvl.contrasts.direction;
        
    elseif con > 8 % F-tests
        
        conf_no = numel(con_indices{con});
        
        for conf = 1:conf_no
            con_id = sprintf('%02d',con_indices{con}(conf));
            for sub = subj
                name = sprintf('sub%03d',sub);
                conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
                conlist{sub} = cellstr(spm_select('ExtFPList',conpathsub,['^*_00' con_id '.*.nii$'],1));
            end
            matlabbatch{1}.spm.stats.factorial_design.des.anova.icell(conf).scans = conlist;
        end
        
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = connames{con};
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = eye(conf_no);
        
    end
    
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = options.stats.secondlvl.contrasts.conrepl.fourier;
    
    % Run either specify, estimate and contrasts, or only contrasts
    if estimate_model
        spm_jobman('run', matlabbatch);
    else
        matlabbatch = matlabbatch{3};
        spm_jobman('run', matlabbatch);
    end
    
    clear matlabbatch
    
end

end