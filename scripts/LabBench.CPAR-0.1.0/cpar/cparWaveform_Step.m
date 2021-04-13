function cparWaveform_Step(waveform, p, t)
% cparWaveform_Step Add a step instruction to a waveform
%   cparWaveform_Step(func, p, t) creates a STEP instruction which results
%   in a pressure [p] being generated for [t] seconds. It is possible to
%   set [t] to zero, in that case the cpar device will change the pressure 
%   to [p] and execute the next instruction in the same instruction cycle.
%   This can be used to create a ramp with an offset pressure.
%
% Important note:
%   The duration [t] will be rounded down to nearest time period that is
%   possible for the cpar device to generate. As the cpar device has an
%   20Hz pressure update rate, this will be in multiples of 50ms.
%
% See also, cparWaveform_Inc, cparWaveform_Dec, cparSetWaveform
   waveform.Instructions.Add(LabBench.Interface.Algometry.Instruction.Step(p, t));
end