function [options] = get_options()

% Paths
options.path.spmdir      = 'C:\Data\Toolboxes\spm12';
options.path.scriptdir   = 'C:\Data\CPM-Pressure\scripts\Analysis\mri';
options.path.basedir     = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\';
options.path.mridir      = fullfile(options.path.basedir,'mri','data');
options.path.physiodir   = fullfile(options.path.basedir,'physio');
options.path.logdir      = fullfile(options.path.basedir,'logs');

% Subjects
options.subj.all_subs    = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];

% MRI acquisition
options.acq.n_runs            = 6;
options.acq.exp_runs          = 2:5;
options.acq.n_scans_all       = [56 232 232 232 232 56];
options.acq.n_dummy           = 5;
options.acq.n_scans           = options.acq.n_scans_all-options.acq.n_dummy;
options.acq.TR                = 1.991;

options.spinal = true; 

% MRI preprocessing
if options.spinal % Spinal
    options.acq.n_slices = 12;
    options.preproc.onset_slice = 1;%1065+50; % onset slice timing in ms, last brain slice + 50 ms (middle of the gap); % onset slice index, here 1 as it's the first spinal slice that is closest to the slice time correction reference slice
    % slices acquired descending
    options.preproc.no_motionreg = 32;
    options.preproc.no_physioreg = 18;
    options.preproc.physio_name  = 'multiple_regressors-spinal-RETROICOR_32motion-zscored';
    options.preproc.no_noisereg = options.preproc.no_physioreg+options.preproc.no_motionreg; % 18 physio + 2 movement = 20
    options.model.firstlvl.mask_name = 'epi-run2\SUBID-spinalmask.nii';
    options.preproc.norm_prefix = 'w_';
    options.stats.secondlvl.mask_name = 'spinalmask_secondlevel.nii';
    
else % Brain
    options.acq.n_slices = 60;
    options.preproc.onset_slice  = 60;%1065+50; % onset slice timing in ms, last brain slice + 50 ms (middle of the gap); % last brain slice closest to the slice time correction reference slice (50 ms from last brain slice and first spinal)
    options.preproc.no_motionreg = 24;
    options.preproc.no_physioreg = 18; % normal RETROICOR 8 + 6 + 4
    options.preproc.physio_name  = 'multiple_regressors-brain-zscored';
    options.preproc.no_noisereg = options.preproc.no_physioreg+options.preproc.no_motionreg; 
    % options.model.firstlvl.mask_name = 't1_corrected\SUBID-brainmask-v2.nii';
    options.model.firstlvl.mask_name = 't1_corrected\SUBID-brainmask.nii'; 
    options.preproc.norm_prefix = 'w_nlco_dartel_';
    options.stats.secondlvl.mask_name = 'brainmask_secondlevel.nii';
    
end

options.preproc.smooth_prefix = 's_';
options.preproc.normsmooth_prefix = [options.preproc.smooth_prefix options.preproc.norm_prefix];

if options.spinal
    options.preproc.smooth_kernel = [2 2 3]; 
else
    options.preproc.smooth_kernel = [6 6 6]; 
end

% Basis function (HRF, FIR or Fourier set Hanning)
options.basisF.fir.nBase      = 5+5; % depending on duration of longest stimulus, for FIR model
options.basisF.fir.baseRes    = options.basisF.fir.nBase*options.acq.TR; % for FIR model

options.basisF.fourier.windowLength  = 200; % window lenght for Fourier set (Hanning)
options.basisF.fourier.order         = 5; % order for Fourier set (Hanning)
options.basisF.fourier.regressors    = 1+2*options.basisF.fourier.order; % Fourier set no. of regressors: Hanning window + order * sine + cosine
options.basisF.fir.stim_duration     = 0; % phasic pain stimulus duration in seconds
options.basisF.fir.vas_duration      = 0; % vas rating duration in seconds
options.basisF.fir.tonic_duration    = 0; % tonic stimulus duration seconds

options.basisF.hrf.derivatives       = [0 0]; % temporal and dispersion derivatives

options.basisF.hrf.stim_duration     = 5; % phasic pain stimulus function duration in seconds
options.basisF.hrf.vas_duration      = 5; % vas rating function duration in seconds
options.basisF.hrf.tonic_duration    = 0; % tonic stimulus function duration seconds -> modeled as stick functions
options.basisF.hrf.tonic_durationtrue = 200;  % tonic stimulus true duration
options.basisF.hrf.tonic_resolution  = 0.5; % resolution to model the tonic stimulus, 0.5 = 2 sticks per TR

options.basisF.onset_shift           = 0; % a quick tool to shift all onsets by x scans/seconds for checks

% Timing units
options.model.firstlvl.timing_units = 'scans'; % scans or secs

