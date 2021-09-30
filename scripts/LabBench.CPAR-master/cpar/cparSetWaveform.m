function cparSetWaveform(dev, channel01, channel02)
% cparSetWaveform Set pressure waveform programs
%   cparSetWaveform(dev, channel01, channel02) sets the pressure waveform
%   programs for pressure outlet 1 [channel01] and 2 [channel02].
%
% See also, cparCreateWaveform, cparStart

dev.Execute(channel01);
dev.Execute(channel02);