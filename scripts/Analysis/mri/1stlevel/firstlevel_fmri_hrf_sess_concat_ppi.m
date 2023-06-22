function firstlevel_fmri_hrf_sess_concat_ppi(options,analysis_version,model,subj,rois)

for sub = subj
    
    clear matlabbatch
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    % Load PPI data
    if options.spinal % if correlate with spinal data, use brain ROI PPIs
        ppi_file = fullfile(options.path.mridir,'2ndlevel','Version_13Apr23-brain','HRF_phasic_tonic_pmod_time_concat_fullPhysio','PPI',[name '-brain_ppi_roi_VOIs.mat']);
    else % vice versa, if correlate with brain data, use spinal ROI PPIs
        ppi_file = fullfile(options.path.mridir,'2ndlevel','Version_13Apr23-spinal','HRF_phasic_tonic_pmod_time_concat_fullPhysio','PPI',[name '-spinal_ppi_roi_VOIs.mat']);
    end
    ppi_data = load(ppi_file);
    rois_list = 1:size(ppi_data.data.xY,2);
    rois_list = rois_list(rois);
    
    for roi = rois_list
        
        roi_data = ppi_data.data.xY(roi);
        roi_name = roi_data.str;
        
        firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],model.name,roi_name);
        if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
        if options.spinal
            masksub = fullfile(options.path.mridir,'2ndlevel','meanmasks',options.model.firstlvl.mask_name);
        else
            masksub = fullfile(options.path.mridir,name,options.model.firstlvl.mask_name);
        end
        masksub = replace(masksub,'SUBID',name);
        
        if sub == 5 || sub == 7
            runs = [2 3 5];
        else
            runs = options.acq.exp_runs;
        end
        nscans_run = options.acq.n_scans(2);
        nscans_all = numel(runs)*options.acq.n_scans(2);
        
        % Noise correction files
        physiopathsub = fullfile(options.path.physiodir,name);
        
        run_ind = 1;
        col_no = 0;
        for run = runs
            noisefiles{run_ind} = fullfile(physiopathsub, [name '-run' num2str(run) '-' options.preproc.physio_name '.txt']);
            delimiter = ' '; %or whatever
            fid = fopen(noisefiles{run_ind},'rt');
            tLines = fgets(fid);
            col_no = col_no + numel(strfind(tLines,delimiter)) + 1;
            fclose(fid);
            run_ind = run_ind + 1;
        end
        
        cond_reg_no = col_no/numel(runs)-options.preproc.no_noisereg;
        assumed_col_no = numel(runs)*(cond_reg_no+options.preproc.no_noisereg);
        if col_no > assumed_col_no
            col_diff = col_no - assumed_col_no;
            noisedataAll = zeros(nscans_all,options.preproc.no_noisereg+col_diff); % all volumes, final column(s) for possible motion exclusion volume
        else
            noisedataAll = zeros(nscans_all,options.preproc.no_noisereg);
        end
        
        episcansAll = [];
        
        block = 1;
        run_vols = 1:nscans_run;
        excl_vol_no = 0;
        
        for run = runs
            
            clear EPI episcans onsetdata pmoddata onsetsPhasic onsetsVAS onsetsTonic
            
            % Select EPI files
            epipath = fullfile(options.path.mridir,name,['epi-run' num2str(run)]);
            cd(epipath)
            if options.spinal
                EPI.epiFiles = spm_vol(spm_select('ExtFPList',epipath,['^a' name '-epi-run' num2str(run) '-' options.model.firstlvl.epi_name '.nii$']));
            else
                EPI.epiFiles = spm_vol(spm_select('ExtFPList',epipath,['^ra' name '-epi-run' num2str(run) '-brain.nii$']));
            end
            
            for epino = 1:size(EPI.epiFiles,1)
                episcans{epino} = [EPI.epiFiles(epino).fname, ',',num2str(epino)]; %#ok<*AGROW>
            end
            
            % Concantenate EPI files
            episcansAll = [episcansAll episcans];
            
            % Physiological noise parameters
            noisedata = importdata(noisefiles{block});
            if size(noisedata,2) > options.preproc.no_noisereg
                excl_vol_cols_run = size(noisedata,2)-options.preproc.no_noisereg;
                excl_vol_cind = excl_vol_cols_run-1;
                for col = 1:excl_vol_cols_run
                    excl_vol_no = excl_vol_no + 1;
                    excl_vol_row = find(noisedata(:,end-excl_vol_cind) == 1);
                    excl_vol_row_ind(excl_vol_no) = run_vols(excl_vol_row); %#ok<*FNDSB>
                    excl_vol_cind = excl_vol_cind - 1;
                end
            end
            
            noisedataAll(run_vols,1:options.preproc.no_noisereg) = noisedata(:,1:options.preproc.no_noisereg);
            run_vols = run_vols + nscans_run;
            
            block  = block + 1;
            
        end
        
        noisedataAll = zscore(noisedataAll);
        
        if excl_vol_no ~= 0
            for col = 1:numel(excl_vol_row_ind)
                col_ind = size(noisedataAll,2)+1;
                noisedataAll(excl_vol_row_ind(col),col_ind) = 1;
            end
        end
        
        if options.spinal
            noisefileAll = fullfile(physiopathsub, [name '-all_runs-multiple_regressors-spinal-zscored.txt']);
        else
            noisefileAll = fullfile(physiopathsub, [name '-all_runs-multiple_regressors-brain-zscored.txt']);
        end
        %writematrix(noisedataAll,noisefileAll,'Delimiter','tab')
        
        disp(['...Blocks ' num2str(options.acq.exp_runs(1)), ' to ' num2str(options.acq.exp_runs(end)), '. Found ', num2str(numel(episcansAll)), ' EPIs...' ])
        disp('................................')
        
        % Define regressors
        r = 1;
        
        % First regressor is the ROI timecourse
        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(r).name = 'ROI-Timecourse';
        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(r).val = roi_data.PPI{1}.Y; % all timecourses same
        
        % Loop over conditions (Tonic/Phasic CON/EXP) for setting PPI regressors
        for cond = 1:4
            
            cond_data = roi_data.PPI{cond};
            
            % Onset
            r = r + 1; % counter for regressors
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(r).name = [cond_data.psy.name{cond} '-Onset'];
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(r).val = cond_data.P;
             
            % Interaction onset and timecourse
            r = r + 1;
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(r).name = [cond_data.psy.name{cond} '-PPI'];
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(r).val = cond_data.o_ppi;
            
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.sess.scans = episcansAll';
        matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {noisefileAll}; % Physiological and head motion noise correction files for nuisance regressors
        if model.tonicIncluded
            matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = options.model.firstlvl.hpf.tonic; % High-pass filter
        else
            matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = options.model.firstlvl.hpf.phasic;
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.dir = {firstlvlpath};
        matlabbatch{1}.spm.stats.fmri_spec.timing.units = options.model.firstlvl.timing_units;
        matlabbatch{1}.spm.stats.fmri_spec.timing.RT = options.acq.TR; % Repetition time in seconds
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = options.acq.n_slices; % Total slices
        matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = options.preproc.onset_slice; % Reference slice
        
        matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = options.basisF.hrf.derivatives; % Hemodynamic response function derivatives - none
        matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
        matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
        %matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.5; % Mask threshold, original 0.8
        matlabbatch{1}.spm.stats.fmri_spec.mask = {masksub}; % Mask to exclude e.g. eyes
        matlabbatch{1}.spm.stats.fmri_spec.cvi = options.model.firstlvl.temp_autocorr; % Temporal autocorrelation removal algorithm to use
        
        %% Specify 1st level model with concatenated sessions
        spm_jobman('run', matlabbatch);
        clear matlabbatch
        
        %% Use SPM concatenate to adjust for session effects
        SPMfile = fullfile(firstlvlpath,'SPM.mat');
        scans2concat = options.acq.n_scans(runs);
        spm_fmri_concatenate(SPMfile, scans2concat);
        
        %% Estimate 1st level model
        matlabbatch{1}.spm.stats.fmri_est.spmmat = {SPMfile};
        matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
        
        %% Run matlabbatch
        spm_jobman('run', matlabbatch);
        
        save(fullfile(firstlvlpath,'batch_firstlevel'), 'matlabbatch')
        clear matlabbatch
        
    end
    
end

end