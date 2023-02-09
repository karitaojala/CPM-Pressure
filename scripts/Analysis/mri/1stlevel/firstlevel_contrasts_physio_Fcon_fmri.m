function firstlevel_contrasts_physio_Fcon_fmri(options,analysis_version,model,subj)

for sub = subj
    
    clear conweights cond_runs
    
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
        cond_runs(block) = conditions(1); %#ok<*AGROW> % whole run is same tonic stimulus condition (CON or EXP)
        
        if sessConcatenat % runs concatenated in the design matrix
            no_reg = numel(SPM.Sess.col); % retrieve number of regressors for the run
        else
            no_reg(block) = numel(SPM.Sess(block).col);
        end
        
        block = block + 1;
        
    end
    
    if ~model.sessConcatenat % calculate regressor indices for this run if runs are not concatenated
        run_ind = [1 no_reg(1)+1 no_reg(1)+no_reg(2)+1 no_reg(1)+no_reg(2)+no_reg(3)+1]; % 1st regressor for each run
        run_ind = run_ind(1:numel(runs));
    end
    
    cond_runs(cond_runs == 0) = -1; % switch CON to -1 (EXP = 1)
    
    % Add stimulus onset regressor conditions (tonic pain, phasic pain, VAS rating) depending on which ones included
    % Also take into account if any HRF derivatives are included in the model
    if model.tonicIncluded; cond_Tonic = (1+pmod(1))*(1+sum(options.basisF.hrf.derivatives)); else; cond_Tonic = 0; end %#ok<*NASGU>
    cond_Stim = 1 + pmod(2);
    if model.VASincluded; cond_VAS = 1 + pmod(3); else; cond_VAS = 0; end
    if any(options.basisF.hrf.derivatives)
        cond_Stim = cond_Stim+sum(options.basisF.hrf.derivatives);
        cond_VAS = model.VASincluded*cond_VAS*(1+sum(options.basisF.hrf.derivatives));
    end
    
    %% Contrasts
    no_cond = 1 + model.tonicIncluded + model.VASincluded;

    % RETROICOR
    con = 1;
    conname = 'RETROICOR';
    con_start = no_cond+con;
    no_contr = 18;
    conweights = zeros(no_contr,no_cond+no_contr);
    col_ind = (con_start):(con_start-1+no_contr); % column indices of the noise regressors (after experimental condition regressors)
    conweights(:,col_ind) = eye(no_contr,no_contr);
    conrepl = 'replsc';

    matlabbatch{1}.spm.stats.con.consess{con}.fcon.name = conname; % Contrast name
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.weights = conweights; % Contrast weight
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.sessrep = conrepl; % Contrast replication across sessions
    
    reg_count = no_contr;
    
    % HRV
    con = 2;
    conname = 'HRV';
    con_start = no_cond+reg_count+1;
    no_contr = 1;
    conweights = zeros(no_contr,no_cond+no_contr);
    col_ind = (con_start):(con_start-1+no_contr); % column indices of the noise regressors (after experimental condition regressors)
    conweights(:,col_ind) = eye(no_contr,no_contr);
    conrepl = 'replsc';
    
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = conname; % Contrast name
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights; % Contrast weight
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = conrepl; % Contrast replication across sessions
    
    reg_count = reg_count + 1;
    
    % RVT
    con = 3;
    conname = 'RVT';
    con_start = no_cond+reg_count+1;
    no_contr = 1;
    conweights = zeros(no_contr,no_cond+no_contr);
    col_ind = (con_start):(con_start-1+no_contr); % column indices of the noise regressors (after experimental condition regressors)
    conweights(:,col_ind) = eye(no_contr,no_contr);
    conrepl = 'replsc';
    
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = conname; % Contrast name
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights; % Contrast weight
    matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = conrepl; % Contrast replication across sessions
    
    reg_count = reg_count + 1;
    
    % Noise ROI WM
    con = 4;
    conname = 'NoiseROI-WM';
    con_start = no_cond+reg_count+1;
    no_contr = 7;
    conweights = zeros(no_contr,no_cond+reg_count+no_contr);
    col_ind = (con_start):(con_start-1+no_contr); % column indices of the noise regressors (after experimental condition regressors)
    conweights(:,col_ind) = eye(no_contr,no_contr);
    conrepl = 'replsc';

    matlabbatch{1}.spm.stats.con.consess{con}.fcon.name = conname; % Contrast name
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.weights = conweights; % Contrast weight
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.sessrep = conrepl; % Contrast replication across sessions
    
    reg_count = reg_count + no_contr;
    
    % Noise ROI CSF
    con = 5;
    conname = 'NoiseROI-CSF';
    con_start = no_cond+reg_count+1;
    no_contr = 7;
    conweights = zeros(no_contr,no_cond+reg_count+no_contr);
    col_ind = (con_start):(con_start-1+no_contr); % column indices of the noise regressors (after experimental condition regressors)
    conweights(:,col_ind) = eye(no_contr,no_contr);
    conrepl = 'replsc';

    matlabbatch{1}.spm.stats.con.consess{con}.fcon.name = conname; % Contrast name
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.weights = conweights; % Contrast weight
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.sessrep = conrepl; % Contrast replication across sessions
    
    reg_count = reg_count + no_contr;
    
    % Motion
    con = 6;
    conname = 'Motion';
    con_start = no_cond+reg_count+1;
    no_contr = options.preproc.no_motionreg;
    conweights = zeros(no_contr,no_cond+reg_count+no_contr);
    col_ind = (con_start):(con_start-1+no_contr); % column indices of the noise regressors (after experimental condition regressors)
    conweights(:,col_ind) = eye(no_contr,no_contr);
    conrepl = 'replsc';

    matlabbatch{1}.spm.stats.con.consess{con}.fcon.name = conname; % Contrast name
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.weights = conweights; % Contrast weight
    matlabbatch{1}.spm.stats.con.consess{con}.fcon.sessrep = conrepl; % Contrast replication across sessions
    
    matlabbatch{1}.spm.stats.con.spmmat = {fullfile(firstlvlpath, 'SPM.mat')};
    matlabbatch{1}.spm.stats.con.delete = options.stats.firstlvl.contrasts.delete; % Deleting old contrast
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    save(fullfile(firstlvlpath,'batch_firstlevel_contrasts'), 'matlabbatch')
    clear matlabbatch
    
end

end