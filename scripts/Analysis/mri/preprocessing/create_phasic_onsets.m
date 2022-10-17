function create_phasic_onsets

base_dir    = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\';
physiodir   = fullfile(base_dir,'physio');

all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];

n_runs            = 6;
exp_runs          = 2:5;

cparSR = 20;
physioSR = 100;

% there is a systematic discrepancy between CPAR recorded phasic pressure
% onsets and Matlab recorded VAS onsets
step = 0.1;
discrepancyCPARVASperStim = (0:8)*step;
discrepancyCPARVASperStim = [discrepancyCPARVASperStim discrepancyCPARVASperStim]';

for sub = 1:numel(all_subs)
    
    name = sprintf('sub%03d',all_subs(sub));
    fprintf([name '\n']);
    
    logdir = fullfile(base_dir,'logs',name,'pain');
    load(fullfile(logdir,['parameters_' name '.mat']));
    load(fullfile(logdir,[name '_CPAR_CPM.mat']));
        
    for run = 1:numel(exp_runs)
        
        run_id = num2str(exp_runs(run));
        
        % file to save onsets to
        behavfile = fullfile(logdir,[name '-run' run_id '-phasic-onsets.mat']);

        load(fullfile(physiodir,name,[name '-run' run_id '-behav.mat']))
        load(fullfile(physiodir,name,[name '-run' run_id '-physio.mat']))

        % tonic trial numbers for this run
        trialNo = [(run-1)+run run+run]+1;
        
        % scanner pulse timings from physio file in seconds
        scannerPulsesvsPhysioStart = physio.scansPhysioStart/physioSR;

        % time from physio file start to first scanner pulse
        timeFromPhysioStarttoFirstPulse = scannerPulsesvsPhysioStart(1);
        % time from first scanner pulse to the first trial onset based on
        % physio file saved triggers sent from Matlab to Spike
        timeFromFirstPulsetoTrial = behav.trialOnsets(trialNo(1))-timeFromPhysioStarttoFirstPulse;
        
        % trial and tonic stimulus onsets as saved in Matlab during
        % experiment
        firstTrialStart = P.time.trialStart(run,1);
        firstTonicStart = P.time.tonicStimStart(run,1);
        timeFromTrialStarttoFirstTonic = firstTonicStart-firstTrialStart;
        
        % VAS onsets as recorded in Spike with triggers sent from Matlab
        phasicVASOnsetsvsPhysioStart = behav.VASOnsets';
        phasicVASOnsetLog = squeeze(P.time.phasicStimVASStart(run,:,:)); 
        phasicVASOnsetLog = sort(phasicVASOnsetLog(:))';
        phasicVASOnsetLogtoTrialStart = phasicVASOnsetLog-firstTrialStart+timeFromFirstPulsetoTrial;
        
        % phasic stimulus onsets from CPAR device pressure recordings
        % detect changes in pressure indicating phasic stimulus start
        for trial = 1:2
            
            try
                phasicPressure = cparData(run).data(trial).Pressure02; 
            catch
                warning([name ' run ' run_id ' trial ' num2str(trial) ' no CPAR data! Use onsets reconstructed from VAS onsets.']);
                continue;
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
        
        % tonic stimulus trial 2 onset from Matlab (to get CPAR pressure
        % recordings into physio/Matlab recording time)
        tonicStartTrial2 = P.time.tonicStimStart(run,2); % start time of tonic trial 2
        tonicStartInd = ceil((tonicStartTrial2-firstTonicStart)*cparSR+1); % find tonic trial 2 start time relative to tonic trial 1 start time
        
        % collect tonic trial 1 and 2 phasic stimulus onsets together
        realPhasicStimOnsetsFromTrialStart = [phasicStim{1} phasicStim{2}+tonicStartInd]; % concatenate the phasic onsets of the two tonic trials
        realPhasicStimOnsetsFromTrialStart = realPhasicStimOnsetsFromTrialStart/cparSR; % back to seconds
        %realPhasicStimOnsetsFromTrialStart = realPhasicStimOnsetsFromTrialStart+timeFromFirstPulsetoTrial; % add difference between first scanner pulse and trial start trigger
        
        % time between phasic stimulus and VAS onsets as a check (should be around
        % 6 seconds but now known that actually decreases over time by 0.1
        % s per phasic stimulus due to some CPAR lag -> in the end of each tonic trial the difference is only ~5 s)
        timeBetweenStimandVAS = phasicVASOnsetLogtoTrialStart-realPhasicStimOnsetsFromTrialStart;
        
        % time of phasic stimulus VAS onset from trial start
        phasicVASOnsetsFromTrialStart = phasicVASOnsetsvsPhysioStart-timeFromPhysioStarttoFirstPulse-timeFromFirstPulsetoTrial;
        physioPhasicOnsetsFromTrialStart = phasicVASOnsetsFromTrialStart-6;
        % deduct time from physio start to first scanner pulse
        % deduct 5 s pressure stimulus + 1 s VAS wait duration = 6 s total from VAS onset to arrive at phasic stimulus onset / NOT PRECISE
         
        % save onsets for phasic stimuli
        if strcmp(name,'sub005') && exp_runs(run) == 3 % subject 5 run 3 tonic trial has 2 missing phasic stimuli at the end
            onsetsStim = physioPhasicOnsetsFromTrialStart'+discrepancyCPARVASperStim;
            % take into account the observed discrepancy between real CPAR phasic stimulus onset and recorded VAS onsets
        else
            onsetsStim = realPhasicStimOnsetsFromTrialStart';
        end
        % add time from run start as defined as first scanner pulse to
        % tonic trial start which defines phasic onsets
        onsetsStim = onsetsStim+timeFromFirstPulsetoTrial;
        % save onsets for phasic VAS ratings
        onsetsVAS = phasicVASOnsetLog'-firstTrialStart+timeFromFirstPulsetoTrial;
        
        % also save condition information
        cond = P.pain.CPM.tonicStim.condition(run);
        if cond == 0 % control
            conditions = zeros(numel(onsetsStim),1);
        else % experimental
            conditions = ones(numel(onsetsStim),1);
        end
        
        save(behavfile,'onsetsStim','onsetsVAS','conditions')
        
    end
    
end

end