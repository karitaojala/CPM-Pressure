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

options.spinal = false; 

% MRI preprocessing
if options.spinal % Spinal
    options.acq.n_slices = 12;
    options.preproc.onset_slice = 1;%1065+50; % onset slice timing in ms, last brain slice + 50 ms (middle of the gap); % onset slice index, here 1 as it's the first spinal slice that is closest to the slice time correction reference slice
    % slices acquired descending
    options.preproc.no_motionreg = 2;
    options.preproc.no_physioreg = 18;
    options.preproc.no_noisereg = options.preproc.no_physioreg+options.preproc.no_motionreg; % 18 physio + 2 movement = 20
    
else % Brain
    options.acq.n_slices = 60;
    options.preproc.onset_slice = 60;%1065+50; % onset slice timing in ms, last brain slice + 50 ms (middle of the gap); % last brain slice closest to the slice time correction reference slice (50 ms from last brain slice and first spinal)
    options.preproc.no_motionreg = 6;
    options.preproc.no_physioreg = 18;
    options.preproc.no_noisereg = options.preproc.no_physioreg+options.preproc.no_motionreg; % 18 physio + 6 movement = 24
    
end

options.preproc.norm_prefix = 'w_nlco_dartel_';
options.preproc.smooth_prefix = 's_';
options.preproc.normsmooth_prefix = [options.preproc.smooth_prefix options.preproc.norm_prefix];

options.preproc.smooth_kernel = [6 6 6];

% Basis function (HRF, FIR or Fourier set Hanning)
options.basisF.fir.nBase      = 5+5; % depending on duration of longest stimulus, for FIR model
options.basisF.fir.baseRes    = options.basisF.fir.nBase*options.acq.TR; % for FIR model

options.basisF.fourier.windowLength  = 200; % window lenght for Fourier set (Hanning)
options.basisF.fourier.order         = 5; % order for Fourier set (Hanning)

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
options.model.firstlvl.orthogonalization = 1;

% High-pass filter
options.model.firstlvl.hpf.phasic = 128; % 128 for phasic only models
options.model.firstlvl.hpf.tonic = 200; % 200 for tonic models

options.model.firstlvl.stimuli.phasic_total = 18*numel(options.acq.exp_runs);

% Statistical models
options.model.firstlvl.tonic_name = {'TonicCON' 'TonicEXP'};
options.stats.firstlvl.contrasts.names.sanitycheck = {'Tonic-baseline' 'TonicTempDeriv' 'TonicDispDeriv' ...
    'TonicPmod-baseline' 'TonicPmodTempDeriv' 'TonicPmodDispDeriv' ...
    'Pain-baseline' 'PainTempDeriv' 'PainDispDeriv' 'VAS-baseline' 'VASTempDeriv' 'VASDispDeriv'};
options.stats.firstlvl.contrasts.names.cpm = {'Pain CON-EXP'};
options.stats.firstlvl.contrasts.names.cpmtime = {'PainCond CON-EXP' 'StimIndex' 'PainCond X StimIndex'};
options.stats.firstlvl.contrasts.names.physioreg = {'PhysioReg' 'MotionReg'};
options.stats.firstlvl.contrasts.names.fourier = {'Pain-baseline' 'VAS-baseline' 'TonicFourier'};
options.stats.firstlvl.contrasts.conrepl.hrf = 'replsc';
options.stats.firstlvl.contrasts.conrepl.fir = 'replsc'; % contrasts not replicated across sessions because sessions different conditions
options.stats.firstlvl.contrasts.conrepl.fourier = 'replsc';
options.stats.firstlvl.contrasts.delete = 1;

options.stats.secondlvl.mask_name = 'brainmask_secondlevel.nii';
options.stats.secondlvl.contrasts.names = options.stats.firstlvl.contrasts.names;
options.stats.secondlvl.contrasts.direction = 1;
options.stats.secondlvl.contrasts.conrepl.hrf = 'replsc';
options.stats.secondlvl.contrasts.conrepl.fir = 'replsc';
options.stats.secondlvl.contrasts.conrepl.fourier = 'replsc';
options.stats.secondlvl.contrasts.delete = 1;

end