function create_onsets(options,subj,onsets_as_scans,debug_plot)

cparSR = 20;
physioSR = 100;

% there is a systematic discrepancy between CPAR recorded phasic pressure
% onsets and Matlab recorded VAS onsets
% step = 0.1;
% discrepancyCPARVASperStim = (0:8)*step;
% discrepancyCPARVASperStim = [discrepancyCPARVASperStim discrepancyCPARVASperStim]';
% -> already taken into account now

for sub = subj
    
    clear P O cparData
    
    name = sprintf('sub%03d',sub);
    fprintf([name '\n']);
    
    logdir = fullfile(options.path.logdir,name,'pain');
    load(fullfile(logdir,['parameters_' name '.mat']));
    load(fullfile(logdir,[name '_CPAR_CPM.mat']));
        
    if debug_plot; figure; subplot_ind = 1; end
    
    for run = 1:numel(options.acq.exp_runs)
        
        clear phasicStim phasicPressure physio behav pmodTonic bpPerVAS pmodVAS
        
        run_id = num2str(options.acq.exp_runs(run));
        
        % file to save onsets to
        behavfile = fullfile(logdir,[name '-run' run_id '-onsets.mat']);
        pmodfile  = fullfile(logdir,[name '-run' run_id '-tonic-pmod.mat']);
        pmodfile2  = fullfile(logdir,[name '-run' run_id '-phasic-pmod.mat']);
        pmodfile3  = fullfile(logdir,[name '-run' run_id '-vas-pmod.mat']);
        
        load(fullfile(options.path.physiodir,name,[name '-run' run_id '-behav.mat']))
        load(fullfile(options.path.physiodir,name,[name '-run' run_id '-physio.mat']))
        load(fullfile(logdir,[name '_VAS_rating_block' num2str(run) '_phasicstim.mat']));
        
        % tonic trial numbers for this run
        trialNo = [(run-1)+run run+run]+1;
        
        % scanner pulse timings from physio file in seconds (starting from
        % 6th pulse after 5 dummies)
        scannerPulsesvsPhysioStart = physio.scansPhysioStart/physioSR;

        % time from physio file start to first scanner pulse
        timeFromPhysioStarttoFirstPulse = scannerPulsesvsPhysioStart(1);
        
        % time from first scanner pulse in Matlab to run's first trial start in Matlab
        timeFromLastDummytoFirstTrial = P.time.trialStart(run,1)-(P.mri.mriRunStartTime(options.acq.exp_runs(run))-P.time.scriptStart);
        % in fact ~5 seconds = 1x 1.991 s TR + ~3s because time counting
        % starts right after last dummy pulse was measured -> last dummy TR
        % is not excluded yet
        
        % time from first scanner pulse to the first trial onset in Spike
        % (sent as marker from Matlab)
        timeFromFirstPulsetoTrial = behav.trialOnsets(trialNo(1))-timeFromPhysioStarttoFirstPulse;
        
        % difference in Matlab and Spike recordings due to the Matlab
        % recording starting from 5th dummy pulse arrival and physio
        % signals set to start from 6th pulse (first experimental pulse)
        diffMatlabSpikeTimings = timeFromLastDummytoFirstTrial-timeFromFirstPulsetoTrial;
        % but why is this less than 1 TR? (1.991 s) -> maybe delay in
        % sending pulse info to Matlab, should not matter much for this
        % paradigm that < 0.2 s difference in timings
        
        % trial and tonic stimulus onsets as saved in Matlab during
        % experiment
        firstTrialStart = P.time.trialStart(run,1); 
        firstTonicStart = P.time.tonicStimStart(run,1);
        timeFromTrialStarttoFirstTonic = firstTonicStart-firstTrialStart;
        % but this difference likely not relevant as trigger is likely more
        % reliable, right before CPAR onset - log-based VAS timings etc.
        % may be up to 0.2 s off (or not) then but no matter in this paradigm
        
        % VAS onsets as recorded in Spike with triggers sent from Matlab
        phasicVASOnsetsvsPhysioStart = behav.VASOnsets';
        phasicVASOnsetsvsFirstPulse = behav.VASOnsets'-timeFromPhysioStarttoFirstPulse;
        phasicVASOnsetsvsFirstTrial = behav.VASOnsets'-behav.trialOnsets(trialNo(1));
        
        % Button presses per VAS rating as parametric modulator
        buttonPressOnsetsvsFirstPulse = behav.buttonPresses'-timeFromPhysioStarttoFirstPulse;
        for vas = 1:numel(phasicVASOnsetsvsFirstPulse)
            vasStart = phasicVASOnsetsvsFirstPulse; 
            vasEnd = phasicVASOnsetsvsFirstPulse+5; % 5 s interval
           bpPerVAS(vas) = sum(buttonPressOnsetsvsFirstPulse >= vasStart(vas) & buttonPressOnsetsvsFirstPulse <= vasEnd(vas));
           if bpPerVAS(vas) == 0
               warning([name ' run ' run_id ' trial ' num2str(vas) ' no button presses! Excluded stimulus.']);
           end
        end
        excludeTrial = bpPerVAS == 0;
        bpPerVAS(excludeTrial) = [];
        pmodVAS = bpPerVAS';
        %pmodVAS = pmodVAS-mean(pmodVAS); % mean-centering
        pmodVAS = zscore(pmodVAS); % z-scoring
        
        % VAS onsets as recorded in Matlab vs script start
        phasicVASOnsetLog = squeeze(P.time.phasicStimVASStart(run,:,:)); 
        phasicVASOnsetLog(phasicVASOnsetLog==0) = NaN; % remove zeros = no stimuli (case only for sub 5 run 4 trial 2)
        phasicVASOnsetLog = sort(phasicVASOnsetLog(:))';
        % adjust to set timings to start from first experimental pulse
        % onset
        phasicVASOnsetLogtoTrialStart = phasicVASOnsetLog-firstTrialStart; % relative timing, not absolute
        
        % phasic stimulus onsets from CPAR device pressure recordings
        % detect changes in pressure indicating phasic stimulus start
        phasicStim = {NaN(1,9) NaN(1,9)}; % for the two tonic trials, 9 stimuli each
        tonicRegressor = NaN(4000/cparSR,2); % runs, trials, max CPAR timepoints
        phasicRegressor = NaN(4000/cparSR,2);
        
        for trial = 1:2
            %clear tonicPressure phasicPressure tonicPressure_filt tonicPresure_filt_extrap
            try
                tonicPressure = cparData(run).data(trial).Pressure01;
                tonicPressure_filt = medfilt1(tonicPressure,100); % filter out spikes
                if sub == 29 && (run == 3 || run == 4); tonicPressure_filt = medfilt1(tonicPressure_filt,200); end % additional filtering
                if sub == 30 && (run == 1 || run == 4); tonicPressure_filt = medfilt1(tonicPressure_filt,200); end % additional filtering
                tonicPressure_filt_extrap = interp1(1:numel(tonicPressure_filt), tonicPressure_filt, 0.5:1:4000,'pchip',0); % extrapolate to zero
                tonicPressure_downsampl = downsample(tonicPressure_filt_extrap,cparSR); % to 1 Hz / seconds
                %tonicPressure_downsampl_filt = smoothdata(tonicPressure_downsampl,'gaussian',20); % filter again to smooth
