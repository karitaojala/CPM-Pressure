function firstlevel_contrasts_fmri(options,analysis_version,modelname,basisF,tonicIncluded,VASincluded,subj)

exp_runs = options.acq.exp_runs;

for sub = subj
    
    clear conweights
    
    name = sprintf('sub%03d',sub);
    disp(name);
    
    firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
    if ~exist(firstlvlpath, 'dir'); mkdir(firstlvlpath); end
    
    % Define conditions
    
    for run = options.acq.exp_runs
        condfile = fullfile(options.path.logdir, name, 'pain', [name '-run' num2str(run) '-phasic-onsets.mat']);
        load(condfile,'conditions')
        cond_runs(run-1) = conditions(1); % whole run is same condition
    end
    cond_runs(cond_runs == 0) = -1; % switch control cond to -1
    cond_runs = -cond_runs; % flip all signs so that CON = 1, EXP = -1 (hypothesis: CON - EXP / CON > EXP)
    
    if tonicIncluded; cond_Tonic = 2*3; else; cond_Tonic = 0; end
    cond_Stim = 1;
    if VASincluded; cond_VAS = 1; else; cond_VAS = 0; end
    if options.basisF.hrf.derivatives(1) == 1
        cond_Stim = cond_Stim+2;
        cond_VAS = VASincluded*(cond_VAS+2);
    end
    
    % Contrast names
    % Sanity check contrasts
    %   1) Pain ON > baseline (regardless of condition)
    %   2) VAS ON > baseline (regardless of condition)
    % Condition differences
    %   1) CON vs. EXP
    
    if strcmp(basisF,'HRF')
        
        connames = options.stats.firstlvl.contrasts.names;
        
        if tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) == 1 % Tonic, VAS, Deriv
            con_ind = 1:numel(connames);
        elseif tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) ~= 1 % Tonic, VAS, ~Deriv
            con_ind = 1:3:numel(connames);
        elseif ~tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) == 1 % ~Tonic, VAS, Deriv
            con_ind = 7:numel(connames);
        elseif ~tonicIncluded && VASincluded && options.basisF.hrf.derivatives(1) ~= 1 % ~Tonic, VAS, ~Deriv
            con_ind = 7:3:numel(connames);
        elseif ~tonicIncluded && ~VASincluded % ~Tonic, ~VAS, tempDeriv
            con_ind = 7:9;
        else % ~Tonic, ~VAS, ~tempDeriv (pain Only)
            con_ind = 7;
        end
        
        conrepl = options.stats.firstlvl.contrasts.conrepl.hrf;
        
        no_contr = numel(con_ind);
        no_cond = cond_Tonic+cond_Stim+cond_VAS;
        no_reg = no_cond+options.preproc.no_noisereg;
        %cn = 1; % Contrast number
        
        %conweights = zeros(4*no_reg,no_contr);
        
        run_ind = [1 no_reg+1 2*no_reg+1 3*no_reg+1];
        
%         % Tonic stimulus contrast
%         conweights(run_ind,cn)                  =  1/numel(exp_runs); cn = cn+1;
%         conweights(run_ind+(cn-1),cn)           =  1/numel(exp_runs); cn = cn+1; % Temporal derivative
%         % Phasic pain stimulus contrast(s)
%         conweights(run_ind+(cn-1),cn)           =  1/numel(exp_runs); cn = cn+1;
%         conweights(run_ind+(cn-1),cn)           =  1/numel(exp_runs); cn = cn+1; % Temporal derivative
%         % VAS contrast(s)
%         conweights(run_ind+(cn-1),cn)           =  1/numel(exp_runs); cn = cn+1;
%         conweights(run_ind+(cn-1),cn)           =  1/numel(exp_runs); %cn = cn+1; % Temporal derivative
        
        % Take relevant contrasts
        connames = connames(con_ind);
        
%         if no_contr == 3
%             for run = 1:numel(exp_runs)
%                 conweights(run_ind(run),cn) = cond_runs(run)*0.5; % CON-EXP contrast
%             end
%         end
        conweights = eye(no_contr);
        
    else
        
        conrepl = options.stats.firstlvl.contrasts.conrepl.fir;
        
        for c = 1:options.basisF.fir.nBase
            connames{c} = sprintf('%s%02d','Pain',c);
        end
        
        no_contr = options.basisF.fir.nBase;
        
        conweights = eye(options.basisF.fir.nBase);
        
    end
    
    matlabbatch{1}.spm.stats.con.spmmat = {fullfile(firstlvlpath, 'SPM.mat')};
    
    %conweights = repmat(conweights,[numel(exp_runs) 1]);
    
    for con = 1:no_contr % Loop over contrasts for current model
        
%         clear conweights
%         conweights(run_ind+(con-1)) = 1/numel(exp_runs);
%         conweights(run_ind(end)+(con-1)+1:run_ind(end)+no_reg-1) = 0;
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = connames{con}; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = conweights(con,:); % Contrast weight
        matlabbatch{1}.spm.stats.con.consess{con}.tcon.sessrep = conrepl; % Contrast replication across sessions
        
    end
    
%     if strcmp(basisF,'FIR')
%         matlabbatch{1}.spm.stats.con.consess{con+1}.fcon.name = 'PainF'; % Contrast name
%         matlabbatch{1}.spm.stats.con.consess{con+1}.fcon.weights = conweights(:,1); % Contrast weight
%         matlabbatch{1}.spm.stats.con.consess{con+1}.fcon.sessrep = conrepl; % Contrast replication across sessions
%     end
    
    matlabbatch{1}.spm.stats.con.delete = 1; % Deleting old contrast
    
    %% Run matlabbatch
    spm_jobman('run', matlabbatch);
    
    save(fullfile(firstlvlpath,'batch_firstlevel_contrasts'), 'matlabbatch')
    clear matlabbatch
    
end

end