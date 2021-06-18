function Step0_5_addTriggerDetails % this function opens a prepreprocessed file imported from spike or vamp into ledalab-format, and adds some crucial detail from the respective log files

trials = 21;
blocks = [ones(1,7), ones(1,7)*2, ones(1,7)*3];
maxStimDuration = 65;
pressureStep = 3;

hostName = char(getHostName(java.net.InetAddress.getLocalHost));
switch hostName
    case 'isnb05cda5ba721'
        scriptDir   = fullfile(cd,'..','..','EDA-VAmp');
        syScriptDir = cd;
        dataDir     = fullfile(cd,'..','..','..','data','eda','imported'); % the single folder where all vamp files are assembled
        outDir      = fullfile(cd,'..','..','..','data','eda','triggerdetails'); % the folder where all imported data will be exported to
        logDir      = fullfile(cd,'..','..','..','calibration','EIH-Expectation-01','Pilot-01','logs'); % where your log files are, in /sub\d/ subfolders
    otherwise
        error('Hosts %s not recognized.',hostName);
end

if ~exist(outDir,'dir')
    mkdir(outDir);
end

sr = 250; % THIS IS THE SAMPLING RATE, AND IT IS A CRUCIAL THING TO INDICATE BECAUSE CORRECTLY IT'S NOT IN THE PREPROCESSED FILE
sPad = 20;
tol = 0.2; % seconds which the log file and EDA data file can diverge in terms of trigger; if this is above tol, it indicates triggering issues

files = dir([dataDir filesep '*_leda*']);
files = {files.name}';

for nFile = 1:length(files)
    sbId = str2double(cell2mat(regexp(files{nFile},'(?<=\_)\d+(?=\.eeg)','MATCH')));
    
    data = load([dataDir filesep files{nFile}]);
    origData = data.data;
    
    logFiles = dir([logDir filesep sprintf('sub%03d%spain%ssub%03d*',sbId,filesep,filesep,sbId)]);
    
    if numel(logFiles)~=1
        fprintf('Subject %d: Expected number of log files is 1, but we found %d. Skipping...',sbId,numel(logFiles));
        continue;
    end
    
    fprintf('Processing subject %d,\n',sbId);
    
    %removeOffset = @(x,y) x-y;
    
    for lF = 1:numel(logFiles) % log files loaded for sanity check only
        %subData = origData;
        
        fprintf('\tsession %d... ',lF);
        
        P = load([logFiles(lF).folder filesep logFiles(lF).name]);
        P = P.cparData;
        
        % let's cut it up according to the session triggers
        dataStim_ITI = find(vertcat(origData.event.nid)==4);
        for iti_event = 1:numel(dataStim_ITI)
            origData.event(dataStim_ITI(iti_event)).time = origData.event(dataStim_ITI(iti_event)).time-10;
        end
        dataStim = find(vertcat(origData.event.nid)==2 | vertcat(origData.event.nid)==4);
%         dataStim = dataStim(end-(trials-1):end); % discard cues from thresholding
%         dataVAS = logVAS; % no VAS during thresholding
%         if sbId==4
%             dataCues = dataCues(end-21:end); % discard cue from training trial
%         elseif sbId==46
%             dataCues = dataCues(4:end); % discard cue from training trial
%         else
%             dataCues = dataCues(2:end); % discard cue from training trial
%         end
%        dataVASs = find(vertcat(origData.event.nid)==4);
%         if sbId==35 || sbId==42 % accidental second training trial
%             dataVASs = dataVASs(3:end); % discard VAS from training trial
%         elseif sbId==46
%             dataVASs = dataVASs(4:end); % discard VAS from training trial
%         else
%             dataVASs = dataVASs(2:end); % discard VAS from training trial
%         end
        
        % determine trigger indices from this session
%         if lF == 1 % then we have the first session
%             logCues = logCues(2:end);
%             logVAS = logVAS(2:end);
%             subDataCue = dataStim(1:end/2);
%             subDataVAS = dataVASs(1:end/2);
%         else
%             subDataCue = dataStim(end/2+1:end);
%             subDataVAS = dataVASs(end/2+1:end);
%         end
        
        % SANITY CHECK
