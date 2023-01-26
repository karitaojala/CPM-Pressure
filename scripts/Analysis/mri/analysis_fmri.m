%%FMRI ANALYSIS MAIN SCRIPT

options = get_options();
addpath(options.path.spmdir)
addpath(genpath(options.path.scriptdir))

% subj = options.subj.all_subs(1:21);
% subj = options.subj.all_subs(22:end);
% subj = options.subj.all_subs(36:end);
subj = options.subj.all_subs;
% subj = [1 2 4 5 8 26 43 46]; % subjects with high WM activity
n_proc = 1;

% analysis_version = '19Jan23';
analysis_version = '16Jan23';
basisF = 'HRF'; % Canonical haemodynamic response function
% basisF = 'FIR'; % Finite Impulse Response model
% basisF = 'Fourier'; % Fourier set with Hanning window
% modelname = [basisF '_phasic_tonic_pmod2_interact'];
% modelname = [basisF '_phasic_VAS_pmod'];
% modelname = [basisF '_phasic_tonic_pmod_sessconcat'];
% modelname = [basisF '_phasic_tonic_pmod'];
% modelname = [basisF '_tonic_only'];
modelname = [basisF '_phasic_tonic_noiseROI'];
tonicIncluded       = true; 
phasicIncluded      = true;
VASincluded         = true;
sessConcatenat      = false;
specifyTonicOnly    = false;
derivsOn            = false;
    options.basisF.hrf.derivatives       = [0 0]; % temporal and dispersion derivatives
physioOn            = true;
%     options.preproc.no_noisereg = 6; % only motion

pmodNo = [0 0 0]; % # of parametric modulators of onsets: 1) Tonic stimulus, 2) Phasic stimulus, 3) VAS rating
% Tonic: tonic pressure, tonic pressure x phasic pressure
% Phasic: pain rating
% VAS rating: number of button presses

congroup            = 'SanityCheck';
% congroup            = 'NoiseReg';
% congroup            = 'SanityCheckTonicPmod';
% contrasts_1stlvl  = 1:3;
% congroup            = 'NoiseROI-CSF';
% congroup            = 'PhysioReg';
% congroup            = 'HRV-RVT';
contrasts_1stlvl  = 1:3;
contrasts_2ndlvl  = 1:3;
% congroup            = 'TonicPressureConcatTime';
% contrasts_1stlvl  = 1:52;
% contrasts_2ndlvl  = 1:9;

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

run_delete_folders              = true;
    folders_level2delete = 1; % 1: first level folders, 2: second level folders

if run_create_onsets
    create_onsets(options,subj,onsets_as_scans,debug_plot)
end
    
if run_firstlevel_mask
   firstlevel_brainmask(options,subj)
end

if run_firstlevel_model
    if strcmp(basisF,'HRF')
        if ~sessConcatenat
            firstlevel_fmri(options,analysis_version,modelname,tonicIncluded,phasicIncluded,VASincluded,pmodNo,physioOn,subj) %#ok<*UNRCH>
        else
            firstlevel_fmri_hrf_sess_concat(options,analysis_version,modelname,tonicIncluded,VASincluded,physioOn,subj) %#ok<*UNRCH>
        end
    elseif strcmp(basisF,'FIR')
        firstlevel_fmri_fir(options,analysis_version,modelname,tonicIncluded,phasicIncluded,physioOn,subj)
    elseif strcmp(basisF,'Fourier')
        firstlevel_fmri_fourier(options,analysis_version,modelname,tonicIncluded,phasicIncluded,VASincluded,physioOn,specifyTonicOnly,subj,n_proc)
    end
end

if run_firstlevel_contrasts
    if strcmp(basisF,'HRF') || strcmp(basisF,'FIR')
        firstlevel_contrasts_fmri(options,analysis_version,modelname,basisF,tonicIncluded,VASincluded,pmodNo,subj,congroup,sessConcatenat)
    elseif strcmp(basisF,'Fourier')
        firstlevel_contrasts_fmri_fourier(options,analysis_version,modelname,subj)
    end
end

if run_firstlevel_smoothnorm
    firstlevel_smooth_normalize_fmri(options,analysis_version,modelname,subj,contrasts_1stlvl,run_norm,run_smooth)
end

if run_secondlevel_mask
    secondlevel_brainmask(options)
end

if run_secondlevel_model_contrasts
    if strcmp(basisF,'HRF') || strcmp(basisF,'FIR')
        secondlevel_contrasts_fmri(options,analysis_version,modelname,basisF,subj,contrasts_2ndlvl,congroup,estimate_model)
    elseif strcmp(basisF,'Fourier')
        secondlevel_contrasts_fmri_fourier(options,analysis_version,modelname,subj,estimate_model)
    end
end

if run_delete_folders
   delete_folders(options,analysis_version,modelname,subj,folders_level2delete)
end