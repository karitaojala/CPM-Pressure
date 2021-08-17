%%Testing script for condititioned pain modulation stimuli: tonic
%%fluctuating conditioning stimulus and short phasic test stimulus
%%Karita Ojala
%%Institute of Systems Neuroscience - University Medical Center Hamburg-Eppendorf
%%28.01.2021

clear all
cparpath = cd;
addpath(genpath(cparpath))

% Create a device and open communication with the device.
cparInitialize;
IDs = cparList;
dev = cparGetDevice(IDs(1));

fprintf('Waiting to connect .');
tic
while cparError(dev)
    fprintf('.');
    pause(0.2);
    
    if toc > 10
        me = MException('CPAR:TimeOut', 'No connection');
        throw(me);
    end
end
fprintf(' connected\n');

% Check if the device is ready
if ~cparIsReady(dev)
    me = MException('CPAR:Ready', sprintf('Device is not ready: %s', cparGetAdvice(dev)));
    throw(me)
end

% CPAR cuff IDs
tonic_cuff = 1; 
phasic_cuff = 2;

% Tonic stimulus properties
% Current settings: 
% 3 cycles of 60 seconds between 20 and 30 kPa
% Each cycle consists of 1 x ramp up for 30 s and 1 x ramp down for 30 s
% 10 seconds ramping up to 20 kPa in the beginning
% 10 seconds ramping down to 0 kPa in the end
% Total tonic stimulus duration 200 seconds (3 x 60 + 2 x 10 s)
cycles = 3;
fullStimDuration = 60; % duration of 1 cycle of the tonic stimulus
rampDuration = fullStimDuration/2; % duration of ramp up/down of 1 cycle
startendRampDuration = 10; % duration of ramp up/down before/after tonic stimulus
peakPressure = 40; % pressure at peak of the tonic stimulus (maximum), e.g. at VAS 9
troughPressure = 20; % pressure at trough of the tonic stimulus (minimum), e.g. at VAS 7
diffPressure = peakPressure-troughPressure;
totalDuration = cycles*fullStimDuration+2*startendRampDuration;

% Phasic stimulus properties
% 2 x 5 seconds pulse, with 4 different potential onset timings during the tonic stimulus
% slopes (not at peak or trough), jittered by 0-2 seconds
% Goal: 3 x 5 seconds pulse but not possible with current CPAR firmware
% (exceeds the maximum of possible components = 12)
%rampSpeed = 10; % kPa/s
phasicPressure = 20; % phasic stimulus pressure, e.g. at VAS 8
phasicRampDuration = 0; %phasicPressure/rampSpeed -> instant ramping up now
phasicStimDuration = 5-phasicRampDuration; % duration of phasic stimulus in seconds
%phasicISI = 8:0.5:10; % interstimulus interval
numberPhasicStimPerCycle = 3; % how many phasic stimuli per cycle of the tonic stimulus
jitter = 0:0.5:2; % jitter for onset of phasic stimuli in seconds
% 5 s stimulus + 2 s jitter from 0 onset -> offset at max. 7 s after ->
% with 15 s in between possible time points, 8-10 sec ISI
phasicTimings1 = startendRampDuration + [5 20 35 50]; % possible phasic stimuli timings for cycle 1 of tonic stimulus
phasicTimings2 = startendRampDuration + [65 80 95 110]; % cycle 2
phasicTimings3 = startendRampDuration + [125 140 155 170]; % cycle 3

% Cycle 1 timings jittered relative to above onsets
randomJitter = jitter(randperm(length(jitter)));
rand_phasicTimings1 = datasample(phasicTimings1, numberPhasicStimPerCycle, 'Replace', false) + randomJitter(1:3);
% Cycle 2 timings jittered
randomJitter = jitter(randperm(length(jitter)));
rand_phasicTimings2 = datasample(phasicTimings2, numberPhasicStimPerCycle, 'Replace', false) + randomJitter(1:3);
% Cycle 3 timings jittered
randomJitter = jitter(randperm(length(jitter)));
rand_phasicTimings3 = datasample(phasicTimings3, numberPhasicStimPerCycle, 'Replace', false) + randomJitter(1:3);

% Sort timings ascending
rand_phasicTimings1 = sort(rand_phasicTimings1);
rand_phasicTimings2 = sort(rand_phasicTimings2); 
rand_phasicTimings3 = sort(rand_phasicTimings3);

% Concatenate cycle timings
rand_phasicTimings = [rand_phasicTimings1; rand_phasicTimings2; rand_phasicTimings3];

PHASIC = 1; % if also testing phasic stimuli, 0 if only tonic

% Create stimuli

%---- TONIC STIMULUS
startendRampRate = troughPressure/startendRampDuration;
diffRampRate = diffPressure/rampDuration;

% TONIC STIMULUS
stimulus1 = cparCreateWaveform(tonic_cuff, 1);
cparWaveform_Inc(stimulus1, startendRampRate, startendRampDuration); % first ramping up to trough pressure of the tonic stimulus

for cycle = 1:cycles
    
    cparWaveform_Inc(stimulus1, diffRampRate, rampDuration);
    cparWaveform_Dec(stimulus1, diffRampRate, rampDuration);
    
end

cparWaveform_Dec(stimulus1, startendRampRate, startendRampDuration); % last ramping down to zero

%--- PHASIC STIMULUS

if PHASIC

    stimulus2 = cparCreateWaveform(phasic_cuff, 1); %#ok<UNRCH>
    stimulusTime = 0;
    
    for cycle = 1:cycles
        
        phasicCycleTimings = rand_phasicTimings(cycle,:);
        
        interCycleInterval = phasicCycleTimings(1)-stimulusTime;
        cparWaveform_Step(stimulus2, 1, interCycleInterval);
        stimulusTime = stimulusTime + interCycleInterval;

        for stim = 1:numberPhasicStimPerCycle
            
            cparWaveform_Step(stimulus2, phasicPressure, phasicStimDuration);
            stimulusTime = stimulusTime + phasicStimDuration;
            
            if stim < numberPhasicStimPerCycle % before last stimulus per cycle
                interStimulusInterval = phasicCycleTimings(stim+1)-phasicCycleTimings(stim)-phasicStimDuration; % retrieve onset timing of the stimulus
                cparWaveform_Step(stimulus2, 1, interStimulusInterval); % keep at 1 kPa between phasic stimuli
                stimulusTime = stimulusTime + interStimulusInterval;
            end
            
        end
        
        if cycle == cycles % fill in the end after last stimulus
            cparWaveform_Step(stimulus2, 1, totalDuration-stimulusTime);
        end
        
    end
    
else
    
    % Make sure the other channel is set to zero.
    stimulus2 = cparCreateWaveform(phasic_cuff, 1);  %#ok<UNRCH>

end

% Set stimuli
cparSetWaveform(dev, stimulus1, stimulus2);

% Start the stimulation
cparStart(dev, 'bp', true);

% Initialize a data sampling structure 
data = cparInitializeSampling;

% Wait until stimulation has completed
while (cparIsRunning(dev))
    fprintf('.');
    pause(0.2);
end
fprintf(' completed\n');

% Retrive data from the device.
data = cparGetData(dev, data);
data = cparFinalizeSampling(dev, data);

% Plot data retreived from the cpar device.
cparPlot(data);
