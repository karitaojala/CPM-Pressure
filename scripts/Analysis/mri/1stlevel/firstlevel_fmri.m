function firstlevel_fmri(options,analysis_version,modelname,basisF,VASincluded,subj)

for sub = subj
    
    %sub_ind = find(options.subj.all_subs == sub);
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    brainmasksub = fullfile(options.path.mridir,name,'t1_corrected',[name '-brainmask.nii']);
    
    block = 1;
    
    for run = options.acq.exp_runs
        
        clear EPI episcans
        
        % Select EPI files
        epipath = fullfile(options.path.mridir,name,['epi-run' num2str(run)]);
        cd(epipath)
        EPI.epiFiles = spm_vol(spm_select('ExtFPList',epipath,['^ra' name '-epi-run' num2str(run) '-brain.nii$']));
        
        for epino = 1:size(EPI.epiFiles,1)
            episcans{epino} = [EPI.epiFiles(epino).fname, ',',num2str(epino)];
        end
        
        % Noise correction files
        physiopathsub = fullfile(options.path.physiodir,name);
        noisefile = fullfile(physiopathsub, [name '-run' num2str(run) '-multiple_regressors-brain.txt']);
        
        % Define onsets of phasic test pressure
        onsetfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-phasic-onsets.mat']);
        onsetdata = load(onsetfile);
        onsetsStim = onsetdata.onsetsStim;
        onsetsVAS  = onsetdata.onsetsVAS;
        
        disp(['...Block ' num2str(run), ' out of ' num2str(options.acq.n_runs), '. Found ', num2str(epino), ' EPIs...' ])
        if epino ~= options.acq.n_scans(run); warning('Wrong number of EPIs found!'); end
        disp(['Found ', num2str(size(noisefile,1)), ' noise correction file(s).'])
        disp(['Found ', num2str(numel(onsetsStim)), ' stimulus and ', num2str(numel(onsetsVAS)), ' VAS rating events.'])
        disp('................................')
        
        % Define conditions
        c = 1;
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'PainStim';
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsStim;
        if strcmp(basisF,'HRF')
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.stim_duration; 
        elseif strcmp(basisF,'FIR')
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.fir.stim_duration; 
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {}); % No parametric modulation
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
                
        if VASincluded
            c = 2;
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).name = 'VAS';
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).onset = onsetsVAS;
            if strcmp(basisF,'HRF')
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.hrf.vas_duration;
            elseif strcmp(basisF,'FIR')
                matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).duration = options.basisF.fir.vas_duration;
            end
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).tmod = 0; % Temporal derivatives - none
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).pmod = struct('name', {}, 'param', {}, 'poly', {}); % No parametric modulation
            matlabbatch{1}.spm.stats.fmri_spec.sess(block).cond(c).orth = options.model.firstlvl.orthogonalization; % Orthogonalization
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).scans = episcans';
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).regress = struct('name', {}, 'val', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).multi_reg = {noisefile}; % Physiological and head motion noise correction files for nuisance regressors
        matlabbatch{1}.spm.stats.fmri_spec.sess(block).hpf = 128; % High-pass filter 128 Hz
        
        block  = block + 1;
        
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {firstlvlpath};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = options.acq.TR; % Repetition time in seconds
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = options.acq.n_slices; % Total slices
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = options.preproc.onset_slice; % Reference slice
    
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    
    if strcmp(basisF,'HRF')
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0]; % Hemodynamic response function derivatives - none
    elseif strcmp(basisF,'FIR')  
        matlabbatch{1}.spm.stats.fmri_spec.bases.fir.length = options.basisF.fir.baseRes; % window length: nBase*TRInSec (~10 s)
        matlabbatch{1}.spm.stats.fmri_spec.bases.fir.order = options.basisF.fir.nBase; % number of estimated timepoints (5 -> 1 Hz)
    end
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