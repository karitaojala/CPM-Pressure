clear all
cparpath = fullfile(cd,'..');
addpath(genpath(fullfile(cparpath,'LabBench.CPAR-master')))

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

% Define stimuli
stimulus1 = cparCreateWaveform(1, 1); % cuff 1: left
stimulus2 = cparCreateWaveform(2, 1); % cuff 2: right

pressure = 30;
% pressure = 40;
% pressure = 50;
% pressure = 60; % kPa
% pressure = 70;
% pressure = 80;
% pressure = 90;
duration = 10; % seconds
% cparWaveform_Step(stimulus1, 1, duration);
cparWaveform_Step(stimulus1, pressure, duration);
% cparWaveform_Step(stimulus2, 1, duration);
cparWaveform_Step(stimulus2, pressure, duration);

% Ramps
% rampRate = 30; % kPa/s
% rampDuration = 2;
% rampDuration = 3;
% rampDuration = 4;
% cparWaveform_Inc(stimulus1, rampRate, rampDuration);
% cparWaveform_Step(stimulus1, rampDuration*rampRate, duration);
% cparWaveform_Inc(stimulus2, rampRate, rampDuration);
% cparWaveform_Step(stimulus2, rampDuration*rampRate, duration);

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