%%Testing script for condititioned pain modulation stimuli: tonic
%%fluctuating conditioning stimulus and short phasic test stimulus
%%Karita Ojala
%%Institute of Systems Neuroscience - University Medical Center Hamburg-Eppendorf
%%28.01.2021

clear all
cparpath = cd;
addpath(genpath(cparpath))

% Create a device and open communication with the device.
dev = cparCreate('COM3');
cparOpen(dev);

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
fullStimDuration = 60; % duration of 1 cycle of the tonic stimulus
rampDuration = fullStimDuration/2; % duration of ramp up/down of 1 cycle
startendRampDuration = 10; % duration of ramp up/down before/after tonic stimulus
peakPressure = 40; % pressure at peak of the tonic stimulus (maximum), e.g. at VAS 9
throughPressure = 20; % pressure at trough of the tonic stimulus (minimum), e.g. at VAS 7
diffPressure = peakPressure-throughPressure;

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
combined_tonic = cparCombined();

pfirst = cparRamp(throughPressure, startendRampDuration, 0); % first ramping up to trough pressure of the tonic stimulus

% Cycle 1
pon = cparRamp(diffPressure, rampDuration, startendRampDuration+0*rampDuration);
poff = cparRamp(-diffPressure, rampDuration, startendRampDuration+1*rampDuration);

% Cycle 2
pon2 = cparRamp(diffPressure, rampDuration, startendRampDuration+2*rampDuration);
poff2 = cparRamp(-diffPressure, rampDuration, startendRampDuration+3*rampDuration);

% Cycle 3
pon3 = cparRamp(diffPressure, rampDuration, startendRampDuration+4*rampDuration);
poff3 = cparRamp(-diffPressure, rampDuration, startendRampDuration+5*rampDuration);

plast = cparRamp(-throughPressure, startendRampDuration, startendRampDuration+6*rampDuration); % last ramping down to zero

% Add stimuli to the combined full stimulus
cparCombinedAdd(combined_tonic, pfirst);

cparCombinedAdd(combined_tonic, pon);
cparCombinedAdd(combined_tonic, poff);

cparCombinedAdd(combined_tonic, pon2);
cparCombinedAdd(combined_tonic, poff2);

cparCombinedAdd(combined_tonic, pon3);
cparCombinedAdd(combined_tonic, poff3);

cparCombinedAdd(combined_tonic, plast);

% Update the device with the created stimulus
cparSetStimulus(dev, cparCreateStimulus(tonic_cuff, 1, combined_tonic));

%--- PHASIC STIMULUS

if PHASIC
    
    combined_phasic = cparCombined();
    
    timingPhasicBetween = 0; % start with 0 kPa pressure in the cuff until the first phasic stimulus timing comes

    for cycle = 1:3
        
        phasicCycleTimings = rand_phasicTimings(cycle,:);
        
        if cycle == 1 % need to add one 0 kPa pressure stimulus before the first phasic stimulus - otherwise first phasic stimulus starts at time 0 despite giving another onset time
            stimPhasicBetween = cparPulse(0, phasicCycleTimings(1), 0);
            cparCombinedAdd(combined_phasic, stimPhasicBetween);
        end
        
        for stim = 1:2%numberPhasicStimPerCycle
            
            timingPhasicStim = phasicCycleTimings(stim); % retrieve onset timing of the stimulus
            %stimPhasicBetween = cparPulse(0, timingPhasicStim-timingPhasicBetween, timingPhasicBetween);
            %cparCombinedAdd(combined_phasic, stimPhasicBetween);
            %stimPhasicRamp = cparRamp(phasicPressure, phasicRampDuration, timingPhasicStim);
            %cparCombinedAdd(combined_phasic, stimPhasicRamp);
            stimPhasicPlateau = cparPulse(phasicPressure, phasicStimDuration, timingPhasicStim);
            %stimPhasicPlateau = cparPulse(phasicPressure, phasicStimDuration, timingPhasicStim+phasicRampDuration);
            cparCombinedAdd(combined_phasic, stimPhasicPlateau);
            clear stimPhasicRamp stimPhasicPlateau
            
            %timingPhasicBetween = timingPhasicStim + phasicRampDuration + phasicStimDuration;
            %timingPhasicBetween = timingPhasicStim + phasicStimDuration;
            
        end
    end    
    
    cparSetStimulus(dev, cparCreateStimulus(phasic_cuff, 1, combined_phasic));
    
else
    
    % Make sure the other channel is set to zero.
    cparSetStimulus(dev, cparCreateStimulus(phasic_cuff, 1, cparPulse(0, 0.1, 0))); %#ok<UNRCH>

end

% Start the stimulation
cparStart(dev, 'b', true);

% Wait until stimulation has completed
pause(1);
while (dev.State == LabBench.Interface.AlgometerState.STATE_STIMULATING)
    fprintf('State: %s\n', dev.State.ToString());
    dev.Ping();
    pause(0.2);
end
fprintf('State: %s\n', dev.State.ToString());

% Retrive data and plot it.
data = cparGetData(dev);
cparPlot(data);
cparClose(dev);
