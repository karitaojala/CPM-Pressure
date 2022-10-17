function [startScan,physio,behav] = get_physio(baseDir, subid, run, startScan, NMaxScans, nDummyScans, runFirstTrial, bufferTimeEnd)
%get_physio Extract scanner pulses and physio signals for each run

samp_int = 0.01; % 10 ms equals 100 Hz

fprintf('Run %1d\n',run);

% read logfiles
[startScan, pulse, resp, scr, scansPhysioStart, ...
    scansRunStart, trialOnsets, VASOnsets, buttonPresses] = readlog_mat(subid, baseDir, run, samp_int, ...
    startScan, NMaxScans, nDummyScans, runFirstTrial, bufferTimeEnd);

% detrend  & smooth
pulse = spm_conv(spm_detrend(pulse),5);
resp = spm_conv(spm_detrend(resp),50);

% scanner pulses
scanner = scansRunStart';
d_p  = diff(scanner);
med  = median(d_p);  % robust against outliers
fprintf('-----Found %1.0f pulses estimated TR of %1.2f s\n',size(scanner,2),med.*samp_int);

physio = struct();
physio.pulse = pulse;
physio.resp = resp;
physio.scr = scr;
physio.scansPhysioStart = scansPhysioStart; % scanner pulse timings relative to physio file onset
physio.scansRunStart = scansRunStart; % scanner pulse timings relative to run onset

behav.trialOnsets = trialOnsets;
behav.VASOnsets = VASOnsets;
behav.buttonPresses = buttonPresses;

end

function [startScan, pulse, resp, scr, scansPhysioStart, scansRunStart, ...
    trialOnsets, VASOnsets, buttonPresses] = readlog_mat(subid, physioDir, ...
    run, samp_int, startScan, NMaxScans, nDummyScans, runFirstTrial, buffer)

% construct path to logfile
idStr = subid;
% runStr = sprintf('%d',run);
subFile = [idStr '.mat'];

physio_file = [physioDir filesep subFile];
physio_data = load(physio_file);

fnames = fieldnames(physio_data);

for fn = 1:numel(fnames)
    if regexp(cell2mat(fnames(fn)),'Ch1') % PULSE
        Ch1Name = fnames(fn); 
    elseif regexp(cell2mat(fnames(fn)),'Ch2') % RESPIRATION
        Ch2Name = fnames(fn); 
    elseif regexp(cell2mat(fnames(fn)),'Ch3') % SKIN CONDUCTANCE
        Ch3Name = fnames(fn);
    elseif regexp(cell2mat(fnames(fn)),'Ch4') % TONIC STIMULUS TRIAL ONSETS
        Ch4Name = fnames(fn);
    elseif regexp(cell2mat(fnames(fn)),'Ch5') % VAS ONSETS
        Ch5Name = fnames(fn);
    elseif regexp(cell2mat(fnames(fn)),'Ch6') % BUTTON PRESSES
        Ch6Name = fnames(fn);
    elseif regexp(cell2mat(fnames(fn)),'Ch7') % SCANNER PULSE/TRIGGER
        Ch7Name = fnames(fn); 
    end
end

% retrieve trial onsets, VAS onsets, button presses and scanner triggers
trialOnsets   = physio_data.(cell2mat(Ch4Name)).times; 
VASOnsets     = physio_data.(cell2mat(Ch5Name)).times; 
buttonPresses = physio_data.(cell2mat(Ch6Name)).times; 
scansAll      = physio_data.(cell2mat(Ch7Name)).times; % loads the seconds of all scans that sent triggers

% visually check trial onsets, scanner pulses in relation to each other
check_scannerpulses(trialOnsets,scansAll)

% remove false trial starts for a few early subjects (run restarted due to
% a problem)
if strcmp(idStr,'sub004')
    trialOnsets(8) = [];
elseif strcmp(idStr,'sub008')
    trialOnsets(6) = [];
elseif strcmp(idStr,'sub009')
    trialOnsets([4 11]) = [];
end

% find scans only for the current run
trial_start = trialOnsets(runFirstTrial);
run_start = scansAll(startScan);
if abs(trial_start-run_start) > 7 % if too large gap between trial start and scanner run start
    % find true run start (can only be later as the only possible reason for extra scans is
    % a restart of a run)
    fprintf('-----Run restarted, need to find true run start!\n');
    %run_ends = scansAll(diff(scansAll) > 2*TR);
    %run_start = run_ends > trial_start-20;
    for scan = startScan+1:numel(scansAll)
        if trial_start-scansAll(scan) < 15
            startScan_true = scan+nDummyScans;
            run_start = scansAll(startScan_true);
            fprintf('-----Real run start found at %1.1f s\n',run_start);
            break
        end
    end
    startScan = startScan_true;
end

% apply scan indices for this run
scanIndices = startScan:(startScan-1)+NMaxScans;
scans = scansAll(scanIndices); 

close all % close opened figures

% now retrieve all heart rate data
pulse   = physio_data.(cell2mat(Ch1Name)).values;
dt      = physio_data.(cell2mat(Ch1Name)).interval;
pulsID  = physio_data.(cell2mat(Ch1Name)).title;
if ~strcmp(pulsID,'PULS'); error('Expect channel 1 title to be "PULS"!'); end
index   = [round(scans(1)./dt) round(scans(end)./dt+buffer/dt)]; % consider adding +TR/dt as additional buffer
pulse   = pulse(index(1):index(2),:);

% now retrieve all respiration data
resp    = physio_data.(cell2mat(Ch2Name)).values;
dt      = physio_data.(cell2mat(Ch2Name)).interval;
respID  = physio_data.(cell2mat(Ch2Name)).title;
if ~strcmp(respID,'Resp'); error('Expect channel 2 title to be "Resp"'); end
index = [round(scans(1)./dt) round(scans(end)./dt+buffer/dt)]; % consider adding +TR/dt as additional buffer
resp  = resp(index(1):index(2),:);

% now retrieve all SCR data
scr     = physio_data.(cell2mat(Ch3Name)).values;
dt      = physio_data.(cell2mat(Ch3Name)).interval;
respID  = physio_data.(cell2mat(Ch3Name)).title;
if ~strcmp(respID,'SCR'); error('Expect channel 2 title to be "SCR"'); end
index = [round(scans(1)./dt) round(scans(end)./dt+buffer/dt)]; % consider adding +TR/dt as additional buffer
scr  = scr(index(1):index(2),:);

% retrieve VAS onsets and button presses within the run
if run == 1
    VASOnsets = VASOnsets(1); % only 1 VAS onset for first and last run (tonic rating)
elseif run == 6
    VASOnsets = VASOnsets(end);
else
    VASOnsets = VASOnsets(VASOnsets > scansAll(scanIndices(1)) & VASOnsets < scansAll(scanIndices(end)));
end
buttonPresses = buttonPresses(buttonPresses > scansAll(scanIndices(1)) & buttonPresses < scansAll(scanIndices(end)));

% finally adjust dt for scans (is in s, needs to be at 100Hz)
scansPhysioStart = 1 + round(scans / samp_int);
scansRunStart = 1 + round((scans - scans(1)) / samp_int);
pulse = interp1(pulse,1:(samp_int/dt):size(pulse,1))';
resp = interp1(resp,1:(samp_int/dt):size(resp,1))';
scr = interp1(scr,1:(samp_int/dt):size(scr,1))';

end