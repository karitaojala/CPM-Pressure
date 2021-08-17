function P = LogMRITriggers(P)

[~,keyTimestamps] = KbQueueDump(P);

if ~isempty(regexp(version,'(2015b|2016a|2016b|2017b)','ONCE'))
    keyTimestamps = flip(keyTimestamps);
else
    keyTimestamps = keyTimestamps(end:-1:1);
end

for i = 1:length(keyTimestamps)
    P.mri.nTrigger = P.mri.nTrigger + 1; 
    P = PutLogFMRI(P, keyTimestamps(i), ['Trigger ' num2str(P.mri.nTrigger)]);
end

KbQueueFlush;

end

function P = PutLogFMRI(P, tEvent, eventInfo)

P.mri.fMRIEventCount                     = P.mri.fMRIEventCount + 1;
P.mri.fMRIEvents(P.mri.fMRIEventCount,1) = {P.mri.fMRIEventCount};
P.mri.fMRIEvents(P.mri.fMRIEventCount,2) = {tEvent};
P.mri.fMRIEvents(P.mri.fMRIEventCount,3) = {tEvent-P.mri.mriExpStartTime};
P.mri.fMRIEvents(P.mri.fMRIEventCount,4) = {eventInfo};

end