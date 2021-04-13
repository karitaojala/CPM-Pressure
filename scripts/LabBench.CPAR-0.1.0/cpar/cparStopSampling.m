function cparStopSampling(dev)
% cparStopSampling
%    cparStopSampling(dev) stop the sampling of data by the cpar device.
%
% Note:
%    This function must be called after the either the cparStart or
%    cparStartSampling function has been called.
%
% See also, cparStart, cparStartSampling
dev.StopUpdates()
