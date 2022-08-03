function [abort,P]=ApplyStimulus(P,O,trialPressure,block,trial)

global dev

cparFile = fullfile(P.out.dir,[P.out.file.CPAR '_CPM.mat']);

abort = 0;

while ~abort
    
    fprintf(['Tonic stimulus initiated (' num2str(trialPressure(1)) ' to ' num2str(trialPressure(2)) ' kPa)... \n']);
    
    % whether phasic stimulus on or not (last trial of the block
    % only long stimulus + continuous rating of it)
    phasic_on = 1;%P.pain.CPM.phasicStim.on(trial);
    
    P.time.trialStart(block,trial) = GetSecs-P.time.scriptStart;
    
    if P.devices.arduino
        
        [abort,initSuccess,dev] = InitCPAR; % initialize CPAR
        P.cpar.dev = dev;
        save(P.out.file.param, 'P', 'O');
        if initSuccess
            data = UseCPAR('Set',dev,'CPM',P,trialPressure,phasic_on,block,trial); % set stimulus
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.pressureOnset);
            [abort,data] = UseCPAR('Trigger',dev,P.cpar.stoprule,P.cpar.forcedstart); % start stimulus
        else
            abort = 1;
            return;
        end
        if abort; return; end
    end
    P.time.tonicStimStart(block,trial) = GetSecs-P.time.scriptStart;
    tStimStart = GetSecs;
    
    % VAS
    if ~phasic_on
        
        fprintf(' VAS... ');
        P.time.tonicStimVASStart(block,trial) = GetSecs-P.time.scriptStart;
        SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
        if ~O.debug.toggleVisual; [abort,P] = tonicStimVASRating(P,O,block,trial); end
        P.time.tonicStimVASEnd(block,trial) = GetSecs-P.time.scriptStart;
        if abort; return; end
        
    else
        
        phasicOnsets = P.pain.CPM.phasicStim.onsets(block,trial,:,:);
        phasicOnsets = sort(phasicOnsets(:));
        
        for phasicStim = 1:P.pain.CPM.tonicStim.cycles*P.pain.CPM.phasicStim.stimPerCycle
            
            VASOnset = tStimStart + phasicOnsets(phasicStim) + P.pain.CPM.phasicStim.duration + P.presentation.CPM.phasicStim.waitforVAS;
            while GetSecs < VASOnset
                % Wait until VAS onset for this cycle/phasic stimulus
                [abort]=LoopBreakerStim(P);
                if abort; break; end
            end
            fprintf([' VAS (' num2str(phasicStim) '/' num2str(P.pain.CPM.tonicStim.cycles*P.pain.CPM.phasicStim.stimPerCycle) ')... ']);
            P.time.phasicStimVASStart(block,trial,phasicStim) = GetSecs-P.time.scriptStart;
            SendTrigger(P,P.com.lpt.CEDAddressSCR,P.com.lpt.VASOnset);
            if ~O.debug.toggleVisual; [abort,P] = phasicStimVASRating(P,O,block,trial,phasicStim); end
            P.time.phasicStimVASEnd(block,trial,phasicStim) = GetSecs-P.time.scriptStart;
            
            if abort; return; end
            
            % White fixation cross
            if ~O.debug.toggleVisual
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix1);
                Screen('FillRect', P.display.w, P.style.white, P.style.whiteFix2);
                Screen('Flip',P.display.w);
            end
            
            if abort; break; end
            
        end
        
    end
    
    if abort; return; end
    
    while GetSecs < tStimStart+P.presentation.CPM.tonicStim.durationVAS%+P.presentation.CPM.tonicStim.durationBuffer
        [abort]=LoopBreakerStim(P);
        if abort; break; end
    end
    
    if P.devices.arduino
        data = cparGetData(dev, data);
        trialData = cparFinalizeSampling(dev, data);
        saveCPARData(trialData,cparFile,block,trial); % save data for this trial
        fprintf(' Saving CPAR data... ')
    end
    if abort; return; end
    
    %     else
    %
    %         countedDown = 1;
    %         tStimStart = GetSecs;
    %         P.time.tonicStimStart(block,trial) = tStimStart-P.time.scriptStart;
    %         while GetSecs < tStimStart+P.presentation.CPM.tonicStim.durationVAS%+P.presentation.CPM.tonicStim.durationBuffer
    %             tmp=num2str(SecureRound(GetSecs-tStimStart,0));
    %             [abort,countedDown]=CountDown(P,GetSecs-tStimStart,countedDown,[tmp ' ']);
    %             if abort; break; end
    %             if mod((countedDown/30), 1) == 0; fprintf('\n'); end % add line every 30 seconds
    %         end
    %
    %         if abort; return; end
    %
    %     end
    
    break;
    
end

if ~abort
    fprintf(' Trial concluded. \n');
else
    return;
end

end