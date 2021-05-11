function [abort]=PreExposure(P,O,varargin)

% if nargin<3
%     preExpInts = P.pain.preExposure.pressureIntensity;
% else % override (e.g. for validation sessions)
%     preExpInts = varargin{1};
% end

cparFile = fullfile([P.out.file.CPAR '_PreExposure.mat']);

abort=0;

fprintf('\n==========================\nRunning preexposure sequence.\n');

while ~abort
    
    for cuff = P.pain.preExposure.cuff_order % pre-exposure for both left (1) and right (2) cuffs, randomized order
        
        stimType = cuff;
        
        if cuff == 1
            side = 'LEFT';
        elseif cuff == 2
            side = 'RIGHT';
        end
        
        fprintf(['Pre-exposure CUFF ' num2str(cuff) ' - ' side '\n']);
        
        for trial = 1:P.awiszus.N%length(preExpInts)
            
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                tCrossOn = Screen('Flip',P.display.w);                      % gets timing of event for PutLog
            else
                tCrossOn = GetSecs;
            end
            
            if trial == 1
                fprintf('[Initial trial, showing P.style.white cross for %1.1f seconds, red cross for %1.1f seconds]\n',P.presentation.sPreexpITI,P.presentation.sPreexpCue);
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
            
            if trial == 1 % first trial pure pre-exposure to get used to the feeling
                preExpInt = 10;
            elseif trial == 2 % second trial Awiszus procedure starts from the defined value
                preExpInt = P.awiszus.mu;
            else % rest of the trials pressure is adjusted according to participant's rating and the Awiszus procedure
                preExpInt = P.awiszus.nextX;
            end 
            fprintf('%1.1f kPa stimulus initiated.',preExpInt);
            
            stimDuration = CalcStimDuration(P,preExpInt,P.presentation.sStimPlateauPreexp(cuff));
            
            countedDown = 1;
            tStimStart = GetSecs;
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
            
            if P.devices.arduino
                [abort,dev] = InitCPAR; % initialize CPAR
                abort = UseCPAR('Set',dev,'preExp',P,stimDuration,preExpInt,cuff); % set stimulus
                [abort,data] = UseCPAR('Trigger',dev,P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
                P.CPAR.dev = dev;
                
                while GetSecs < tStimStart+sum(stimDuration)
                    [abort,countedDown] = CountDown(P,GetSecs-tStimStart,countedDown,'.');
                    if abort; break; end
                end
                
            else
                
                while GetSecs < tStimStart+sum(stimDuration)
                    [abort,countedDown] = CountDown(P,GetSecs-tStimStart,countedDown,'.');
                    if abort; return; end
                end
                
            end
            
            fprintf(' concluded.\n');
            data = cparGetData(dev, data);
            preExpCPARdata = cparFinalizeSampling(dev, data);
            saveCPARData(preExpCPARdata,cparFile,cuff,trial);
            
            if ~O.debug.toggleVisual
                Screen('Flip',P.display.w);
            end
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
            
            % nextX updated based on ratings
            if trial == 1 % first trial no ratings, only to get subject used to the feeling
                preexPainful = NaN;
            else
                P = Awiszus('init',P);
                preexPainful = QueryPreExpPain(P,O);
                P = Awiszus('update',P,preexPainful);
            
                if preexPainful
                    fprintf('Stimulus rated as painful. \n');
                elseif ~preexPainful
                    fprintf('Stimulus rated as not painful. \n');
                else
                    fprintf('No valid rating. \n');
                end

            end

            P.awiszus.threshRatings.pressure(cuff,trial) = P.awiszus.nextX;
            P.awiszus.threshRatings.ratings(cuff,trial) = preexPainful;
%             P.data.preExposure.painRatings(cuff,trial) = preexPainful;
%             P.data.preExposure.CPAR(cuff,trial) = preExpCPARdata;
        end
        
        % last suggested value from Awiszus is the pain threshold
        P.awiszus.painThresholdFinal(cuff) = P.awiszus.nextX;%preExpInts(find(P.data.preExposure.painRatings(cuff,:),1,'first'));
        save(P.out.file.param,'P','O');
        fprintf(['Pre-exposure pain threshold CUFF ' num2str(cuff) ': ' num2str(P.awiszus.painThresholdFinal(cuff)) ' kPa\n']);
        
    end
    
    break;

end

end