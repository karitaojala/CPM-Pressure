function cparWaveform_Inc(func, dp, t)
% cparWaveform_Inc Add a increment instruction to a waveform
%   cparWaveform_Inc(func, dp, t) creates a INC instruction which results
%   in a linearly increasing pressure with a rate of increase of [dp]
%   [kPa/s] for [t] seconds.
%
% Important note:
%   The duration [t] will be rounded down to nearest time period that is
%   possible for the cpar device to generate. As the cpar device has an
%   20Hz pressure update rate, this will be in multiples of 50ms.
%
% See also, cparWaveform_Step, cparWaveform_Dec, cparSetWaveform
   func.Instructions.Add(LabBench.Interface.Algometry.Instruction.Increment(dp, t));
end

