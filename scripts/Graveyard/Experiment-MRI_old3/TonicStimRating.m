function [P,abort] = TonicStimRating(P,O,trialPressure,rating)

% Start trial
fprintf('\n=======TONIC STIMULUS RATING=======\n');

% Red fixation cross
if ~O.debug.toggleVisual
    Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
    Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
    Screen('Flip',P.display.w);
end

% Pre or post rating
if strcmp(rating,'pre')
    noRating = 1;
elseif strcmp(rating,'post')
    noRating = 2;
end

% Apply tonic stimulus
[abort,P]=ApplyTonicStimulus(P,O,trialPressure,noRating); % run stimulus
save(P.out.file.param,'P','O'); % Save instantiated parameters and overrides after each trial (includes timing information)
        
if strcmp(rating,'pre') % IBI only for first rating
    P.mri.mriRunEndTime(1) = GetSecs;
    % Interblock interval
    if ~O.debug.toggleVisual
        upperHalf = P.display.screenRes.height/2;
        if strcmp(P.language,'de')
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Dieser Teil ist nun beendet. Bitte warten Sie auf den Beginn des nächsten Teils.', 'center', upperHalf, P.style.white);
        elseif strcmp(P.language,'en')
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'There will now be a break before the next part starts. Please wait.', 'center', upperHalf, P.style.white);
        end
        outroTextOn = Screen('Flip',P.display.w);
    else
        outroTextOn = GetSecs;
    end
    
    countedDown = 1;
    while GetSecs < outroTextOn + P.presentation.CPM.blockBetweenText % wait the time between blocks
        tmp=num2str(SecureRound(GetSecs-outroTextOn,0));
        [abort,countedDown]=CountDown(P,GetSecs-outroTextOn,countedDown,[tmp ' ']);
        if abort; break; end
        %                 WaitSecs(1);
    end
    
    if abort; return; end
    
    if ~O.debug.toggleVisual
        Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
        Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
        tCrossOn = Screen('Flip',P.display.w);
    else
        tCrossOn = GetSecs;
    end
    
    fprintf('\nInterblock interval... ');
    countedDown = 1;
    while GetSecs < tCrossOn + (P.presentation.CPM.blockBetweenTime - P.presentation.CPM.blockBetweenText) % wait the time between blocks
        tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
        [abort,countedDown]=CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
        if abort; break; end
        if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
        %                 WaitSecs(1);
    end
    
else
    P.mri.mriRunEndTime(P.presentation.CPM.blocks+2) = GetSecs;
end

if abort; return; end

end