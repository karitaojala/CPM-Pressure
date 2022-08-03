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
        if size(P.calibration.pressure,2) == P.pain.psychScaling.trials
            P.calibration.pressure(cuff,P.pain.psychScaling.trials+trial) = trialPressure;
            P.calibration.rating(cuff,P.pain.psychScaling.trials+trial) = finalRating;
        else
            P.calibration.pressure(cuff,trial) = trialPressure;
            P.calibration.rating(cuff,trial) = finalRating;
        end
    elseif calibStep == 2
        if numel(nonzeros(P.calibration.pressure(cuff,:))) == P.pain.psychScaling.trials+trial-1
            itemNo = P.pain.psychScaling.trials+trial; % start from after Psychometric Scaling trials
        else
            itemNo = size(P.calibration.pressure,2) + 1; 
        end
        P.calibration.pressure(cuff,itemNo) = trialPressure;
        P.calibration.rating(cuff,itemNo) = finalRating;
    elseif calibStep == 3
        if numel(nonzeros(P.calibration.pressure(cuff,:))) == P.pain.psychScaling.trials+numel(P.pain.Calibration.VASTargetsFixed)
            itemNo = P.pain.psychScaling.trials+numel(P.pain.Calibration.VASTargetsFixed)+trial; % start from after Psychometric Scaling and Fixed Intensity trials
        else
            itemNo = size(P.calibration.pressure,2) + 1;
        end
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