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
        
        fprintf(['\n' P.pain.cuffSide{cuff} ' ARM - ' P.pain.stimName{stimType} ' STIMULUS\n--------------------------\n']);
        
        if stimType == 1
            durationITI = P.presentation.Calibration.tonicStim.ITI;
        else
            durationITI = P.presentation.Calibration.phasicStim.ITI;
        end
        
        %         P.awiszus.painThresholdFinal = [30 35];
        painThreshold = P.awiszus.painThresholdFinal(cuff);
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
            
            % Red fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
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
        
        % Intercuff interval between 1st and 2nd cuff
        if cuff2process == 1
            fprintf('\nIntercuff interval... ');
            countedDown = 1;
            while GetSecs < tCrossOn + P.presentation.Calibration.interCuffInterval
                tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                if abort; break; end
            end
            fprintf('\n');
        end
        
        if abort; break; end
        
    end
    
    break;
    
end

if ~abort
    fprintf('\nPsychometric perceptual scaling finished. \n');
else
    return;
end

end