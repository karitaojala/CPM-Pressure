function [abort,P]=ApplyTonicStimulus(P,O,tonicPressure,noRating)

global dev

cparFile = fullfile(P.out.dir,[P.out.file.CPAR '_CPM_tonic.mat']);

abort = 0;

while ~abort
    
    fprintf(['Tonic stimulus initiated (' num2str(tonicPressure(1)) ' to ' num2str(tonicPressure(2)) ' kPa)... ']);
    
    P.time.tonicTrialStart(noRating) = GetSecs-P.time.scriptStart;
    
    if P.devices.arduino
        
        [abort,initSuccess,dev] = InitCPAR; % initialize CPAR
        if abort; return; end
        P.cpar.dev = dev;
        save(P.out.file.param, 'P', 'O');
        if initSuccess
            data = UseCPAR('Set',dev,'TonicRating',P,tonicPressure); % set stimulus
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
            [abort,data] = UseCPAR('Trigger',dev,P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
        else
            abort = 1;
            return;
        end
        if abort; return; end
    end
    P.time.tonicRatingStimStart(noRating) = GetSecs-P.time.scriptStart;
    tStimStart = GetSecs;
    
    % Block and trial for VAS saving index purpose
    block = noRating;
    trial = 1;
    
    % VAS
    fprintf(' VAS... ');
    P.time.tonicVASStart(noRating) = GetSecs-P.time.scriptStart;
    SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
    if ~O.debug.toggleVisual; [abort,P] = tonicStimVASRating(P,O,block,trial); end
    P.time.tonicVASEnd(noRating) = GetSecs-P.time.scriptStart;
    if abort; return; end
    
    while GetSecs < tStimStart+P.pain.CPM.tonicRating.totalDuration%+P.presentation.CPM.tonicStim.durationBuffer
        [abort]=LoopBreakerStim(P);
        if abort; break; end
    end
    
    if P.devices.arduino
        data = cparGetData(dev, data);
        trialData = cparFinalizeSampling(dev, data);
        saveCPARData(trialData,cparFile,block,trial); % save data for this trial
        fprintf(' Saving CPAR data... ')
    end
    if abort; return; end
    
    break;
    
end

if ~abort
    fprintf(' Rating concluded. \n');
else
    return;
end

end