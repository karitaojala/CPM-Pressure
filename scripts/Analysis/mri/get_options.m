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
    options.preproc.no_noisereg = 18+2; % 18 physio + 2 movement = 20
    
else % Brain
    options.acq.n_slices = 60;
    options.preproc.onset_slice = 60;%1065+50; % onset slice timing in ms, last brain slice + 50 ms (middle of the gap); % last brain slice closest to the slice time correction reference slice (50 ms from last brain slice and first spinal)
    options.preproc.no_noisereg = 18+6; % 18 physio + 6 movement = 24
    
end

options.preproc.norm_prefix = 'w_nlco_dartel_';
options.preproc.smooth_prefix = 's_';
options.preproc.normsmooth_prefix = [options.preproc.smooth_prefix options.preproc.norm_prefix];

options.preproc.smooth_kernel = [6 6 6];

% Basis function (HRF or FIR)
options.basisF.fir.nBase      = 5+5; % depending on duration of longest stimulus, for FIR model
options.basisF.fir.baseRes    = options.basisF.fir.nBase*options.acq.TR; % for FIR model

options.basisF.fir.stim_duration     = 0; % phasic stimulus pressure duration in seconds
options.basisF.fir.vas_duration      = 0; % phasic stimulus pressure duration in seconds

options.basisF.hrf.derivatives       = [1 1]; % temporal derivative%[0 0];

options.basisF.hrf.stim_duration     = 5; % phasic stimulus pressure duration in seconds
options.basisF.hrf.vas_duration      = 5; % VAS duration in seconds
options.basisF.hrf.tonic_duration    = 200; % tonic stimulus duration

options.basisF.onset_shift           = 0;%-5; % a quick tool to shift all onsets by x seconds

% Orthogonalization
options.model.firstlvl.orthogonalization = 0;

% Statistical models
options.stats.firstlvl.contrasts.names = {'Tonic-baseline' 'TonicTempDeriv' 'TonicDispDeriv' ...
    'TonicCond EXP-CON' 'TonicCondTempDeriv' 'TonicCondDispDeriv' ...
    'Pain-baseline' 'PainTempDeriv' 'PainDispDeriv' 'VAS-baseline' 'VASTempDeriv' 'VASDispDeriv'};
options.stats.firstlvl.contrasts.conrepl.hrf = 'none';
options.stats.firstlvl.contrasts.conrepl.fir = 'replsc'; % contrasts not replicated across sessions because sessions different conditions

options.stats.secondlvl.mask_name = 'brainmask_secondlevel.nii';
options.stats.secondlvl.contrasts.contrastnames = options.stats.firstlvl.contrasts.names;
% options.stats.secondlvl.contrasts.contrastnames = {'Pain01' 'Pain02' 'Pain03' 'Pain04' 'Pain05' 'Pain06' 'Pain07' ... 
%     'Pain08' 'Pain09' 'Pain10' 'PainF'};
options.stats.secondlvl.contrasts.direction = 1;
options.stats.secondlvl.contrasts.conrepl.hrf = 'none';
options.stats.secondlvl.contrasts.conrepl.fir = 'replsc';

if options.stats.secondlvl.contrasts.direction
    options.stats.secondlvl.contrasts.actualnames = replace(options.stats.firstlvl.contrasts.names,'-','>');
%     options.stats.secondlvl.contrasts.actualnames = options.stats.secondlvl.contrasts.contrastnames;
else
    options.stats.secondlvl.contrasts.actualnames = replace(options.stats.firstlvl.contrasts.names,'-','<');
end

end