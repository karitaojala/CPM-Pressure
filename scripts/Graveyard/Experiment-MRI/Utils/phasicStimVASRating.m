function [abort,P]=phasicStimVASRating(P,O,block,trial,stim)
% Phasic stimulus pain rating with one-off VAS during interstimulus
% interval

abort = 0;

while ~abort
    
    [abort,finalRating,reactionTime,keyId,keyTime,response] = singleratingScale(P);
    
    VASFile = fullfile(P.out.dir, [P.out.file.VAS '_rating_block' num2str(block) '_phasicstim.mat']);
    if exist(VASFile,'file')
        VASData = load(VASFile);
        VAS = VASData.VAS;
    end
    
    phasicStim.finalRating = finalRating;
    phasicStim.reactionTime = reactionTime;
    phasicStim.keyId = keyId;
    phasicStim.keyTime = keyTime;
    phasicStim.response = response;
    
    VAS(trial,stim).phasicStim = phasicStim;
    
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end