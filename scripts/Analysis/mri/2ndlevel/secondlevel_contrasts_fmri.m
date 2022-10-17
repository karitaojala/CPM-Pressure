function secondlevel_contrasts_fmri(options,analysis_version,modelname,basisF,subj,contrasts,copycons,congroup)

secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],modelname,congroup);
conpath = fullfile(secondlvlpath,'conimages');
%modelpath = fullfile(firstlevelpath,modelname);
if ~exist(secondlvlpath, 'dir'); mkdir(secondlvlpath); mkdir(conpath); end

secondlvl_maskpath = fullfile(options.path.mridir,'2ndlevel','meanmasks');

if copycons
    
    for sub = subj
        
        name = sprintf('sub%03d',sub);
        disp(name);
        
        firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
        
        % Transfer CON images to 2nd level folder
        norm_con_files = char(spm_select('List', firstlvlpath, ['^' options.preproc.normsmooth_prefix '.*nii$']));
        norm_con_files_fp = char(spm_select('FPList', firstlvlpath, ['^' options.preproc.normsmooth_prefix '.*nii$']));
        
        for confile = 1:size(norm_con_files)
            newname = norm_con_files(confile,:);
            newname = [newname(1:end-4) '_' name newname(end-3:end)];
            newname = fullfile(conpath,newname);
            copyfile(norm_con_files_fp(confile,:),newname)
        end
        
    end
    
end

for con = contrasts
    % 2nd level model specification
    contrastpath = fullfile(secondlvlpath,options.stats.secondlvl.contrasts.contrastnames{con});
    if ~exist(contrastpath, 'dir'); mkdir(contrastpath); end
    
    con_id = sprintf('%02d',con);
    
    matlabbatch{1}.spm.stats.factorial_design.dir = {fullfile(secondlvlpath,options.stats.secondlvl.contrasts.contrastnames{con})};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = cellstr(spm_select('ExtFPList',conpath,['^*_00' con_id '.*.nii$'],1));
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {fullfile(secondlvl_maskpath,options.stats.secondlvl.mask_name)}; 
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    % 2nd level model estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cellstr(fullfile(contrastpath,'SPM.mat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    % Contrasts
    matlabbatch{3}.spm.stats.con.spmmat = {fullfile(contrastpath,'SPM.mat')};
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = options.stats.secondlvl.contrasts.actualnames{con};
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = options.stats.secondlvl.contrasts.direction;
    if strcmp(basisF,'HRF')
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = options.stats.secondlvl.contrasts.conrepl.hrf;
    elseif strcmp(basisF,'FIR')
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = options.stats.secondlvl.contrasts.conrepl.fir;
    end
    matlabbatch{3}.spm.stats.con.delete = 1;
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    save(fullfile(secondlvlpath,'batch_secondlevel'), 'matlabbatch')
    clear matlabbatch
    
end

end