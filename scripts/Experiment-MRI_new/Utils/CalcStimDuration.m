function [stimDuration] = CalcStimDuration(P,pressure,sStimPlateau)
%% Returns a vector with riseTime, P.presentation.sStimPlateau and fallTime for the target stimulus

%diff=abs(temp-P.pain.bT);
%riseTime=diff/P.pain.rS;
riseTime = pressure/P.pain.preExposure.riseSpeed;
%fallTime=diff/P.pain.fS;
%stimDuration=[riseTime sStimPlateau fallTime];
stimDuration = [riseTime sStimPlateau];% only rise time

end