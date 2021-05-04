function P = InstantiateParameters

P = struct;
P.protocol.sbId     = 09; % subject ID
P.protocol.session  = 1;
% P.protocol.nRatings = 2;
% P.log.ratings       = [];
P.language          = 'en'; % de or en
P.project.name      = 'CPM-Pressure-01';
P.project.part      = 'Pilot-01';
P.devices.arduino     = 1; % if '' or [], will not try to use Arduino
P.devices.eyetracker  = 0;
P.devices.trigger   = 0; % 1 single parallel port, arduino; rest undefined

P.display.white = [1 1 1];
P.lineheight = 40;
P.display.startY = 0.5;
P.display.Ytext = 0.25;

[~, tmp]                        = system('hostname');
P.env.hostname                  = deblank(tmp);
P.env.hostaddress               = java.net.InetAddress.getLocalHost;
P.env.hostIPaddress             = char(P.env.hostaddress.getHostAddress);

if strcmp(P.env.hostname,'stimpc1')

elseif strcmp(P.env.hostname,'isnb05cda5ba721')
    P.path.scriptBase           = cd;
    P.path.experiment           = fullfile('C:\Data','CPM-Pressure','data',P.project.name);
    P.path.PTB                  = 'C:\Data\Toolboxes\Psychtoolbox';
else
    P.path.scriptBase           = cd;
    P.path.experiment           = fullfile(cd,'..','..','data',P.project.name);
    P.path.PTB                  = 'C:\toolbox\Psychtoolbox';
end
if ~exist(P.path.experiment,'dir')
    mkdir(P.path.experiment);
end

if P.devices.arduino
    if strcmp(P.env.hostname,'stimpc1')
        %             P.com.arduino = 'COM12'; % Mario COM11, Luigi COM12
        %             P.path.arduino = '';
        %             disp('stimpc1');
    elseif strcmp(P.env.hostname,'isnb05cda5ba721')
        P.com.arduino = 'COM3'; 
        P.path.cpar = fullfile(cd,'LabBench.CPAR-0.1.0');
        disp('worklaptop');
    else
        P.com.arduino = 'COM5'; % CPAR: depends on PC - work laptop COM3 - experiment laptop COM5
        P.path.cpar = fullfile(cd,'..','CPAR');
        disp('vamplaptop');
    end
end

%% Stimulus parameters
% General CPAR
P.cpar.forcedstart                   = true; % CPAR starts even if VAS rating device of CPAR is not at 0 (otherwise false)
P.cpar.stoprule                      = 'bp';  % CPAR stops only at button press (not when VAS rating with the device reaches the maximum, 'v')

% Pre-exposure
P.pain.preExposure.cuff_left            = 1; % 1: left, 2: right - depends on how cuffs plugged into the CPAR unit and put on participant's arm
P.pain.preExposure.cuff_right           = 2; % 
P.pain.preExposure.repeat               = 1; % number of repeats of each stimulus1111
P.pain.preExposure.pressureIntensity    = [10 20 30]; % preexposure pressure intensities (kPa)
P.pain.preExposure.riseSpeed            = 10; % kPa/s
P.pain.preExposure.pressureRange        = 5.0:1:100.0; % possible pressure range (kPa)
P.presentation.sStimPlateauPreexp       = 30; % duration of the constant pressure plateau after rise time for pre-exposure (part 1)
P.presentation.sPreexpITI               = 10; % pre-exposure intertrial interval (ITI)
P.presentation.sPreexpCue               = P.presentation.sStimPlateauPreexp/P.pain.preExposure.riseSpeed+P.presentation.sStimPlateauPreexp; % pre-exposure cue duration (stimulus duration with rise time included)
P.presentation.sStimPlateau             = P.presentation.sStimPlateauPreexp; % duration of the constant pressure plateau after rise time for pressure test (part 2)
% P.data.preExposure.painThreshold        = []; % will be filled during pre-exposure

