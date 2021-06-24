function [abort] = TargetRegressionVAS(P,O)

abort=0;

fprintf('\n==========================\nRunning VAS target regression.\n==========================\n');

while ~abort
    
    cuff2process = 0;
    
    % Separately for long tonic stimuli and short phasic stimuli
    for cuff = P.pain.Calibration.cuff_order % randomized order
        
        clear x y ex ey pressureData ratingData nextStim nH
        cuff2process = cuff2process + 1;
        
        stimType = P.pain.cuffStim(cuff);
        
        fprintf(['\n' P.pain.cuffSide{cuff} ' ARM - ' P.pain.stimName{stimType} ' STIMULUS\n--------------------------\n']);
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            if stimType == 1
                if strcmp(P.language,'de')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Kalibrierung: langanhaltender Reiz, den ' P.presentation.armname_long_de ' Arm'], 'center', upperHalf, P.style.white);
                elseif strcmp(P.language,'en')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Calibration: short pain stimuli, the ' P.presentation.armname_long_en ' arm'], 'center', upperHalf, P.style.white);
                end
            else
                if strcmp(P.language,'de')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Kalibrierung: kurzer Reiz, den ' P.presentation.armname_short_de ' Arm'], 'center', upperHalf, P.style.white);
                elseif strcmp(P.language,'en')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Calibration: short pain stimuli, the ' P.presentation.armname_en ' arm'], 'center', upperHalf, P.style.white);
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
        
        if stimType == 1
            durationITI = P.presentation.Calibration.tonicStim.ITI;
        else
            durationITI = P.presentation.Calibration.phasicStim.ITI;
        end
        
        fprintf('\n')
        if isempty(P.calibration.pressure) || isempty(P.calibration.rating)% || ~exist('P.calibration.pressure') || ~exist('P.calibration.rating') %#ok<EXIST>
            fprintf('No valid previous data from psychometric scaling.');
            fprintf('\nTake preset values to continue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
            
            while 1
                [keyIsDown, ~, keyCode] = KbCheck();
                if keyIsDown
                    if find(keyCode) == P.keys.resume
                        painThreshold = P.awiszus.mu(cuff);
                        P.pain.Calibration.VASTargetsFixedPressure = painThreshold + P.pain.Calibration.VASTargetsFixedPresetSteps;
                        break;
                    elseif find(keyCode) == P.keys.esc
                        abort = 1;
                        break;
                    end
                end
            end
            
        else
            % Fit previous data and retrieve regression results
            pressureData = P.calibration.pressure(cuff,:);
            ratingData = P.calibration.rating(cuff,:);
            x = pressureData(pressureData>0 | ratingData>0); % take only non-zero data
            y = ratingData(pressureData>0 | ratingData>0); % take only ratings associated with non-zero pressures
            [P.pain.Calibration.VASTargetsFixedPressure,~] = FitData(x,y,P.pain.Calibration.VASTargetsFixed,0);  % last vargin, 0 = figure+text, 2 = text only output
            
            if any(P.pain.Calibration.VASTargetsFixedPressure < 0) || any(P.pain.Calibration.VASTargetsFixedPressure > 100)
                fprintf('Invalid fit based on psychometric scaling data!\n');
                fprintf('\nTake preset values to continue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
                
                while 1
                    [keyIsDown, ~, keyCode] = KbCheck();
                    if keyIsDown
                        if find(keyCode) == P.keys.resume
                            painThreshold = P.awiszus.painThresholdFinal(cuff);
                            P.pain.Calibration.VASTargetsFixedPressure = painThreshold + P.pain.Calibration.VASTargetsFixedPresetSteps;
                            break;
                        elseif find(keyCode) == P.keys.esc
                            abort = 1;
                            break;
                        end
                    end
                end
            end
        end
        
        %% FIXED INTENSITY VAS TARGETS
        % Iterative procedure where first pressure is based on the
        % psychometric scaling VAS ratings and a few fixed VAS targets are
        % used at first to better estimate the VAS and pressure relationship
        % by fitting a sigmoid function
        fprintf('\n==========================\nFIXED VAS TARGET REGRESSION.\n==========================\n');
        calibStep = P.pain.Calibration.calibStep.fixedTrials;
        
        trialsFixed = numel(P.pain.Calibration.VASTargetsFixed);
        
        for trial = 1:trialsFixed
            
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
            fprintf('\n\n=======TRIAL %d of %d=======\n',trial,trialsFixed);
            
            % Red fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            % Retrieve predicted pressure as current trial pressure to rate
            trialPressure = P.pain.Calibration.VASTargetsFixedPressure(trial);
            
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
            if trial ~= trialsFixed
                
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
        
        %% ADAPTIVE INTENSITY VAS TARGETS
        
        fprintf('\n==========================\nADAPTIVE VAS TARGET REGRESSION.\n==========================\n');
        calibStep = P.pain.Calibration.calibStep.adaptiveTrials;
        
        % Start trial
        nextStim = NaN;
        varTrial = 0;
        nH = figure;
        while ~isempty(nextStim)
            
            % White fixation cross
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
            
            % Find next stimulus pressure intensity based on previous VAS rating data
            pressureData = P.calibration.pressure(cuff,:);
            ratingData = P.calibration.rating(cuff,:);
            ex = pressureData(pressureData>0 | ratingData>0); % take only non-zero data
            ey = ratingData(pressureData>0 | ratingData>0); % take only ratings associated with non-zero pressures
            linOrSig = 'lin';
            %                 if varTrial<2 % lin is more robust for the first additions; in the worst case [0 X 100], sig will get stuck in a step fct
            %                     linOrSig = 'lin';
            %                 else
            %                     linOrSig = 'sig';
            %                 end
            [nextStim,~,~,~] = CalibValidation(ex,ey,[],[],linOrSig,P.toggles.doConfirmAdaptive,1,1,nH,num2cell([zeros(1,numel(ex)-1) varTrial]),['s' num2str(numel(varTrial)+1)]);
            
            % Red fixation cross during the trial
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            % Apply stimulus
            varTrial = varTrial+1;
            fprintf('\n=======VARIABLE TRIAL %d=======\n',varTrial);
            [abort,P] = ApplyStimulusCalibration(P,O,nextStim,calibStep,stimType,cuff,varTrial); % run stimulus
            save(P.out.file.param,'P','O'); % Save instantiated parameters and overrides after each trial
            if abort; break; end
            
            % White fixation cross during ITI
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);
            else
                tCrossOn = GetSecs;
            end
            
            % Intertrial interval
            fprintf('\nIntertrial interval... ');
            countedDown = 1;
            while GetSecs < tCrossOn + durationITI
                tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                if abort; break; end
            end
            
            if abort; break; end
            
        end
        
        if abort; break; end
        
        % Get calibration results for the stimulus type
        calibration = GetRegressionResults(P,cuff);
        P.calibration.results(stimType) = calibration;
        
        save(P.out.file.param, 'P', 'O');
        try
            savefig(nH, fullfile(P.out.dir,['calibration_' lower(P.pain.stimName{stimType}) '.fig']));
        catch
            fprintf('\nFigure not saved! ');
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
    fprintf(' Calibration finished. \n');
    abort = 1;
else
    return;
end

end