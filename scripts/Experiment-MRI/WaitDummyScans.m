function WaitDummyScans(P)

%% Wait for MRI dummy scans
fprintf('Will wait for %i dummy pulses...\n',P.mri.dummyScans);
if P.mri.dummyScans > 0
    secs  = NaN(1,P.mri.dummyScans);
    pulse = 0;
    dummy = []; %#ok<NASGU>
    while pulse < P.mri.dummyScans % Listening loop
        dummy         = KbTriggerWait(P.keys.trigger,P.devices.input);
        pulse         = pulse + 1;
        secs(pulse)   = dummy; % formerly secs(pulse+1)   = dummy;
        fprintf('Waiting for dummy scan %d\n',pulse);
        % add log functions here
    end
else
    secs = GetSecs; %#ok<NASGU>
end

% UNC: Listening Post Theta
KbQueueCreate(P.devices.input,P.keys.triggerKeyList); % 2016-07-19 Trigger listening method; initialize queue
KbQueueStart; % 2016-07-19 Trigger listening method; start queue (will be flushed before the respective waiting loops)

end