function plot_onsets

% To confirm that timings can be retrieved and match

% CPAR data start in relation to tonic pressure start
% behav data start in relation to physio data recording onset
% physio scanner

% Outcome: take trial onsets from real CPAR pressure and VAS onsets + trial
% start relation from behav file

clear all; close all;

base_dir    = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\';
physiodir   = fullfile(base_dir,'physio');

all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];

cparSR = 20;
physioSR = 100;
TR = 1.991;
% 
% figpos = [200,615,600,500; 815,615,600,500; ...
%     200,35,600,500;  815,35,600,500];

for sub = [5 12 15 18 29]%1:numel(all_subs)
    
    name = sprintf('sub%03d',all_subs(sub));
    fprintf([name '\n']);
    
    logdir = fullfile(base_dir,'logs',name,'pain');
    load(fullfile(logdir,['parameters_' name '.mat']));
    load(fullfile(logdir,[name '_CPAR_CPM.mat']));
    
    fig = figure('Position',[100,400,900,700]);
    sgtitle(name)
    
    for run = 1:4
        
        subplot(4,1,run)
        
        load(fullfile(physiodir,name,[name '-run' num2str(run+1) '-behav.mat']))
        load(fullfile(physiodir,name,[name '-run' num2str(run+1) '-physio.mat']))
        
        trialNo = [(run-1)+run run+run]+1;
        trialStim = [1:9; 10:18];
        
        scannerPulsesvsPhysioStart = physio.scansPhysioStart/physioSR;
        scannerPulsesvsTrialStart = scannerPulsesvsPhysioStart-behav.trialOnsets(trialNo(1));
        scannerPulsesvsTrialStart = scannerPulsesvsTrialStart*cparSR;
        
        tonicPressure = NaN(1,500*cparSR); % 500 seconds
        phasicPressure = NaN(1,500*cparSR); % 500 seconds
        
        firstTonicStart = P.time.tonicStimStart(run,1);
        
        for trial = 1:2
            
            tonicStart = P.time.tonicStimStart(run,trial);
            %phasicOnsetsVsTrialStart = (phasicVASOnsetsVsTrialStart-5*cparSR); % deduct 5 seconds of pressure stimulus / NOT PRECISE

            if tonicStart == 0 % no data
                continue;
            end
            
            tonicStartInd = round((tonicStart-firstTonicStart)*cparSR+1);
            tonicEndInd = tonicStartInd+numel(cparData(run).data(trial).Pressure01);
            tonicPressure(tonicStartInd:tonicEndInd-1) = cparData(run).data(trial).Pressure01;
            
            phasicPressure(tonicStartInd:tonicEndInd-1) = cparData(run).data(trial).Pressure02;
            if max(phasicPressure) < 50
                realPhasicOnsets = find(diff(phasicPressure)>(0.4*max(phasicPressure))); % does this work ok -> seems to
                if numel(realPhasicOnsets) < 9
                    realPhasicOnsets = find(diff(phasicPressure)>(0.35*max(phasicPressure)));
                elseif numel(realPhasicOnsets) > 9
                    realPhasicOnsets = find(diff(phasicPressure)>(0.45*max(phasicPressure)));
                end
            else
                realPhasicOnsets = find(diff(phasicPressure)>25);
            end
            
            %             %tonicStartvsTrialStart = P.time.tonicStimStart(run,trial)-P.time.trialStart(run,trial);
            %             if trial == 1
            %                 firstScan = 1;
            %                 lastScan = firstScan + ceil(220/TR);
            %                 scannerPulsesvsTrialStartRun = scannerPulsesvsTrialStart(firstScan:lastScan);
            %             else
            %                 firstScan = firstScan + ceil(220/TR) + 1;
            %                 lastScan = firstScan + ceil(220/TR);
            %                 scannerPulsesvsTrialStartRun = scannerPulsesvsTrialStart(firstScan:lastScan);
            %                 %scannerPulsesvsTrialStartRun = scannerPulsesvsTrialStartRun-scannerPulsesvsTrialStartRun(firstScan-1);
            %             end
            
        end
        
        phasicOnsets = P.time.phasicStimVASStart(run,:,:);
        phasicOnsets = sort(phasicOnsets(:))';
        phasicVASOnsetsVsTrialStart = phasicOnsets-P.time.tonicStimStart(run,1); % VAS onset recorded for each phasic stimulus
        phasicVASOnsetsVsTrialStart = phasicVASOnsetsVsTrialStart*cparSR;
        
        phasicVASOnsetsvsPhysioStart = behav.VASOnsets'-behav.trialOnsets(trialNo(1));
        phasicVASOnsetsvsPhysioStart = phasicVASOnsetsvsPhysioStart*cparSR;
            
        plot(tonicPressure,'k','LineWidth',1.5)
        hold on
        plot(phasicPressure,'b','LineWidth',1.5)
        
        for l = 1:numel(realPhasicOnsets)
            xline(realPhasicOnsets(l),'r','LineWidth',1.5)
        end
        
        for l = 1:numel(phasicVASOnsetsVsTrialStart)
            xline(phasicVASOnsetsVsTrialStart(l),'m','LineWidth',1.5)
        end
        
        for l = 1:numel(phasicVASOnsetsvsPhysioStart)
            xline(phasicVASOnsetsvsPhysioStart(l),'g','LineWidth',1.5)
        end
        
        for l = 1:numel(scannerPulsesvsTrialStart)
            xline(scannerPulsesvsTrialStart(l),'-c','LineWidth',1)
        end
        
        title(['Run ' num2str(run+1)])
        
        ylim([0 100])
        ylabel('Pressure (kPa)')
        
        xlim([-1000 10000])
        xticks(-1000:1000:10000)
        xticklabels({'-50','0','50','100','150','200','250','300','350','400','450','500'})
        %xlim([0 200])
        xlabel('Time (s)')
        
    end
    
    savefig(fig,fullfile(logdir,[name '-onsets-fig.fig']),'compact')
    
end

end