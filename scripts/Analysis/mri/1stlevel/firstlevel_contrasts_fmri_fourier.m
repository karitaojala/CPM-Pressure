function firstlevel_contrasts_fmri_fourier(options,analysis_version,model,subj)

for sub = subj
    
    clear conweights conweights_CON conweights_EXP
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    
    % Load SPM to extract 1st level regressor numbers
    load(fullfile(firstlvlpath,'SPM.mat'))
    
    % Define conditions & extract number of regressors
    if sub == 5
        runs = [2 3 5];
    else
        runs = options.acq.exp_runs;
    end
    
    block = 1;
    
    for run = runs
        
        condfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-onsets.mat']);
        load(condfile,'conditions')
        cond_runs(block) = conditions(1); %#ok<*AGROW> % whole run is same condition
        no_reg(block) = numel(SPM.Sess(block).col);
        block = block + 1;
        
    end
    cond_runs(cond_runs == 0) = -1;
    run_ind = [1 no_reg(1)+1 no_reg(1)+no_reg(2)+1 no_reg(1)+no_reg(2)+no_reg(3)+1];
    run_ind = run_ind(1:numel(runs));
    
    % Add conditions
    cond_Phasic = model.phasicIncluded;
    cond_VAS = model.VASincluded;
    cond_Tonic = 11; % 5 sine, 5 cosine, 1 Henning
    no_cond = cond_Phasic+cond_VAS+cond_Tonic;
    
    % Index for accumulating contrasts
    con_ind = 0;
    
    % Contrast names
    % Sanity check contrasts
    %   1) Pain ON > baseline (regardless of condition)
    %   2) VAS ON > baseline (regardless of condition)
    
    % Sanity check
    connames = {'Pain-baseline' 'VAS-baseline'};
    no_contr = cond_Phasic+cond_VAS;
    conweights = eye(no_contr); % first 2 so no need to take rest of the columns/regressors into account
    conrepl = 'replsc';
    
    for con = 1:no_contr % Loop over contrasts for current model
        con_ind = con_ind + 1;
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.name = connames{con}; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.weights = conweights(con,:); % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.sessrep = conrepl; % Contrast replication across sessions
    end
    
    % Phasic stimulus CON/EXP
    connames = {'PhasicStim' 'VAS' 'TonicHanning'...
        'TonicSine1' 'TonicCosine1' 'TonicSine2' 'TonicCosine2' ...
        'TonicSine3' 'TonicCosine3' 'TonicSine4' 'TonicCosine4' ...
        'TonicSine5' 'TonicCosine5' ...
        };
    %no_reg = numel(connames) + options.preproc.no_noisereg;
    no_contr = numel(connames); % CON and EXP contrasts for each regressor
    conweights = zeros(no_contr,sum(no_reg)); % initialize zero matrix
    
    if sub == 5 % only 1 experimental run but 2 control runs
        cond_runs_scaled(cond_runs == 1) = 1;
        cond_runs_scaled(cond_runs == -1) = -1/2;
    else
        cond_runs_scaled = cond_runs/2;
    end
    
    for cn = 1:no_contr
        conweights(cn,run_ind) = cond_runs_scaled; 
        run_ind = run_ind + 1;
    end
    
    conrepl = 'none';
    
    % EXP contrasts
    conweights_EXP = conweights;
    conweights_EXP(conweights_EXP == -0.5) = 0; % remove control condition
    for con = 1:no_contr % Loop over contrasts for current model
        con_ind = con_ind + 1;
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.name = [connames{con} '-EXP']; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.weights = conweights_EXP(con,:); % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.sessrep = conrepl; % Contrast replication across sessions
    end
    
    % CON contrasts (flipped)
    conweights_CON = -conweights; % flip weights
    conweights_CON(conweights_CON == -0.5) = 0; % remove experimental condition
    for con = 1:no_contr % Loop over contrasts for current model
        con_ind = con_ind + 1;
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.name = [connames{con} '-CON']; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.weights = conweights_CON(con,:); % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.sessrep = conrepl; % Contrast replication across sessions
    end

    % Noise regressor contrasts
    no_contr = options.preproc.no_noisereg;
    no_reg = no_cond + options.preproc.no_noisereg;
    conweights = zeros(no_contr,no_reg);
    col_ind = (no_cond+1):(no_cond+no_contr);
    conweights(:,col_ind) = eye(no_contr,no_contr);
    conrepl = 'replsc';
    
    for con = 1:no_contr % Loop over contrasts for current model
        con_ind = con_ind + 1;
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.name = sprintf('NoiseReg%02d',con); % Contrast name
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.weights = conweights(con,:); % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{con_ind}.tcon.sessrep = conrepl; % Contrast replication across sessions
    end
    
    matlabbatch{1}.spm.stats.con.spmmat = {fullfile(firstlvlpath, 'SPM.mat')};
    matlabbatch{1}.spm.stats.con.delete = options.stats.firstlvl.contrasts.delete; % Deleting old contrast
    
    %% Run matlabbatch
   spm_jobman('run', matlabbatch);
    
    save(fullfile(firstlvlpath,'batch_firstlevel_contrasts'), 'matlabbatch')
    clear matlabbatch
    
end

end