% Calibration
P.presentation.Calibration.firstTrialWait       = 5;

P.pain.Calibration.painTresholdPreset           = [20 30]; % 40 for tonic stimuli, 50 for phasic stimuli
P.pain.Calibration.tonicStim.stimDuration       = 30;
P.pain.Calibration.tonicStim.pressureChange     = [-10 5 10 15];
P.presentation.Calibration.tonicStim.trials     = numel(P.pain.Calibration.tonicStim.pressureChange);
P.pain.Calibration.tonicStim.pressureOrder      = randperm(P.presentation.Calibration.tonicStim.trials);

P.pain.Calibration.phasicStim.stimDuration      = 5;
P.pain.Calibration.phasicStim.pressureChange    = [-10 5 10 15];
P.presentation.Calibration.phasicStim.trials    = numel(P.pain.Calibration.phasicStim.pressureChange);
P.pain.Calibration.phasicStim.pressureOrder     = randperm(P.presentation.Calibration.phasicStim.trials);

P.presentation.Calibration.tonicStim.ITI        = 30;
P.presentation.Calibration.phasicStim.ITI       = 15;
P.presentation.Calibration.durationVAS          = 5;

% Conditioned pain modulation
P.presentation.CPM.blocks                   = 2; % number of blocks/runs in the CPM experiment - plan: 3 blocks/runs
P.presentation.CPM.trialsPerBlock           = 2; % 4 stimuli of 3 min per block -> 12 min + 4 x 30 s ITI + 60 s between blocks = 15 min per block/run -> 3 blocks = 45 min
P.pain.CPM.phasicStim.on                    = [1 1 1 1 1 0]; % on which blocks the phasic test stimuli will be delivered to the other cuff, in addition to the tonic conditioning stimulus
% these are also the blocks with online VAS rating of tonic stimulus
conditions                      = [zeros(1,P.presentation.CPM.blocks/2) ones(1,P.presentation.CPM.blocks/2)]; % 0 = control tonic stimulus (non-painful), 1 = experimental tonic stimulus (painful)
ordering                        = randperm(P.presentation.CPM.blocks);
conditions_rand                 = conditions(ordering);
P.pain.CPM.tonicStim.condition  = conditions_rand;%[1 conditions_rand 1];

% CPAR cuff IDs
P.pain.CPM.tonicStim.cuff   = 1; 
P.pain.CPM.phasicStim.cuff  = 2;

% Tonic stimulus properties
% Current settings: 
% 3 cycles of 60 seconds between e.g. 20 and 30 kPa
% Each cycle consists of 1 x ramp up for 30 s and 1 x ramp down for 30 s
% 10 seconds ramping up to 20 kPa in the beginning
% 10 seconds ramping down to 0 kPa in the end
% Total tonic stimulus duration 200 seconds (3 x 60 + 2 x 10 s)
P.pain.CPM.tonicStim.fullCycleDuration             = 60; % duration of 1 cycle of the tonic stimulus
P.pain.CPM.tonicStim.rampDuration                 = P.pain.CPM.tonicStim.fullCycleDuration/2; % duration of ramp up/down of 1 cycle
P.pain.CPM.tonicStim.startendRampDuration         = 10; % duration of ramp up/down before/after tonic stimulus
P.pain.CPM.tonicStim.pressurePeak    = 20; % pressure at peak of the tonic stimulus (maximum), e.g. at VAS 9
P.pain.CPM.tonicStim.pressureTrough  = 10; % pressure at trough of the tonic stimulus (minimum), e.g. at VAS 7
%P.pain.CPM.tonicStim.pressureDiff    = P.pain.CPM.tonicStim.pressurePeak-P.pain.CPM.tonicStim.pressureTrough;
P.pain.CPM.tonicStim.pressurePeakControl    = 10; % pressure at peak of the tonic stimulus (maximum) for control condition
P.pain.CPM.tonicStim.pressureTroughControl  = 5;  % pressure at trough of the tonic stimulus (minimum) for control condition
P.pain.CPM.tonicStim.cycles          = 3;
P.pain.CPM.tonicStim.multipliers     = [1:2*P.pain.CPM.tonicStim.cycles]-1;
P.pain.CPM.tonicStim.totalDuration   = P.pain.CPM.tonicStim.fullCycleDuration*P.pain.CPM.tonicStim.cycles+2*P.pain.CPM.tonicStim.startendRampDuration;

