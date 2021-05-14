function [abort]=PreExposureAwiszus(P,O,varargin)

cparFile = fullfile([P.out.file.CPAR '_PreExposure.mat']);

abort=0;

fprintf('\n==========================\nRunning pre-exposure and Awiszus pain thresholding.\n==========================\n');

while ~abort
    
    for cuff = P.pain.preExposure.cuff_order % pre-exposure for both left (1) and right (2) cuffs, randomized order
        
        stimType = P.pain.cuffStim(cuff);

        fprintf([P.pain.cuffSide{cuff} ' ARM - ' P.pain.stimName{stimType} ' STIMULUS\n--------------------------']);
        
        for trial = 1:P.awiszus.N
            
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
            
            if trial <= numel(P.pain.preExposure.startSimuli) % pure pre-exposure to get used to the feeling
                preExpInt = P.pain.preExposure.startSimuli(trial);
                preExpPhase = 'pre-exposure';
            elseif trial > numel(P.pain.preExposure.startSimuli) % second trial Awiszus procedure starts from the defined value
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

                abort = UseCPAR('Set',P.cpar.dev,'preExp',P,stimDuration,preExpInt,cuff); % set stimulus
                [abort,data] = UseCPAR('Trigger',P.cpar.dev,P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
   
            end
            
            while GetSecs < tStimStart+sum(stimDuration)
                [abort,countedDown] = CountDown(P,GetSecs-tStimStart,countedDown,'.');
                if abort; return; end
            end
                
            fprintf(' concluded.\n');
            data = cparGetData(P.cpar.dev, data);
            preExpCPARdata = cparFinalizeSampling(P.cpar.dev, data);
            saveCPARData(preExpCPARdata,cparFile,cuff,trial);
            
            if ~O.debug.toggleVisual
                Screen('Flip',P.display.w);
            end
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
            
            % Next pressure (nextX) updated based on ratings
            if trial <= numel(P.pain.preExposure.startSimuli) % pre-exposure trials no ratings, only to get subject used to the feeling
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

            P.awiszus.threshRatings.pressure(cuff,trial) = P.awiszus.nextX(stimType);
            P.awiszus.threshRatings.ratings(cuff,trial) = preexPainful;

        end
        
        % last suggested value from Awiszus is the pain threshold
        P.awiszus.painThresholdFinal(cuff) = P.awiszus.nextX(stimType);
        save(P.out.file.param,'P','O');
        fprintf(['Pain threshold CUFF ' num2str(cuff) ': ' num2str(P.awiszus.painThresholdFinal(cuff)) ' kPa\n']);
        
    end
    
    break;

end

end