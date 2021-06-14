function [abort,P] = calibStimVASRating(P,O,calibStep,cuff,trial,trialPressure)

abort = 0;

while ~abort
    
    [abort,finalRating,reactionTime,keyId,keyTime,response] = singleratingScale(P);
    
    VASFile = fullfile(P.out.dir, [P.out.file.VAS '_calibration.mat']);
    if exist(VASFile,'file')
        VASData = load(VASFile);
        VAS = VASData.VAS;
    end
    
    clear calibData
    calibData.trialPressure = trialPressure;
    calibData.finalRating = finalRating;
    calibData.reactionTime = reactionTime;
    calibData.keyId = keyId;
    calibData.keyTime = keyTime;
    calibData.response = response;
    
    if calibStep == 1
        P.calibration.pressure(cuff,trial) = trialPressure;
        P.calibration.rating(cuff,trial) = finalRating;
    elseif calibStep == 2
        itemNo = P.pain.psychScaling.trials+trial; % start from after Psychometric Scaling trials
        P.calibration.pressure(cuff,itemNo) = trialPressure;
        P.calibration.rating(cuff,itemNo) = finalRating;
    elseif calibStep == 3
        itemNo = P.pain.psychScaling.trials+numel(P.pain.Calibration.VASTargetsFixed)+trial; % start from after Psychometric Scaling and Fixed Intensity trials
        P.calibration.pressure(cuff,itemNo) = trialPressure;
        P.calibration.rating(cuff,itemNo) = finalRating;
    end
    
    VAS(calibStep,cuff).calibStep(trial) = calibData;
    
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end