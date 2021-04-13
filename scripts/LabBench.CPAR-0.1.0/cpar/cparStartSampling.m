function cparStartSampling(dev)
% cparStartSampling Start sampling of data
%   cparStartSampling(dev) explicitly start sampling of data. Please note,
%   do not call this function if sampling has implicitly started by
%   starting a pressure stimulation with cparStart, as the data buffer in
%   the cpar device is cleared when this function is called. Consequently,
%   if this function is called after cparStart has been called, then data
%   related to the pressure stimulation will be lost.
%
% See also, cparStopSampling, cparGetData
    dev.StartUpdates()
end

