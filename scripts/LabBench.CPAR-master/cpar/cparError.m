function [err] = cparError(dev)
% cparError Retrive error information 
%   [err] = cparError(dev) return the error state of the cpar device.
%
% Note:
%    The CPAR device will only return an error if a connection cannot be
%    established with the device. This is not the same as the device being
%    ready to perform a pressure stimulation.
%
% See also, cparIsRunning, cparIsReady, cparGetAdvice

if dev.Error
    err = 1;
else
    err = 0;
end