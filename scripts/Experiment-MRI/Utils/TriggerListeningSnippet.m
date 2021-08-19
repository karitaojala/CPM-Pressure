function TriggerListeningSnippet

clear mex global functions;

ListenChar(2); % ensure no keyboard entries end up in scripts etc; deactivate with ListenChar(0) in script or Ctrl+C ONCE if in commandline
clear functions; % necessary to get ListenChar (GetChar) to work with KbQueue

%% set script parameters
P = struct;

[~, tmp]                        = system('hostname');
P.env.hostname                  = deblank(tmp);
P.devices.input                  = [];

KbQueueRelease(P.devices.input); % just to make sure

if strcmp(P.env.hostname,'stimpc1') % curdes button box single diamond (HID NAR 12345)
    P.keys.trigger              = KbName('5%');
else % e.g. settings for laptop computer.
    KbName('UnifyKeyNames');
    P.keys.trigger              = KbName('5%');
end

P.keys.triggerKeyList           = zeros(1,256);
P.keys.triggerKeyList(P.keys.trigger) = 1;

P.mri.dummyScans = 5;

%% set PTB
%     screens                         =  Screen('Screens');                  % Find the number of the screen to be opened
%     P.display.screenNumber      =  max(screens);                       % The maximum is the second monitor
%
%     Screen('Preference', 'Verbosity',0);
%     Screen('Preference','SyncTestSettings',0.005,50,0.2,10);
%     Screen('Preference', 'SkipSyncTests', 1);
%     Screen('Preference', 'VisualDebuglevel', 0);                       % 0 disable all visual alerts
%
%     P.display.w                     = Screen('OpenWindow', P.display.screenNumber, [0 0 0]);
%     Screen('Flip',P.display.w);

%% wait for dummies
fprintf('Will wait for %i dummy pulses...\n',P.mri.dummyScans);
if P.mri.dummyScans > 0
    secs  = NaN(1,P.mri.dummyScans);
    pulse = 0;
    dummy = [];
    while pulse < P.mri.dummyScans % Listening loop
        dummy         = KbTriggerWait(P.keys.trigger,P.devices.input);
        pulse         = pulse + 1;
        secs(pulse)   = dummy; % formerly secs(pulse+1)   = dummy;
        fprintf('Waiting for dummy scan %d\n',pulse);
        % add log functions here
    end
else
    secs = GetSecs;
end

% UNC: Listening Post Theta
KbQueueCreate(P.devices.input,P.keys.triggerKeyList); % 2016-07-19 Trigger listening method; initialize queue
KbQueueStart; % 2016-07-19 Trigger listening method; start queue (will be flushed before the respective waiting loops)

% . . . EXPERIMENT . . .
for t = 1:NTrial
    
    fprintf('Trial %d execution.\n',t);
    
    P.currentTrial.variousData = '...';
    
    P = LogMRITriggers(P);
    P = PutRatingLog(P);
    % ggf save(P.path.save ,'P'); je nach Größe und Dauer (tic toc)
    
end

%% wait for BOLD
finalWait = 10;
fprintf('Entering %ds post-experiment wait for BOLD to catch up.',finalWait);
WaitSecs(finalWait); % arbitrary duration to wait out final BOLD; check if this interferes with the KbQueue somehow
KbQueueRelease(P.devices.input); % essential or KbTriggerWait below won't work

%% wait for final pulse
if strcmp(P.env.hostname,'stimpc1')
    fprintf('=================\n=================\nWait for last scanner pulse of experiment!...\n');
    
    mriEnd = KbTriggerWait(P.keys.trigger,P.devices.input);
    % add log functions here
end

ListenChar(0); % unlock


    function P = LogMRITriggers(P)
        
        [~,keyTimestamps]=KbQueueDump(P);
        
        if ~isempty(regexp(version,'(2015b|2016a|2016b|2017b)','ONCE'))
            keyTimestamps=flip(keyTimestamps);
        else
            keyTimestamps=keyTimestamps(end:-1:1);
        end
        
        for i = 1:length(keyTimestamps)
            P.nMRITrigger = P.nMRITrigger + 1;
            P = PutLogFMRI(P, keyTimestamps(i), ['Trigger ' num2str(P.nMRITrigger)]);
        end
        
        KbQueueFlush;
        
    end
%% Log all events
    function P = PutLog(P, tEvent, eventInfo)
        P.log.eventCount                        = P.log.eventCount + 1;
        P.log.events(P.log.eventCount,1)        = {P.log.eventCount};
        P.log.events(P.log.eventCount,2)        = {tEvent};
        P.log.events(P.log.eventCount,3)        = {tEvent-P.log.mriExpStartTime};
        P.log.events(P.log.eventCount,4)        = {eventInfo};
    end

    function P = PutLogFMRI(P, tEvent, eventInfo)
        P.log.fMRIEventCount                    = P.log.fMRIEventCount + 1;
        P.log.fMRIEvents(P.log.fMRIEventCount,1) = {P.log.fMRIEventCount};
        P.log.fMRIEvents(P.log.fMRIEventCount,2) = {tEvent};
        P.log.fMRIEvents(P.log.fMRIEventCount,3) = {tEvent-P.log.mriExpStartTime};
        P.log.fMRIEvents(P.log.fMRIEventCount,4) = {eventInfo};
    end

    function P = PutRatingLog(P,O)
        P.log.ratingEventCount                  = P.log.ratingEventCount + 1;
        P.log.ratings(P.log.ratingEventCount,1) = P.currentTrial.modality;
        P.log.ratings(P.log.ratingEventCount,2) = 1; % once we have multiple VAS, we'll take care of this
        P.log.ratings(P.log.ratingEventCount,3) = P.currentTrial.N;
        P.log.ratings(P.log.ratingEventCount,4) = P.currentTrial.intensity; % the actually applied intensity
        if ~O.debug.toggleVisual
            P.log.ratings(P.log.ratingEventCount,5) = P.currentTrial.finalRating;
            P.log.ratings(P.log.ratingEventCount,6) = P.currentTrial.response;
            P.log.ratings(P.log.ratingEventCount,7) = P.currentTrial.reactionTime;
        else
            pseudoRating = SecureRound(25+(P.currentTrial.intensity-1)*50+randn*10,0);
            if pseudoRating>100;pseudoRating=100;elseif pseudoRating<0;pseudoRating=0;end
            P.log.ratings(P.log.ratingEventCount,5) = pseudoRating;
            P.log.ratings(P.log.ratingEventCount,6) = -Inf;
            P.log.ratings(P.log.ratingEventCount,7) = -Inf;
        end
        P.log.ratings(P.log.ratingEventCount,8) = P.currentTrial.NBlock;
        P.log.ratings(P.log.ratingEventCount,9) = P.currentTrial.BlockLength;
        P.log.ratings(P.log.ratingEventCount,10) = P.presentation.NTrialInBlock(P.currentTrial.CCS);
        P.log.ratings(P.log.ratingEventCount,11) = P.currentTrial.CCS;
        P.log.ratings(P.log.ratingEventCount,12) = P.currentTrial.CUS;
        P.log.ratings(P.log.ratingEventCount,13:16) = P.currentTrial.USOrder; % mod*int array
        P.log.ratings(P.log.ratingEventCount,17) = P.currentTrial.USSelPosInit;
        P.log.ratings(P.log.ratingEventCount,18) = P.currentTrial.USSelPos;
        P.log.ratings(P.log.ratingEventCount,19) = P.currentTrial.USExpected;
        P.log.ratings(P.log.ratingEventCount,20) = P.currentTrial.Correct;
        
    end
end