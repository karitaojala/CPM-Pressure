function [allData] = Step2_CompileEDA(exportTag)

doCycleSingleTrialFigures   = 1; % 0 (no figures), 1 (time courses only), 2 (includes patches for relevant segments, plus single scrs; takes a while)

if ~nargin
    exportTag = 'tonic'; % tonic (SCL) or phasic (SCR)
end

baseDir = fullfile(cd,'..','..','..','data','eda');
outDir = [baseDir filesep 'aggregateData'];
if ~exist(outDir,'dir'); mkdir(outDir); end
allSbs = [3 5:8];
sb_stim2exclude = [0 4 2 6 3];
runs = 1;
NTrial = 21;
%allData.RAWDATA = NaN;

EXCLSEGS = cell(max(allSbs),max(runs)); % vector of individual segments to skip, or 'all'

padd = 10; % this is really important; from TruncateSpikeFiles, the leading padding which needs to be included in determining the times (which are starting at 0 last dummy)

% SC response window
rwVisual(1,1:2) = [0 0]; % response window for visualization
rwVisual(2,1:2) = [0 0]; % response window for visualization
rw(1,1:2) = [0 0]; % response window for analysis for heat (in seconds) %THIS IS THE RW USED FOR THE MEAN VALUES!!
rw(2,1:2) = [0 0]; % response window for analysis for sound (in seconds) %THIS IS THE RW USED FOR THE MEAN VALUES!!
rwOffset = rw-rwVisual(:,1);

minSCR = 0.01;

%allData = readtable('C:\Users\horing\Documents\projects\P11_WindUp\data\aggregateData\allData.txt');

minSize = Inf(3,2);
maxSize = -Inf(3,2);

for sb = 1:numel(allSbs)

    evTs = [];
    EDA = [];
    times = [];
    runData = [];
    
    logPath = sprintf('%s%slogs%ssub%03d.mat',baseDir,filesep,filesep,allSbs(sb));
    ledaPath = sprintf('%s%sleda_proc%ssub%03d.mat',baseDir,filesep,filesep,allSbs(sb));
    
    if ~exist(logPath,'file') || ~exist(ledaPath,'file')
        continue;
    else
        fprintf('Processing subject %03d\n',allSbs(sb));
        
        logFile = load(logPath);
        
        % major operations
        evTs = [];
        
        % REVISE EVTS DEFINITION ACCORDING TO LOG FILE
        pressureStim_start = find(vertcat(logFile.data.event.nid)==2);
        %pressureStim_end = find(vertcat(logFile.data.event.nid)==4);
        firsttrial = numel(pressureStim_start)-21+1;
        pressureStim_start = pressureStim_start(firsttrial:end);
        %pressureStim_end = pressureStim_end(firsttrial:end);
        %pressureStim_end = pressureStim_end(2:end);
        pressureStim_end = pressureStim_start+1;
        subEvents_id = vertcat(logFile.data.event.nid);
        subEvents_idx = [pressureStim_start pressureStim_end];
        subEvents_all = vertcat(logFile.data.event.time);
        subEvents(:,1) = subEvents_all(subEvents_idx(:,1));
        subEvents(21,2) = subEvents_all(end)+64;
        subEvents(1:20,2) = subEvents_all(subEvents_idx(1:20,2));
        
        % START AND ENDPOINTS
        NRInT = -1;
        NTrial = 21;
%         for sE = 1:size(subEvents,1)
%             NTrial = NTrial+1;
%             evTs(NTrial,1) = subEvents{sE,3};
%         end
%         evTs = evTs-subEvents+padd;
        subEvents(:,2) = subEvents(:,2)+padd;
        %subEvents(21,2) = subEvents(21,2)-5; % last trial not enough time after
        evTs = subEvents;
        
