function [abort] = TargetRegressionVAS(P,O)

abort=0;

fprintf('\n==========================\nRunning VAS target regression.\n==========================\n');

while ~abort
    
    % Separately for long tonic stimuli and short phasic stimuli
    for cuff = P.pain.Calibration.cuff_order % randomized order
        
        stimType = P.pain.cuffStim(cuff);

        fprintf([P.pain.cuffSide{cuff} ' ARM - ' P.pain.stimName{stimType} ' STIMULUS\n--------------------------\n']);
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            if stimType == 1
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

        if stimType == 1
            durationITI = P.presentation.Calibration.tonicStim.ITI;
        else
            durationITI = P.presentation.Calibration.phasicStim.ITI;
        end
        
        fprintf('\n')
        if isempty(P.calibration.pressure(stimType,:)) || isempty(P.calibration.rating(stimType,:))
            fprintf('No valid previous data from psychometric scaling.');
            fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
        else
            % Fit previous data and retrieve regression results
            pressureData = P.calibration.pressure(stimType,:);
            ratingData = P.calibration.rating(stimType,:);
            x = pressureData(pressureData>0); % take only non-zero data
            y = ratingData(pressureData>0); % take only ratings associated with non-zero pressures
            [P.pain.Calibration.VASTargetsFixedPressure,~] = FitData(x,y,P.pain.Calibration.VASTargetsFixed,0);  % last vargin, 0 = figure+text, 2 = text only output
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
        
        if abort; break; end
        
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
            
            if ~isempty(nextStim)
                
                % Find next stimulus pressure intensity based on previous VAS rating data
                ex = P.calibration.pressure(stimType,:);
                ey = P.calibration.rating(stimType,:);
                if varTrial<2 % lin is more robust for the first additions; in the worst case [0 X 100], sig will get stuck in a step fct
                    linOrSig = 'lin';
                else
                    linOrSig = 'sig';
                end
                [nextStim,~,~,~] = CalibValidation(ex,ey,[],[],linOrSig,P.toggles.doConfirmAdaptive,1,1,nH,num2cell([zeros(1,numel(ex)-1) varTrial]),['s' num2str(numel(varTrial)+1)]);
                
                if isempty(nextStim)
                    fprintf('Last variable stimulus, exiting loop.');
%                     warning('Next stimulus pressure intensity from CalibValidation is empty, exiting while loop.');
                    break
                end
                
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
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
        end
        
        if abort; break; end
        
        % Get calibration results for the stimulus type
        calibration = GetRegressionResults(P,stimType);
        P.calibration.results(stimType) = calibration;
        
        save(P.out.file.param, 'P', 'O');
        
    end
    
    break;
    
end

if ~abort
    fprintf(' Calibration finished. \n');
else
    return;
end

end