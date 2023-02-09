function firstlevel_fmri_fourier(options,analysis_version,model,subj,n_proc)

for sub = subj
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    brainmasksub = fullfile(options.path.mridir,name,'t1_corrected',[name '-brainmask' options.model.firstlvl.mask_name '.nii']);
    
    % Noise correction files
    physiopathsub = fullfile(options.path.physiodir,name);
    
    block = 1;
    if sub == 5
        runs = [2 3 5]; % run 4 excluded
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
        
        episcans_all{block} = episcans;
        
        if model.physioOn
            noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-multiple_regressors-brain-zscored.txt']);
        else % only motion regressors
            noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-motion_regressors-brain-zscored.txt']);
        end
        
        % Define onsets and conditions
        onsetfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-onsets.mat']);
        onsetdata = load(onsetfile);
        
        % Tonic stimulus onsets
        onsetsTonic = onsetdata.onsetsTonic+options.basisF.onset_shift;
        % Phasic stimulus onsets
        onsetsStim = onsetdata.onsetsStim+options.basisF.onset_shift;
        onsetsStim_all{block} = onsetsStim; %#ok<*AGROW>
        % VAS ratings onsets
        onsetsVAS  = onsetdata.onsetsVAS+options.basisF.onset_shift;
        onsetsVAS_all{block} = onsetsVAS;
        
        % Conditions
        %conditionsPhasic = onsetdata.conditions;
        %conditionsTonic = [conditionsPhasic(1) conditionsPhasic(1)]';
        %if any(conditions) == 0; conditions = conditions-1; end % transforming zeros to -1
        
        disp(['...Block ' num2str(run), ' out of ' num2str(options.acq.n_runs), '. Found ', num2str(epino), ' EPIs...' ])
        if epino ~= options.acq.n_scans(run); warning('Wrong number of EPIs found!'); end
        disp(['Found ', num2str(size(noisefile,1)), ' noise correction file(s).'])
        disp(['Found ', num2str(numel(onsetsTonic)) ' tonic, ', num2str(numel(onsetsStim)), ' phasic, and ', num2str(numel(onsetsVAS)), ' VAS rating events.'])
        disp('................................')
        
        % Define conditions
        c = 0;
        if model.tonicIncluded
            c = c+1;
            %matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = options.model.firstlvl.tonic_name{conditionsTonic(1)+1};
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'TonicStim';
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsTonic;
            if strcmp(options.model.firstlvl.timing_units,'scans')
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration/options.acq.TR;
            else
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.tonic_duration;
            end
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {}); % No parametric modulation
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).scans = episcans';
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi_reg = {noisefile}; % Physiological and head motion noise correction files for nuisance regressors
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).hpf = options.model.firstlvl.hpf.tonic; % High-pass filter
        block  = block + 1;
        
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {firstlvlpath};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = options.model.firstlvl.timing_units;
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = options.acq.TR; % Repetition time in seconds
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = options.acq.n_slices; % Total slices
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = options.preproc.onset_slice; % Reference slice
    
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    
    matlabbatch{1}.spm.stats.fmri_spec.bases.fourier_han.length = options.basisF.fourier.windowLength;
    matlabbatch{1}.spm.stats.fmri_spec.bases.fourier_han.order = options.basisF.fourier.order;
    
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    %matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.5; % Mask threshold, original 0.8
    matlabbatch{1}.spm.stats.fmri_spec.mask = {brainmasksub}; % Brain mask to exclude e.g. eyes
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'FAST'; % Temporal autocorrelation removal algorithm to use
    
    % Create tonic Fourier set regressors
    spm_jobman('run', matlabbatch);
    
    matlabbatch{1}.spm.stats.fmri_spec = rmfield(matlabbatch{1}.spm.stats.fmri_spec,'sess');
    matlabbatch{1}.spm.stats.fmri_spec = rmfield(matlabbatch{1}.spm.stats.fmri_spec,'bases');
    
    %% Define phasic stimuli
    
    if ~model.specifyTonicOnly
        
        block = 1;
        run_ind_regressors = 1:options.acq.n_scans(runs(1));
        
        % Retrieve unestimated regressors
        SPMtonic = load(fullfile(firstlvlpath, 'SPM.mat'));
        tonicReg = SPMtonic.SPM.xX.X; % 5 sines + 5 cosines + Hanning window = 11 regressors
        
        for run = runs
            
            % Define phasic regressors
            c = 0;
            if model.phasicIncluded
                c = c+1;
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'PhasicStim';
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsStim_all{block};
                if strcmp(options.model.firstlvl.timing_units,'scans')
                    matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration/options.acq.TR;
                else
                    matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration;
                end
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {}); % No parametric modulation
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
            end
            
            if model.VASincluded
                c = c+1;
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'VAS';
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsVAS_all{block};
                if strcmp(options.model.firstlvl.timing_units,'scans')
                    matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.vas_duration/options.acq.TR;
                else
                    matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.vas_duration;
                end
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {}); % No parametric modulation
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
            end
            
            clear tonigReg_run newMultiReg noiseReg
            % Retrieve tonic regressors for this run
            tonicReg_run = tonicReg(SPMtonic.SPM.Sess(block).row,SPMtonic.SPM.Sess(block).col(1:11));
            % Retrieve noise data
            if model.physioOn
                noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-' options.preproc.physio_name '.txt']);
            else % only motion regressors
                noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-motion_regressors-brain-zscored.txt']);
            end
            noiseReg = importdata(noisefile);
            
            % Concatenate regressors, tonic stimuli first
            newMultiReg = [tonicReg_run noiseReg];
            
            % Save new multiple regressors data
            newMultiFn = [name '-run' num2str(run) '-multiple_regressors-brain_fourierTonic.txt'];
            newMultiFile = fullfile(firstlvlpath,newMultiFn);
            writematrix(newMultiReg,newMultiFile,'Delimiter','tab')
            
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).scans = episcans_all{block}';
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi = {''};
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).regress = struct('name', {}, 'val', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi_reg = {newMultiFile}; % File including tonic stimulus Fourier set and nuisance regressors
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).hpf = options.model.firstlvl.hpf.tonic; % High-pass filter
            
            run_ind_regressors = run_ind_regressors + options.acq.n_scans(run);
            block = block + 1;
            
        end
        
        delete(fullfile(firstlvlpath, 'SPM.mat')) % delete old SPM
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = options.basisF.hrf.derivatives; % Hemodynamic response function derivatives
        
        %% Estimate 1st level model
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(firstlvlpath, 'SPM.mat')};
        matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
        
        %% Run matlabbatch
        if n_proc > 1
            run_matlab(process, matlabbatch, '');
        else
            spm_jobman('initcfg');
            spm('defaults', 'FMRI');
            spm_jobman('run',matlabbatch);
        end
        
        save(fullfile(firstlvlpath,'batch_firstlevel'), 'matlabbatch')
        
    end
    
    clear matlabbatch
    
end

end