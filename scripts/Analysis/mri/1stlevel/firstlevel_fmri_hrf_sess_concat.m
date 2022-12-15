function firstlevel_fmri_hrf_sess_concat(options,analysis_version,modelname,tonicIncluded,phasicIncluded,VASincluded,physioOn,subj)

for sub = subj
    
    %sub_ind = find(options.subj.all_subs == sub);
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    brainmasksub = fullfile(options.path.mridir,name,'t1_corrected',[name '-brainmask.nii']);
    
    nscans_run = options.acq.n_scans(2);
    nscans_all = 4*options.acq.n_scans(2);
    
    tonic_SPM_file = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],'HRF_phasic_tonic_pmod');
    tonic_SPM = load(tonic_SPM_file);
    reg_no = size(tonic_SPM.xX.X,2)-4; % number of design matrix columns without constants
    if reg_no > 4*
    
    episcansAll = [];
    noisedataAll = zeros(nscans_all,25); % all volumes, 25th column for possible motion exclusion volume
    onsetsTonicAll = [];
    pmodTonic1All = [];
    pmodTonic2All = [];
    onsetsPhasicAll = [];
    onsetsVASAll = [];
    conditionsPhasicAll = [];
    
    block = 1;
    scans2add = 0;
    run_vols = 1:nscans_run;
    
    for run = options.acq.exp_runs
        
        clear EPI episcans onsetdata pmoddata onsetsTonic
        
        % Select EPI files
        epipath = fullfile(options.path.mridir,name,['epi-run' num2str(run)]);
        cd(epipath)
        EPI.epiFiles = spm_vol(spm_select('ExtFPList',epipath,['^ra' name '-epi-run' num2str(run) '-brain.nii$']));
        
        for epino = 1:size(EPI.epiFiles,1)
            episcans{epino} = [EPI.epiFiles(epino).fname, ',',num2str(epino)]; 
        end
        
        % Concantenate EPI files
        episcansAll = [episcansAll episcans];
        
        % Noise correction files
        physiopathsub = fullfile(options.path.physiodir,name);
        
        if physioOn
            noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-multiple_regressors-brain-zscored.txt']);
        else % only motion regressors
            noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-motion_regressors-brain-zscored.txt']);
        end
        
        noisedata = importdata(noisefile);
        if size(noisedata,2) == options.preproc.no_noisereg
            noisedataAll(run_vols,:) = [noisedata zeros(nscans_run,1)]; 
        elseif size(noisedata,2) == options.preproc.no_noisereg+1
            noisedataAll(run_vols,:) = noisedata; 
        end
        run_vols = run_vols + nscans_run;
        
        % Define onsets and conditions
        onsetfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-onsets.mat']);
        onsetdata = load(onsetfile);
        
        % Tonic stimulus onsets
        if tonicIncluded
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
            
            % Concatenate pmods
            pmodTonic1All = [pmodTonic1All; pmoddata.pmodTonic(:)];
            pmodTonic2All = [pmodTonic2All; pmoddata.pmodTonic2(:)];
            
        else
            onsetsTonic = onsetdata.onsetsTonic+options.basisF.onset_shift;
        end
        
        % Phasic stimulus and VAS ratings onsets
        onsetsPhasic = onsetdata.onsetsStim+options.basisF.onset_shift;
        onsetsVAS  = onsetdata.onsetsVAS+options.basisF.onset_shift;
        
        % Concatenated onsets
        onsetsPhasicAll = [onsetsPhasicAll; onsetsPhasic + scans2add];
        onsetsVASAll = [onsetsVASAll; onsetsVAS + scans2add];
        onsetsTonicAll = [onsetsTonicAll; onsetsTonic + scans2add];
        
        scans2add = scans2add + options.acq.n_scans(run);
        
        % Conditions
        conditionsPhasic = onsetdata.conditions;
        if any(conditionsPhasic == 0); conditionsPhasic = conditionsPhasic-1; end % transforming zeros to -1
        conditionsPhasicAll = [conditionsPhasicAll; conditionsPhasic];
        
        block  = block + 1;
        
    end
    
    noisedataAll = zscore(noisedataAll);
    noisefileAll = fullfile(physiopathsub, [name '-all_runs-multiple_regressors-brain-zscored.txt']);
    writematrix(noisedataAll,noisefileAll,'Delimiter','tab')
    
    pmodStructTonic = struct();
    pmodStructTonic(1).name = 'TonicPressure';
    pmodStructTonic(1).poly = 1;
    pmodStructTonic(1).param = zscore(pmodTonic1All(:));
    pmodStructTonic(2).name = 'TonicPressurexPhasicPressure';
    pmodStructTonic(2).poly = 1;
    pmodStructTonic(2).param = zscore(pmodTonic2All(:));
    
    pmodStructPhasic = struct('name', {}, 'param', {}, 'poly', {});
    pmodStructPhasic(1).name = 'TonicCond';
    pmodStructPhasic(1).poly = 1;
    conditionsPhasicAll = conditionsPhasicAll*(-1); % flip sign, CON = 1, EXP = -1
    pmodStructPhasic(1).param = conditionsPhasicAll(:);
    
    pmodStructPhasic(2).name = 'StimIndex';
    pmodStructPhasic(2).poly = 1;
    %no_stim = options.model.firstlvl.stimuli.phasic_total;
    stim_ind = (1:numel(conditionsPhasicAll))'; % stimulus index across experiment
    stim_ind_meanc = stim_ind-mean(stim_ind); % mean-centered
    pmodStructPhasic(2).param = stim_ind_meanc;
    
    pmodStructPhasic(3).name = 'TonicCondxStimIndex';
    pmodStructPhasic(3).poly = 1;
    cond_stimind_interaction = conditionsPhasicAll .* stim_ind;
    cond_stimind_interaction_meanc = cond_stimind_interaction-mean(cond_stimind_interaction);
    pmodStructPhasic(3).param = cond_stimind_interaction_meanc; % stimulus index mean-centered
    
    disp(['...Blocks ' num2str(options.acq.exp_runs(1)), ' to ' num2str(options.acq.n_runs(end)), '. Found ', num2str(numel(episcansAll)), ' EPIs...' ])
    %if epino ~= options.acq.n_scans(run); warning('Wrong number of EPIs found!'); end
    %disp(['Found ', num2str(size(noisefile,1)), ' noise correction file(s).'])
    disp(['Found ', num2str(numel(onsetsTonicAll)) ' tonic, ', num2str(numel(onsetsPhasicAll)), ' phasic, and ', num2str(numel(onsetsVASAll)), ' VAS rating events.'])
    disp('................................')
    
    % Define conditions
    block = 1;
    c = 0;
    if tonicIncluded
        c = c+1;
        %matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = options.model.firstlvl.tonic_name{conditionsTonic(1)+1};
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'TonicStim';
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsTonicAll;
        if strcmp(options.model.firstlvl.timing_units,'scans')
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration/options.acq.TR;
        else
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration;
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = pmodStructTonic; % Parametric modulation
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
    end
    
    if phasicIncluded
        c = c+1;
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'PhasicStim';
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsPhasicAll;
        if strcmp(options.model.firstlvl.timing_units,'scans')
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration/options.acq.TR;
        else
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration;
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = pmodStructPhasic; % No parametric modulation
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
    end
    
    if VASincluded
        c = c+1;
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'VASRating';
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsVASAll;
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
    if tonicIncluded
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
    matlabbatch{1}.spm.stats.fmri_spec.mask = {brainmasksub}; % Brain mask to exclude e.g. eyes
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST'; % Temporal autocorrelation removal algorithm to use
    
    %% Specify 1st level model with concatenated sessions
    spm_jobman('run', matlabbatch);
    clear matlabbatch
    
    %% Use SPM concatenate to adjust for session effects
    SPMfile = fullfile(firstlvlpath,'SPM.mat');
    scans2concat = options.acq.n_scans(options.acq.exp_runs);
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