%                 if debug_plot
%                     subplot(2,4,subplot_ind)
%                     plot(tonicPressure_filt_extrap); hold on
%                     subplot_ind = subplot_ind + 1;
%                     title(['Run ' num2str(run+1) ' - Trial ' num2str(trial)])
%                 end
                tonicRegressor(1:numel(tonicPressure_downsampl),trial) = tonicPressure_downsampl;
                
                phasicPressure = cparData(run).data(trial).Pressure02; 
                phasicPressure_filt = medfilt1(phasicPressure,20);
                phasicPressure_filt_extrap = interp1(1:numel(phasicPressure_filt), phasicPressure_filt, 0.5:1:4000,'pchip',0); % extrapolate to zero
                phasicPressure_downsampl = downsample(phasicPressure_filt_extrap,cparSR); % to 1 Hz / seconds
                phasicRegressor(1:numel(phasicPressure_downsampl),trial) = phasicPressure_downsampl;
                
            catch
                warning([name ' run ' run_id ' trial ' num2str(trial) ' no CPAR data! Use onsets reconstructed from VAS onsets or previous trial data. ' ...
                    'Exclude trial from tonic pmod models.']);
                if sub == 5 && run == 3 && trial == 2
                    tonicRegressor(:,trial) = tonicRegressor(:,trial-1); % take previous trial data (same type, same form)
