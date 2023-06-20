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

function AnalyzePressureVAS_CPM_exp_effect_bgvariables

close all; clear all

plotIndividual = false; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

load(fullfile(path.code,'Experiment-01_ratings.mat'))
load(fullfile(path.code,'Experiment-01_backgroundvar.mat'))
load(fullfile(path.code,'Experiment-01_conditions.mat'))

backgroundvar = backgroundvar(1:end-1,:);

ratings_allsubs = ratings_allsubs(1:end-1,:,:); % last subject 50 excluded
blocks_to_take = 0; % 0 all, 1 = first con vs. exp, 2 = last con vs. exp

no_subjects = size(ratings_allsubs,1);
no_blocks = size(ratings_allsubs,2);
no_trials_block = size(ratings_allsubs,3); 
no_trials_total = no_blocks*no_trials_block;
no_trials_cond = no_trials_block*2;

for row = 1:size(ratings_allsubs,1)
    sub_blocks = conditions_allsubs_perblock(row,:);
    exp_ratings(row,:,:) = ratings_allsubs(row,sub_blocks==1,:);
    control_ratings(row,:,:) = ratings_allsubs(row,sub_blocks==0,:);
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

% exp_1stblock_mean = nanmean(exp_ratings(:,1,:),3);
% exp_2ndblock_mean = nanmean(exp_ratings(:,2,:),3);
% 
% control_1stblock_mean = nanmean(control_ratings(:,1,:),3);
% control_2ndblock_mean = nanmean(control_ratings(:,2,:),3);
% 
% exp_1stblock_vs_2ndblock = exp_2ndblock_mean-control_1stblock_mean;
% control_1stblock_vs_2ndblock = control_2ndblock_mean-control_1stblock_mean; % mean diff from 1st block to 2nd block

cpm_data = [ratings_allsubs_mean_control ratings_allsubs_mean_exp];
cpm_diff_data = ratings_allsubs_mean_control-ratings_allsubs_mean_exp;
% cpm_data = [control_1stblock_vs_2ndblock exp_1stblock_vs_2ndblock];
% cpm_diff_data = control_1stblock_vs_2ndblock-exp_1stblock_vs_2ndblock; % diff per subj for CON-EXP

Subject = [1:2 4:13 15:18 20:27 29:34 37:40 42:49]';
RatedCPM = cpm_diff_data;
VerbalCPM = backgroundvar.SubjectiveCPM;
cpmtable = table(Subject,RatedCPM,VerbalCPM);
%writetable(cpmtable,'CPM_rated_reported.csv')
% writetable(cpmtable,'CPM_rated_reported_block1vs2.csv')
% Scatterplot CPM effect magnitude vs. backgroundvar

%% Subjective CPM
cpm_diff_pos = cpm_diff_data(backgroundvar.SubjectiveCPM == 1);
cpm_diff_zero = cpm_diff_data(backgroundvar.SubjectiveCPM == 0);
cpm_diff_neg = cpm_diff_data(backgroundvar.SubjectiveCPM == -1);

aligned_resp = sum(cpm_diff_pos > 5) + sum(cpm_diff_neg < -5) + sum(abs(cpm_diff_zero) < 5);
conflicting_resp = sum(cpm_diff_pos < 5) + sum(cpm_diff_neg > -5) + sum(abs(cpm_diff_zero) > 5);

% Calculate between-subject error bars (SEM)
sem_pos = std(cpm_diff_pos)/sqrt(numel(cpm_diff_pos));
sem_zero = std(cpm_diff_zero)/sqrt(numel(cpm_diff_zero));
sem_neg = std(cpm_diff_neg)/sqrt(numel(cpm_diff_neg));
errorbars = [sem_pos sem_zero sem_neg];

clear bardata
bardata = [mean(cpm_diff_pos); mean(cpm_diff_zero); mean(cpm_diff_neg)];

figure('Position',[10 10 450 400]);