% Phasic stimulus properties
% 2 x 5 seconds pulse, with 4 different potential onset timings during the tonic stimulus
% slopes (not at peak or trough), jittered by 0-2 seconds
% Goal: 3 x 5 seconds pulse but not possible with current CPAR firmware
% (exceeds the maximum of possible components = 12)
%rampSpeed = 10; % kPa/s
P.pain.CPM.phasicStim.pressure          = 30; % phasic stimulus pressure, e.g. at VAS 8
P.pain.CPM.phasicStim.rampDuration      = 0; %phasicPressure/rampSpeed -> instant ramping up now
P.pain.CPM.phasicStim.duration          = 5-P.pain.CPM.phasicStim.rampDuration; % duration of phasic stimulus in seconds
%P.pain.CPM.phasicStim.ISI = 8:0.5:10; % interstimulus interval
P.pain.CPM.phasicStim.stimPerCycle      = 2; % how many phasic stimuli per cycle of the tonic stimulus
P.pain.CPM.phasicStim.jitter            = 0:0.5:2; % jitter for onset of phasic stimuli in seconds
P.pain.CPM.phasicStim.stimInterval      = 15; % approximate interval between phasic stimuli onsets
% 5 s stimulus + 2 s jitter from 0 onset -> offset at max. 7 s after ->
% with 15 s in between possible time points, 8-10 sec ISI

phasicOnsets =  P.pain.CPM.tonicStim.startendRampDuration + [5:P.pain.CPM.phasicStim.stimInterval:(P.pain.CPM.tonicStim.fullCycleDuration*P.pain.CPM.tonicStim.cycles-P.pain.CPM.tonicStim.startendRampDuration)];
phasicOnsets = reshape(phasicOnsets,[],P.pain.CPM.tonicStim.cycles)';

onsets = nan(P.presentation.CPM.blocks,P.presentation.CPM.trialsPerBlock,P.pain.CPM.tonicStim.cycles,P.pain.CPM.phasicStim.stimPerCycle);

for block = 1:P.presentation.CPM.blocks
    
    for trial = 1:P.presentation.CPM.trialsPerBlock
        
        for cycle = 1:P.pain.CPM.tonicStim.cycles
            
            % Cycle timings jittered relative to above onsets
            randomJitter = P.pain.CPM.phasicStim.jitter(randperm(length(P.pain.CPM.phasicStim.jitter)));
            P.pain.CPM.phasicStim.randomJitter(cycle,:) = randomJitter;
            rand_phasicOnsets = datasample(phasicOnsets(cycle,:), P.pain.CPM.phasicStim.stimPerCycle, 'Replace', false) + randomJitter(1:P.pain.CPM.phasicStim.stimPerCycle);
            clear randomJitter
            
            % Sort timings ascending
            rand_phasicOnsets = sort(rand_phasicOnsets);
            
            % Save onsets
            onsets(block,trial,cycle,:) = rand_phasicOnsets;
            
        end
        
    end

end

% Concatenate cycle timings
P.pain.CPM.phasicStim.onsets = onsets;


%% VAS rating parameters
% Rating of pressure pain stimuli
P.presentation.CPM.tonicStim.firstTrialWait = 5; 
P.presentation.CPM.tonicStim.durationVAS    = P.pain.CPM.tonicStim.totalDuration; % Presentation duration of VAS rating scale for tonic stimuli (continous, online)
P.presentation.CPM.tonicStim.durationBuffer = 5; % Seconds to wait until VAS finishes for CPAR to have finished, to save CPAR data
P.presentation.CPM.tonicStim.totalITI       = 30; % total ITI between conditioning stimuli
P.presentation.CPM.blockBetweenTime         = 60; % time in between blocks/runs
P.presentation.CPM.blockBetweenText         = 3; % time to show end of block text
P.presentation.BlockStopDuration        = 2;  % time to stop at the block display