%                     if debug_plot
%                     subplot(2,4,subplot_ind)
%                     plot(tonicRegressor(:,trial)); hold on
%                     subplot_ind = subplot_ind + 1;
%                     title(['Run ' num2str(run+1) ' - Trial ' num2str(trial)])
%                     end
                end
                %continue;
            end
            maxPressure = max(phasicPressure);
            
            realPhasicOnsets = 0;
            threshold = 0.5;
            stepSize = 0.01;
            
            while numel(realPhasicOnsets) ~= 9 % go at it until the correct number of stimuli is found
                
                realPhasicOnsets = find(diff(phasicPressure)>(threshold*maxPressure));
                
                if ~isempty(realPhasicOnsets) && any(diff(realPhasicOnsets) < 100)
                    realPhasicOnsets = realPhasicOnsets(logical([1 diff(realPhasicOnsets) > 100]));
                end
                    
                if numel(realPhasicOnsets) < 9
                    threshold = threshold-stepSize;
                elseif numel(realPhasicOnsets) > 9
                    threshold = threshold+stepSize;
                end

            end
            
            phasicStim{trial} = realPhasicOnsets;
            
        end
        
                    
        % Pain ratings for phasic stimuli as parametric modulator
        for trial = 1:2
            for stim = 1:9
                try
                    painRating(stim,trial) = VAS(trial,stim).phasicStim.finalRating; %#ok<*AGROW>
                catch
                    painRating(stim,trial) = NaN;
                end
            end
        end
        pmodPhasic = painRating(:);
        pmodPhasic = pmodPhasic(~isnan(pmodPhasic));

        % Remove all tonic regressor values below the trough value to only
        % take the cycling pressure part
        troughPressure = tonicRegressor(70,1); % trough value
        tonicRegressor(tonicRegressor < troughPressure) = troughPressure;
        tonicRegressor = tonicRegressor - troughPressure; % set trough to zero
        
        if debug_plot
            subplot(2,2,subplot_ind)
            plot(tonicRegressor(:)); hold on
            subplot_ind = subplot_ind + 1;
            title(['Run ' num2str(run+1)])
        end
                    
        % tonic stimulus trial 2 onset from Matlab (to get CPAR pressure
        % recordings into physio/Matlab recording time)
        if sub == 5 && run == 3
            tonicStartTrial2 = P.time.trialStart(run,2)+timeFromTrialStarttoFirstTonic; % tonic time not recorded, take trial start time and add difference estimated from first tonic trial
        else
            tonicStartTrial2 = P.time.tonicStimStart(run,2); % start time of tonic trial 2
        end
        tonicStartInd = ceil((tonicStartTrial2-firstTonicStart)*cparSR+1); % find tonic trial 2 start time relative to tonic trial 1 start time
        
        % collect tonic trial 1 and 2 phasic stimulus onsets together
        realPhasicStimOnsetsFromTonicStart = [phasicStim{1} phasicStim{2}+tonicStartInd]; % concatenate the phasic onsets of the two tonic trials
        realPhasicStimOnsetsFromTonicStart = realPhasicStimOnsetsFromTonicStart/cparSR; % back to seconds
        
        % time between phasic stimulus and VAS onsets as a check (should be around
        % 6 seconds but now known that actually decreases over time by 0.1
        % s per phasic stimulus due to some CPAR lag -> in the end of each tonic trial the difference is only ~5 s)
        timeBetweenStimandVAS = phasicVASOnsetLogtoTrialStart-realPhasicStimOnsetsFromTonicStart;
        
        % time of phasic stimulus VAS onset from trial start
        if sub == 5 && run == 3 % actually used
            physioPhasicOnsetsFromTrialStart = phasicVASOnsetsvsFirstTrial-6; % 6 seconds is the programmed value
        else % just for checking purposes
            physioPhasicOnsetsFromTrialStart = phasicVASOnsetsvsFirstTrial-timeBetweenStimandVAS;
        end
        % deduct time from physio start to first scanner pulse
        % deduct 5 s pressure stimulus + 1 s VAS wait duration = 6 s total from VAS onset to arrive at phasic stimulus onset / NOT PRECISE
         
        % save onsets for tonic stimuli
        firstTonic = timeFromFirstPulsetoTrial; % no need to correct as based on Spike triggers already
        secondTonic = firstTonic+(tonicStartTrial2-firstTonicStart); % no need to correct as first time based on Spike and then only relative difference between first and second tonic onset
        onsetsTonic = [firstTonic secondTonic]';
        
        % save onsets for phasic stimuli
        if sub == 5 && run == 3 % subject 5 run 3 tonic trial has 2 missing phasic stimuli at the end
            onsetsStim = physioPhasicOnsetsFromTrialStart'+timeFromFirstPulsetoTrial;%+discrepancyCPARVASperStim(1:numel(physioPhasicOnsetsFromTrialStart));
            onsetsStim = onsetsStim(1:numel(pmodPhasic)); % remove the last onset for phasic for which there is no pain rating
        else
            onsetsStimMatlab = realPhasicStimOnsetsFromTonicStart';
            onsetsStim = onsetsStimMatlab+timeFromFirstPulsetoTrial-diffMatlabSpikeTimings; % corrected for Matlab-Spike difference due to last dummy pulse
            onsetsStim = onsetsStim(1:numel(pmodPhasic)); % remove the last onset for phasic for which there is no pain rating
        end
        % add time from run start as defined as first scanner pulse to
        % tonic trial start which defines phasic onsets
        
        % save onsets for phasic VAS ratings
        %onsetsVAS = (onsetsVASMatlab-diffMatlabSpikeTimings)+timeFromFirstPulsetoTrial; % corrected for Matlab-Spike difference due to last dummy pulse
        onsetsVAS = phasicVASOnsetsvsFirstPulse'-diffMatlabSpikeTimings;
        %disp(diffMatlabSpikeTimings)
        onsetsVAS(excludeTrial) = []; % exclude VAS onset if zero button presses (invalid trial)
        
        % exclude stimuli with zero pain rating (missed) entirely
