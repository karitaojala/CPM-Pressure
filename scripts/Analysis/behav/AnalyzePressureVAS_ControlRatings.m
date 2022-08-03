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

function AnalyzePressureVAS_ControlRatings

close all; clear all

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = pwd;%fullfile(path.main,'data',project.name,project.phase,'logs');

data = load('Experiment-01_controlratings.mat');

subjects = [1:6 8:19 21:27 29:31 33];%1:size(ratings_allsubs_b1,1);
ratings_allsubs_b1_mean = data.ratings_allsubs_b1_mean(subjects,:);
ratings_allsubs_b2_mean = data.ratings_allsubs_b2_mean(subjects,:);

rating_data = [ratings_allsubs_b1_mean ratings_allsubs_b2_mean];

% Calculate within-subject error bars
subavg = nanmean(rating_data,2); % mean over conditions for each sub
grandavg = nanmean(subavg); % mean over subjects and conditions

newvalues = nan(size(rating_data));

% normalization of subject values
for cond = 1:2
    meanremoved = rating_data(:,cond)-subavg; % remove mean of conditions from each condition value for each sub
    newvalues(:,cond) = meanremoved+repmat(grandavg,[numel(subjects) 1 1]); % add grand average over subjects to the values where individual sub average was removed
    bardata(:,cond) = nanmean(newvalues(:,cond));
end

tvalue = tinv(1-0.05, numel(subjects)-1);
newvar = (cond/(cond-1))*nanvar(newvalues);
errorbars = squeeze(tvalue*(sqrt(newvar)./sqrt(numel(subjects)))); % calculate error bars according to Cousineau (2005) with Morey (2008) fix
    
% Averaged plot over subjects
figure;

bardata = [mean(ratings_allsubs_b1_mean); mean(ratings_allsubs_b2_mean)];
b = bar(bardata,'LineWidth',1);  
b.FaceColor = 'flat';
b.CData(1,:) = [253, 216, 110]./255;
b.CData(2,:) = [239, 123, 5]./255;
hold on
xdata = repmat([1 2],size(rating_data,1),1);
jitter_amount = 0.2;
jittered_xdata = xdata;% + (rand(size(xdata))-0.5)*(2*jitter_amount);

scattercolors = [252, 190, 14; 179, 92, 4]./255;

for sub = 1:numel(subjects)
    plot([jittered_xdata(sub,1),jittered_xdata(sub,2)],[rating_data(sub,1),rating_data(sub,2)],'k')
end

hold on

for cond = 1:2
    scatter(jittered_xdata(:,cond),rating_data(:,cond),'filled','MarkerEdgeColor','k','MarkerFaceColor',scattercolors(cond,:));
end

hold on
errorbar(1:2,bardata',errorbars,'k','LineStyle','none','LineWidth',2,'CapSize',0)

ylim([0 100])
set(gca,'yTick',0:20:100)
ylabel('Test stimulus pain rating (VAS)','FontSize',14)
set(gca,'xTickLabel', {'Block 1','Block 2'},'FontSize',14)
box off
title({'Average No pain (CON) ratings', ['fMRI study (N = ' num2str(size(rating_data,1)) ')']},'FontSize',14)
%title(['Conditioned pain modulation / ' project.phase ' - N = ' num2str(numel(subjects))])

end