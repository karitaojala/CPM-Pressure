function [abort,P] = calibStimVASRating(P,O,calibStep,trial,trialPressure)

abort = 0;

while ~abort
    
    [abort,finalRating,reactionTime,keyId,keyTime,response] = singleratingScale(P);
    
    VASFile = fullfile(P.out.dir, [P.out.file.VAS '_calibration_step' num2str(calibStep) '.mat']);
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
    
    P.calibration.pressure(end+1) = trialPressure;
    P.calibration.rating(end+1) = finalRating;
    
    VAS(calibStep).calibStep(trial) = calibData;
    
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end