% Creationg of CPAR pressure cuff stimuli
% 
% [stimulus1, stimulus2] = CreateCPARStimulus(varargin)
%
% Varargin:
%   1. type - pre-exposure, calibration or CPM stimulus
%   2. settings - P
%   3. duration - an array of stimulus durations
%                   pre-exposure stimuli: 
%                           duration(1): ramp up
%                           duration(2): plateau
%                   CPM stimuli: 
%                           not used, durations defined in InstantiateParameters.m
%   4. pressure - intensity in kPa
%                   pre-exposure stimuli: 
%                           pressure(1): constant plateau pressure
%                   CPM stimuli: 
%                           pressure(1): tonic conditioning stimulus VAS 7
%                           pressure(2): tonic conditioning stimulus VAS 9
%                           pressure(3): phasic test stimulus
%   5. phasic stimulus setting (ON/OFF for the block) for CPM
%   6. CPM block
%   7. CPM trial within block
                    
% Version: 1.0
% Author: Karita Ojala, University Medical Center Hamburg-Eppendorf
% Date: 2021-02-18

function [stimulus1, stimulus2] = CreateCPARStimulus(varargin)

varargin = varargin{:};
type = varargin{1}; % pre-exposure, conditioning, or test stimulus
settings = varargin{2};

if strcmp(type,'preExp')
    
    duration = varargin{3};
    pressure = varargin{4}; % target pressure (kPa)
    cuff = varargin{5};
    
    cuff_left = settings.pain.preExposure.cuff_left; 
    cuff_right = settings.pain.preExposure.cuff_right;

    stim_pressure = pressure(1);
    ramp_up_duration = duration(1); % duration of ramp-up (target pressure/ramping up speed)
%     plateau_onset = ramp_up_duration; % onset of constant pressure
    plateau_duration = duration(2);
    
    if cuff == 1
        stimulus1 = cparCreateWaveform(cuff_left,1); % combined stimulus
        stimulus2 = cparCreateStimulus(cuff_right,1); % off cuff set to zero
    elseif cuff == 2
        stimulus1 = cparCreateStimulus(cuff_right,1); % combined stimulus
        stimulus2 = cparCreateStimulus(cuff_left,1); % off cuff set to zero
    end
    
    cparWaveform_Inc(stimulus1, stim_pressure, ramp_up_duration); % ramp up
    cparWaveform_Step(stimulus1, stim_pressure, plateau_duration); % constant pressure
    
elseif strcmp(type,'Calibration')
    
    pressure = varargin{3};
    stimulusType = varargin{4};
    cuff_tonic = settings.pain.preExposure.cuff_left; 
    cuff_phasic = settings.pain.preExposure.cuff_right;
    
    if stimulusType == 1
        duration = settings.pain.Calibration.tonicStim.stimDuration;
        rampUp = settings.pain.CPM.tonicStim.startendRampDuration;
        
        stimulus1 = cparCreateWaveform(cuff_tonic,1); % combined stimulus
        stimulus2 = cparCreateWaveform(cuff_phasic,1); % off cuff set to zero
        
        cparWaveform_Inc(stimulus1,pressure,rampUp); % first ramping up to trough pressure of the tonic stimulus
        cparWaveform_Step(stimulus1,pressure,duration); % create constant pressure part
        
    else
        duration = settings.pain.Calibration.phasicStim.stimDuration;
        %rampUp = 0;
        
        stimulus1 = cparCreateWaveform(cuff_phasic,1); % combined stimulus
        stimulus2 = cparCreateWaveform(cuff_tonic,1); % off cuff set to zero
        
        cparWaveform_Step(stimulus1,pressure,duration);

    end

elseif strcmp(type,'CPM')
   
    pressure = varargin{3}; % target pressure (kPa)
    
    throughPressure = pressure(1);
    peakPressure = pressure(2);
    diffPressure = peakPressure-throughPressure;
    startendRampDuration = settings.pain.CPM.tonicStim.startendRampDuration;
    rampDuration = settings.pain.CPM.tonicStim.rampDuration;
    
    % TONIC STIMULUS
    stimulus1 = cparCreateWaveform(settings.pain.CPM.tonicStim.cuff, 1);
    cparWaveform_Inc(stimulus1,throughPressure, startendRampDuration); % first ramping up to trough pressure of the tonic stimulus
    
    for cycle = 1:settings.pain.CPM.tonicStim.cycles
        
        cparWaveform_Inc(stimulus1, diffPressure, rampDuration);
        cparWaveform_Dec(stimulus1, diffPressure, rampDuration);
        
    end
    
    cparWaveform_Dec(stimulus1, throughPressure, startendRampDuration); % last ramping down to zero

    % PHASIC STIMULUS

    phasicOn = varargin{4};
    block = varargin{5};
    trial = varargin{6};
    phasicPressure = pressure(3);
    phasicStimDuration = settings.pain.CPM.phasicStim.duration;
    
    if phasicOn % if phasic stimuli on for this block
        
        combined_phasic = cparCombined();
        %     timingPhasicBetween = 0; % start with 0 kPa pressure in the cuff until the first phasic stimulus timing comes
        
        for cycle = 1:settings.pain.CPM.tonicStim.cycles
            
            phasicCycleTimings = squeeze(settings.pain.CPM.phasicStim.onsets(block,trial,cycle,:));
            
            if cycle == 1 % need to add one 0 kPa pressure stimulus before the first phasic stimulus - otherwise first phasic stimulus starts at time 0 despite giving another onset time
                stimPhasicBetween = cparPulse(0, phasicCycleTimings(1), 0);
                cparCombinedAdd(combined_phasic, stimPhasicBetween);
            end
            
            for stim = 1:settings.pain.CPM.phasicStim.stimPerCycle
                
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
        
        stimulus2 = cparCreateStimulus(settings.pain.CPM.phasicStim.cuff, 1, combined_phasic);
        
    else
        
        null_phasic = cparPulse(0, 0.1, 0);
        stimulus2 = cparCreateStimulus(settings.pain.CPM.phasicStim.cuff, 1, null_phasic);
        
    end
    
end