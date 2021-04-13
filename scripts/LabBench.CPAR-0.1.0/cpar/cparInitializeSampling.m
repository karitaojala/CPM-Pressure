function [data] = cparInitializeSampling(expectedTime)
% cparInitializeSampling Initialize a sampling structure
%   [data] = cparInitializeSampling(expectedTime) initialized a data
%   structure that can later be used with the cparGetData function to
%   collect data from the device, and which must when data collection is
%   completed be finalized with the cparFinalizeSampling function.
%
%   The expectedTime parameter is used to initialize the initial capacity
%   of the data structures holding the data from the device. The value of
%   the expectedTime can be calculated from the duration of the longest
%   pressure waveform plus the time that needs to be sampled after the
%   pressure stimulation has completed. However, it is not a critical
%   parameter, setting it to a close to correct value will lead to a slight
%   performance boost, however, with a modern computer, this is
%   insignificant and the parameter can also safely be omitted.
%
% Important note!
%   The cparInitializeSampling function only and only initialize the
%   sampling structure it does not start the sampling of data. If sampling
%   of data is not started, subsequent calls to cparGetData with the data
%   structure created by this function will always return no data.
%
%   Sampling of data is started implicitly when cparStart is called, or it
%   can be started explicitly with the cparStartSampling function. The
%   cparStartSampling can be used to sample data without starting a
%   pressure stimulation.
%
%   When data sampling has been started either implicitly with cparStart or
%   explicitly with cparStartSampling it is important that cparStopSampling
%   is called when no more data is needed. If cparStopSampling is not
%   called then data will accumulate in the memory of the computer and even
%   though cpar does not generate excessive amounths of data it will fill
%   up the memory of the computer eventually if given enough time.
%
% Code example:
%      data = cparInitializeSampling;
%
%      while (cparIsRunning(dev))
%          % Here other code that must be run in parallel can be inserted if
%          % needed
%
%          pause(0.2); % It is a good idea to insert a pause in order to free
%                      % the processor for other tasks. 
%
%          data = cparGetData(dev, data);
%      end
%
%      data = cparFinalizeSampling(dev, data);
%
%
% See also, cparGetData, cparFinalizeSampling
%
    if ~exist('expectedTime', 'file')
        expectedTime = 1;
    end

    data.Pressure01 = NET.createGeneric('System.Collections.Generic.List',{'System.Double'}, expectedTime * 20);
    data.Pressure02 = NET.createGeneric('System.Collections.Generic.List',{'System.Double'}, expectedTime * 20);
    data.Target01 = NET.createGeneric('System.Collections.Generic.List',{'System.Double'}, expectedTime * 20);
    data.Target02 = NET.createGeneric('System.Collections.Generic.List',{'System.Double'}, expectedTime * 20);
    data.VAS = NET.createGeneric('System.Collections.Generic.List',{'System.Double'}, expectedTime * 20);
    data.Final01 = 0;
    data.Final02 = 0;
    data.FinalVAS = 0;
end