%         allData.Intercept = NaN(size(NTrial,1),1);
%         allData.Slope = NaN(size(NTrial,1),1);
        
        % EDA file
        if exist(ledaPath,'file')
            ledaFile = load(ledaPath);
            %evTs = vertcat(ledaFile.data.event.time);
            if strcmp(exportTag,'tonic')
                EDA = ledaFile.analysis.tonicDriver;
            elseif strcmp(exportTag,'phasic')
                EDA = ledaFile.analysis.driver;
            end
            times = ledaFile.data.time;
            %times = times-(padd+NDummies*TR); % it's either this, or ADD padd+NDummies*TR to the evTs
            
            % add some side notes
            res = mean(diff(times));
            dsf = str2double(cell2mat(regexp(ledaFile.fileinfo.log{2,1},'(?<=\(Factor )\d+(?=\))','MATCH'))); % determine downsampling factor
            origRes = res/dsf;
            
            allData_sub = [];
            [runData] = ObtainContinuousEDAData(doCycleSingleTrialFigures,allData_sub,evTs,EDA,times,rwVisual,rw);
            %[runData_singleSCRs] = ObtainSingleEDAData(runData,evTs,times,rw);
        end
        
        % get length of entries in both response windows to possibly replace them with NaNs if exclusions apply
        if ~isempty(EXCLSEGS{allSbs(sb)})
            if strcmp(EXCLSEGS{allSbs(sb)},'all')
                warning('Subject %d, is completely excluded.',allSbs(sb));
                runData(:,:) = []; % flush table
            else
                %runData(EXCLSEGS{allSbs(sb),runs(r)},:) = [];  % then we throw out whatever is in EXCLSEGS for this sb/run
                
                vedl = numel(runData.VisualEDADriver{1});
                edl = numel(runData.EDADriver{1});
                
                runData.VisualEDADriver(EXCLSEGS{allSbs(sb),runs(r)}) = {NaN(1,vedl)};
                runData.EDADriver(EXCLSEGS{allSbs(sb),runs(r)}) = {NaN(1,edl)};
                runData.EDAAvgDriver(EXCLSEGS{allSbs(sb),runs(r)}) = NaN;
            end
        end
    end
    
    %allData.NTrial = 1:NTrial;
    %allData.Event = subEvents_id;
    
    for dN = 1:numel(runData.EDADriver)
        if ~isempty(runData.EDADriver{dN})
            stats  = regstats(runData.VisualEDADriver{dN},[1:numel(runData.VisualEDADriver{dN})]);
            allData.RAWDATA{sb,dN} = runData.VisualEDADriver{dN}; % only need it once
            allData.Intercept(sb,dN) = stats.beta(1);
            allData.Slope(sb,dN) = stats.beta(2);
            allData.MinEDA(sb,dN) = min(runData.VisualEDADriver{dN});
            allData.MaxEDA(sb,dN) = max(runData.VisualEDADriver{dN});
            allData.DiffMaxMinEDA(sb,dN) = max(runData.VisualEDADriver{dN})-min(runData.VisualEDADriver{dN});
        else
            allData.RAWDATA{sb,dN} = []; % only need it once
            allData.Intercept(sb,dN) = NaN;
            allData.Slope(sb,dN) = NaN;
            allData.MinEDA(sb,dN) = NaN;
            allData.MaxEDA(sb,dN) = NaN;
            allData.DiffMaxMinEDA(sb,dN) = NaN;
        end
    end
    
end

saveAllDataWRaw = 1;
if saveAllDataWRaw
    save(sprintf('%s%sPressureTest_%s_SCR_Raw.mat',outDir,filesep,exportTag),'allData')
end
% tmp = allData; % store
% allData.RAWDATA = []; % make file version for aggregates, because time course won't save properly in the table
% writetable(allData,[outDir filesep 'allData.txt']);
allData = tmp; % write back


% add EDA data chunks to runData
function [runData] = ObtainContinuousEDAData(doVisualsDepth,runData,evTs,EDA,times,rwVisual,rw)

runData = [];

rwOffset = rw-rwVisual(:,1);

if doVisualsDepth
    modCols(1,1,:) = [1 0.5 0.5];
    modCols(1,2,:) = [1 0 0];
    modCols(2,1,:) = [0.5 0.5 1];
    modCols(2,2,:) = [0 0 1];
    
    F = figure('Position',[300,300,1000,400]);
end

rowN = 3;
colN = 7;
id = 1;
% get EDA chunks
for e = 1:size(evTs,1) % we go through the events in the log file
    % VISUAL RESPONSE WINDOW
    rwVisualT = evTs(e,:)+rw(1,:);%rwVisual(runData.Modality(e),:);
    iS = find(times<rwVisualT(1),1,'last'); % start index of response window
    if ~isempty(find(times>rwVisualT(2),1,'first'))
        iE = find(times>rwVisualT(2),1,'first'); % end index of response window
    else
        iE = numel(times);
    end
    visUsChunk = EDA(iS:iE);
    visChunk = smooth(visUsChunk,10); % apply minor smoothing to get rid of weird oscillations...
    runData.VisualEDADriver{e} = visChunk;
    
    rwT = evTs(e,:)+rw(1,:);
    iS = find(times<rwT(1),1,'last'); % start index of response window
    iE = find(times>rwT(2),1,'first'); % end index of response window
    usChunk = EDA(iS:iE);
    chunk = smooth(usChunk,10); % apply minor smoothing to get rid of weird oscillations...
    runData.EDADriver{e} = chunk;
    runData.EDAAvgDriver(e) = nanmean(chunk);
    if isnan(runData.EDAAvgDriver(e))
        warning('There is a nan in your vector. This shouldn''t happen.');
    end
    
    if doVisualsDepth
        subplot(rowN,colN,id)
        x = (1:size(visChunk,1))/20;
        %plot(x,visUsChunk,'Color',[0 0 0],'LineWidth',2);
        hold on;
        %plot(visChunk,'Color',squeeze(modCols(runData.Modality(e),runData.Intensity(e),:)),'LineWidth',2);
        plot(x,visChunk,'Color','black','LineWidth',2);
        %xticks(0:20:180)
        %xticklabels(0:20:180)
        %title(sprintf('Sub %d, run %d, modality %d, intensity %d, event %d',runData.SbId(e),runData.Session(e),runData.Modality(e),runData.Intensity(e),e))
        if ~mod(e,3)
            es = 3;
        else
            es = mod(e,3);
        end
        %title(sprintf('Event %d, segment %d/3',e,es));
        title(sprintf('Trial %d',e));
        set(gca,'XTick',0:50:100,'FontSize',8)
        %set(gca,'YTick',ymin:0.1:ymax,'FontSize',12)
%         hold off;
%         drawnow;
%         pause;

    id = id+1;
    end
end


if doVisualsDepth
    close(F);
end


end

end


% Results were log- and z-transformed to reduce the impact of intra- and interindividual outliers
% [24]. Subsequently, SCR was averaged within subjects for 2 modalities (heat/sound) and 6
% stimulus intensities each, yielding 12 values per person.