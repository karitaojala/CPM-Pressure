function firstlevel_fmri_hrf_sess_concat(options,analysis_version,model,subj)

allcondsfile = fullfile(options.path.logdir, '..', 'conditions_list.mat');
allconds = load(allcondsfile);

for sub = subj
    
    clear matlabbatch
    %sub_ind = find(options.subj.all_subs == sub);
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    if options.spinal
        masksub = fullfile(options.path.mridir,'2ndlevel','meanmasks',options.model.firstlvl.mask_name);
    else
        masksub = fullfile(options.path.mridir,name,options.model.firstlvl.mask_name);
    end
    masksub = replace(masksub,'SUBID',name);

    if sub == 5 || sub == 7
        runs = [2 3 5];
    else
        runs = options.acq.exp_runs;
    end
    nscans_run = options.acq.n_scans(2);
    nscans_all = numel(runs)*options.acq.n_scans(2);
    
    % Noise correction files
    physiopathsub = fullfile(options.path.physiodir,name);
    
    run_ind = 1;
    col_no = 0;
    for run = runs
        noisefiles{run_ind} = fullfile(physiopathsub, [name '-run' num2str(run) '-' options.preproc.physio_name '.txt']);
        delimiter = ' '; %or whatever
        fid = fopen(noisefiles{run_ind},'rt');
        tLines = fgets(fid);
        col_no = col_no + numel(strfind(tLines,delimiter)) + 1;
        fclose(fid);
        run_ind = run_ind + 1;
    end

    cond_reg_no = col_no/numel(runs)-options.preproc.no_noisereg;
    assumed_col_no = numel(runs)*(cond_reg_no+options.preproc.no_noisereg);
    if col_no > assumed_col_no
        col_diff = col_no - assumed_col_no;
        noisedataAll = zeros(nscans_all,options.preproc.no_noisereg+col_diff); % all volumes, final column(s) for possible motion exclusion volume
    else
        noisedataAll = zeros(nscans_all,options.preproc.no_noisereg);
    end
        
    %     tonic_SPM_file = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],'HRF_phasic_tonic_pmod','SPM.mat');
    %     tonic_SPM = load(tonic_SPM_file);
    %     col_no = size(tonic_SPM.SPM.xX.X,2)-numel(runs); % number of design matrix columns without constants
    %     cond_reg_no = col_no/numel(runs)-options.preproc.no_noisereg;
    %     assumed_col_no = numel(runs)*(cond_reg_no+options.preproc.no_noisereg);
    %     if col_no > assumed_col_no
    %         col_diff = col_no - assumed_col_no;
    %         noisedataAll = zeros(nscans_all,options.preproc.no_noisereg+col_diff); % all volumes, final column(s) for possible motion exclusion volume
    %     else
    %         noisedataAll = zeros(nscans_all,options.preproc.no_noisereg);
    %     end
    
    if model.tonicIncluded
        cond_runs = allconds.conditions_list_rand(sub,:);
        cond_runs = cond_runs(runs-1);
        exp_run = find(cond_runs == 1,1)+1; % find first EXP run and use its tonic pmod shape for all runs
        pmodfile_exp = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(exp_run) '-tonic-pmod.mat']);
        pmoddata_exp = load(pmodfile_exp);
        tonicReg = pmoddata_exp.tonicRegressor_z;
    end
    
    episcansAll = [];
    onsetsTonicAll = [];
    pmodTonic1All = [];
    pmodTonic2All = [];
    onsetsPhasicAll = [];
    onsetsVASAll = [];
    conditionsPhasicAll = [];
    
    block = 1;
    scans2add = 0;
    run_vols = 1:nscans_run;
    excl_vol_no = 0;
    
    for run = runs
        
        clear EPI episcans onsetdata pmoddata onsetsPhasic onsetsVAS onsetsTonic
        
        % Select EPI files
        epipath = fullfile(options.path.mridir,name,['epi-run' num2str(run)]);
        cd(epipath)
        if options.spinal
            EPI.epiFiles = spm_vol(spm_select('ExtFPList',epipath,['^a' name '-epi-run' num2str(run) '-' options.model.firstlvl.epi_name '.nii$']));
        else
            EPI.epiFiles = spm_vol(spm_select('ExtFPList',epipath,['^ra' name '-epi-run' num2str(run) '-brain.nii$']));
        end

        for epino = 1:size(EPI.epiFiles,1)
            episcans{epino} = [EPI.epiFiles(epino).fname, ',',num2str(epino)];
        end
        
        % Concantenate EPI files
        episcansAll = [episcansAll episcans];
        
        % Physiological noise parameters
        noisedata = importdata(noisefiles{block});
        if size(noisedata,2) > options.preproc.no_noisereg
            excl_vol_cols_run = size(noisedata,2)-options.preproc.no_noisereg;
            excl_vol_cind = excl_vol_cols_run-1;
            for col = 1:excl_vol_cols_run
                excl_vol_no = excl_vol_no + 1;
                excl_vol_row = find(noisedata(:,end-excl_vol_cind) == 1);
                excl_vol_row_ind(excl_vol_no) = run_vols(excl_vol_row); %#ok<*FNDSB>
                excl_vol_cind = excl_vol_cind - 1;
            end
        end
        
        noisedataAll(run_vols,1:options.preproc.no_noisereg) = noisedata(:,1:options.preproc.no_noisereg);
        run_vols = run_vols + nscans_run;
        
        % Define onsets and conditions
        onsetfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-onsets.mat']);
        onsetdata = load(onsetfile);
        
        % Tonic stimulus onsets
        if model.tonicIncluded
            pmodfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-tonic-pmod.mat']);
            pmoddata = load(pmodfile);
            
            onsetsTonicStart = pmoddata.onsetsTonic+options.basisF.onset_shift;
            for ons = 1:numel(onsetsTonicStart) % create stick onsets and pmod with selected resolution to fill the true tonic stimulus duration
                firstStick = onsetsTonicStart(ons);
                resStick = options.basisF.hrf.tonic_resolution;
                if strcmp(options.model.firstlvl.timing_units,'scans')
                    lastStick = (onsetsTonicStart(ons)+options.basisF.hrf.tonic_durationtrue/options.acq.TR); % as scans
                else
                    lastStick = (onsetsTonicStart(ons)+options.basisF.hrf.tonic_durationtrue); % as seconds
                end
                onsetsTonic_temp = firstStick:resStick:lastStick;
                onsetsTonic(:,ons) = onsetsTonic_temp(1:end-1)'; %#ok<*AGROW> % remove last element to reach even number matching with pmod
            end
            onsetsTonic = onsetsTonic(:);
            durationTonic = options.basisF.hrf.tonic_durationtrue;
            if numel(onsetsTonic) < 2*durationTonic; onsetsTonic = [onsetsTonic; NaN(durationTonic,1)]; end
            
            phasicReg = pmoddata.phasicRegressor_z;
            %             if sub == 5 && run == 4 % remove tonic trial 2 from sub 5 run 3
            %                 pmodTonic1 = [tonicReg(1:durationTonic) NaN(durationTonic,1)];
            %                 pmodTonic2 = [zscore(phasicReg(1:durationTonic) .* tonicReg(1:durationTonic)) NaN(durationTonic,1)];
            %             else
            pmodTonic1 = tonicReg;
            pmodTonic2 = zscore(phasicReg .* tonicReg);
            %             end
            
            % Concatenate pmods
            pmodTonic1All(:,block) = pmodTonic1(:);
            pmodTonic2All(:,block) = pmodTonic2(:);
            
        else
            onsetsTonic = onsetdata.onsetsTonic+options.basisF.onset_shift;
        end
        
        % Phasic stimulus and VAS ratings onsets
        onsetsPhasic = onsetdata.onsetsStim+options.basisF.onset_shift;
        onsetsVAS  = onsetdata.onsetsVAS+options.basisF.onset_shift;
        
        nPhasic = options.model.firstlvl.stimuli.phasic_run;
        
        if numel(onsetsPhasic) < nPhasic; onsetsPhasic = [onsetsPhasic; NaN(nPhasic-numel(onsetsPhasic),1)]; end
        if numel(onsetsVAS) < nPhasic; onsetsVAS = [onsetsVAS; NaN(nPhasic-numel(onsetsVAS),1)]; end
        
        % Concatenated onsets
        onsetsPhasicAll(:,block) = onsetsPhasic + scans2add;
        onsetsVASAll(:,block) = onsetsVAS + scans2add;
        onsetsTonicAll(:,block) = onsetsTonic + scans2add;
        
        scans2add = scans2add + options.acq.n_scans(run);
        
        % Conditions
        conditionsPhasic = onsetdata.conditions;
        if any(conditionsPhasic == 0); conditionsPhasic = conditionsPhasic-1; end % transforming zeros to -1
        conditionsPhasicAll(:,block) = conditionsPhasic(1)*ones(nPhasic,1);
        
        block  = block + 1;
        
    end
    
    noisedataAll = zscore(noisedataAll);
    
    if excl_vol_no ~= 0
        for col = 1:numel(excl_vol_row_ind)
            col_ind = size(noisedataAll,2)+1;
            noisedataAll(excl_vol_row_ind(col),col_ind) = 1;
        end
    end
    
    %noisedataAll = zscore(noisedataAll);
    if options.spinal
        noisefileAll = fullfile(physiopathsub, [name '-all_runs-multiple_regressors-spinal-zscored.txt']);
    else
        noisefileAll = fullfile(physiopathsub, [name '-all_runs-multiple_regressors-brain-zscored.txt']);
    end
    writematrix(noisedataAll,noisefileAll,'Delimiter','tab')
    
    disp(['...Blocks ' num2str(options.acq.exp_runs(1)), ' to ' num2str(options.acq.exp_runs(end)), '. Found ', num2str(numel(episcansAll)), ' EPIs...' ])
    disp(['Found ', num2str(numel(onsetsTonicAll)) ' tonic, ', num2str(numel(onsetsPhasicAll)), ' phasic, and ', num2str(numel(onsetsVASAll)), ' VAS rating events.'])
    disp('................................')
    
    % Define conditions
    %pmodTonic1All = zscore(pmodTonic1All);
    %pmodTonic2All = zscore(pmodTonic2All);
    cond_runs = cond_runs + 1; % CON = 1, EXP = 2
    
    block = 1; % does not change
    c = 0;
    
    % Loop over experimental conditions (CON, EXP) for setting tonic stimuli
    for cond = 1:2
        
        c = c+1; % counter for batch
        cond_name = options.model.firstlvl.stimuli.tonic_name{cond}; % condition name ('CON' or 'EXP')
        rows = size(pmodTonic1All,1)*sum(cond_runs==cond); % number of rows of the pmod array
        
        % Initialize pmod structure
        pmodStructTonic = struct('name', {}, 'param', {}, 'poly', {});
        
        % Pmod 1: Tonic pressure
        pmodStructTonic(1).name = [model.pmodName{1} '-' cond_name];
        pmodStructTonic(1).poly = 1;
        pmodTonic1All_final = reshape(pmodTonic1All(:,cond_runs==cond),[rows 1]);
        pmodTonic1All_final = pmodTonic1All_final(~isnan(pmodTonic1All_final));
        pmodStructTonic(1).param = zscore(pmodTonic1All_final);
        
        % Pmod 2: Interaction tonic and phasic pressure
        pmodStructTonic(2).name = [model.pmodName{2} '-' cond_name];
        pmodStructTonic(2).poly = 1;
        pmodTonic2All_final = reshape(pmodTonic2All(:,cond_runs==cond),[rows 1]);
        pmodTonic2All_final = pmodTonic2All_final(~isnan(pmodTonic2All_final));
        pmodStructTonic(2).param = zscore(pmodTonic2All_final);
        
        % Onset condition
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = ['TonicStim-' cond_name];
        tonicOnset = reshape(onsetsTonicAll(:,cond_runs==cond),[rows 1]);
        tonicOnset = tonicOnset(~isnan(tonicOnset));
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = tonicOnset;
        if strcmp(options.model.firstlvl.timing_units,'scans') % duration of the stimulus if duration is in scans
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration/options.acq.TR;
        else % if timing is in seconds
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration;
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = pmodStructTonic; % Parametric modulation
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
        
    end
    
    conditionsPhasicAll = conditionsPhasicAll*(-1); % flip sign, CON = 1, EXP = -1
    stim_ind = (1:numel(conditionsPhasicAll))'; % stimulus index across experiment
    %stim_ind_meanc = stim_ind-mean(stim_ind); % mean-centered
    stim_ind_meanc = zscore(stim_ind); % zscored
    stim_ind_meanc = reshape(stim_ind_meanc,[numel(stim_ind_meanc)/numel(runs) numel(runs)]); % reshaped with 1 column per run
    
    % Loop over experimental conditions (CON, EXP) for setting phasic stimuli
    for cond = 1:2
        
        c = c+1;
        cond_name = options.model.firstlvl.stimuli.tonic_name{cond};
        rows = size(conditionsPhasicAll,1)*sum(cond_runs==cond);
        
        pmodStructPhasic = struct('name', {}, 'param', {}, 'poly', {});
        
        % Pmod 1: Stimulus index over the entire experiment
        pmodStructPhasic(1).name = [model.pmodName{3} '-' cond_name];
        pmodStructPhasic(1).poly = 1;
        pmodStructPhasic(1).param = reshape(stim_ind_meanc(:,cond_runs==cond),[rows 1]);
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = ['PhasicStim-' cond_name];
        phasicOnset = reshape(onsetsPhasicAll(:,cond_runs==cond),[rows 1]);
        phasicOnset = phasicOnset(~isnan(phasicOnset));
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = phasicOnset;
        if strcmp(options.model.firstlvl.timing_units,'scans') % duration in scans
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration/options.acq.TR;
        else % duration in seconds
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration;
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = pmodStructPhasic; % No parametric modulation
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
        
    end
    
    if model.VASincluded
        c = c+1;
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'VASRating';
        VASOnset = onsetsVASAll(:);
        VASOnset = VASOnset(~isnan(VASOnset));
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = VASOnset;
        if strcmp(options.model.firstlvl.timing_units,'scans')
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.vas_duration/options.acq.TR;
        else
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.vas_duration;
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {}); % No parametric modulation
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.sess(block).scans = episcansAll';
    matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(block).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi_reg = {noisefileAll}; % Physiological and head motion noise correction files for nuisance regressors
    if model.tonicIncluded
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).hpf = options.model.firstlvl.hpf.tonic; % High-pass filter
    else
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).hpf = options.model.firstlvl.hpf.phasic;
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {firstlvlpath};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = options.model.firstlvl.timing_units;
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = options.acq.TR; % Repetition time in seconds
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = options.acq.n_slices; % Total slices
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = options.preproc.onset_slice; % Reference slice
    
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = options.basisF.hrf.derivatives; % Hemodynamic response function derivatives - none
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    %matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.5; % Mask threshold, original 0.8
    matlabbatch{1}.spm.stats.fmri_spec.mask = {masksub}; % Mask to exclude e.g. eyes
    matlabbatch{1}.spm.stats.fmri_spec.cvi = options.model.firstlvl.temp_autocorr; % Temporal autocorrelation removal algorithm to use
    
    %% Specify 1st level model with concatenated sessions
    spm_jobman('run', matlabbatch);
    clear matlabbatch
    
    %% Use SPM concatenate to adjust for session effects
    SPMfile = fullfile(firstlvlpath,'SPM.mat');
    scans2concat = options.acq.n_scans(runs);
    spm_fmri_concatenate(SPMfile, scans2concat);
    
    %% Estimate 1st level model
    matlabbatch{1}.spm.stats.fmri_est.spmmat = {SPMfile};
    matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    save(fullfile(firstlvlpath,'batch_firstlevel'), 'matlabbatch')
    clear matlabbatch
    
end

end