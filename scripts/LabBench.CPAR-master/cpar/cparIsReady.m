function [ready] = cparIsReady(dev)
% cparIsReady Is the device ready to perform a pressure stimulation
%   [ready] = cparIsReady(dev) checks if a cpar device [dev] is ready to
%   perform a pressure stimulation.
%
% See also, cparGetAdvice

if dev.Ready
    ready = 1;
else
    ready = 0;
end