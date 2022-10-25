%%FMRI ANALYSIS MAIN SCRIPT

options = get_options();
addpath(options.path.spmdir)
addpath(genpath(options.path.scriptdir))

subj = options.subj.all_subs(10:end);%(end-4:end);

%analysis_version = '13Oct22';
analysis_version = '24Oct22';
basisF = 'FIR'; % 'HRF' for canonical haemodynamic response function, or 'FIR' for Finite Impulse Response model
%modelname = ['Boxcar_painOnly_' basisF '_noMotion'];
% modelname = ['Boxcar_' basisF '_TempDeriv'];
% modelname = ['Boxcar_' basisF '_TonicIncl_Derivs'];
modelname = ['Boxcar_' basisF];
VASincluded     = false;
tonicIncluded   = false; 
physioOn        = true;
    %options.preproc.no_noisereg = 0; % only motion

congroup    = 'SanityCheck';
contrasts   = 1:10;%

% create a pipeline for physio regressors and onsets

run_create_onsets               = false;
run_firstlevel_mask             = false;
run_firstlevel_model            = false;
run_firstlevel_contrasts        = false;
run_firstlevel_smoothnorm       = false;
    run_norm                    = false;
    run_smooth                  = false;
run_secondlevel_mask            = false;
run_secondlevel_model_contrasts = false;
    copycons                    = false;

run_delete_folders              = true;
    folders_level2delete = 1; % 1: first level folders, 2: second level folders

if run_create_onsets
    create_phasic_onsets(options,subj)    
end
    
if run_firstlevel_mask
   firstlevel_brainmask(options,subj)
end

if run_firstlevel_model
    firstlevel_fmri(options,analysis_version,modelname,basisF,tonicIncluded,VASincluded,physioOn,subj) %#ok<*UNRCH>
end

if run_firstlevel_contrasts
    firstlevel_contrasts_fmri(options,analysis_version,modelname,basisF,tonicIncluded,VASincluded,subj)
end

if run_firstlevel_smoothnorm
    firstlevel_smooth_normalize_fmri(options,analysis_version,modelname,subj,contrasts,run_norm,run_smooth)
end

if run_secondlevel_mask
    secondlevel_brainmask(options)
end

if run_secondlevel_model_contrasts
    secondlevel_contrasts_fmri(options,analysis_version,modelname,basisF,subj,contrasts,copycons,congroup)
end

if run_delete_folders
   delete_folders(options,analysis_version,modelname,subj,folders_level2delete)
end