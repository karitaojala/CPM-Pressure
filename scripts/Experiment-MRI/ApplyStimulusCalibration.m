function [abort,P]=ApplyStimulusCalibration(P,O,trialPressure,calibStep,stimType,cuff,trial)

global dev

cparFile = fullfile(P.out.dir,[P.out.file.CPAR '_calibration.mat']);

abort = 0;

while ~abort
    
    fprintf(['Stimulus initiated at ' num2str(trialPressure) ' kPa... ']);
    
    if stimType == 1
        rampDuration = trialPressure/P.pain.preExposure.riseSpeed;
        stimDuration = rampDuration+P.pain.Calibration.tonicStim.stimDuration;
    elseif stimType == 2
        stimDuration = P.pain.Calibration.phasicStim.stimDuration;
    end
    
    P.time.calibStart(calibStep,stimType,trial) = GetSecs-P.time.scriptStart;
    
    if P.devices.arduino
        
        clear data
        [abort,initSuccess,dev] = InitCPAR; % initialize CPAR
        P.cpar.dev = dev;
        save(P.out.file.param, 'P', 'O');
        if initSuccess
            abort = UseCPAR('Set',dev,'Calibration',P,trialPressure,stimType,cuff,trial); % set stimulus
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
            [abort,data] = UseCPAR('Trigger',dev,P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
        else
            abort = 1;
            return;
        end
        if abort; return; end
        P.time.calibStimStart(calibStep,stimType,trial) = GetSecs-P.time.scriptStart;
        
        tStimStart = GetSecs;
        while GetSecs < tStimStart+stimDuration
            [abort]=LoopBreakerStim(P);
            if abort; break; end
        end
                
        % VAS
        fprintf(' VAS... ');
        tVASStart = GetSecs;
        P.time.calibStimVASStart(calibStep,stimType,trial) = GetSecs-P.time.scriptStart;
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
        if ~O.debug.toggleVisual; [abort,P] = calibStimVASRating(P,O,calibStep,cuff,trial,trialPressure); end
        P.time.calibStimVASEnd(calibStep,stimType,trial) = GetSecs-P.time.scriptStart;
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
        P.time.calibStart(calibStep,stimType,trial) = tStimStart-P.time.scriptStart;
        while GetSecs < tStimStart+stimDuration
            tmp=num2str(SecureRound(GetSecs-tStimStart,0));
            [abort,countedDown]=CountDown(P,GetSecs-tStimStart,countedDown,[tmp ' ']);
            if abort; break; end
            if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
        end
        
        if abort; return; end
        
        % VAS
        fprintf(' VAS... ');
        tVASStart = GetSecs;
        P.time.calibStimVASStart(calibStep,stimType,trial) = GetSecs-P.time.scriptStart;
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
        if ~O.debug.toggleVisual; [abort,P] = calibStimVASRating(P,O,calibStep,cuff,trial,trialPressure); end
        P.time.calibStimVASEnd(calibStep,stimType,trial) = GetSecs-P.time.scriptStart;
        if abort; return; end
        
        while GetSecs < tVASStart+P.presentation.Calibration.durationVAS
            [abort]=LoopBreakerStim(P);
            if abort; break; end
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