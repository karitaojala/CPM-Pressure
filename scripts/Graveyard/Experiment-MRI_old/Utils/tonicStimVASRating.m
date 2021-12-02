function [abort,P]=tonicStimVASRating(P,O,block,trial)

abort = 0;

while ~abort
    
    [abort,startRating,conRating,conTime,keyId,response] = onlineScale(P);
    
    VASFile = fullfile(P.out.dir, [P.out.file.VAS '_rating_block' num2str(block) '_tonicstim.mat']);
    if exist(VASFile,'file')
        VASData = load(VASFile);
        VAS = VASData.VAS;
    end
    
    tonicStim.startRating = startRating;
    tonicStim.conRating = conRating;
    tonicStim.conTime = conTime;
    tonicStim.keyId = keyId;
    tonicStim.response = response;
    
    VAS(block).tonicStim = tonicStim;
    
    % Save on every trial
    % fprintf(' Saving VAS data... ')
    save(VASFile, 'VAS');
    
    if ~O.debug.toggleVisual
        Screen('Flip',P.display.w);
    end
    
    break;
    
end

end