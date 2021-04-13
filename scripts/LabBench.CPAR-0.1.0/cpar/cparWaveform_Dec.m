function cparWaveform_Dec(func, dp, t)
% cparWaveform_Dec Add a decrement instruction to a waveform
%   cparWaveform_Dec(func, dp, t) creates a DEC instruction which results
%   in a linearly decreasing pressure with a rate of decrease of -[dp]
%   [kPa/s] for [t] seconds. Please note that [dp] must be a positive
%   number, and that the minus sign is added by the cpar device.
%
% Important note:
%   The duration [t] will be rounded down to nearest time period that is
%   possible for the cpar device to generate. As the cpar device has an
%   20Hz pressure update rate, this will be in multiples of 50ms.
%
% See also, cparWaveform_Step, cparWaveform_Inc, cparSetWaveform
    func.Instructions.Add(LabBench.Interface.Algometry.Instruction.Decrement(dp, t));
end

