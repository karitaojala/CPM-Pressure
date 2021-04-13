function [running] = cparIsRunning(dev)
% cparIsRunning Check if a pressure stimulation is running
%   [running] = cparIsRunning(dev) returns true if a pressure stimulation
%   is current being performed by the cpar device.
%
% See also, cparError
   running = dev.State == LabBench.Interface.Algometry.AlgometerState.STATE_STIMULATING;
end

