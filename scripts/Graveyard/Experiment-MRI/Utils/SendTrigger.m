function SendTrigger(P,address,port)
%% Set Marker for CED and BrainVision Recorder
% Send pulse to CED for SCR, thermode, digitimer
% [handle, errmsg] = IOPort('OpenSerialport',num2str(port)); % gives error
% msg on grahl laptop

if P.devices.trigger
    
    if strcmp(P.env.hostname,'isnb05cda5ba721') % use COM port for triggering
        value_string = string(port);
        fprintf(P.com.trigger,value_string);
        WaitSecs(P.com.lpt.CEDDuration);
        fprintf(P.com.trigger,0);
    else % parallel port triggering
        outp(address,port);
        WaitSecs(P.com.lpt.CEDDuration);
        outp(address,0);
        WaitSecs(P.com.lpt.CEDDuration);
    end
    
end

end