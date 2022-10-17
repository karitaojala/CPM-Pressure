function check_scannerpulses(trialOnsets,scans)
%Check scanner pulses and trial onsets

figure;

for pulse = 1:numel(scans)
    line([scans(pulse) scans(pulse)],[0 1],'Color',[128 128 128]./255)
    hold on
end

for trial = 1:numel(trialOnsets)
    line([trialOnsets(trial) trialOnsets(trial)],[0 1],'Color','r')
    hold on
end

end