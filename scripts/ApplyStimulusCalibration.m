function [abort,P]=ApplyStimulusCalibration(P,O,trialPressure,calibStep,trial)

cparFile = fullfile([P.out.file.CPAR '_Calibration.mat']);

abort = 0;

while ~abort
    
    fprintf(['Stimulus initiated at ' num2str(trialPressure) ' kPa... ']);
    
    if calibStep == 1 || calibStep == 3
        stimType = 2;
        stimDuration = P.pain.Calibration.phasicStim.stimDuration;
    elseif calibStep == 2
        stimType = 1;
        stimDuration = P.pain.Calibration.tonicStim.stimDuration;
    end
    
    P.time.calibStart(trial) = GetSecs-P.time.scriptStart;
    
    if P.devices.arduino
        
        clear data
        [abort,dev] = InitCPAR; % initialize CPAR
        abort = UseCPAR('Set',dev,'Calibration',P,trialPressure,stimType,trial); % set stimulus
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
        [abort,data] = UseCPAR('Trigger',dev,P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
        P.CPAR.dev = dev;
        if abort; return; end
        P.time.calibStimStart(trial) = GetSecs-P.time.scriptStart;
        
        tStimStart = GetSecs;
        while GetSecs < tStimStart+stimDuration
            [abort]=LoopBreakerStim(P);
            if abort; break; end
        end
                
        % VAS
        fprintf(' VAS... ');
        tVASStart = GetSecs;
        P.time.calibStimVASStart(trial) = GetSecs-P.time.scriptStart;
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
        if ~O.debug.toggleVisual; [abort,P] = calibStimVASRating(P,O,calibStep,trial,trialPressure); end
        P.time.calibStimVASEnd(trial) = GetSecs-P.time.scriptStart;
        if abort; return; end
        
        while GetSecs < tVASStart+P.presentation.Calibration.durationVAS
            [abort]=LoopBreakerStim(P);
            if abort; break; end
        end
        
        data = cparGetData(dev, data);
        calibCPARData = cparFinalizeSampling(dev, data);
        saveCPARData(calibCPARData,cparFile,calibStep,trial); % save data for this trial
        fprintf(' Saving CPAR data... ')
        
        if abort; return; end
        
    else
        
        countedDown = 1;
        tStimStart = GetSecs;
        P.time.calibStart(stimType,trial) = tStimStart-P.time.scriptStart;
        while GetSecs < tStimStart+stimDuration+5+P.presentation.Calibration.durationVAS
            tmp=num2str(SecureRound(GetSecs-tStimStart,0));
            [abort,countedDown]=CountDown(P,GetSecs-tStimStart,countedDown,[tmp ' ']);
            if abort; break; end
            if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
        end
        
        if abort; return; end
        
    end
    
    break;
    
end

if ~abort
    fprintf(' Calibration trial concluded. \n');
else
    return;
end

end