b = bar(bardata,'LineWidth',1);
b.FaceColor = 'flat';
b.CData(1,:) = [0, 102, 204]./255;%[253, 216, 110]./255;
b.CData(2,:) = [128, 128, 128]./255;
b.CData(3,:) = [255, 77, 77]./255;%[239, 123, 5]./255;
hold on

errorbar(1:3,bardata',errorbars,'k','LineStyle','none','LineWidth',2,'CapSize',0)

ylim([-10 10])
set(gca,'xTickLabel', {sprintf('Hypoalgesia'),sprintf('No difference'),sprintf('Hyperalgesia')},'FontSize',10)
%set(gca,'yAxisLabel', {'Rated CPM magnitude'},'FontSize',14)
ylabel('Rated CPM magnitude','FontSize',14)
set(gca,'yTick',-10:2:10,'FontSize',14)
box off
title({'Rated vs. verbally reported CPM'},'FontSize',14)
%;['N = ' num2str(numel(cpm_diff_pos)) ' - ' ...
%    num2str(numel(cpm_diff_zero)) ' - ' num2str(numel(cpm_diff_neg))]

[~,ttest_p,~,ttest_stats] = ttest2(cpm_diff_pos,cpm_diff_neg,'tail','right','Vartype','unequal')
% % addpath(cd,'..','Utils')
% d = computeCohen_d(cpm_diff_tonic,cpm_diff_phasic)

%% Calibration order (tonic first vs. phasic first)
% cpm_diff_tonic = cpm_diff_data(backgroundvar.Calibrationorder == 1);
% cpm_diff_phasic = cpm_diff_data(backgroundvar.Calibrationorder == 2);
% 
% clear bardata
% bardata = [mean(cpm_diff_tonic); mean(cpm_diff_phasic)];
% 
% figure('Position',[10 10 400 420]);
% 
% b = bar(bardata,'LineWidth',1);
% b.FaceColor = 'flat';
% b.CData(1,:) = [30,129,176]./255;%[253, 216, 110]./255;
% b.CData(2,:) = [226,135,67]./255;%[239, 123, 5]./255;
% hold on
% 
% ylim([0 10])
% set(gca,'yTick',0:2:10,'FontSize',14)
% ylabel('CPM magnitude CON-EXP (VAS)','FontSize',14)
% set(gca,'xTickLabel', {sprintf('Tonic first'),sprintf('Phasic First')},'FontSize',14)
% box off
% title({'Average CPM vs. calibration order';['N = ' num2str(numel(cpm_diff_tonic)) ' - ' ...
%     num2str(numel(cpm_diff_phasic))]},'FontSize',14)
% 
% [~,ttest_p,~,ttest_stats] = ttest2(cpm_diff_tonic,cpm_diff_phasic)
% % addpath(cd,'..','Utils')
% d = computeCohen_d(cpm_diff_tonic,cpm_diff_phasic)

%% Block orders (control vs. experimental block first)
% cpm_diff_b1_con = cpm_diff_data(conditions.Block1 == 0);
% cpm_diff_b1_exp = cpm_diff_data(conditions.Block1 == 1);
% 
% clear bardata
% bardata = [mean(cpm_diff_b1_con); mean(cpm_diff_b1_exp)];
% 
% % Calculate between-subject error bars (SEM)
% sem_b1_con = std(cpm_diff_b1_con)/sqrt(numel(cpm_diff_b1_con));
% sem_b1_exp = std(cpm_diff_b1_exp)/sqrt(numel(cpm_diff_b1_exp));
% errorbars = [sem_b1_con sem_b1_exp];
% 
% figure('Position',[10 10 400 420]);
% 
% b = bar(bardata,'LineWidth',1);
% b.FaceColor = 'flat';
% b.CData(1,:) = [30,129,176]./255;%[253, 216, 110]./255;
% b.CData(2,:) = [226,135,67]./255;%[239, 123, 5]./255;
% hold on
% 
% errorbar(1:2,bardata',errorbars,'k','LineStyle','none','LineWidth',2,'CapSize',0)
% 
% ylim([-4 10])
% set(gca,'yTick',-4:2:10,'FontSize',14)
% ylabel('CPM magnitude CON-EXP (VAS)','FontSize',14)
% set(gca,'xTickLabel', {sprintf('CON first half'),sprintf('EXP first')},'FontSize',14)
% box off
% title({'Average CPM vs. block order';['N = ' num2str(numel(cpm_diff_b1_con)) ' - ' ...
%     num2str(numel(cpm_diff_b1_exp))]},'FontSize',14)
% 
% [~,ttest_p,~,ttest_stats] = ttest2(cpm_diff_b1_con,cpm_diff_b1_exp)
% % addpath(cd,'..','Utils')
% d = computeCohen_d(cpm_diff_b1_con,cpm_diff_b1_exp)

%% Sex (female vs. male)
% figure('Position',[10 10 400 420]);
% 
% cpm_diff_f = cpm_diff_data(backgroundvar.Sex == 'F');
% cpm_diff_m = cpm_diff_data(backgroundvar.Sex == 'M');
% 
% bardata = [mean(cpm_diff_f); mean(cpm_diff_m)];
% b = bar(bardata,'LineWidth',1);
% b.FaceColor = 'flat';
% b.CData(1,:) = [30,129,176]./255;%[253, 216, 110]./255;
% b.CData(2,:) = [226,135,67]./255;%[239, 123, 5]./255;
% 
% ylim([0 10])
% set(gca,'yTick',0:2:10,'FontSize',14)
% ylabel('CPM magnitude CON-EXP (VAS)','FontSize',14)
% set(gca,'xTickLabel', {sprintf('Female'),sprintf('Male')},'FontSize',14)
% box off
% title({'Average CPM vs. sex';['N = ' num2str(numel(cpm_diff_f)) ' - ' ...
%     num2str(numel(cpm_diff_m))]},'FontSize',14)
% 
% [~,ttest_p,~,ttest_stats] = ttest2(cpm_diff_f,cpm_diff_m)
% % addpath(cd,'..','Utils')
% d = computeCohen_d(cpm_diff_f,cpm_diff_m)

%% Scatterplot correlations
% scattercolors = [30,129,176; 226,135,67]./255;
% 
% % Phasic pressure
% % xvar = phasicStimPressures;
% % xvarlabel = 'Test stimulus pressure (kPa)';
% % xvartitle = 'Test stimulus pressure';
% % 
% % xmin = 20;
% % xmax = 100;
% 
% % Age
% % xvar = backgroundvar.Age;
% % xvarlabel = 'Age (years)';
% % xvartitle = 'Age';
% 
% % xmin = 18;
% % xmax = 40;
% % xstep = 20;
% 
% % BMI
% % xvar = backgroundvar.BMI;
% % xvarlabel = 'Body Mass Index (BMI)';
% % xvartitle = 'BMI';
% % 
% % xmin = 18;
% % xmax = 30;
% % xstep = 20;
% 
% line([xmin xmax],[0 0],'LineStyle','-','Color',[133, 146, 158]./255,'LineWidth',1.5)
% 
% hold on
% 
% scatter(xvar,cpm_diff_data,40,'filled','MarkerFaceColor',scattercolors(1,:),'MarkerEdgeColor',[52, 73, 94]./255);
% 
% xlabel(xvarlabel)
% xlim([xmin xmax])
% % set(gca,'xTick',xmin:xstep:xmax,'FontSize',14)
% 
% ylabel('CPM magnitude CON-EXP (VAS)')
% ylim([-25 25])
% set(gca,'yTick',-25:5:25,'FontSize',14)
% 
% title({[xvartitle ' vs. CPM magnitude'];['N = ' num2str(no_subjects)]},'FontSize',14)
% 
% corr(xvar,cpm_diff_data,'Type','Spearman')

end