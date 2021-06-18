function Step3_AnalyzeEDA

path.logdata = 'C:\Data\EIH-Expectation\calibration\EIH-Expectation-01\Pilot-01\logs';
data = load('C:\Data\EIH-Expectation\data\eda\aggregateData\PressureTest_tonic_SCR_Raw.mat');
data = data.allData;

sub_SCR = NaN(2000,21);
sList = [3 5:8];
SCR = data.RAWDATA;
diff_SCR = data.DiffMaxMinEDA;
max_SCR = data.MaxEDA;
trials = 21;
pressureStep = 3;

for sub = 1:size(SCR,1)

    subID = ['sub' sprintf('%03d',sList(sub))];
    
    path.sub = fullfile(path.logdata,subID,'pain');
    path.datafile =  fullfile(path.sub,[subID '_painRatingData.mat']);
    logFile = load(path.datafile);
    
    for trial = 1:trials
        dataLength = numel(SCR{sub,trial});
        if dataLength > 2000
            sub_SCR(1:2000,trial) = SCR{sub,trial}(1:2000);
        else
            sub_SCR(1:dataLength,trial) = SCR{sub,trial};
        end
        subEvents.pressure(trial) = ceil(logFile.cparData(trial).data.t01(end-1));
        subEvents.pressurelevel(trial) = (subEvents.pressure(1)-subEvents.pressure(trial))/pressureStep;
        subEvents.trial(trial) = trial;
        %subEvents.block(trial) = blocks(trial);
    end
    
    pressureLevels = unique(subEvents.pressurelevel);
    
    for cond = 1:7
       pressureLevel = pressureLevels(cond);
       submean_SCR(sub,cond,:) = nanmean(sub_SCR(:,subEvents.pressurelevel==pressureLevel),2); 
       submean_SCR_diff(sub,cond) = nanmean(diff_SCR(sub,subEvents.pressurelevel==pressureLevel)); 
       submean_SCR_max(sub,cond) = nanmean(max_SCR(sub,subEvents.pressurelevel==pressureLevel)); 
    end
    
end

% Standardize data
% mean_SCR = nanmean(submean_SCR(:));
%std_SCR = nanstd(submean_SCR(:));
%submean_SCR = submean_SCR./mean_SCR;
%submean_SCR = normalize(submean_SCR);
mean_SCR_diff = nanmean(submean_SCR_diff(:));
submean_SCR_diff = submean_SCR_diff./mean_SCR_diff;

mean_SCR_max = nanmean(submean_SCR_max(:));
submean_SCR_max = submean_SCR_max./mean_SCR_max;

diff_SCR_mean = nanmean(submean_SCR_diff);
max_SCR_mean = nanmean(submean_SCR_max);

% condmean_SCR_standard = squeeze(nanmean(submean_SCR))';
% figure
% plot(condmean_SCR_standard)
figure
bar(diff_SCR_mean)
xticklabels({'-9 kPa' '-6 kPa' '-3 kPa' '0' '+3 kPa' '+6 kPa' '+9 kPa'})
title('Standardized max-min SCR')

figure
bar(max_SCR_mean)
xticklabels({'-9 kPa' '-6 kPa' '-3 kPa' '0' '+3 kPa' '+6 kPa' '+9 kPa'})
title('Standardized max SCR')

end