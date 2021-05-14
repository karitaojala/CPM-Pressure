function [abort] = CondPainMod(P,O,pressure_input)

abort=0;

while ~abort
    
    fprintf('\n==========================\nRunning CPM experiment.\n==========================\n');
    
    countTrial = 1;
    
    if pressure_input == 1
        
        % Find VAS70 and VAS90 from tonic stimulus calibration
        predPressureTonic = P.calibration.results(P.pain.CPM.tonicStim.cuff).fitData.predPressureLinear;
        TonicVASTrough = predPressureTonic(P.pain.CPM.tonicStim.VASindexPeak);
        TonicVASPeak = predPressureTonic(P.pain.CPM.tonicStim.VASindexTrough);
        tonicPressure_trough_Exp = TonicVASTrough;
        tonicPressure_peak_Exp = TonicVASPeak;
      
        % Find intensity from phasic stimulus calibration
        predPressurePhasic = P.calibration.results(P.pain.CPM.phasicStim.cuff).fitData.predPressureLinear;
        PhasicVAS = predPressurePhasic(P.pain.CPM.phasicStim.VASindex);
        phasicPressure = PhasicVAS;
        
    elseif pressure_input == 2
        
        ListenChar(0); % activate keyboard input
        commandwindow;
        tonicPressure_trough_Exp=input('\nPlease enter tonic pain stimulus trough intensity (kPa) for the experiment.\n');
        ListenChar(2); % deactivate keyboard input
        
        ListenChar(0); % activate keyboard input
        commandwindow;
        tonicPressure_peak_Exp=input('Please enter tonic pain stimulus peak intensity (kPa) for the experiment.\n');
        ListenChar(2); % deactivate keyboard input
        
        ListenChar(0); % activate keyboard input
        commandwindow;
        phasicPressure=input('Please enter phasic pain stimulus intensity (kPa) for the experiment.\n');
        ListenChar(2); % deactivate keyboard input
        
    elseif pressure_input == 3
        
        tonicPressure_trough_Exp = P.pain.CPM.tonicStim.pressureTrough;
        tonicPressure_peak_Exp = P.pain.CPM.tonicStim.pressurePeak;
        phasicPressure = P.pain.CPM.phasicStim.pressure;
        
    end
    
    tonicPressure_trough_Control = P.pain.CPM.tonicStim.pressureTroughControl;
    tonicPressure_peak_Control = P.pain.CPM.tonicStim.pressurePeakControl;
        
    % Loop over blocks/runs
    for block = 1:P.presentation.CPM.blocks
        
        % Set tonic stimulus pressure
        if P.pain.CPM.tonicStim.condition(block) == 1 % experimental tonic stimulus
            tonicPressure_trough = tonicPressure_trough_Exp;
            tonicPressure_peak = tonicPressure_peak_Exp;
        
        elseif P.pain.CPM.tonicStim.condition(block) == 0 % control tonic stimulus
            tonicPressure_trough = tonicPressure_trough_Control;
            tonicPressure_peak = tonicPressure_peak_Control;
        end
        
        trialPressure = [tonicPressure_trough tonicPressure_peak phasicPressure]; % input to UseCPAR and CreateCPARStimulus
        
        % Start block
        fprintf('\n\n=======BLOCK %d of %d=======\n',block,P.presentation.CPM.blocks);
        
        fprintf('Displaying instructions... ');
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ['Block ' num2str(block)], 'center', upperHalf, P.style.white);
            [P.display.screenRes.width, upperHalf]=DrawFormattedText(P.display.w, ' ', 'center', upperHalf+P.style.lineheight, P.style.white);
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
        
        if ~O.debug.toggleVisual
            Screen('Flip',P.display.w);
        end
        
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
%                     WaitSecs(1);
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
            % Start trial
            fprintf('\n\n=======TRIAL %d of %d=======\n',trial,P.presentation.CPM.trialsPerBlock);
            
            % Red fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            [abort,P]=ApplyStimulus(P,O,trialPressure,block,trial); % run stimulus
            save(P.out.file.param,'P','O'); % Save instantiated parameters and overrides after each trial
            % (includes timing information)
            if abort; break; end
            
            countTrial = countTrial+1;
            
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
%                     WaitSecs(1);
                end
                
                if abort; return; end
                
            end
            
            if abort; break; end
            
        end
        
        if abort; break; end

        % Interblock interval
        if block ~= P.presentation.CPM.blocks
            % Text for finishing a block
            if ~O.debug.toggleVisual
                [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'Stimulus block finished. Wait for the next block.', 'center', upperHalf, P.style.white);
                outroTextOn = Screen('Flip',P.display.w);
            else
                outroTextOn = GetSecs;
            end
            
            while GetSecs < outroTextOn + P.presentation.CPM.blockBetweenText % wait the time between blocks
                tmp=num2str(SecureRound(GetSecs-outroTextOn,0));
                [abort,countedDown]=CountDown(P,GetSecs-outroTextOn,countedDown,[tmp ' ']);
                if abort; break; end
%                 WaitSecs(1);
            end
        
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
            
            if abort; return; end
            
        elseif block == P.presentation.CPM.blocks % if last block, show end of the experiment screen
            
            if ~O.debug.toggleVisual
                [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, 'This part of the test has ended. Please wait for further instruction.', 'center', upperHalf, P.style.white);
                %             endTextOn = Screen('Flip',P.display.w);
            end
            
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
            
            fprintf('\n==========================\nCPM test has ended. ');
            
        end
        
    end
    
    break;
    
end

end