%         if any((diff(logCues)-diff(vertcat(origData.event(subDataCue).time)))>tol)
%             error('Trigger mismatch for subject %d.',sbId);
%             
%             % mismatch troubleshooting
%             ttt=struct2table(origData.event)
%             [diff(logCues) diff(vertcat(origData.event(subDataCue).time))]
%             qdata = load([dataDir filesep files{nFile-2}]);
%             qdata = qdata.data
%             ttt2=struct2table(qdata.event)
%             qdataCues = find(vertcat(qdata.event.nid)==1);
%         end
        
        iTimeOff = origData.timeoff;
        sTimeOff = origData.timeoff/sr;
        
        sPad_start = sPad-10;
        
        sPadS = origData.event(dataStim(1)).time-sPad_start-sTimeOff; % second of first pressure stimulus minus pad
        sPadE = origData.event(dataStim(end-1)).time+maxStimDuration+sPad-sTimeOff; % last stimulus end plus pad
        iPadS = (floor(origData.event(dataStim(1)).time*sr)-ceil(sPad_start*sr)); % first data point minus pad
        iPadE = (ceil((origData.event(dataStim(end-1)).time+maxStimDuration)*sr)+ceil(sPad*sr)); % last data point plus pad
        
        iPadS = iPadS-iTimeOff;
        iPadE = iPadE-iTimeOff;
        
        subData = origData.conductance(iPadS:iPadE); % pad with 10s pre, 10s post
        subEvents = origData.event((vertcat(origData.event.time)-sTimeOff)>=sPadS & (vertcat(origData.event.time)-sTimeOff)<=sPadE);
        
        % Since this doesn't work right away, I loop it to subtract the offsets
        %structfun(@removeOffset,subEvents.time,10)
        %subEvents.time = subEvents.time-sPadS
        
%         prunedEvents = [];
%         
%         % now we kick out ALL events except three per trial: at handOn 0 (initial exposure), handOn 5 and handOn 11
%         % to do that, we need to count the events up from the respective cues
%         NRInT = -1;
%         NTrial = 0;
%         for sE = 1:numel(subEvents)
%             if ~isempty(regexp(subEvents(sE).name,'S  1','ONCE')) && (sE+3)<numel(subEvents) && ~isempty(regexp(subEvents(sE+3).name,'S  4','ONCE')) % then we have a single exposure
%                 NRInT = -1; % number of repetition in trial
%                 NTrial = NTrial+1;
%             end
%             if ~isempty(regexp(subEvents(sE).name,'S  3','ONCE'))
%                 NRInT = NRInT+1;
%             else
%                 continue;
%             end
%             if NRInT==0 || NRInT==5 || NRInT==11
%                 lastEvent = numel(prunedEvents);
%                 prunedEvents(lastEvent+1).nid = P.session.trialRandomization(NTrial)*100+NRInT;
%                 prunedEvents(lastEvent+1).time = subEvents(sE).time-sPadS-sTimeOff;
%                 prunedEvents(lastEvent+1).name = sprintf('T %d, R %d, S %d',NTrial,NRInT,P.session.trialRandomization(NTrial)); % trial, repetition, trial structure
%                 prunedEvents(lastEvent+1).userdata = [];
%             end
%             
%         end
        
%         for trial = 1:trials
%             subEvents(trial).pressure = ceil(P(trial).data.t01(end-1));
%             subEvents(trial).pressurelevel = (subEvents(1).pressure-subEvents(trial).pressure)/pressureStep;
%             subEvents(trial).trial = trial;
%             subEvents(trial).block = blocks(trial);
%         end
        
        data.timeoff = 0;% sPad*sr;
        data.conductance = subData;
        data.time = [0:(numel(subData)-1)]*1/sr;
        data.event = subEvents;
        
        save([outDir filesep sprintf('sub%03d.mat',sbId)],'data'); % cell2mat(regexp(scrData.comments,'(?<=Original file\: ).+$','MATCH')) % Use if vamp was properly named (not the case in windup)
        
        fprintf('concluded.\n');
        
    end
    
end
