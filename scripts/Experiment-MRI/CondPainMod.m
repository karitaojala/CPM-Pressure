function [abort,P] = CondPainMod(P,O)

% ListenChar(2); % deactivate keyboard input
upperHalf = P.display.screenRes.height/2;
abort=0;

if ~O.debug.toggleVisual
    Screen('Preference', 'TextRenderer', 0);
    Screen('TextFont', P.display.w, 'Arial', 1);
end

while ~abort
    
    fprintf('\n==========================\nRunning CPM experiment.\n==========================\n');
    
    if isfield(P.calibration,'results')
        
        % Find CPM trough and peak from tonic stimulus calibration
        predPressureTonic = P.calibration.results(1).fitData.predPressureLinear;
        TonicVASTrough = predPressureTonic(P.pain.CPM.tonicStim.VASindexTrough);
        TonicVASPeak = predPressureTonic(P.pain.CPM.tonicStim.VASindexPeak);
        tonicPressure_trough_Exp = TonicVASTrough;
        tonicPressure_peak_Exp = TonicVASPeak;
        
        % Find intensity from phasic stimulus calibration
        predPressurePhasic = P.calibration.results(2).fitData.predPressureLinear;
        PhasicVAS = predPressurePhasic(P.pain.CPM.phasicStim.VASindex);
        phasicPressure = PhasicVAS;
        
    else
        
        warning('CALIBRATION RESULTS DO NOT EXIST!!!');
        fprintf('\nTake preset values to continue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.resume))),upper(char(P.keys.keyList(P.keys.esc))));
        
        while 1
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                if find(keyCode) == P.keys.resume
                    tonicPressure_trough_Exp = P.pain.CPM.tonicStim.pressureTrough;
                    tonicPressure_peak_Exp = P.pain.CPM.tonicStim.pressurePeak;
                    phasicPressure = P.pain.CPM.phasicStim.pressure;
                    break;
                elseif find(keyCode) == P.keys.esc
                    abort = 1;
                    break;
                end
            end
        end
        
%         tonicPressure_trough_Exp = P.pain.CPM.tonicStim.pressureTrough;
%         tonicPressure_peak_Exp = P.pain.CPM.tonicStim.pressurePeak;
%         phasicPressure = P.pain.CPM.phasicStim.pressure;
                    
    end
    
    P.pain.CPM.experimentPressure.tonicStimTrough = tonicPressure_trough_Exp;
    P.pain.CPM.experimentPressure.tonicStimPeak = tonicPressure_peak_Exp;
    P.pain.CPM.experimentPressure.phasicStim = phasicPressure;
    save(P.out.file.param,'P','O');
    
    tonicPressure_trough_Control = P.pain.CPM.tonicStim.pressureTroughControl;
    tonicPressure_peak_Control = P.pain.CPM.tonicStim.pressurePeakControl;
    
    run = P.startRun;
    
    fprintf('\n=======RUN %d=======\n',run);
    
    if run == 1 || run == 6
        %% Tonic stimulus rating

        %noRating = P.noRating + 1;
        if run == 1
            abort = ShowInstruction(P,O,5,1);
            P.noRating = 1;
            noRating = 1;
        elseif run == 6
            abort = ShowInstruction(P,O,7,1);
            P.noRating = 2;
            noRating = 2;
        end
        if abort; return; end
        
        % Wait for MRI dummy scans
        WaitDummyScans(P);
        if run == 1
            P.mri.mriExpStartTime = GetSecs;
        end
        P.mri.mriRunStartTime(run) = GetSecs;
    
        % Experimental tonic stimulus pressures
        tonicPressure_trough = tonicPressure_trough_Exp;
        tonicPressure_peak = tonicPressure_peak_Exp;
        trialPressure = [tonicPressure_trough tonicPressure_peak];
        % Applying stimulus and rating
        [P, abort] = TonicStimRating(P,O,trialPressure,noRating);
        if abort; return; end
        
        P.startRun = P.startRun + 1;
    
    elseif run > 1 && run < 6
        %% Experiment block
        block = run-1;
        
        % Set tonic stimulus pressure
        if P.pain.CPM.tonicStim.condition(block) == 1 % experimental tonic stimulus
            tonicPressure_trough = tonicPressure_trough_Exp;
            tonicPressure_peak = tonicPressure_peak_Exp;
            
        elseif P.pain.CPM.tonicStim.condition(block) == 0 % control tonic stimulus
            tonicPressure_trough = tonicPressure_trough_Control;
            tonicPressure_peak = tonicPressure_peak_Control;
        end
        
        trialPressure = [tonicPressure_trough tonicPressure_peak phasicPressure];
        
        % Start block
        fprintf('\n=======BLOCK %d of %d=======\n',block,P.presentation.CPM.blocks);
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            
            if block == 1
                abort = ShowInstruction(P,O,6,1);
            end
            if abort; return; end
            
            Screen('TextSize', P.display.w, 50);
            upperHalf = P.display.screenRes.height/2;
            if strcmp(P.language,'de')
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ['Teil ' num2str(block)], 'center', upperHalf, P.style.white);
            elseif strcmp(P.language,'en')
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ['Part ' num2str(block)], 'center', upperHalf, P.style.white);
            end
            [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ' ', 'center', upperHalf+P.style.lineheight, P.style.white);
            introTextOn = Screen('Flip',P.display.w);
            
        else
            introTextOn = GetSecs;
        end
        
        while GetSecs < introTextOn + P.presentation.BlockStopDuration
            [abort]=LoopBreaker(P);
            if abort; break; end
        end
        
        % Wait for input from experimenter to continue
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
        
        if ~O.debug.toggleVisual
            Screen('Flip',P.display.w);
        end
        
        % Wait for MRI dummy scans
        WaitDummyScans(P);
        P.mri.mriRunStartTime(run) = GetSecs;
        
        % Loop over trials
        for trial = 1:P.presentation.CPM.trialsPerBlock
            
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
                while GetSecs < tCrossOn + P.presentation.CPM.tonicStim.firstTrialWait
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
            % Start trial
            fprintf('\n\n=======TRIAL %d of %d=======\n',trial,P.presentation.CPM.trialsPerBlock);
            P.countTrial = P.countTrial +1;
            
            [abort,P]=ApplyStimulus(P,O,trialPressure,block,trial); % run stimulus
            save(P.out.file.param,'P','O'); % Save instantiated parameters and overrides after each trial
            % (includes timing information)
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
            if trial ~= P.presentation.CPM.trialsPerBlock
                
                fprintf('\nIntertrial interval... ');
                countedDown = 1;
                while GetSecs < tCrossOn + P.presentation.CPM.tonicStim.totalITI
                    tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
                    [abort,countedDown] = CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
                    if abort; break; end
                    if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
        end
        
        if abort; break; end
        
        P.startRun = P.startRun + 1;
        
    end
    
    if run < 6
        %% Interblock interval
        % Text for finishing a block
        if ~O.debug.toggleVisual
            if strcmp(P.language,'de')
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, 'Dieser Teil ist nun beendet. Bitte warten Sie auf den Beginn des nächsten Teils.', 'center', upperHalf, P.style.white);
            elseif strcmp(P.language,'en')
                [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, 'There will now be a break. Please wait.', 'center', upperHalf, P.style.white);
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
        end
        
        if abort; return; end
        
        if ~O.debug.toggleVisual
            Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
            Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
            tCrossOn = Screen('Flip',P.display.w);
        else
            tCrossOn = GetSecs;
        end
        
        % Wait for final pulse
        fprintf('\n=================\nWait for last scanner pulse of the run!...\n');
        WaitSecs(P.mri.timeExtraVolumes);
        P.mri.mriRunEndTime(run) = GetSecs;
        P = LogMRITriggers(P,run); % save data
        save(P.out.file.param,'P','O');
        RestrictKeysForKbCheck(P.keys.resume); % wait for experimenter after scanner noise stops
        KbStrokeWait;
        RestrictKeysForKbCheck([]); % enable all keys again
        
        fprintf('\nRemaining interblock interval... ');
        countedDown = 1;
        while GetSecs < tCrossOn + (P.presentation.CPM.blockBetweenTime - (tCrossOn-outroTextOn)) % wait the time between blocks
            tmp=num2str(SecureRound(GetSecs-tCrossOn,0));
            [abort,countedDown]=CountDown(P,GetSecs-tCrossOn,countedDown,[tmp ' ']);
            if abort; break; end
            if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
        end
        
        if abort; return; end
        
    elseif run == 6
        %% Post-experiment wait for BOLD
        fprintf('\nEntering %ds post-experiment wait for BOLD to catch up.\n',P.mri.finalWait);
        WaitSecs(P.mri.finalWait); % arbitrary duration to wait out final BOLD
        P.mri.mriRunEndTime(run) = GetSecs;
        P.mri.mriExpEndTime = GetSecs;
        P = LogMRITriggers(P,run); % save data
        save(P.out.file.param,'P','O');
        RestrictKeysForKbCheck(P.keys.resume); % wait for experimenter after scanner noise stops
        KbStrokeWait;
        RestrictKeysForKbCheck([]); % enable all keys again
        
        % Show end of the experiment screen
        if ~O.debug.toggleVisual
            if strcmp(P.language,'de')
                [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Das Experiment ist beendet. Vielen Dank für Ihre Zeit!', 'center', upperHalf, P.style.white);
            elseif strcmp(P.language,'en')
                [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'The experiment has finished. Thank you for your time!', 'center', upperHalf, P.style.white);
            end
        end
        
        fprintf('\nContinue [%s], or abort [%s].\n',upper(char(P.keys.keyList(P.keys.confirm))),upper(char(P.keys.keyList(P.keys.esc))));
        
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
        
        fprintf('\n==========================\nCPM experiment has ended. ');
        
        break;
        
    end

end

% ListenChar(0);

end