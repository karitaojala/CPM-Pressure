function [abort] = VASTraining(P,O)

abort=0;

fprintf('\n==========================\nRunning VAS training.\n==========================\n');

while ~abort
    
    
    if ~O.debug.toggleVisual
        Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
        Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
        tCrossOn = Screen('Flip',P.display.w);
    else
        tCrossOn = GetSecs;
    end
    
    countedDown = 1;
    while GetSecs < tCrossOn + P.presentation.Calibration.firstTrialWait
        tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
        [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
        if abort; break; end
    end
    
    if abort; return; end
    
    for trial = 1:P.presentation.VAStraining.trials
        
        [abort,finalRating,~,~,~,~] = singleratingScale(P);
        fprintf(['\nFinal rating was ' num2str(finalRating)]);
        
        if ~O.debug.toggleVisual
            Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
            Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
            tCrossOn = Screen('Flip',P.display.w);
        else
            tCrossOn = GetSecs;
        end
    
        % Intertrial interval if not the last stimulus in the block,
        % if last trial then end trial immediately
        if trial ~= P.presentation.VAStraining.trials
            
            fprintf('\nIntertrial interval... ');
            countedDown = 1;
            while GetSecs < tCrossOn + P.presentation.VAStraining.durationITI
                tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                if abort; break; end
            end
            
            if abort; return; end
            
        end
        
        if abort; break; end
        
    end
    
    if abort; break; end
    
    break;
    
end

if ~abort
    fprintf('\nVAS training finished. \n');
else
    return;
end

end