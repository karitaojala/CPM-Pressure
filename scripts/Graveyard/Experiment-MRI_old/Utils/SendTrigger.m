function SendTrigger(P,address,port)
%% Set Marker for CED and BrainVision Recorder
% Send pulse to CED for SCR, thermode, digitimer
% [handle, errmsg] = IOPort('OpenSerialport',num2str(port)); % gives error
% msg on grahl laptop
if P.devices.trigger
    outp(address,port);
    WaitSecs(P.com.lpt.CEDDuration);
    outp(address,0);
    WaitSecs(P.com.lpt.CEDDuration);
end

end