P.presentation.CPM.phasicStim.durationVAS   = 5; % time to rate VAS for test stimuli during ISI
P.presentation.CPM.phasicStim.waitforVAS    = 1; % time to wait until VAS onset after stimulus end
% P.presentation.phasicStim.totalISI      = 20; % total ISI between test stimuli

% P.CPM_CondStimTroughPressure    = 1; % tonic conditioning stimulus intensity trough (kPa); overridden by calibration
% P.CPM_CondStimTonicPeakPressure = 20; % tonic conditioning stimulus intensity peak (kPa)
% P.CPM_TestStimPressure          = 40; % phasic test stimulus intensity (kPa); overridden by calibration
% P.CPM_Blocks                    = 1;  % blocks number of times the whole set of stimuli is repeated - will be 4, 1 for testing
% P.CondStimCyclesPerBlock        = 1; % number of cycles for conditioning stimuli per experiment block
% P.CondStimCycleDuration         = 20; % 60 seconds
% P.TestStimPerCondStimCycle      = 3; % number of phasic test stimuli per cycle of conditioning stimulus
% P.CondStimDuration              = P.CondStimCyclesPerBlock*P.CondStimCycleDuration; % 3 minutes
% %P.CondStimTroughDuration        = P.CondStimDuration/P.CondStimCyclesPerBlock/10;
% P.FirstRiseDuration             = P.CPM_CondStimTroughPressure/P.pain.riseSpeed;
% % P.CondStimSlopeFrequency        = 2; % Hz -> increments in slope per second
% % P.CondStimStepDuration          = 1/P.CondStimSlopeFrequency;
% % P.CondStimStepNumber            = (P.CondStimCycleDuration/2)/P.CondStimStepDuration;
% % P.CondStimStepPressure          = (P.CPM_CondStimTonicPeakPressure-P.CPM_CondStimTroughPressure)/P.CondStimStepNumber;
% P.CondStimPeakTroughDuration    = 0; %P.CondStimDuration/P.CondStimCyclesPerBlock/10; % 6 s with 60 s cycle
% P.CondStimSlopeDuration         = P.CondStimDuration/P.CondStimCyclesPerBlock/2; % 2.5; 24 s with 60 s cycle
% P.CondStimRampUpSpeed           = (P.CPM_CondStimTonicPeakPressure-P.CPM_CondStimTroughPressure)/P.CondStimSlopeDuration; % kPa/s
% P.TestStimOnset                 = [0 0.25 0.75 1]; % onset for test stimuli with regard to conditioning stimulus cycle (0 trough, 0.5 peak, 1 trough)
% P.TestStimJitter                = [-0.1 -0.05 0 0.05 0.1]; % amount of jittering relative to the onset, e.g. with 60 s conditioning stimulus jitter is +-0, 3 or 6 s
% P.TestStimRampUpSpeed           = 30; % kPa/s
% P.TestStimPlateauDuration       = 5; % 5 seconds
% P.TestStimRampUpDuration        = P.CPM_TestStimPressure/P.TestStimRampUpSpeed;
% P.FullBlockDuration             = P.FirstRiseDuration + P.CondStimPeakTroughDuration*2*P.CondStimCyclesPerBlock + P.CondStimSlopeDuration*2*P.CondStimCyclesPerBlock;
% P.presentation.CPM_ITI               = 20; % ITI for in between 3 min conditioning stimuli + 10 seconds from rating time
% P.presentation.CPM_ISI               = 10; % interstimulus interval (ISI) between phasic test stimuli + 10 seconds from rating time

end

