function [advice] = cparGetAdvice(dev)
% cparGetAdvice Get advice on why the device is not ready.
%   [advice] = cparGetAdvice(dev) get advice on why the cpar is not ready.
%   If the device is ready this function will display an empty string.
%
% See also, cparIsReady
advice = dev.Advice;