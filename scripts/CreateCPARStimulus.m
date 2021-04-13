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

    ramp_up_duration = duration(1); % duration of ramp-up (target pressure/ramping up speed)
    plateau_onset = ramp_up_duration; % onset of constant pressure
    
    ramp_up = cparRamp(pressure(1),ramp_up_duration,0); % create ramping up part
    plateau_duration = duration(2);
    
    constant_pressure = cparPulse(pressure(1),plateau_duration,plateau_onset); % create constant pressure part
    
    stimComb = cparCombined();
    cparCombinedAdd(stimComb,ramp_up); % add ramping up to stimulus
    cparCombinedAdd(stimComb,constant_pressure); % add constant pressure
    
    if cuff == 1
        stimulus1 = cparCreateStimulus(cuff_left,1,stimComb); % combined stimulus
        stimulus2 = cparCreateStimulus(cuff_right,1,cparPulse(0, 0.1, 0)); % off cuff set to zero
    elseif cuff == 2
        stimulus1 = cparCreateStimulus(cuff_right,1,stimComb); % combined stimulus
        stimulus2 = cparCreateStimulus(cuff_left,1,cparPulse(0, 0.1, 0)); % off cuff set to zero
    end
    
elseif strcmp(type,'Calibration')
    
    pressure = varargin{3};
    stimulusType = varargin{4};
    cuff_tonic = settings.pain.preExposure.cuff_left; 
    cuff_phasic = settings.pain.preExposure.cuff_right;
    
    clear combined_stim
    combined_stim = cparCombined();
    
    if stimulusType == 1
        duration = settings.pain.Calibration.tonicStim.stimDuration;
        rampUp = settings.pain.CPM.tonicStim.startendRampDuration;
        
        pfirst = cparRamp(pressure, rampUp, 0); % first ramping up to trough pressure of the tonic stimulus
        cparCombinedAdd(combined_stim, pfirst);
        constant_pressure = cparPulse(pressure,duration,rampUp); % create constant pressure part
        cparCombinedAdd(combined_stim, constant_pressure); % add constant pressure
        stimulus1 = cparCreateStimulus(cuff_tonic,1,combined_stim); % combined stimulus
        stimulus2 = cparCreateStimulus(cuff_phasic,1,cparPulse(0, 0.1, 0)); % off cuff set to zero
    else
        duration = settings.pain.Calibration.phasicStim.stimDuration;
        rampUp = 0;
        phasicStim = cparPulse(pressure,duration,rampUp);
        cparCombinedAdd(combined_stim, phasicStim);
        stimulus1 = cparCreateStimulus(cuff_phasic,1,combined_stim); % combined stimulus
        stimulus2 = cparCreateStimulus(cuff_tonic,1,cparPulse(0, 0.1, 0)); % off cuff set to zero
    end

elseif strcmp(type,'CPM')
   
    pressure = varargin{3}; % target pressure (kPa)
    
    throughPressure = pressure(1);
    peakPressure = pressure(2);
    diffPressure = peakPressure-throughPressure;
    startendRampDuration = settings.pain.CPM.tonicStim.startendRampDuration;
    rampDuration = settings.pain.CPM.tonicStim.rampDuration;
    
    % TONIC STIMULUS
    clear combined_tonic
    combined_tonic = cparCombined();

    clear pfirst plast
    pfirst = cparRamp(throughPressure, startendRampDuration, 0); % first ramping up to trough pressure of the tonic stimulus
    cparCombinedAdd(combined_tonic, pfirst);
    
    cycleStep = 0;
    
    for cycle = 1:settings.pain.CPM.tonicStim.cycles

        clear pon poff
        
        pon = cparRamp(diffPressure, rampDuration, startendRampDuration+cycleStep*rampDuration);
        poff = cparRamp(-diffPressure, rampDuration, startendRampDuration+(cycleStep+1)*rampDuration);
        
        cparCombinedAdd(combined_tonic, pon);
        cparCombinedAdd(combined_tonic, poff);
    
        cycleStep = cycleStep+2;
        
    end
    
    plast = cparRamp(-throughPressure, startendRampDuration, startendRampDuration+cycleStep*rampDuration); % last ramping down to zero
    cparCombinedAdd(combined_tonic, plast);
    
    stimulus1 = cparCreateStimulus(settings.pain.CPM.tonicStim.cuff, 1, combined_tonic);
    
%     % Update the device with the created stimulus
%     cparSetStimulus(dev, cparCreateStimulus(tonic_cuff, 1, combined_tonic));

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

