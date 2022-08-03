% Creationg of CPAR pressure cuff stimuli
% 
% [stimulus1, stimulus2, cuff] = CreateCPARStimulus(varargin)
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
%                           pressure(1): tonic conditioning stimulus VAS 70
%                           pressure(2): tonic conditioning stimulus VAS 90
%                           pressure(3): phasic test stimulus
%   5. phasic stimulus setting (ON/OFF for the block) for CPM
%   6. CPM block
%   7. CPM trial within block
                    
% Version: 1.0
% Author: Karita Ojala, University Medical Center Hamburg-Eppendorf
% Date: 2021-06-09

function [stimulus1, stimulus2, cuff] = CreateCPARStimulus(varargin)

varargin = varargin{:};
type = varargin{1}; % pre-exposure, conditioning, or test stimulus
settings = varargin{2};

if strcmp(type,'preExp')
    
    duration = varargin{3};
    pressure = varargin{4}; % target pressure (kPa)
    cuff = varargin{5};
    
    if cuff == 1
        cuff_off = 2;
    elseif cuff == 2
        cuff_off = 1;
    end
    
    stim_pressure = pressure(1);
    ramp_up_duration = duration(1); % duration of ramp-up (target pressure/ramping up speed)
    ramp_up_rate = stim_pressure/ramp_up_duration;
    plateau_duration = duration(2);
    
    stimulus1 = cparCreateWaveform(cuff,1); % combined stimulus
    stimulus2 = cparCreateWaveform(cuff_off,1); % off cuff set to zero
    
    cparWaveform_Inc(stimulus1, ramp_up_rate, ramp_up_duration); % ramp up
    cparWaveform_Step(stimulus1, stim_pressure, plateau_duration); % constant pressure
    
elseif strcmp(type,'Calibration')
    
    pressure = varargin{3};
    stimulusType = varargin{4};
    cuff = varargin{5};

    if cuff == 1
        cuff_off = 2;
    elseif cuff == 2
        cuff_off = 1;
    end
    
    if stimulusType == 1
        
        stimDuration = settings.pain.Calibration.tonicStim.stimDuration;
        duration = CalcStimDuration(settings,pressure,stimDuration);
        
        rampUp = duration(1);
        
        stimulus1 = cparCreateWaveform(cuff,1); % combined stimulus
        stimulus2 = cparCreateWaveform(cuff_off,1); % off cuff set to zero
        
        rateRampUp = pressure/rampUp;
        
        cparWaveform_Inc(stimulus1,rateRampUp,rampUp); % first ramping up to pressure of the tonic stimulus
        cparWaveform_Step(stimulus1,pressure,stimDuration); % create constant pressure part
        
    else
        
        duration = settings.pain.Calibration.phasicStim.stimDuration;
        
        stimulus1 = cparCreateWaveform(cuff,1); % combined stimulus
        stimulus2 = cparCreateWaveform(cuff_off,1); % off cuff set to zero
        cparWaveform_Step(stimulus1,pressure,duration);

    end

elseif strcmp(type,'TonicRating')
    
    cuff = settings.pain.CPM.tonicStim.cuff;
    
    pressure = varargin{3}; % target pressure (kPa)
    
    troughPressure = pressure(1);
    peakPressure = pressure(2);
    diffPressure = peakPressure-troughPressure;
    startendRampDuration = settings.pain.CPM.tonicStim.startendRampDuration;
    rampDuration = settings.pain.CPM.tonicStim.rampDuration;
    
    startendRampRate = troughPressure/startendRampDuration;
    diffRampRate = diffPressure/rampDuration;
    
    % TONIC STIMULUS
    stimulus1 = cparCreateWaveform(settings.pain.CPM.tonicStim.cuff, 1);
    cparWaveform_Inc(stimulus1, startendRampRate, startendRampDuration); % first ramping up to trough pressure of the tonic stimulus
    
    for cycle = 1:settings.pain.CPM.tonicRating.cycles
        
        cparWaveform_Inc(stimulus1, diffRampRate, rampDuration);
        cparWaveform_Dec(stimulus1, diffRampRate, rampDuration);
        
    end
    
    cparWaveform_Dec(stimulus1, startendRampRate, startendRampDuration); % last ramping down to zero
       
    % OTHER CUFF NO STIMULUS
    stimulus2 = cparCreateWaveform(settings.pain.CPM.phasicStim.cuff, 1);
    
elseif strcmp(type,'CPM')
   
    cuff = settings.pain.CPM.tonicStim.cuff;
    
    pressure = varargin{3}; % target pressure (kPa)
    
    troughPressure = pressure(1);
    peakPressure = pressure(2);
    diffPressure = peakPressure-troughPressure;
    startendRampDuration = settings.pain.CPM.tonicStim.startendRampDuration;
    rampDuration = settings.pain.CPM.tonicStim.rampDuration;
    
    startendRampRate = troughPressure/startendRampDuration;
    diffRampRate = diffPressure/rampDuration;
    
    % TONIC STIMULUS
    stimulus1 = cparCreateWaveform(settings.pain.CPM.tonicStim.cuff, 1);
    cparWaveform_Inc(stimulus1, startendRampRate, startendRampDuration); % first ramping up to trough pressure of the tonic stimulus
    
    for cycle = 1:settings.pain.CPM.tonicStim.cycles
        
        cparWaveform_Inc(stimulus1, diffRampRate, rampDuration);
        cparWaveform_Dec(stimulus1, diffRampRate, rampDuration);
        
    end
    
    cparWaveform_Dec(stimulus1, startendRampRate, startendRampDuration); % last ramping down to zero

    % PHASIC STIMULUS

    phasic_on = varargin{4};
    block = varargin{5};
    trial = varargin{6};
    phasicPressure = pressure(3);
    phasicStimDuration = settings.pain.CPM.phasicStim.duration;
    
    stimulus2 = cparCreateWaveform(settings.pain.CPM.phasicStim.cuff, 1);
    
    if phasic_on % if phasic stimuli on for this trial
        
        stimulusTime = 0; % counter to keep track of stimulus time
        
        for cycle = 1:settings.pain.CPM.tonicStim.cycles
            
            phasicCycleTimings = squeeze(settings.pain.CPM.phasicStim.onsets(block,trial,cycle,:));
            
            interCycleInterval = phasicCycleTimings(1)-stimulusTime;
            cparWaveform_Step(stimulus2, 1, interCycleInterval);
            stimulusTime = stimulusTime + interCycleInterval;
            
            for stim = 1:settings.pain.CPM.phasicStim.stimPerCycle
                
                cparWaveform_Step(stimulus2, phasicPressure, phasicStimDuration);
                stimulusTime = stimulusTime + phasicStimDuration;
                
                if stim < settings.pain.CPM.phasicStim.stimPerCycle % before last stimulus per cycle
                    interStimulusInterval = phasicCycleTimings(stim+1)-phasicCycleTimings(stim)-phasicStimDuration; % retrieve onset timing of the stimulus
                    cparWaveform_Step(stimulus2, 1, interStimulusInterval); % keep at 1 kPa between phasic stimuli
                    stimulusTime = stimulusTime + interStimulusInterval;
                end
                
            end
            
            if cycle == settings.pain.CPM.tonicStim.cycles % fill in the end after last stimulus
                cparWaveform_Step(stimulus2, 1, settings.pain.CPM.tonicStim.totalDuration-stimulusTime);
            end

        end

    end
    
end

end