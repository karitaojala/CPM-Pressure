function firstlevel_contrasts_fmri(options,analysis_version,modelname,basisF,tonicIncluded,VASincluded,pmod,subj,congroup,sessConcatenat)

for sub = subj
    
    clear conweights cond_runs
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end

    % Load SPM to extract 1st level regressor numbers
    load(fullfile(firstlvlpath,'SPM.mat'))
    
    % Define conditions & extract number of regressors
    for run = options.acq.exp_runs
        
        condfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-onsets.mat']);
        load(condfile,'conditions')
        cond_runs(run-1) = conditions(1); %#ok<*AGROW> % whole run is same condition
        
        if sessConcatenat
            no_reg = numel(SPM.Sess.col);
        else
            no_reg(run-1) = numel(SPM.Sess(run-1).col);
        end
        
    end
    cond_runs(cond_runs == 0) = -1; % switch control cond to -1
    
    % Add conditions depending on which ones included and are there any
    % derivatives
    if tonicIncluded; cond_Tonic = (1+pmod(1))*(1+sum(options.basisF.hrf.derivatives)); else; cond_Tonic = 0; end %#ok<*NASGU>
    cond_Stim = 1 + pmod(2);
    if VASincluded; cond_VAS = 1 + pmod(3); else; cond_VAS = 0; end
    if any(options.basisF.hrf.derivatives)
        cond_Stim = cond_Stim+sum(options.basisF.hrf.derivatives);
        cond_VAS = VASincluded*cond_VAS*(1+sum(options.basisF.hrf.derivatives));
    end
    
    % Contrast names
    % Sanity check contrasts
    %   1) Pain ON > baseline (regardless of condition)
    %   2) VAS ON > baseline (regardless of condition)
    % Condition differences
    %   1) CON vs. EXP
    
    if strcmp(basisF,'HRF')
        
        %no_cond = cond_Tonic+cond_Stim+cond_VAS;
        %no_reg = no_cond+options.preproc.no_noisereg;     
        
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
            %start_noise_reg = no_contr+1;
            %conweights(:,start_noise_reg:start_noise_reg+options.preproc.no_noisereg-1) = 0;
            
            conrepl = 'replsc';
            
        elseif strcmp(congroup,'SanityCheckTonicPmod')
            
            connames = options.stats.firstlvl.contrasts.names.sanitycheck_tonic;
            con_ind = 1:numel(connames);
            no_contr = numel(con_ind);
            conweights = eye(no_contr);
            
            if sessConcatenat
                conrepl = 'none';
            else
                conrepl = 'replsc';
            end
            
        elseif strcmp(congroup,'TonicPressure')
            
            connames = options.stats.firstlvl.contrasts.names.tonic;
            con_ind = 1:numel(connames);
            no_contr = numel(con_ind);
            
            conweights = zeros(no_contr,sum(no_reg));
            cn = 1;
            
            % Tonic onset contrasts
            run_ind = [1 no_reg(1)+1 no_reg(1)+no_reg(2)+1 no_reg(1)+no_reg(2)+no_reg(3)+1]; % 1st regressor for each run
            conweights(cn,run_ind) = (cond_runs == 1)/2; cn = cn + 1; % EXP contrast
            conweights(cn,run_ind) = (cond_runs == -1)/2; cn = cn + 1; % CON contrast
            conweights(cn,run_ind) = cond_runs/2; cn = cn + 1; % EXP > CON contrast
            
            % Tonic pressure contrasts
            run_ind = run_ind + 1; % 2nd regressor for each run
            conweights(cn,run_ind) = (cond_runs == 1)/2; cn = cn + 1; % EXP contrast
            conweights(cn,run_ind) = (cond_runs == -1)/2; cn = cn + 1; % CON contrast
            conweights(cn,run_ind) = cond_runs/2; cn = cn + 1; % EXP > CON contrast
            
            % Tonic x phasic interaction contrasts
            run_ind = run_ind + 1; % 3rd regressor for each run
            conweights(cn,run_ind) = (cond_runs == 1)/2; cn = cn + 1; % EXP contrast
            conweights(cn,run_ind) = (cond_runs == -1)/2; cn = cn + 1; % CON contrast
            conweights(cn,run_ind) = cond_runs/2; % EXP > CON contrast
            
            conrepl = 'none';
            
        elseif strcmp(congroup,'CPM')
            
            connames = options.stats.firstlvl.contrasts.names.cpm;
            
            con_ind = 1;
            no_contr = numel(con_ind);
            
            conweights = zeros(no_contr,numel(options.acq.exp_runs)*no_reg);
            run_ind = [1 no_reg(1)+1 no_reg(1)+no_reg(2)+1 no_reg(1)+no_reg(2)+no_reg(3)+1]; 
            
            cn = 1;
            for run = 1:numel(options.acq.exp_runs)
                %conweights(cn,run_ind(run)) = cond_runs(run)*(1/(numel(options.acq.exp_runs)/2)); % CON-EXP contrast, with equal weight for each run of each condition
                conweights(cn,run_ind(run)) = cond_runs(run)/2;
            end
            conweights = -conweights; % flip to have CON as positive and EXP as negative (CON > EXP)
            
            conrepl = 'none';
            
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
        
    end
    
    matlabbatch{1}.spm.stats.con.spmmat = {fullfile(firstlvlpath, 'SPM.mat')};
    
    cond = 1;
    for con = 1:no_contr % Loop over contrasts for current model
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = connames{con,cond}; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights(con,:); % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = conrepl; % Contrast replication across sessions
    end
    
    matlabbatch{1}.spm.stats.con.delete = options.stats.firstlvl.contrasts.delete; % Deleting old contrast
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    save(fullfile(firstlvlpath,'batch_firstlevel_contrasts'), 'matlabbatch')
    clear matlabbatch
    
end

end