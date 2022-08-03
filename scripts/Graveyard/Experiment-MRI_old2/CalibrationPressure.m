function [abort] = CalibrationPressure(P,O)

abort=0;

while ~abort
    
    if ~isempty(P.data.preExposure.painThreshold)
        painThresholdSaved = P.data.preExposure.painThreshold;
    else
        painThresholdSaved = [];
    end
    
    fprintf('\n==========================\nRunning calibration procedure.\n');
    
    % TONIC STIMULUS CALIBRATION
    % Loop over calibration trials
    
    for calib = 1:2 % tonic stimuli first, then phasic stimuli (?)
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            if calib == 1
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, 'Calibration long stimuli', 'center', upperHalf, P.style.white);
            else
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, 'Calibration short stimuli', 'center', upperHalf, P.style.white);
            end
            Screen('TextSize', P.display.w, 30);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ' ', 'center', upperHalf+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ' ', 'center', upperHalf+P.style.lineheight, P.style.white);
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Rate the pain intensity quickly after each stimulus ends!', 'center', upperHalf, P.style.white);
            introTextOn = Screen('Flip',P.display.w);
        else
            introTextOn = GetSecs;
        end
        
        while GetSecs < introTextOn + P.presentation.BlockStopDuration
            [abort]=LoopBreaker(P);
            if abort; break; end
        end
        
        % Wait for input from experiment to continue
        fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
        
        while 1
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                if find(keyCode) == P.keys.resume
                    break;
                elseif find(keyCode) == P.keys.esc
                    abort = 1;
                    break;
                end
            end
        end
        
        WaitSecs(0.2);
        
        if calib == 1
            trials = P.presentation.Calibration.tonicStim.trials;
            pressureOrder = P.pain.Calibration.tonicStim.pressureOrder;
            pressureChange = P.pain.Calibration.tonicStim.pressureChange;
            durationITI = P.presentation.Calibration.tonicStim.ITI;
        else
            trials = P.presentation.Calibration.phasicStim.trials;
            pressureOrder = P.pain.Calibration.phasicStim.pressureOrder;
            pressureChange = P.pain.Calibration.phasicStim.pressureChange;
            durationITI = P.presentation.Calibration.phasicStim.ITI;
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
            
            if abort; break; end
            
            % Start trial
            fprintf('\n\n=======TRIAL %d of %d=======\n',trial,trials);
            
            % Red fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            clear index
            index = pressureOrder(trial);
            pressureChangeTrial = pressureChange(index);
            if ~isempty(painThresholdSaved)
                painThreshold = painThresholdSaved(calib); % take individual pain threshold from pre-exposure
            else
                painThreshold = P.pain.Calibration.painTresholdPreset(calib); % take preset pain threshold (40 kPa)
            end
            trialPressure = painThreshold+pressureChangeTrial; % Need to make sure that cuff 1 = left = tonic, cuff 2 = right = phasic OR switch if any change
            
            [abort,P] = ApplyStimulusCalibration(P,O,trialPressure,calib,trial); % run stimulus
            save(fullfile(P.out.dir,['parameters_sub' sprintf('%03d',P.protocol.sbId) '.mat']),'P','O'); % Save instantiated parameters and overrides after each trial
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
        
    end
    
    break;
    
end

if ~abort
    fprintf(' Calibration finished. \n');
else
    return;
end

end