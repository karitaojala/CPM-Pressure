function P = LogMRITriggers(P,run)

[~,keyTimestamps] = KbQueueDump(P);

if ~isempty(regexp(version,'(2015b|2016a|2016b|2017b)','ONCE'))
    keyTimestamps = flip(keyTimestamps);
else
    keyTimestamps = keyTimestamps(end:-1:1);
end

for i = 1:length(keyTimestamps)
    P.mri.nTrigger = P.mri.nTrigger + 1; 
    P = PutLogFMRI(P, keyTimestamps(i), ['Trigger ' num2str(P.mri.nTrigger)], run);
end

KbQueueFlush;

end

function P = PutLogFMRI(P, tEvent, eventInfo, run)

P.mri.fMRIEventCount(run)                                               = P.mri.fMRIEventCount(run) + 1;
P.mri.fMRIEvents(run).eventCount(P.mri.fMRIEventCount(run))             = {P.mri.fMRIEventCount(run)};
P.mri.fMRIEvents(run).timeEvent(P.mri.fMRIEventCount(run))              = {tEvent};
P.mri.fMRIEvents(run).timeEventFromStartExp(P.mri.fMRIEventCount(run))  = {tEvent-P.mri.mriExpStartTime};
P.mri.fMRIEvents(run).timeEventFromStartRun(P.mri.fMRIEventCount(run))  = {tEvent-P.mri.mriRunStartTime(run)};
P.mri.fMRIEvents(run).eventInfo(P.mri.fMRIEventCount(run))              = {eventInfo};

end