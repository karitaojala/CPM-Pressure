%%FMRI ANALYSIS MAIN SCRIPT

options = get_options();
addpath(options.path.spmdir)
addpath(genpath(options.path.scriptdir))

subj = options.subj.all_subs;

analysis_version = '13Oct22';
basisF = 'HRF'; % or 'HRF' for usual models
modelname = ['Boxcar_painOnly_' basisF];
VASincluded = false;

congroup    = 'SanityCheck';
contrasts   = 1;%:3;%1:11;%

% create a pipeline for physio regressors and onsets

run_firstlevel_mask             = false;
run_firstlevel_model            = false;
run_firstlevel_contrasts        = false;
run_firstlevel_smoothnorm       = true;
    run_norm                    = true;
    run_smooth                  = true;
run_secondlevel_mask            = false;
run_secondlevel_model_contrasts = true;
    copycons                    = true;

run_delete_folders              = false;
    folders_level2delete = 1; % 1: first level folders, 2: second level folders

if run_firstlevel_mask
   firstlevel_brainmask(options,subj)
end

if run_firstlevel_model
    firstlevel_fmri(options,analysis_version,modelname,basisF,VASincluded,subj) %#ok<*UNRCH>
end

if run_firstlevel_contrasts
    firstlevel_contrasts_fmri(options,analysis_version,modelname,basisF,VASincluded,subj,contrasts)
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