%         onsetsStim(pmodPhasic == 0) = [];
%         onsetsVAS(pmodPhasic == 0) = [];
%         pmodPhasic(pmodPhasic == 0) = [];
        pmodPhasic = zscore(pmodPhasic); % z-score pmodPhasic after removing missed trials
        
        % also save condition information
        cond = P.pain.CPM.tonicStim.condition(run);
        if cond == 0 % control
            conditions = zeros(numel(onsetsStim),1);
            conditionsTonic = zeros(numel(onsetsTonic),1);
        else % experimental
            conditions = ones(numel(onsetsStim),1);
            conditionsTonic = ones(numel(onsetsTonic),1);
        end
        
        if onsets_as_scans
            onsetsTonic = onsetsTonic/options.acq.TR;
            onsetsStim = onsetsStim/options.acq.TR;
            onsetsVAS = onsetsVAS/options.acq.TR;
        end
        
        if sub == 5 && run == 3 % remove tonic trial 2 for run 4
            onsetsTonic(2) = [];
            tonicRegressor(:,2) = [];
            phasicRegressor(:,2) = [];
        end
        
        %pmodTonic = zscore(tonicRegressor(:));
        tonicRegressor_z = zscore(tonicRegressor(:));
        phasicRegressor_z = zscore(phasicRegressor(:));
        %pmodTonic2 = zscore(phasicReg_z .* pmodTonic);
%         save(pmodfile,'tonicRegressor_z','phasicRegressor_z','onsetsTonic')
%         save(behavfile,'onsetsTonic','onsetsStim','onsetsVAS','conditions')
%         save(pmodfile,'onsetsTonic','pmodTonic','pmodTonic2','conditionsTonic')
        save(pmodfile2,'onsetsStim','pmodPhasic')
%         save(pmodfile3,'onsetsVAS','pmodVAS')
        
    end
    
    if debug_plot; sgtitle(name); end
    
end

end