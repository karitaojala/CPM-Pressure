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

function AnalyzePressureVAS_CPM_exp_effect_plot

close all; clear all

plotIndividual = false; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

load(fullfile(path.code,'Experiment-01_ratings.mat'))

% ratings_allsubs = ratings_allsubs(1:40,:,:);
blocks_to_take = 0; % 0 all, 1 = first con vs. exp, 2 = last con vs. exp

no_subjects = size(ratings_allsubs,1);
no_blocks = size(ratings_allsubs,2);
no_trials_block = size(ratings_allsubs,3); 
no_trials_total = no_blocks*no_trials_block;
no_trials_cond = no_trials_block*2;

for sub = 1:size(ratings_allsubs,1)
    sub_blocks = conditions_allsubs_perblock(sub,:);
    exp_ratings(sub,:,:) = ratings_allsubs(sub,sub_blocks==1,:);
    control_ratings(sub,:,:) = ratings_allsubs(sub,sub_blocks==0,:);
end

if ~blocks_to_take
    ratings_allsubs_mean_exp = nanmean(reshape(exp_ratings,[no_subjects no_trials_cond]),2); % note that trial order for ratings is not retained here
    ratings_allsubs_mean_control = nanmean(reshape(control_ratings,[no_subjects no_trials_cond]),2); % but does not matter for overall mean
elseif blocks_to_take == 1
    ratings_allsubs_mean_exp = nanmean(squeeze(exp_ratings(:,1,:)),2); 
    ratings_allsubs_mean_control = nanmean(squeeze(control_ratings(:,1,:)),2); 
elseif blocks_to_take == 2
    ratings_allsubs_mean_exp = nanmean(squeeze(exp_ratings(:,2,:)),2); 
    ratings_allsubs_mean_control = nanmean(squeeze(control_ratings(:,2,:)),2); 
end

cpm_data = [ratings_allsubs_mean_control ratings_allsubs_mean_exp];
cpm_diff_data = ratings_allsubs_mean_control-ratings_allsubs_mean_exp;
% cpm_data_table = [ratings_allsubs_mean_control; ratings_allsubs_mean_exp; sbOrder; limb_order]';

% Control = ratings_allsubs_mean_control';
% Experimental = ratings_allsubs_mean_exp';
% SubjectID = subjects';
% cpm_table = table(SubjectID,Control,Experimental);
% datafile = fullfile(path.main,'data',project.name,project.phase,'cpm_data.csv');
% writetable(cpm_table,datafile)

% Calculate within-subject error bars
subavg = nanmean(cpm_data,2); % mean over conditions for each sub
grandavg = nanmean(subavg); % mean over subjects and conditions

newvalues = nan(size(cpm_data));

% normalization of subject values
for cond = 1:2
    meanremoved = cpm_data(:,cond)-subavg; % remove mean of conditions from each condition value for each sub
    newvalues(:,cond) = meanremoved+repmat(grandavg,[no_subjects 1 1]); % add grand average over subjects to the values where individual sub average was removed
    bardata(:,cond) = nanmean(newvalues(:,cond));
end

tvalue = tinv(1-0.025, no_subjects-1);
newvar = (cond/(cond-1))*nanvar(newvalues);
errorbars = squeeze(tvalue*(sqrt(newvar)./sqrt(no_subjects))); % calculate error bars according to Cousineau (2005) with Morey (2008) fix

% Averaged plot over subjects
figure('Position',[10 10 400 420]);

bardata = [mean(ratings_allsubs_mean_control); mean(ratings_allsubs_mean_exp)];
b = bar(bardata,'LineWidth',1);
b.FaceColor = 'flat';
b.CData(1,:) = [253, 216, 110]./255;
b.CData(2,:) = [239, 123, 5]./255;
hold on
xdata = repmat([1 2],size(cpm_data,1),1);
jitter_amount = 0.2;
jittered_xdata = xdata;% + (rand(size(xdata))-0.5)*(2*jitter_amount);

scattercolors = [252, 190, 14; 179, 92, 4]./255;

for sub = 1:no_subjects
    plot([jittered_xdata(sub,1),jittered_xdata(sub,2)],[cpm_data(sub,1),cpm_data(sub,2)],'k')
end

hold on

for cond = 1:2
    scatter(jittered_xdata(:,cond),cpm_data(:,cond),'filled','MarkerEdgeColor','k','MarkerFaceColor',scattercolors(cond,:));
end

hold on
errorbar(1:2,bardata',errorbars,'k','LineStyle','none','LineWidth',2,'CapSize',0)

ylim([0 100])
set(gca,'yTick',0:20:100,'FontSize',14)
ylabel('Test stimulus pain rating (VAS)','FontSize',14)
mylabels = {'No pain', 'Pain'; '(CON)', '(EXP)'};
ax = gca;
ax.XTick = [1 2];
ax.XTickLabel = '';
for cond = 1:2
    text(cond, ax.YLim(1),sprintf('%s\n%s', mylabels{:,cond}),...
        'horizontalalignment','center','verticalalignment','top','FontSize',14);
end
% ax.XLabel.String = sprintf('\n%s', 'Condition');
% set(gca,'xTickLabel', {sprintf('No pain\nCON'),sprintf('Pain\nEXP')},'FontSize',14)
box off
title({'Average CPM effect';['N = ' num2str(no_subjects)]},'FontSize',14)
%title(['Conditioned pain modulation / ' project.phase ' - N = ' num2str(numel(subjects))])

% [~,ttest_p,~,ttest_stats] = ttest(cpm_data(:,1),cpm_data(:,2),'Tail','right')
[~,ttest_p,~,ttest_stats] = ttest(cpm_data(:,1),cpm_data(:,2))
% addpath(cd,'..','Utils')
d = computeCohen_d(cpm_data(:,1),cpm_data(:,2),'paired')

end