% Old
%     testStimOnset = varargin{5};
%     duration_rampup_firststim = duration(1);
%     duration_rampupdown = duration(1);
%     duration_rampupdown = duration(2);
%     duration_peaktrough = duration(3);
%     duration_fullcycle = duration_rampupdown+duration_peaktrough+duration_rampupdown+duration_peaktrough;
%     onset_trough = duration_rampup_firststim;
%     onset_peak = onset_trough + duration_peaktrough;
%     onset_rampup = onset_trough + duration_peaktrough;
%     onset_rampup = 0;
%     onset_peak = onset_rampup + duration_rampupdown;
%     onset_rampdown = onset_rampup + duration_peaktrough;
%     onset_rampdown = onset_rampup + duration_rampupdown;

    % Create initial stimulus part            
%     ramp_up_firststim = cparRamp(pressure_trough,duration_rampup_firststim,0); % Ramp up to VAS 7
        
    % Combine stimulus parts into 1 full cycle and loop over no. of cycles
%     stimComb = cparCombined();
%     cparCombinedAdd(stimComb,ramp_up_firststim); % add first rise up (only first stimulus)
    
%     pressureStep = settings.CPM_CondStimTroughPressure:settings.CondStimStepPressure:settings.CPM_CondStimTonicPeakPressure;
%     onsetStep = [duration_rampup_firststim 1:numel(pressureStep(2:end))];
%     onsetStep(2:end) = onsetStep(2:end)*settings.CondStimStepDuration;
    
%     for cycle = 1:settings.CondStimCyclesPerBlock
        
%         for step = 1:settings.CondStimStepNumber 
%             step_pressure = cparPulse(pressureStep(step),settings.CondStimStepDuration,onsetStep(step));
%             cparCombinedAdd(stimComb,step_pressure);
%         end
        % Create stimulus parts
%         trough_pressure = cparPulse(pressure_trough,duration_peaktrough,onset_trough); % Keep at VAS 7 trough
%         rampup2peak = cparRamp(pressure_peak,duration_rampupdown,onset_rampup); % Ramp up to VAS 9
%         peak_pressure = cparPulse(pressure_peak,duration_peaktrough,onset_peak); % Keep at VAS 9 peak
%         rampdown2trough = cparRamp(pressure_trough,duration_rampupdown,onset_rampdown); % Ramp down to VAS 7
    
        % Add cycle parts
%         cparCombinedAdd(stimComb,trough_pressure);
%         cparCombinedAdd(stimComb,rampup2peak);
%         cparCombinedAdd(stimComb,peak_pressure);
%         cparCombinedAdd(stimComb,rampdown2trough);
        
        % Adjust onsets for next cycle
%         onset_trough = onset_trough + duration_fullcycle;
%         onset_rampup = onset_rampup + duration_fullcycle;
%         onset_peak = onset_peak + duration_fullcycle;
%         onset_rampdown = onset_rampdown + duration_fullcycle;
        
%     end
%     
%     stimulus1 = cparCreateStimulus(settings.pain.cuff_left,settings.pain.repeat,stimComb); % combined stimulus
% 
%     stimulus2 = cparCreateStimulus(settings.pain.cuff_right,1,cparPulse(0, 0.1, 0)); % off cuff set to zero
%     
%     % phasic test stimulus for CPM
%     ISIOnset = testStimOnset+testStimDuration;
%     
%     ramp_up_duration = duration(1); % duration of ramp-up (target pressure/ramping up speed)
%     plateau_onset = ramp_up_duration; % onset of constant pressure
%     ramp_up = cparRamp(pressure(1),ramp_up_duration,0); % create ramping up part
%     plateau_duration = duration(2);
%     constant_pressure = cparPulse(pressure(1),plateau_duration,plateau_onset); % create constant pressure part
%       
%     pressure_ISI = 5; % low pressure, kPa
%     
%     stimComb = cparCombined();
%     for testStim = 1:settings.TestStim
%         cparCombinedAdd(stimComb,ramp_up); % add ramping up to stimulus
%         cparCombinedAdd(stimComb,constant_pressure); % add constant pressure
%         % interstimulus interval pressure (ISI)
%         ISI_pressure = cparPulse(pressure_ISI,ISI_duration,ISIOnset(testStim)); % create constant pressure part
%         cparCombinedAdd(stimComb,ISI_pressure);
%     
%     end
%     stimulus2 = cparCreateStimulus(settings.pain.cuff_right,settings.pain.repeat,stimComb); % combined stimulus