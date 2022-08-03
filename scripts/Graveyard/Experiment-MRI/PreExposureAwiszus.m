function [abort]=PreExposureAwiszus(P,O,varargin)

global dev

cparFile = fullfile(P.out.dir,[P.out.file.CPAR '_PreExposure.mat']);

abort=0;

fprintf('\n====================================================\nRunning pre-exposure and Awiszus pain thresholding.\n====================================================\n');

while ~abort
    
    for cuff = P.pain.preExposure.cuff_order % pre-exposure for both left (1) and right (2) cuffs, randomized order
        
        stimType = P.pain.cuffStim(cuff);

        preExpStim = P.pain.preExposure.startSimuli(stimType,:);
        
        fprintf([P.pain.cuffSide{cuff} ' ' P.pain.cuffLimb{stimType} ' - ' P.pain.stimName{stimType} ' STIMULUS\n--------------------------\n']);
        
        if ~O.debug.toggleVisual
            upperHalf = P.display.screenRes.height/2;
            Screen('TextSize', P.display.w, 50);
            if stimType == 1
                if strcmp(P.language,'de')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Kalibrierung: langanhaltender Reiz, dem ' P.presentation.armname_long_de], 'center', upperHalf, P.style.white);
                elseif strcmp(P.language,'en')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Calibration: long pain stimuli, the ' P.presentation.armname_long_en], 'center', upperHalf, P.style.white);
                end
            else
                if strcmp(P.language,'de')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Kalibrierung: kurzer Reiz, den ' P.presentation.armname_short_de], 'center', upperHalf, P.style.white);
                elseif strcmp(P.language,'en')
                    [P.display.screenRes.width, ~]=DrawFormattedText(P.display.w, ['Calibration: short pain stimuli, the ' P.presentation.armname_short_en], 'center', upperHalf, P.style.white);
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
        if abort; break; end
        
        WaitSecs(0.2);
        
        for trial = 1:(numel(preExpStim)+P.awiszus.N) % pre-exposure + Awiszus trials
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);                      % gets timing of event for PutLog
            else
                tCrossOn = GetSecs;
            end
            
            fprintf('Displaying fixation cross... ');
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.ITIOnset);
            
            while GetSecs < tCrossOn + P.presentation.sPreexpITI
                [abort]=LoopBreaker(P);
                if abort; break; end
            end
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.red, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            if trial <= numel(preExpStim) % pure pre-exposure to get used to the feeling
                preExpInt = preExpStim(trial);
                preExpPhase = 'pre-exposure';
            elseif trial == numel(preExpStim)+1 % first trial of Awiszus procedure starts from the pre-defined population mean
                preExpInt = P.awiszus.mu(stimType);
                preExpPhase = 'Awiszus';
            else % rest of the trials pressure is adjusted according to participant's rating and the Awiszus procedure
                preExpInt = P.awiszus.nextX(stimType);
                preExpPhase = 'Awiszus';
            end
            fprintf('%1.1f kPa %s stimulus initiated.',preExpInt,preExpPhase);
            
            stimDuration = CalcStimDuration(P,preExpInt,P.presentation.sStimPlateauPreexp(stimType));
            
            countedDown = 1;
            tStimStart = GetSecs;
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
            
            if P.devices.arduino && P.cpar.init

                abort = UseCPAR('Set',dev,'preExp',P,stimDuration,preExpInt,cuff); % set stimulus
                [abort,data] = UseCPAR('Trigger',dev,P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
   
            end
            
            while GetSecs < tStimStart+sum(stimDuration)
                [abort,countedDown] = CountDown(P,GetSecs-tStimStart,countedDown,'.');
                if abort; return; end
            end
                
            fprintf(' concluded.\n');
            
            if P.devices.arduino && P.cpar.init
                data = cparGetData(dev, data);
                preExpCPARdata = cparFinalizeSampling(dev, data);
                saveCPARData(preExpCPARdata,cparFile,cuff,trial);
            end
            
            if ~O.debug.toggleVisual
                Screen('Flip',P.display.w);
            end
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
            
            % Next pressure (nextX) updated based on ratings
            if trial <= numel(preExpStim) % pre-exposure trials no ratings, only to get subject used to the feeling
                preexPainful = NaN;
            else
                P = Awiszus('init',P,stimType);
                preexPainful = QueryPreExpPain(P,O);
                P = Awiszus('update',P,preexPainful,stimType);
            
                if preexPainful
                    fprintf('--Stimulus rated as painful. \n');
                elseif ~preexPainful
                    fprintf('--Stimulus rated as not painful. \n');
                else
                    fprintf('--No valid rating. \n');
                end

            end

            P.awiszus.threshRatings.pressure(cuff,trial) = preExpInt;
            P.awiszus.threshRatings.ratings(cuff,trial) = preexPainful;

        end
        
        % Pain threshold
        if preexPainful % if last stimulus rated as painful
            P.awiszus.painThresholdFinal(cuff) = P.awiszus.threshRatings.pressure(cuff,trial); % last rated value is the pain threshold
        elseif ~preexPainful && ~any(P.awiszus.threshRatings.ratings(cuff,:)) % not painful and no previous painful ratings
            P.awiszus.painThresholdFinal(cuff) = P.awiszus.threshRatings.pressure(cuff,trial); % last rated value is the pain threshold
        else
            P.awiszus.painThresholdFinal(cuff) = P.awiszus.threshRatings.pressure(cuff,trial-1); % previous rated value from Awiszus (usually painful)
        end
        save(P.out.file.param,'P','O');
        fprintf(['\nPain threshold ' P.pain.cuffSide{cuff} ' ' P.pain.cuffLimb{stimType} ' - ' P.pain.stimName{stimType} ' STIMULUS : ' num2str(P.awiszus.painThresholdFinal(cuff)) ' kPa\n\n']);
        
    end
    
    break;

end

end