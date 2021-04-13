% Cuff Pressure Algometry Reseach (CPAR) Toolbox
% 
% Matlab toolbox for the Cuff Pressure Algometry Research (CPAR) device
% from Nocitech ApS.
%
% Initialization and management of CPAR devices
%   cparInitialize         - Initialize the Instrument database.
%   cparList               - List all installed CPAR devices.
%   cparGetDevice          - Get a CPAR device from the Instrument database.
%
% Creation and generation of pressure stimuli
%   cparCreateWaveform     - Create an empty pressure waveform
%   cparWaveform_Step      - Add a step in pressure to a waveform
%   cparWaveform_Inc       - Add a linear increase in pressure to a waveform
%   cparWaveform_Dec       - Add a linear decrease in pressure to a waveform
%   cparSetWaveform        - Set pressure waveform programs
%   cparStart              - Start a presssure stimulation
%   cparStop               - Stop a pressure stimulation before it is completed
%
% Data retrieval and handling
%   cparInitializeSampling - Initialize a sampling structure
%   cparGetData            - Collect data into a sampling structure
%   cparFinalizeSampling   - Finalize sampling of data from the cpar deviced
%   cparStartSampling      - Start sampling of data
%   cparStopSampling       - Stop sampling of data
%   cparPlot               - Plot the results in a sampling structure
%
% Device state and handling
%   cparError              - Has there been established a connection with the device
%   cparIsRunning          - Check if a pressure stimulation is running
%   cparPing               - Check the connection to a cpar device
%   cparIsReady            - Is the device ready to perform a pressure stimulation
%   cparGetAdvice          - Get advice (if any) on why the device is not ready.
