function [model,options] = get_model(options,modelNo)

model = struct();

if options.spinal; region = 'spinal'; else; region = 'brain'; end
% if sessConcatenat
%     sessconcat = '_sessconcat';
% else
%     sessconcat = '';
% end

switch modelNo
    
    case 1 % HRF - tonic phasic - RETROICOR, 24 (or 32 for spinal) motion
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_RETROICOR'];
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = true;
        
        model.sessConcatenat      = false;
        model.PPI                 = false;
        model.specifyTonicOnly    = false;
        model.covariate           = false;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        if options.spinal
            options.preproc.no_motionreg    = 32; % 24 brain, 32 spinal cord
            options.preproc.no_physioreg    = 18;
            options.model.firstlvl.temp_autocorr = 'FAST';
        else
            options.preproc.no_motionreg    = 24;
            options.preproc.no_physioreg    = 18;
            options.model.firstlvl.temp_autocorr = 'FAST';
        end
        options.preproc.physio_name     = ['multiple_regressors-' region '-RETROICOR_' num2str(options.preproc.no_motionreg) 'motion-zscored'];
        
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        
        model.pmodNo = [0 0 0]; % # of parametric modulators of onsets: 1) Tonic stimulus, 2) Phasic stimulus, 3) VAS rating
        
        model.congroups_1stlvl.names    = {'SanityCheck' 'NoiseReg'};
        %         model.contrasts_1stlvl.indices  = {1:3 4:21};
        model.contrasts_1stlvl.indices  = {1:3 4:53};
        
        model.congroups_2ndlvl.names    = {'SanityCheck' 'RETROICOR' 'Motion'};
        %         model.contrasts_2ndlvl.indices  = {1:3 4:21};
        model.contrasts_2ndlvl.indices  = {1:3 4:21 22:53};
        model.contrasts_2ndlvl.Ftest    = {false true true};
        
    case 2 % HRF - tonic phasic - RETROICOR, noise ROI WMxCSF, 24 motion
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_RETROICOR_noiseROI-WMxCSF'];
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = true;
        
        model.sessConcatenat      = false;
        model.PPI                 = false;
        model.specifyTonicOnly    = false;
        model.covariate           = false;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        options.preproc.no_motionreg    = 24;
        options.preproc.no_physioreg    = 18 + 7;
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion_v2-zscored'];
        
        model.pmodNo = [0 0 0]; % # of parametric modulators of onsets: 1) Tonic stimulus, 2) Phasic stimulus, 3) VAS rating
        
        model.congroups_1stlvl.names    = {'SanityCheck' 'NoiseReg'};
        model.contrasts_1stlvl.indices  = {1:3 4:52};
        model.congroups_2ndlvl.names    = {'SanityCheck' 'RETROICOR' 'NoiseROI-WMxCSF' 'Motion24'};
        model.contrasts_2ndlvl.indices  = {1:3 4:21 22:28 29:52};
        model.contrasts_2ndlvl.Ftest    = {false true true true};
        
    case 3 % HRF - tonic phasic - RETROICOR, noise ROI WM CSF WMxCSF, 24 motion
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_fullPhysio'];
        %         model.name      = [model.basisF '_phasic_tonic_fullPhysio-gradient'];
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = true;
        
        model.sessConcatenat      = false;
        model.PPI                 = false;
        model.specifyTonicOnly    = false;
        model.covariate           = false;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        options.preproc.no_motionreg    = 24;
        options.preproc.no_physioreg    = 18 + 21;
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        
        options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WM_CSF_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion_v2-zscored'];
        %         options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WM_CSF_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion-gradient_v2-zscored'];
        
        model.pmodNo = [0 0 0]; % # of parametric modulators of onsets: 1) Tonic stimulus, 2) Phasic stimulus, 3) VAS rating
        
        model.congroups_1stlvl.names    = {'SanityCheck' 'NoiseReg'};
        model.contrasts_1stlvl.indices  = {1:3 4:66};
        model.congroups_2ndlvl.names    = {'SanityCheck' 'RETROICOR' 'NoiseROI-WM' 'NoiseROI-CSF' 'NoiseROI-WMxCSF' 'Motion24'};
        model.contrasts_2ndlvl.indices  = {1:3 4:21 22:28 29:35 36:42 43:66};
        model.contrasts_2ndlvl.Ftest    = {false true true true true true};
        
    case 4 % HRF - tonic phasic pmod - RETROICOR, noise ROI WM CSF WMxCSF, 24 motion
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_pmod_fullPhysio'];
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = true;
        
        model.sessConcatenat      = false;
        model.PPI                 = false;
        model.specifyTonicOnly    = false;
        model.covariate           = false;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        options.preproc.no_motionreg    = 24;
        options.preproc.no_physioreg    = 18 + 21;
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WM_CSF_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion-zscored'];
        
        model.pmodNo    = [2 1 1]; % # of parametric modulators of onsets: 1) Tonic stimulus, 2) Phasic stimulus, 3) VAS rating
        model.pmodName  = {'TonicPressure' 'TonicxPhasic' 'PhasicPainRating' 'ButtonPress'};
        
        model.congroups_1stlvl.names    = {'SanityCheckTonicPmod' 'TonicPmod'};
        model.contrasts_1stlvl.indices  = {1:5 6:22};
        model.congroups_2ndlvl.names    = {'SanityCheckTonicPmod' 'TonicPmod'};
        model.contrasts_2ndlvl.indices  = {1:5 6:22};
        model.contrasts_2ndlvl.Ftest    = {false false};
        
    case 5 % HRF - tonic phasic pmod with time - concatenated design - RETROICOR, noise ROI WM CSF WMxCSF, 24 motion
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_pmod_time_concat_fullPhysio'];
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = true;
        
        model.sessConcatenat      = true;
        model.PPI                 = false;
        model.specifyTonicOnly    = false;
        model.covariate           = false;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        if options.spinal
            options.preproc.no_motionreg    = 32; % 24 brain, 32 spinal
            options.preproc.no_physioreg    = 18; % 18 + 21 brain, 18 spinal;
            options.preproc.physio_name     = ['multiple_regressors-' region '-RETROICOR_' num2str(options.preproc.no_motionreg) 'motion-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        else
            options.preproc.no_motionreg    = 24;
            options.preproc.no_physioreg    = 18 + 21;
            options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WM_CSF_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion_v2-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        end
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        
        model.pmodNo    = [2 1 0]; % # of parametric modulators of onsets: 1) Tonic stimulus, 2) Phasic stimulus, 3) VAS rating
        model.pmodName  = {'TonicPressure' 'TonicxPhasicPressure' 'PhasicStimInd'};
        
        model.congroups_1stlvl.names    = {'TonicPhasicTimeConcat'};
        model.congroups_1stlvl.names_cons = options.stats.firstlvl.contrasts.names.tonic_concat;
        model.contrasts_1stlvl.indices  = {1:numel(options.stats.firstlvl.contrasts.names.tonic_concat)};
        model.congroups_2ndlvl.names    = {'TonicPhasicTimeConcat'};
        model.congroups_2ndlvl.names_cons = options.stats.secondlvl.contrasts.names.tonic_concat;
        model.contrasts_2ndlvl.indices  = {1:numel(options.stats.secondlvl.contrasts.names.tonic_concat)};
        model.contrasts_2ndlvl.Ftest    = {false};
        
    case 6 % HRF - tonic phasic concatenated design - full Physio - for PPI
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_concat_PPI_fullPhysio'];
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = false;
        
        model.sessConcatenat      = true;
        model.PPI                 = true;
        model.specifyTonicOnly    = false;
        model.covariate           = false;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        if options.spinal
            options.preproc.no_motionreg    = 32; % 24 brain, 32 spinal
            options.preproc.no_physioreg    = 18; % 18 + 21 brain, 18 spinal;
            options.preproc.physio_name     = ['multiple_regressors-' region '-RETROICOR_' num2str(options.preproc.no_motionreg) 'motion-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        else
            options.preproc.no_motionreg    = 24;
            options.preproc.no_physioreg    = 18 + 21;
            options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WM_CSF_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion_v2-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        end
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        
        model.pmodNo    = [0 0 0];
        
        model.congroups_1stlvl.names    = {'TonicPhasicPPIConcat'};
        model.congroups_1stlvl.names_cons = options.stats.firstlvl.contrasts.names.tonic_concat_ppi;
        model.contrasts_1stlvl.indices  = {1:numel(options.stats.firstlvl.contrasts.names.tonic_concat_ppi)};
        model.congroups_2ndlvl.names    = {'TonicPhasicPPIConcat'};
        model.congroups_2ndlvl.names_cons = options.stats.secondlvl.contrasts.names.tonic_concat_ppi;
        model.contrasts_2ndlvl.indices  = {1:numel(options.stats.secondlvl.contrasts.names.tonic_concat_ppi)};
        model.contrasts_2ndlvl.Ftest    = {false};
        
    case 7 % HRF - tonic phasic concatenated design - full Physio - with behavioral rated CPM as a 2nd level covariate
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_pmod_time_concat_CPMcov_fullPhysio'];
        if options.spinal
            model.name_1stlvl = [model.basisF '_phasic_tonic_pmod_time_concat_fullPhysio_' num2str(options.preproc.no_motionreg) 'motion'];
        else
            model.name_1stlvl = [model.basisF '_phasic_tonic_pmod_time_concat_fullPhysio'];
        end
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = false;
        
        model.sessConcatenat      = true;
        model.PPI                 = false;
        model.specifyTonicOnly    = false;
        model.covariate           = true;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        if options.spinal
            options.preproc.no_motionreg    = 32; % 24 brain, 32 spinal
            options.preproc.no_physioreg    = 18; % 18 + 21 brain, 18 spinal;
            options.preproc.physio_name     = ['multiple_regressors-' region '-RETROICOR_' num2str(options.preproc.no_motionreg) 'motion-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        else
            options.preproc.no_motionreg    = 24;
            options.preproc.no_physioreg    = 18 + 21;
            options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WM_CSF_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion_v2-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        end
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        
        model.pmodNo    = [0 0 0];
        
        model.congroups_1stlvl.names    = {'TonicPhasicTimeConcat'}; % same model at 1st level
        model.congroups_1stlvl.names_cons = options.stats.firstlvl.contrasts.names.tonic_concat;
        model.contrasts_1stlvl.indices  = {1:numel(options.stats.firstlvl.contrasts.names.tonic_concat)};
        model.congroups_2ndlvl.names    = {'TonicPhasicTimeConcat'};
        model.congroups_2ndlvl.names_cons = options.stats.firstlvl.contrasts.names.tonic_concat;
        model.contrasts_2ndlvl.indices  = {1:numel(options.stats.firstlvl.contrasts.names.tonic_concat)};
        model.contrasts_2ndlvl.Ftest    = {false};
        
    case 8 % HRF - tonic phasic concatenated design - full Physio - with verbal CPM report as a 2nd level covariate
        
        model.basisF    = 'HRF'; % Canonical haemodynamic response function
        model.name      = [model.basisF '_phasic_tonic_pmod_time_concat_VerbRepcov_fullPhysio'];
       if options.spinal
            model.name_1stlvl = [model.basisF '_phasic_tonic_pmod_time_concat_fullPhysio_' num2str(options.preproc.no_motionreg) 'motion'];
        else
            model.name_1stlvl = [model.basisF '_phasic_tonic_pmod_time_concat_fullPhysio'];
        end
        model.tonicIncluded       = true;
        model.phasicIncluded      = true;
        model.VASincluded         = false;
        
        model.sessConcatenat      = true;
        model.PPI                 = false;
        model.specifyTonicOnly    = false;
        model.covariate           = true;
        
        model.derivsOn                  = false;
        options.basisF.hrf.derivatives  = [0 0]; % temporal and dispersion derivatives
        
        model.physioOn                  = true;
        if options.spinal
            options.preproc.no_motionreg    = 32; % 24 brain, 32 spinal
            options.preproc.no_physioreg    = 18; % 18 + 21 brain, 18 spinal;
            options.preproc.physio_name     = ['multiple_regressors-' region '-RETROICOR_' num2str(options.preproc.no_motionreg) 'motion-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        else
            options.preproc.no_motionreg    = 24;
            options.preproc.no_physioreg    = 18 + 21;
            options.preproc.physio_name     = ['multiple_regressors-' region '-noiseROI_WM_CSF_WMxCSF_6comp_' num2str(options.preproc.no_motionreg) 'motion_v2-zscored'];
            options.model.firstlvl.temp_autocorr = 'FAST';
        end
        options.preproc.no_noisereg     = options.preproc.no_physioreg+options.preproc.no_motionreg;
        
        model.pmodNo    = [0 0 0];
        
        model.congroups_1stlvl.names    = {'TonicPhasicTimeConcat'}; % same model at 1st level
        model.congroups_1stlvl.names_cons = options.stats.firstlvl.contrasts.names.tonic_concat;
        model.contrasts_1stlvl.indices  = {1:numel(options.stats.firstlvl.contrasts.names.tonic_concat)};
        model.congroups_2ndlvl.names    = {'TonicPhasicTimeConcat'};
        model.congroups_2ndlvl.names_cons = options.stats.firstlvl.contrasts.names.tonic_concat;
        model.contrasts_2ndlvl.indices  = {1:numel(options.stats.firstlvl.contrasts.names.tonic_concat)};
        model.contrasts_2ndlvl.Ftest    = {false};
        
end

end