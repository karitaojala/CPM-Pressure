%%FMRI ANALYSIS MAIN SCRIPT

options = get_options();
addpath(options.path.spmdir)
% addpath(genpath(fullfile(options.path.spmdir,'toolbox')))
addpath(genpath(options.path.scriptdir))

subj = options.subj.all_subs;
% subj = options.subj.all_subs(1:21);
% subj = options.subj.all_subs(22:end);
% subj = options.subj.all_subs(36:end);
% subj = [1 2 4 5 8 26 34 43 46]; % subjects with high WM activity
n_proc = 1;

analysis_version = '01Mar23-spinal';
modelNo = 1;
[model,options] = get_model(options,modelNo);
% 1 = HRF - tonic phasic - RETROICOR, full motion (24 brain / 32 spinal)
% 2 = HRF - tonic phasic - RETROICOR, noise ROI WMxCSF, full motion
% 3 = HRF - tonic phasic - RETROICOR, noise ROI WM CSF WMxCSF, full motion
% 4 = HRF - tonic phasic pmod - run-wise design (EXP/CON same column) - RETROICOR, noise ROI WM CSF WMxCSF, full motion
% 5 = HRF - tonic phasic pmod with time (stimulus index) - concatenated design (EXP/CON different columns) - RETROICOR, noise ROI WM CSF WMxCSF, 24 motion

% create a pipeline for physio scripts

run_create_onsets               = false;
    onsets_as_scans             = false;
    debug_plot                  = false;
run_firstlevel_mask             = false;
run_firstlevel_model            = false;
run_firstlevel_contrasts        = false;
run_firstlevel_smoothnorm       = false;
    run_norm                    = false;
    run_smooth                  = false;
run_secondlevel_mask            = false; 
run_secondlevel_model_contrasts = false;
    estimate_model              = false;

run_delete_folders              = false;
    folders_level2delete = 1; % 1: first level folders, 2: second level folders
    delete_model_only    = false; % delete only the specific model folder (or entire analysis version folder)

if run_create_onsets
    create_onsets(options,subj,onsets_as_scans,debug_plot)
end
    
if run_firstlevel_mask
   firstlevel_brainmask(options,subj)
end

if run_firstlevel_model
    if strcmp(model.basisF,'HRF')
        if ~model.sessConcatenat
            firstlevel_fmri(options,analysis_version,model,subj) %#ok<*UNRCH>
        else
            firstlevel_fmri_hrf_sess_concat(options,analysis_version,model,subj) %#ok<*UNRCH>
        end
    elseif strcmp(model.basisF,'FIR')
        firstlevel_fmri_fir(options,analysis_version,model,subj)
    elseif strcmp(model.basisF,'Fourier')
        firstlevel_fmri_fourier(options,analysis_version,model,subj,n_proc)
    end
end

if run_firstlevel_contrasts
    if strcmp(model.basisF,'HRF') || strcmp(model.basisF,'FIR')
        if strcmp(model.congroups_1stlvl.names,'NoiseRegFTest')
            firstlevel_contrasts_physio_Fcon_fmri(options,analysis_version,model,subj)
        else
            firstlevel_contrasts_fmri(options,analysis_version,model,subj)
        end
    elseif strcmp(model.basisF,'Fourier')
        firstlevel_contrasts_fmri_fourier(options,analysis_version,model,subj)
    end
end

if run_firstlevel_smoothnorm
    firstlevel_smooth_normalize_fmri(options,analysis_version,model,subj,run_norm,run_smooth)
end

if run_secondlevel_mask
    secondlevel_brainmask(options)
end

if run_secondlevel_model_contrasts
    if strcmp(model.basisF,'HRF') || strcmp(model.basisF,'FIR')
        secondlevel_contrasts_fmri(options,analysis_version,model,subj,estimate_model)
    elseif strcmp(model.basisF,'Fourier')
        secondlevel_contrasts_fmri_fourier(options,analysis_version,model,subj,estimate_model)
    end
end

if run_delete_folders
   delete_folders(options,analysis_version,model,subj,folders_level2delete,delete_model_only)
end