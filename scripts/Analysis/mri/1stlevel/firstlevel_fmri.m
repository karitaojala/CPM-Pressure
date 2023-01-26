function firstlevel_fmri(options,analysis_version,modelname,tonicIncluded,phasicIncluded,VASincluded,pmodNo,physioOn,subj)

allcondsfile = fullfile(options.path.logdir, '..', 'conditions_list.mat');
allconds = load(allcondsfile);

for sub = subj
    
    %sub_ind = find(options.subj.all_subs == sub);
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    brainmasksub = fullfile(options.path.mridir,name,'t1_corrected',[name '-brainmask' options.model.firstlvl.mask_name '.nii']);
    
    if tonicIncluded
        cond_runs = allconds.conditions_list_rand(sub,:);
        exp_run = find(cond_runs == 1,1)+1; % find first EXP run and use its tonic pmod shape for all runs
        pmodfile_exp = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(exp_run) '-tonic-pmod.mat']);
        pmoddata_exp = load(pmodfile_exp);
        tonicReg = pmoddata_exp.tonicRegressor_z;
    end
    
    block = 1; 
    
    if sub == 5
        runs = [2 3 5];
    else
        runs = options.acq.exp_runs;
    end
    
    for run = runs
        
        clear EPI episcans onsetsTonic
        
        % Select EPI files
        epipath = fullfile(options.path.mridir,name,['epi-run' num2str(run)]);
        cd(epipath)
        EPI.epiFiles = spm_vol(spm_select('ExtFPList',epipath,['^ra' name '-epi-run' num2str(run) '-brain.nii$']));
        
        for epino = 1:size(EPI.epiFiles,1)
            episcans{epino} = [EPI.epiFiles(epino).fname, ',',num2str(epino)];
        end
        
        % Noise correction files
        physiopathsub = fullfile(options.path.physiodir,name);
        
        if physioOn
            noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-' options.preproc.physio_name '.txt']);
        else % only motion regressors
            noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-motion_regressors-brain-zscored.txt']);
        end
        
        % Define onsets and conditions
        onsetfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-onsets.mat']);
        onsetdata = load(onsetfile);
        
        % Tonic stimulus onsets
        if tonicIncluded

            pmodfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-tonic-pmod.mat']);
            pmoddata = load(pmodfile,'phasicRegressor_z');
            phasicReg = pmoddata.phasicRegressor_z;
            
            onsetsTonicStart = onsetdata.onsetsTonic+options.basisF.onset_shift;
            if sub == 5 && run == 4 % remove tonic trial 2 from sub 5 run 3
                onsetsTonicStart = onsetsTonicStart(1);
            end
            
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
            
            if pmodNo(1) >= 1 % 1 parametric modulator
                pmodStructTonic = struct();
                pmodStructTonic.name = 'TonicPressure';
                if sub == 5 && run == 4 % remove tonic trial 2 from sub 5 run 3
                    pmodStructTonic.param = tonicReg(1:200);
                else
                    pmodStructTonic.param = tonicReg;
                end
                pmodStructTonic.poly = 1;
                if pmodNo(1) == 2 % 2 parametric modulators
                    %pmodStructTonic = struct();
                    pmodStructTonic(2).name = 'TonicPressure x PhasicStimuli';
                    if sub == 5 && run == 4 % remove tonic trial 2 from sub 5 run 3
                        pmodStructTonic(2).param = zscore(phasicReg(1:200) .* tonicReg(1:200));
                    else
                        pmodStructTonic(2).param = zscore(phasicReg .* tonicReg);
                    end
                    pmodStructTonic(2).poly = 1;
                end
            else
                pmodStructTonic = struct('name', {}, 'param', {}, 'poly', {});
            end
            
        else
            onsetsTonic = onsetdata.onsetsTonic+options.basisF.onset_shift;
        end
        
        % Phasic stimulus and VAS ratings onsets
        onsetsStim = onsetdata.onsetsStim+options.basisF.onset_shift;
        onsetsVAS  = onsetdata.onsetsVAS+options.basisF.onset_shift;
        
        if phasicIncluded && any(pmodNo(2))
            pmodfile_phasic = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-phasic-pmod.mat']);
            pmoddata_phasic = load(pmodfile_phasic);
            pmodStructPhasic = struct();
            pmodStructPhasic.name = 'PainRating';
            pmodStructPhasic.param = pmoddata_phasic.pmodPhasic(:);
            pmodStructPhasic.poly = 1;
        else
            pmodStructPhasic = struct('name', {}, 'param', {}, 'poly', {});
        end
        
        if VASincluded && any(pmodNo(3))
            pmodfile_vas = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-vas-pmod.mat']);
            pmoddata_vas = load(pmodfile_vas);
            pmodStructVAS = struct();
            pmodStructVAS.name = 'ButtonPresses';
            pmodStructVAS.param = pmoddata_vas.pmodVAS(:);
            pmodStructVAS.poly = 1;
        else
            pmodStructVAS = struct('name', {}, 'param', {}, 'poly', {});
        end
        
        % Conditions
        %conditionsPhasic = onsetdata.conditions;
        %conditionsTonic = [conditionsPhasic(1) conditionsPhasic(1)]';
        %if any(conditions) == 0; conditions = conditions-1; end % transforming zeros to -1
        
        disp(['...Block ' num2str(run), ' out of ' num2str(options.acq.n_runs), '. Found ', num2str(epino), ' EPIs...' ])
        if epino ~= options.acq.n_scans(run); warning('Wrong number of EPIs found!'); end
        disp(['Found ', num2str(size(noisefile,1)), ' noise correction file(s).'])
        disp(['Found ', num2str(numel(onsetsTonic)) ' tonic, ', num2str(numel(onsetsStim)), ' phasic, and ', num2str(numel(onsetsVAS)), ' VAS rating events.'])
        disp('................................')
        
        c = 0;
        if tonicIncluded
            c = c+1;
%             matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = ['TonicStim' cond_name];
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'TonicStim';
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsTonic;
            if strcmp(options.model.firstlvl.timing_units,'scans')
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration/options.acq.TR;
            else
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration;
            end
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = pmodStructTonic; % Parametric modulation
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
        end
        
        if phasicIncluded
            c = c+1;
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'PhasicStim';
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsStim;
            if strcmp(options.model.firstlvl.timing_units,'scans')
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration/options.acq.TR;
            else
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration;
            end
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = pmodStructPhasic; 
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
        end
        
        if VASincluded
            c = c+1;
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'VAS';
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsVAS;
            if strcmp(options.model.firstlvl.timing_units,'scans')
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.vas_duration/options.acq.TR;
            else
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.vas_duration;
            end
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = pmodStructVAS; 
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).scans = episcans';
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi_reg = {noisefile}; % Physiological and head motion noise correction files for nuisance regressors
        if tonicIncluded
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).hpf = options.model.firstlvl.hpf.tonic; % High-pass filter
        else
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).hpf = options.model.firstlvl.hpf.phasic;
        end
        block  = block + 1;
        
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
    
    %% Estimate 1st level model
    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(firstlvlpath, 'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    save(fullfile(firstlvlpath,'batch_firstlevel'), 'matlabbatch')
    clear matlabbatch
    
end

end