% Orthogonalization
options.model.firstlvl.orthogonalization = 0;

% High-pass filter
options.model.firstlvl.hpf.phasic = 128; % 128 for phasic only models
options.model.firstlvl.hpf.tonic = 200; % 200 for tonic models

options.model.firstlvl.stimuli.phasic_run   = 18;
options.model.firstlvl.stimuli.phasic_total = options.model.firstlvl.stimuli.phasic_run*numel(options.acq.exp_runs);
options.model.firstlvl.stimuli.tonic_name = {'CON' 'EXP'};

% Statistical models
options.stats.firstlvl.contrasts.names.sanitycheck = {'Tonic-baseline' 'Phasic-baseline' 'VAS-baseline'};
options.stats.firstlvl.contrasts.names.sanitycheck_deriv = {'Tonic-baseline' 'TonicTempDeriv' 'TonicDispDeriv' ...
    'Phasic-baseline' 'PhasicTempDeriv' 'PhasicDispDeriv' ...
    'VAS-baseline' 'VASTempDeriv' 'VASDispDeriv'};
options.stats.firstlvl.contrasts.names.sanitycheck_tonic = {'Tonic-baseline' 'TonicPressure-baseline' 'TonicxPhasic-baseline' ...
    'Phasic-baseline' 'PhasicPainRating-baseline' 'VAS-baseline' 'VASButtonPress-baseline'};
options.stats.firstlvl.contrasts.names.sanitycheck_tonic_phasic = {'Tonic-baseline' 'TonicPressure-baseline' 'TonicxPhasic-baseline' ...
    'Phasic-baseline' 'TonicCond-baseline' 'StimIndex-baseline' 'TonicCondxStimInd-baseline' 'VAS-baseline'};
options.stats.firstlvl.contrasts.names.tonic = {'TonicOnset-CON' 'TonicOnset-EXP' 'TonicOnset-CON-EXP' ...
    'TonicPressure-CON' 'TonicPressure-EXP' 'TonicPressure-CON-EXP' ...
    'TonicxPhasic-CON' 'TonicxPhasic-EXP' 'TonicxPhasic-CON-EXP' ...
    'PhasicOnset-CON' 'PhasicOnset-EXP' 'PhasicOnset-CON-EXP' ...
    'PhasicPainRating-CON' 'PhasicPainRating-EXP' 'PhasicPainRating-CON-EXP' ...
    'VASOnset' 'VASButtonPresses'};
options.stats.firstlvl.contrasts.names.tonic_concat = {'TonicOnset-CON' 'TonicOnset-EXP' 'TonicOnset-CON-EXP-avg' 'TonicOnset-CON-EXP-diff'...
    'TonicPressure-CON' 'TonicPressure-EXP' 'TonicPressure-CON-EXP-avg' 'TonicPressure-CON-EXP-diff'...
    'TonicxPhasic-CON' 'TonicxPhasic-EXP' 'TonicxPhasic-CON-EXP-avg' 'TonicxPhasic-CON-EXP-diff'...
    'PhasicOnset-CON' 'PhasicOnset-EXP' 'PhasicOnset-CON-EXP-avg' 'PhasicOnset-CON-EXP-diff'...
    'PhasicStimInd-CON' 'PhasicStimInd-EXP' 'PhasicStimInd-CON-EXP-avg' 'PhasicStimInd-CON-EXP-diff'...
    'VASOnset'};
options.stats.firstlvl.contrasts.names.cpm = {'Phasic CON-EXP'};
options.stats.firstlvl.contrasts.names.cpmtime = {'TonicCond EXP-CON' 'StimIndex' 'TonicCond X StimIndex'};
options.stats.firstlvl.contrasts.names.physioreg = {'PhysioReg' 'MotionReg'};
options.stats.firstlvl.contrasts.names.hrvrvt = {'HRV' 'RVT'};
options.stats.firstlvl.contrasts.names.fourier = {'Phasic-baseline' 'VAS-baseline' 'TonicFourier'};
options.stats.firstlvl.contrasts.conrepl.hrf = 'replsc';
options.stats.firstlvl.contrasts.conrepl.fir = 'replsc'; % contrasts not replicated across sessions because sessions different conditions
options.stats.firstlvl.contrasts.conrepl.fourier = 'replsc';
options.stats.firstlvl.contrasts.delete = 0;

options.stats.secondlvl.contrasts.names = options.stats.firstlvl.contrasts.names;
options.stats.secondlvl.contrasts.direction = 1;
options.stats.secondlvl.contrasts.conrepl.hrf = 'none';
options.stats.secondlvl.contrasts.conrepl.fir = 'none';
options.stats.secondlvl.contrasts.conrepl.fourier = 'none';
options.stats.secondlvl.contrasts.delete = 0;

end