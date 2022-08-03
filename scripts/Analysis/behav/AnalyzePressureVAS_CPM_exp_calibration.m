%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Analysis of CPAR cuff algometer online VAS rating
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Changelog
%
% Version: 1.0
% Author: Karita Ojala, k.ojala@uke.de, University Medical Center Hamburg-Eppendorf
% Date: 2021-05-12
%
% Version notes
% 1.0

function AnalyzePressureVAS_CPM_exp_calibration

close all; clear all

plotIndividual = false; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

subjects = 1:11;

for sub = 1:numel(subjects)
    
    clear ratings_blocks pressure
    
    subID = ['sub' sprintf('%03d',subjects(sub))];
    
    path.sub = fullfile(path.data,subID,'pain');
    
    path.paramfile = fullfile(path.sub,['parameters_' subID '.mat']);
    param = load(path.paramfile,'P');
    param = param.P;
    
    %     blocks_sub = param.pain.CPM.tonicStim.condition;
    
    row_no = 1;
    
    path.datafile =  fullfile(path.sub,[subID '_VAS_calibration.mat']);
    
    data = load(path.datafile,'VAS');
    data = data.VAS;
    
    tonicArm = 1;%param.pain.CPM.tonicStim.cuff;
    phasicArm = 2;%param.pain.CPM.phasicStim.cuff;
    
    if isfield(param.calibration,'results')
        tonicCalibData = param.calibration.results(tonicArm).fitData;
        phasicCalibData = param.calibration.results(phasicArm).fitData;
        
        interceptLinearTonic(:,sub) = tonicCalibData.interceptLinear;
        slopeLinearTonic(:,sub) = tonicCalibData.slopeLinear;
        predpressureLinearTonic(:,sub) = tonicCalibData.predPressureLinear;
        
        interceptLinearPhasic(:,sub) = phasicCalibData.interceptLinear;
        slopeLinearPhasic(:,sub) = phasicCalibData.slopeLinear;
        predpressureLinearPhasic(:,sub) = phasicCalibData.predPressureLinear;
        
    else
        fprintf([subID ' -- No field: calibration results!\n'])
        interceptLinearTonic(:,sub) = NaN;
        slopeLinearTonic(:,sub) = NaN;
        predpressureLinearTonic(:,sub) = NaN;
        
        interceptLinearPhasic(:,sub) = NaN;
        slopeLinearPhasic(:,sub) = NaN;
        predpressureLinearPhasic(:,sub) = NaN;
    end
    
    tonicStimPeak(:,sub) = param.pain.CPM.experimentPressure.tonicStimPeak;
    tonicStimTrough(:,sub) = param.pain.CPM.experimentPressure.tonicStimTrough;
    phasicStim(:,sub) = param.pain.CPM.experimentPressure.phasicStim;
    
end    
    
interceptLinearTonic = interceptLinearTonic';
slopeLinearTonic = slopeLinearTonic';
interceptLinearPhasic = interceptLinearPhasic';
slopeLinearPhasic = slopeLinearPhasic';

tonicStimPeak = tonicStimPeak';
tonicStimTrough = tonicStimTrough';
phasicStim = phasicStim';

% Averaged plot over subjects
figure;

bardata = [mean(ratings_allsubs_mean_control); mean(ratings_allsubs_mean_exp)];
b = bar(bardata,'LineWidth',1);  
b.FaceColor = 'flat';
b.CData(1,:) = [253, 216, 110]./255;
b.CData(2,:) = [239, 123, 5]./255;
hold on
xdata = repmat([1 2],size(cpm_data,1),1);
jitter_amount = 0.2;
jittered_xdata = xdata + (rand(size(xdata))-0.5)*(2*jitter_amount);

scattercolors = [252, 190, 14; 179, 92, 4]./255;

for cond = 1:2
    scatter(jittered_xdata(:,cond),cpm_data(:,cond),'filled','MarkerEdgeColor','k','MarkerFaceColor',scattercolors(cond,:));
end

hold on
errorbar(1:2,bardata',errorbars,'k','LineStyle','none','LineWidth',2,'CapSize',0)
        
ylim([0 100])
set(gca,'yTick',0:20:100)
ylabel('Test stimulus pain rating (VAS)','FontSize',14)
set(gca,'xTickLabel', {'Control','Experimental'},'FontSize',14)
box off
title('Average CPM effect','FontSize',14)
%title(['Conditioned pain modulation / ' project.phase ' - N = ' num2str(numel(subjects))])

[~,ttest_p,~,ttest_stats] = ttest(cpm_data(:,1),cpm_data(:,2),'Tail','right')
% addpath(cd,'..','Utils')
d = computeCohen_d(cpm_data(:,1),cpm_data(:,2),'paired')

end