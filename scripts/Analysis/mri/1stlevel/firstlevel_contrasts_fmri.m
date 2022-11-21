function firstlevel_contrasts_fmri(options,analysis_version,modelname,basisF,tonicIncluded,VASincluded,subj,congroup)

for sub = subj
    
    clear conweights
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    
    % Define conditions
    
    for run = options.acq.exp_runs
        condfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-onsets.mat']);
        load(condfile,'conditions')
        cond_runs(run-1) = conditions(1); % whole run is same condition
    end
    cond_runs(cond_runs == 0) = -1; % switch control cond to -1
    cond_runs = -cond_runs; % flip all signs so that CON = 1, EXP = -1 (hypothesis: CON - EXP / CON > EXP)
    
    % Add conditions depending on which ones included and are there any
    % derivatives
    if tonicIncluded; cond_Tonic = 2*(1+sum(options.basisF.hrf.derivatives)); else; cond_Tonic = 0; end
    cond_Stim = 1;
    if VASincluded; cond_VAS = 1; else; cond_VAS = 0; end
    if any(options.basisF.hrf.derivatives)
        cond_Stim = cond_Stim+sum(options.basisF.hrf.derivatives);
        cond_VAS = VASincluded*(cond_VAS+sum(options.basisF.hrf.derivatives));
    end
    
    % Contrast names
    % Sanity check contrasts
    %   1) Pain ON > baseline (regardless of condition)
    %   2) VAS ON > baseline (regardless of condition)
    % Condition differences
    %   1) CON vs. EXP
    
    if strcmp(basisF,'HRF')
        
        no_cond = cond_Tonic+cond_Stim+cond_VAS;
        no_reg = no_cond+options.preproc.no_noisereg;     
        
        if strcmp(congroup,'SanityCheck')
            
            connames = options.stats.firstlvl.contrasts.names.sanitycheck;
            
            if tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) == 1 % Tonic, VAS, Deriv
                con_ind = 1:numel(connames);
            elseif tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) ~= 1 % Tonic, VAS, ~Deriv
                con_ind = 1:3:numel(connames);
            elseif ~tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) == 1 % ~Tonic, VAS, Deriv
                con_ind = 7:numel(connames);
            elseif ~tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) ~= 1 % ~Tonic, VAS, ~Deriv
                con_ind = 7:3:numel(connames);
            elseif ~tonicIncluded && ~VASincluded && options.basisF.hrf.derivatives(1) == 1 % ~Tonic, ~VAS, Deriv
                con_ind = 7:9;
            elseif ~tonicIncluded && ~VASincluded && options.basisF.hrf.derivatives(1) ~= 1 % ~Tonic, ~VAS, ~Deriv (pain only)
                con_ind = 7;
            end
            
            no_contr = numel(con_ind);
            
            conweights = eye(no_contr);
            start_noise_reg = no_contr+1;
            conweights(:,start_noise_reg:start_noise_reg+options.preproc.no_noisereg-1) = 0;
            
            conrepl = 'replsc';
            
        elseif strcmp(congroup,'CPM')
            
            connames = options.stats.firstlvl.contrasts.names.cpm;
            
            con_ind = 1;
            no_contr = numel(con_ind);
            
            conweights = zeros(no_contr,numel(options.acq.exp_runs)*no_reg);
            run_ind = [1 no_reg+1 2*no_reg+1 3*no_reg+1];
            
            cn = 1;
            for run = 1:numel(options.acq.exp_runs)
                %conweights(cn,run_ind(run)) = cond_runs(run)*(1/(numel(options.acq.exp_runs)/2)); % CON-EXP contrast, with equal weight for each run of each condition
                conweights(cn,run_ind(run)) = cond_runs(run);
            end
            
            conrepl = 'none';
            
        elseif strcmp(congroup,'PhysioReg')
            
            connames = options.stats.firstlvl.contrasts.names.physioreg;
            
            con_ind = 1:2;
            no_contr = numel(con_ind);
            
            % F-contrast for physio regressors
            conweights_physio = zeros(no_reg);
            start_physio_reg = no_cond+1;
            conweights_physio(:,start_physio_reg:start_physio_reg+options.preproc.no_physioreg-1) = eye(no_reg,options.preproc.no_physioreg);
            
            % F-contrast for motion regressors
            conweights_motion = zeros(no_reg);
            start_motion_reg = no_cond+options.preproc.no_physioreg+1;
            conweights_motion(:,start_motion_reg:start_motion_reg+options.preproc.no_motionreg-1) = eye(no_reg,options.preproc.no_motionreg);
            
            conrepl = 'replsc';
            
        end
        
        %conrepl = options.stats.firstlvl.contrasts.conrepl.hrf;
        
        % Take relevant contrasts
        connames = connames(con_ind)';

    elseif strcmp(basisF,'FIR')
        
        for c = 1:options.basisF.fir.nBase
            connames{c,:} = sprintf('%s%02d','Bin',c);
        end
        
        no_contr = options.basisF.fir.nBase;
        
        if tonicIncluded
            load(fullfile(firstlvlpath, 'SPM.mat')) % load SPM to get condition information for each run
            
            conweights_CON = [];
            conweights_EXP = [];
            
            for run = 1:numel(options.acq.exp_runs)
               clear conweights_run
               condname = SPM.Sess(run).U.name{:}(end-2:end); 
               if strcmp(condname,'CON') % if CON run, ones for CON condition contrasts, zeros for EXP condition contrasts
                   connames_CON = cellfun(@(c)[condname '_' c],connames,'uni',false); % add condition name to contrast name
                   conweights_CON = [conweights_CON [eye(options.basisF.fir.nBase) zeros(options.basisF.fir.nBase,options.preproc.no_noisereg)]];
                   conweights_EXP = [conweights_EXP zeros(options.basisF.fir.nBase,options.basisF.fir.nBase+options.preproc.no_noisereg)];
               elseif strcmp(condname,'EXP') % if EXP run, ones for EXP condition contrasts, zeros for CON condition contrasts
                   connames_EXP = cellfun(@(c)[condname '_' c],connames,'uni',false); % add condition name to contrast name
                   conweights_EXP = [conweights_EXP [eye(options.basisF.fir.nBase) zeros(options.basisF.fir.nBase,options.preproc.no_noisereg)]];
                   conweights_CON = [conweights_CON zeros(options.basisF.fir.nBase,options.basisF.fir.nBase+options.preproc.no_noisereg)];
               end
            end

            clear connames
            connames = {connames_CON{:}; connames_EXP{:}}';
            
            conweights_CON = conweights_CON*0.5; % scaling over runs
            conweights_EXP = conweights_EXP*0.5;
            conweights = [conweights_CON; conweights_EXP];
            
            conrepl = 'none'; % no replication across runs as each run has only one condition
        else
            conweights = eye(no_contr);
            conrepl = options.stats.firstlvl.contrasts.conrepl.fir;
        end
        
    elseif strcmp(basisF,'Fourier')
        
        cond_Tonic = 11; % 5 sine, 5 cosine, 1 Henning
        no_cond = cond_Stim+cond_VAS+cond_Tonic;
        
        connames = options.stats.firstlvl.contrasts.names.fourier';
        conweights = eye(no_cond);
        
        conrepl = options.stats.firstlvl.contrasts.conrepl.fourier;
        
    end
    
    matlabbatch{1}.spm.stats.con.spmmat = {fullfile(firstlvlpath, 'SPM.mat')};
    
    cond = 1;
    if strcmp(congroup,'PhysioReg') % F-contrasts already at 1st level -> not interested in single regressor effect
        
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = connames{1}; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = conweights_physio; % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = conrepl; % Contrast replication across sessions
        
        matlabbatch{1}.spm.stats.con.consess{2}.fcon.name = connames{2}; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{2}.fcon.weights = conweights_motion; % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{2}.fcon.sessrep = conrepl; % Contrast replication across sessions
        
    elseif strcmp(basisF,'Fourier')
        
        for con = 1:2 % Loop over contrasts for current model
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = connames{con,cond}; % Contrast name
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights(con,:); % Contrast weight
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = conrepl; % Contrast replication across sessions
        end
        
        con = 3;
        matlabbatch{1}.spm.stats.con.consess{3}.fcon.name = connames{con,cond}; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{3}.fcon.weights = conweights(con:end,:); % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{3}.fcon.sessrep = conrepl; % Contrast replication across sessions
        
    else % all other contrasts
        
        for con = 1:no_contr % Loop over contrasts for current model
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = connames{con,cond}; % Contrast name
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights(con,:); % Contrast weight
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = conrepl; % Contrast replication across sessions
        end
        
    end
    
%     if tonicIncluded
%         
%         cond = cond + 1;
%         for con = 1:no_contr
%             matlabbatch{1}.spm.stats.con.consess{no_contr+con}.tcon.name = connames{con,cond}; % Contrast name
%             matlabbatch{1}.spm.stats.con.consess{no_contr+con}.tcon.weights = conweights(no_contr+con,:); % Contrast weight
%             matlabbatch{1}.spm.stats.con.consess{no_contr+con}.tcon.sessrep = conrepl; % Contrast replication across sessions
%         end
%         
%     end
    
    matlabbatch{1}.spm.stats.con.delete = options.stats.firstlvl.contrasts.delete; % Deleting old contrast
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    save(fullfile(firstlvlpath,'batch_firstlevel_contrasts'), 'matlabbatch')
    clear matlabbatch
    
end

end