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

function AnalyzePressureVAS_CPM_exp_effect_plot_overtime

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

subjects = [1:2 4:13 15:18 20:27 29:34 37:40 42:50];

no_subjects = size(ratings_allsubs,1);
no_blocks = size(ratings_allsubs,2);
no_stims_block = size(ratings_allsubs,3); 
no_stims_total = no_blocks*no_stims_block;
no_stims_cond = no_stims_block*2;

no_trials_block = 2;

% for sub = 1:size(ratings_allsubs,1)
%     sub_blocks = conditions_allsubs_perblock(sub,:);
%     exp_ratings(sub,:,:) = ratings_allsubs(sub,sub_blocks==1,:);
%     control_ratings(sub,:,:) = ratings_allsubs(sub,sub_blocks==0,:);
% end
% 
% if ~blocks_to_take
%     ratings_allsubs_mean_exp = nanmean(reshape(exp_ratings,[no_subjects no_trials_cond]),2); % note that trial order for ratings is not retained here
%     ratings_allsubs_mean_control = nanmean(reshape(control_ratings,[no_subjects no_trials_cond]),2); % but does not matter for overall mean
% elseif blocks_to_take == 1
%     ratings_allsubs_mean_exp = nanmean(squeeze(exp_ratings(:,1,:)),2); 
%     ratings_allsubs_mean_control = nanmean(squeeze(control_ratings(:,1,:)),2); 
% elseif blocks_to_take == 2
%     ratings_allsubs_mean_exp = nanmean(squeeze(exp_ratings(:,2,:)),2); 
%     ratings_allsubs_mean_control = nanmean(squeeze(control_ratings(:,2,:)),2); 
% end

% cpm_data = [ratings_allsubs_mean_control ratings_allsubs_mean_exp];

rows = 6;%12;%ceil(numel(subjects)/3);
cols = 8;%ceil(numel(subjects)/4); 

plotcolors = [252, 190, 14; 179, 92, 4]./255;

% Averaged plot over subjects
figure('Position',[10 10 1800 1200]);


for sub = 1:no_subjects
    
    subID = ['sub' sprintf('%02d',subjects(sub))];
    subplot(rows,cols,sub)
    stimcounter = 1:no_stims_block;
    trialcounter = 1:no_trials_block;
    
    for block = 1:no_blocks
        
        x_trial1_start = stimcounter(1);
        x_trial2_start = stimcounter(end)-no_stims_block/2+1;
        
        line([x_trial1_start x_trial1_start],[0 100],'LineWidth',1,'LineStyle',':','Color',[156 156 156]./255)
        hold on
        line([x_trial2_start x_trial2_start],[0 100],'LineWidth',1,'LineStyle',':','Color',[156 156 156]./255)
        hold on
        
        clear plotdata
        plotdata = squeeze(ratings_allsubs(sub,block,:))';
        condition = conditions_allsubs_perblock(sub,block)+1;
        plot(stimcounter,plotdata,'-o','LineWidth',1,'MarkerFaceColor',plotcolors(condition,:),'MarkerEdgeColor',[0.3 0.3 0.3],'Color',[0.3 0.3 0.3],'MarkerSize',3);
        hold on
        
        stimcounter = stimcounter+no_stims_block;
        trialcounter = trialcounter+no_trials_block;
        
    end

    title(subID)
    
    xlim([1 no_stims_total+1])
    xticks(1:9:no_stims_total+1)
    xticklabels({'1','10','19','28','37','46','55','64','72'})
    xlabel('Stimulus index')

    ylim([0 100])
    yticks(0:20:100)
    ylabel('Test pain rating (VAS)')

end