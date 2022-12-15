function secondlevel_contrasts_fmri_fourier(options,analysis_version,modelname,subj,estimate_model)

secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],modelname);
if ~exist(secondlvlpath, 'dir'); mkdir(secondlvlpath); end

secondlvl_maskpath = fullfile(options.path.mridir,'2ndlevel','meanmasks');

con_indices = {1; 2; 3; 4; 16; 17; [3 16]; [4 17]; [5:15 18:28]; 29:52};
connames = {'PhasicStim-All' 'VAS-All' ...
    'PhasicStim-EXP' 'VAS-EXP' ...
    'PhasicStim-CON' 'VAS-CON' ...
    'PhasicStim-CON-EXP' 'VAS-CON-EXP' ...
    'TonicStim-All' ...
    'NoiseReg-All'};

conprefix = [options.preproc.smooth_prefix options.preproc.norm_prefix];

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
        
        clear conlist
        con_id = sprintf('%02d',con_indices{con});
        for sub = 1:numel(subj)
            name = sprintf('sub%03d',subj(sub));
            conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
            conlist(sub) = cellstr(spm_select('ExtFPList',conpathsub,['^' conprefix 'con_00' con_id '.*.nii$'],1)); %#ok<*AGROW>
        end
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = conlist';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = connames{con};
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = options.stats.secondlvl.contrasts.direction;
        
    elseif con == 7 || con == 8 % Paired t-tests
        
        for sub = 1:numel(subj)
            clear conlist
            name = sprintf('sub%03d',subj(sub));
            conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
            con_id = sprintf('%02d',con_indices{con}(1));
            conlist(1) = cellstr(spm_select('ExtFPList',conpathsub,['^' conprefix 'con_00' con_id '.*.nii$'],1));
            con_id = sprintf('%02d',con_indices{con}(2));
            conlist(2) = cellstr(spm_select('ExtFPList',conpathsub,['^' conprefix 'con_00' con_id '.*.nii$'],1));
            matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(sub).scans = conlist';
        end
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = connames{con};
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [-1 1] * options.stats.secondlvl.contrasts.direction; % [EXP CON] dir 1: CON > EXP, dir -1: EXP > CON
        
    else % F-tests
        
        conf_no = numel(con_indices{con});
        
        for conf = 1:conf_no
            clear conlist
            con_id = sprintf('%02d',con_indices{con}(conf));
            for sub = 1:numel(subj)
                name = sprintf('sub%03d',subj(sub));
                conpathsub = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
                conlist(sub) = cellstr(spm_select('ExtFPList',conpathsub,['^' conprefix 'con_00' con_id '.*.nii$'],1));
            end
            matlabbatch{1}.spm.stats.factorial_design.des.anova.icell(conf).scans = conlist';
            matlabbatch{1}.spm.stats.factorial_design.des.anova.dept = 0;
            matlabbatch{1}.spm.stats.factorial_design.des.anova.variance = 1;
        end
        
        % Contrast over all regressors
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = connames{con};
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = eye(conf_no);
        
        if con == 9
            
            cn = 1;
            
            % EXP contrast
            cn = cn + 1;
            matlabbatch{3}.spm.stats.con.consess{cn}.fcon.name = 'TonicStim-EXP';
            matlabbatch{3}.spm.stats.con.consess{cn}.fcon.weights = [eye(conf_no/2) zeros(conf_no/2)];
            
            % CON contrast
            cn = cn + 1;
            matlabbatch{3}.spm.stats.con.consess{cn}.fcon.name = 'TonicStim-CON';
            matlabbatch{3}.spm.stats.con.consess{cn}.fcon.weights = [zeros(conf_no/2) eye(conf_no/2)];
            
            % EXP > CON contrast
            cn = cn + 1;
            matlabbatch{3}.spm.stats.con.consess{cn}.fcon.name = 'TonicStim-EXP-CON';
            matlabbatch{3}.spm.stats.con.consess{cn}.fcon.weights = [eye(conf_no/2) -eye(conf_no/2)];
            
            % Load betas wave contrast
            nscans = options.acq.n_scans(2);
            tonicBF_file = fullfile(options.path.mridir,'sub001','1stlevel',['Version_' analysis_version],'Fourier_tonic_only','SPM.mat');
            SPM_tonicBF = load(tonicBF_file);
            tonicFourier_des = SPM_tonicBF.SPM.xX.X;
            tonicFourier_desmat = tonicFourier_des(1:nscans,1:(conf_no/2)); % take 1st run regressors for Fourier set
            
            tonicPmod_file = fullfile(options.path.mridir,'sub001','1stlevel',['Version_' analysis_version],'HRF_phasic_tonic_pmod','SPM.mat');
            SPM_tonicPmod = load(tonicPmod_file);
            %tonicPmod_con = SPM_tonicPmod.SPM.xX.X(1:nscans,2); % take 1st run regressor for tonic parametric modulator (pressure)
            col_ind = find(contains(SPM_tonicPmod.SPM.xX.name,'Sn(2) TonicStimxTonicPressure^1*bf(1)'));
            tonicPmod_exp = SPM_tonicPmod.SPM.xX.X((1:nscans)+nscans,col_ind); %#ok<FNDSB>
            %beta_con = pinv(tonicFourier_desmat)*tonicPmod_con; % retrieve betas for each Fourier set regressor when predicting tonic pressure
            %beta_con = beta_con';
            %beta_con_mc = beta_con-mean(beta_con);
            beta_exp = pinv(tonicFourier_desmat)*tonicPmod_exp;
            beta_exp = beta_exp';
            beta_exp_mc = beta_exp-mean(beta_exp);
            
            % Wave contrasts t-tests
            matlabbatch{4}.spm.stats.factorial_design.des.t1.scans = conlist';
            
            %cn = 0;
            
            % EXP wave contrast
            cn = cn + 1;
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.name = 'TonicStim-EXP-wave';
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.weights = [beta_exp_mc zeros(1,conf_no/2)];
            
            % CON wave contrast
            cn = cn + 1;
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.name = 'TonicStim-CON-wave';
            %matlabbatch{3}.spm.stats.con.consess{cn}.tcon.weights = [zeros(1,conf_no/2) beta_con_mc];
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.weights = [zeros(1,conf_no/2) beta_exp_mc]; % same wave shape for both cond
            
            % EXP > CON wave contrast
            cn = cn + 1;
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.name = 'TonicStim-EXP>CON-wave';
            %matlabbatch{3}.spm.stats.con.consess{cn}.tcon.weights = [beta_exp_mc -beta_con_mc];
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.weights = [beta_exp_mc -beta_exp_mc];
            
            % EXP & CON wave average
            cn = cn + 1;
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.name = 'TonicStim-EXP-CON-avg-wave';
            %matlabbatch{3}.spm.stats.con.consess{cn}.tcon.weights = [beta_exp_mc beta_con_mc];
            matlabbatch{3}.spm.stats.con.consess{cn}.tcon.weights = [beta_exp_mc beta_exp_mc];
            
        elseif con == 10
            
            % Physio regressors only contrast
            matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'NoiseReg-Physio';
            matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = eye(options.preproc.no_physioreg);
            
            % Motion regressors only contrast
            matlabbatch{3}.spm.stats.con.consess{3}.fcon.name = 'NoiseReg-Motion';
            conweights = eye(options.preproc.no_noisereg);
            conweights(:,1:options.preproc.no_physioreg) = 0;
            matlabbatch{3}.spm.stats.con.consess{3}.fcon.weights = conweights;
            
        end
        
    end
    
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = options.stats.secondlvl.contrasts.conrepl.fourier;
    
    % Run either specify, estimate and contrasts, or only contrasts
    if estimate_model
        spm_jobman('run', matlabbatch);
    else
        conbatch = matlabbatch{3};
        clear matlabbatch
        matlabbatch{1} = conbatch;
        spm_jobman('run', matlabbatch);
    end
    
    clear matlabbatch
    
end

end