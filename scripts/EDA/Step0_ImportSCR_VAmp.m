function Step0_ImportSCR_VAmp
% This is for importing BrainVision data, NOT for use with Spike SCR.

project.name = 'CPM-Pressure-01';
project.phase = 'Pilot-02';

% sr = 500;
files2process = 1; % File 2 / sub004 does not have proper triggers
visualize = true;
% leadIn = 1000; % samples to append before trigger 1, ~4s; THE REST IS TRUNCATED
% tag = 'sub'; % default 'sub'

hostName = char(getHostName(java.net.InetAddress.getLocalHost));
switch hostName
    case 'isnb05cda5ba721'
        scriptDir   = fullfile(cd,'..','..','..','EDA-VAmp');
        syScriptDir = cd;
        dataDir     = fullfile(cd,'..','..','data',project.name,project.phase,'eda','vamp'); % the single folder where all vamp files are assembled
        outDir      = fullfile(cd,'..','..','data',project.name,project.phase,'eda','imported'); % the folder where all imported data will be exported to
    otherwise
        error('Hosts %s not recognized.',hostName);
end

addpath([scriptDir filesep 'bvaio']);
addpath([scriptDir filesep 'eeglab']);

if ~exist(outDir,'dir')
    mkdir(outDir);
end

files = dir([dataDir filesep '*.vhdr']);
files = {files.name}';
tolerance = 5;

load([syScriptDir filesep 'validTriggers.mat']);

validTriggers.Pattern = []; % Some studies have a fixed sequence of triggers (e.g. always 2=>3=>5), which can
% be indicated here to filter out irregularities.
% LEAVE PATTERN EMPTY IF YOU WANT TO ACCEPT ALL ACCEPTED SCALAR TRIGGERS (likely the default case)

for t = 1:numel(validTriggers.Unique)
    validTriggers.Strings{t} = sprintf('S%3d',validTriggers.Unique(t));
end

for nFile = 1:length(files)
    
    subID = files{nFile}(1:end-5);
    importedFile = fullfile(outDir,[subID '.eeg_leda.mat']);
    
    if ~exist(importedFile,'file') && ismember(nFile,files2process)
        
        [scrData,~] = pop_loadbv(dataDir,files{nFile});
        
        sr = scrData.srate;
        incl = 0;
        excl = 0;
        data = [];
        fIdc = []; % filtered indices
        
        % do some (three-tier) cleanup for faulty triggers
        % only include event if among the valid trigger types
        for e = 2:size(scrData.event,2)
            if any(ismember(validTriggers.Strings,scrData.event(e).type))
                incl = incl+1;
                fIdc(incl) = e;
            else
                fprintf('Event %d (%s) removed (unknown or discarded trigger type).\n',e,scrData.event(e).type);
            end
        end
        % exclude if too low latency
        for ii = 1:incl
            if ii<incl
                if scrData.event(fIdc(ii-excl)+1).latency-scrData.event(fIdc(ii-excl)).latency<tolerance
                    fprintf('Event %d (%s) removed with latency %d.\n',fIdc(ii-excl),scrData.event(fIdc(ii-excl)).type,scrData.event(fIdc(ii-excl)+1).latency-scrData.event(fIdc(ii-excl)).latency);
                    fIdc(ii-excl) = [];
                    excl = excl+1;
                end
            end
        end
        incl = numel(fIdc);
        fIdc = [fIdc;zeros(size(fIdc))];
        % only include if in connection to validTriggers.Patterns
        trialN = 0;
        if isempty(validTriggers.Pattern)
            fIdc(2,:) = fIdc(1,:)-1;
        else
            for ii = 1:incl
                %             trialStart = 0;
                for vtp = 1:numel(validTriggers.Pattern)
                    tT = str2double(cell2mat(regexp(scrData.event(fIdc(1,ii)).type,'\d+$','MATCH')));
                    if tT==validTriggers.Pattern{vtp}(1) % then we have a trial start
                        if ii+numel(validTriggers.Pattern{vtp})-1>incl
                            warning('Trial start detected at entry %d, but validTriggers.Pattern %d too long for trial conclusion. Skipping pattern.\n',fIdc(1,ii),vtp);
                        else
                            currentPattern = [];
                            for cP = 0:numel(validTriggers.Pattern{vtp})-1
                                currentPattern(cP+1) = str2double(cell2mat(regexp(scrData.event(fIdc(1,ii+cP)).type,'\d+$','MATCH')));
                            end
                            if all(currentPattern==validTriggers.Pattern{vtp}) % then it's a valid trial pattern
                                trialN = trialN + 1;
                                fIdc(2,ii:ii+numel(validTriggers.Pattern{vtp})-1) = trialN;
                            end
                        end
                        
                    end
                end
                
            end
        end
        
        % some individual file troubleshooting (example)
        %if strcmp(files{nFile},'sub006.vhdr')
        %    fIdc(2,:) = fIdc(2,:)-3;
        %elseif strcmp(files{nFile},'sub013.vhdr')
        %    fIdc(2,:) = fIdc(2,:)-2;
        %end
        
        % clean up events without validated trial association
        fIdc(:,fIdc(2,:)<=0) = [];
        
        data.timeoff        = 0; % ACTUALLY NOT NECESSARY, see /ledalab/main/import/import_data.m (someone scrapped this and fixed it to data.time(1))
        data.conductance    = -1*double(scrData.data);
        data.time           = [0:numel(scrData.data)-1]*1/scrData.srate;
        
%         data.timeoff        = scrData.event(2).latency-leadIn; % ACTUALLY NOT NECESSARY, see /ledalab/main/import/import_data.m (someone scrapped this and fixed it to data.time(1))
%         data.conductance    = data.conductance(scrData.event(2).latency-leadIn:end);
%         data.time           = data.time(scrData.event(2).latency-leadIn:end);
        
        for ii=1:size(fIdc,2)
            data.event(ii).time     = scrData.event(fIdc(1,ii)).latency/sr;
            data.event(ii).nid      = str2double(cell2mat(regexp(scrData.event(fIdc(1,ii)).type,'\d+$','MATCH')));
            data.event(ii).name     = sprintf('%s, trial %d',scrData.event(fIdc(1,ii)).type,fIdc(2,ii));
            data.event(ii).userdata = [];
        end
        
        % visualize the triggers
        if visualize % ... if you like
            figure;
            plot([vertcat(data.event.time) vertcat(data.event.time)]',repmat([0 1],numel(vertcat(data.event.time)),1)')
            hold on;
            text(vertcat(data.event.time),repmat(0.9,numel(vertcat(data.event.time)),1),num2str(vertcat(data.event.nid)))
        end
        
        save([outDir filesep regexprep(cell2mat(regexp(scrData.comments,'(?<=Original file\: ).+$','MATCH')),'nocbay','windup') '_leda.mat'],'data'); % cell2mat(regexp(scrData.comments,'(?<=Original file\: ).+$','MATCH')) % Use if vamp was properly named (not the case in windup)
        
    end
end
