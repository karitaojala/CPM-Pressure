function [abort] = PsychometricScaling(P,O)
% Psychometric scaling
% Present few stimuli above the pain threshold to expose participants to
% a wide range of stimuli to scale their psychological perception of what
% intensity of pain is available

% If participant's pain threshold is high, the steps will be larger
% If the pain detection threshold is low, the steps will be smaller

% Predict which kPa pressure needed to produce which VAS rating with
% FitData

abort=0;

fprintf('\n========================================\nRunning psychometric perceptual scaling.\n========================================\n');

while ~abort
    
    calibStep = P.pain.psychScaling.calibStep;
    trials = P.pain.psychScaling.trials;
    
    cuff2process = 0;
    
    for cuff = P.pain.psychScaling.cuff_order % randomized order
        
        cuff2process = cuff2process + 1;
        
        stimType = P.pain.cuffStim(cuff);
        
        fprintf(['\n' P.pain.cuffSide{cuff} ' ' P.pain.cuffLimb{stimType} ' - ' P.pain.stimName{stimType} ' STIMULUS\n--------------------------\n']);
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            if stimType == 1
                if strcmp(P.language,'de')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Kalibrierung: langanhaltender Reiz, ' P.presentation.armname_long_de_c], 'center', upperHalf, P.style.white);
                elseif strcmp(P.language,'en')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Calibration: long stimuli, ' P.presentation.armname_long_en], 'center', upperHalf, P.style.white);
                end
            else
                if strcmp(P.language,'de')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Kalibrierung: kurzer Reiz, ' P.presentation.armname_short_de_c], 'center', upperHalf, P.style.white);
                elseif strcmp(P.language,'en')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Calibration: short stimuli, ' P.presentation.armname_short_en], 'center', upperHalf, P.style.white);
                end
            end
            Screen('TextSize', P.display.w, 30);
            introTextOn = Screen('Flip',P.display.w);
        else
            introTextOn = GetSecs;
        end
        
        while GetSecs < introTextOn + P.presentation.BlockStopDuration
            [abort]=LoopBreaker(P);
            if abort; break; end
        end
        
%         % Wait for input from experiment to continue
%         fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
%         
%         while 1
%             [keyIsDown, ~, keyCode] = KbCheck();
%             if keyIsDown
%                 if find(keyCode) == P.keys.resume
%                     break;
%                 elseif find(keyCode) == P.keys.esc
%                     abort = 1;
%                     break;
%                 end
%             end
%         end
%         if abort; break; end
%         
%         WaitSecs(0.2);
        
        if stimType == 1
            durationITI = P.presentation.Calibration.tonicStim.ITI;
        else
            durationITI = P.presentation.Calibration.phasicStim.ITI;
        end
        
        if isfield(P.awiszus,'painThresholdFinal') && numel(P.awiszus.painThresholdFinal) == 2 % pain thresholds for both cuffs exist
            painThreshold = P.awiszus.painThresholdFinal(cuff);
        else
            painThreshold = P.awiszus.mu(stimType);
        end
        stepSize = P.pain.psychScaling.thresholdMultiplier*painThreshold;
        
        clear scalingPressures
        for pressure = 1:trials
            if pressure ~= trials
                scalingPressures(pressure) = ceil(painThreshold+pressure*stepSize); %#ok<AGROW>
            else
                scalingPressures(pressure) = ceil(painThreshold+(pressure-2)*stepSize); %#ok<AGROW>
            end
        end
        
        for trial = 1:trials
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
            
            
            if trial == 1 % first trial no intertrial interval
                
                fprintf('\nWaiting for the first stimulus to start... ');
                countedDown = 1;
                while GetSecs < tCrossOn + P.presentation.Calibration.firstTrialWait
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
                end
                
                if abort; return; end
                
            end
            
            % Start trial
            fprintf('\n\n=======TRIAL %d of %d=======\n',trial,trials);
            
%             % Red fixation cross
%             if ~O.debug.toggleVisual
%                 Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
%                 Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
%                 Screen('Flip',P.display.w);
%             end
            
            trialPressure = scalingPressures(trial);
            [abort,P] = ApplyStimulusCalibration(P,O,trialPressure,calibStep,stimType,cuff,trial); % run stimulus
            save(P.out.file.param,'P','O'); % Save instantiated parameters and overrides after each trial
            if abort; break; end
            
            % White fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
            
            % Intertrial interval if not the last stimulus in the block,
            % if last trial then end trial immediately
            if trial ~= trials
                
                fprintf('\nIntertrial interval... ');
                countedDown = 1;
                while GetSecs < tCrossOn + durationITI
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
        end
        
        if abort; break; end
        
        % Intercuff interval between 1st and 2nd cuff
        if cuff2process == 1
            fprintf('\nIntercuff interval... ');
            countedDown = 1;
            while GetSecs < tCrossOn + P.presentation.Calibration.interCuffInterval
                tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                if abort; break; end
                if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
            end
            fprintf('\n');
        end
        
        if abort; break; end
        
    end
    
    break;
    
end

if ~abort
    fprintf('\nPsychometric perceptual scaling finished. \n');
end

return;

end