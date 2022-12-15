function secondlevel_contrasts_fmri(options,analysis_version,modelname,basisF,subj,contrasts,congroup,estimate_model)

secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],modelname,congroup);
if ~exist(secondlvlpath, 'dir'); mkdir(secondlvlpath); end

secondlvl_maskpath = fullfile(options.path.mridir,'2ndlevel','meanmasks');
conprefix = [options.preproc.smooth_prefix options.preproc.norm_prefix];

matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {fullfile(secondlvl_maskpath,options.stats.secondlvl.mask_name)};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

con_ind = 0;

for con = contrasts
    
    con_ind = con_ind + 1;
    % 2nd level model specification
    if strcmp(basisF,'HRF')
        
        if strcmp(congroup,'SanityCheck')
            conname = options.stats.secondlvl.contrasts.names.sanitycheck{con};
        elseif strcmp(congroup,'SanityCheckTonicPmod')
            conname = options.stats.secondlvl.contrasts.names.sanitycheck_tonic{con};
        elseif strcmp(congroup,'TonicPressure')
            conname = options.stats.secondlvl.contrasts.names.tonic{con};
        elseif strcmp(congroup,'CPM')
            conname = options.stats.secondlvl.contrasts.names.cpm{con};
        elseif strcmp(congroup,'PhysioReg')
            conname = options.stats.secondlvl.contrasts.names.physioreg{con};
        end
        
%         dash_ind = strfind(conname,'-');
%         if numel(dash_ind) == 1 && ~strcmp(congroup,'TonicPressure')
%             actualname = replace(conname,'-','>');
%         elseif numel(dash_ind) > 1 && ~strcmp(congroup,'TonicPressure')
%             conname_direction(dash_ind(end)) = '>';
%             actualname = conname_direction;
%         else
%             
%         end
%         
%         if options.stats.secondlvl.contrasts.direction == -1
%             actualname = replace(conname,'>','<');
%         end

        actualname = conname;
        
        contrastpath = fullfile(secondlvlpath,conname);
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = actualname;
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = options.stats.secondlvl.contrasts.direction;
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = options.stats.secondlvl.contrasts.conrepl.hrf;
        
    elseif strcmp(basisF,'FIR')
        contrastpath = secondlvlpath;
    end
    
    if ~exist(contrastpath, 'dir'); mkdir(contrastpath); end
    
    con_id = sprintf('%04d',con_ind);
    
    matlabbatch{1}.spm.stats.factorial_design.dir = {contrastpath};
    
    if strcmp(basisF,'HRF')
        clear conlist
        for sub = 1:numel(subj)
            name = sprintf('sub%03d',subj(sub));
            conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
            conlist(sub) = cellstr(spm_select('ExtFPList',conpathsub,['^' conprefix 'con_' con_id '.nii$'],1)); %#ok<*AGROW>
        end
        %conlist = cellstr(spm_select('ExtFPList',conpath,['^*_00' con_id '.*.nii$'],1));
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = conlist';
        
    elseif strcmp(basisF,'FIR')
        if numel(contrasts) <= 2 % separate contrasts for CON and EXP stimuli
            cons2take = [1:100; 101:200];
            cons2take = cons2take(con,:);
            for conf = 1:numel(cons2take)
                clear conlist
                for sub = 1:numel(subj)
                    name = sprintf('sub%03d',subj(sub));
                    conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
                    conlist(sub) = cellstr(spm_select('ExtFPList',conpathsub,sprintf('^%scon_%04d.*.nii$',conprefix,cons2take(conf)),1));
                end
                %conlist = cellstr(spm_select('ExtFPList',conpath,sprintf('^*_%04d.*.nii$', cons2take(conf)),1));
                matlabbatch{1}.spm.stats.factorial_design.des.anova.icell(conf).scans = conlist';
            end
            matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = 'FIR';
            matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = eye(numel(cons2take));
            matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = 'none';%options.stats.secondlvl.contrasts.conrepl.fir;
        else % 1 contrast per timebin
            clear conlist
            for sub = 1:numel(subj)
                name = sprintf('sub%03d',subj(sub));
                conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
                conlist(sub) = cellstr(spm_select('ExtFPList',conpathsub,sprintf('^%scon_%s.*.nii$',conprefix,con_id),1));
            end
            %conlist = cellstr(spm_select('ExtFPList',conpath,['^*_00' con_id '.*.nii$'],1));
            matlabbatch{1}.spm.stats.factorial_design.des.anova.icell(con).scans = conlist';
        end
        
    end
    
    % 2nd level model estimation
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cellstr(fullfile(contrastpath,'SPM.mat'));
    
    % Contrasts
    matlabbatch{3}.spm.stats.con.spmmat = {fullfile(contrastpath,'SPM.mat')};
    matlabbatch{3}.spm.stats.con.delete = options.stats.secondlvl.contrasts.delete;
    
    %% Run matlabbatch
    if strcmp(basisF,'HRF') || numel(contrasts) <= 2
        if estimate_model % estimate model and contrasts
            spm_jobman('run', matlabbatch);
        else % only contrasts
            matlabbatch2{1} = matlabbatch{3}; 
            spm_jobman('run', matlabbatch2);
        end
    end
    %save(fullfile(secondlvlpath,'batch_secondlevel'), 'matlabbatch')
    clear matlabbatch{3}.spm.stats.con
    
end

if strcmp(basisF,'FIR') && estimate_model && numel(contrasts) > 2 % only run all contrast images together
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = 'FIR';
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = eye(numel(contrasts));
    matlabbatch{3}.spm.stats.con.consess{1}.fcon.sessrep = options.stats.secondlvl.contrasts.conrepl.fir;
    spm_jobman('run', matlabbatch);
end

clear matlabbatch

end