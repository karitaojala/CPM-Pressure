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

subjects = [1:2 4:13 15:18 20:27 29:34 37:40 42:50];

no_subjects = size(ratings_allsubs,1);
no_blocks = size(ratings_allsubs,2);
no_trials_block = size(ratings_allsubs,3); 
no_trials_total = no_blocks*no_trials_block;
no_trials_cond = no_trials_block*2;

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

rows = 3;%12;%ceil(numel(subjects)/3);
cols = 4;%ceil(numel(subjects)/4); 

plotcolors = [252, 190, 14; 179, 92, 4]./255;

% Averaged plot over subjects
figure('Position',[10 10 1800 1200]);


for sub = 1:12%numel(no_subjects)
    
    subID = ['sub' sprintf('%02d',subjects(sub))];
    subplot(rows,cols,sub)
    trialcounter = 1:no_trials_block;
    
    for block = 1:no_blocks
        clear plotdata
        plotdata = squeeze(ratings_allsubs(sub,block,:))';
        condition = conditions_allsubs_perblock(sub,block)+1;
        plot(trialcounter,plotdata,'-o','LineWidth',2,'MarkerFaceColor',plotcolors(condition,:),'MarkerEdgeColor',[0.3 0.3 0.3],'Color',[0.3 0.3 0.3]);
        hold on
        trialcounter = trialcounter+no_trials_block;
    end

    title(subID)
    
    xlim([1 no_trials_total])
    xticks(1:8:no_trials_total)
    xlabel('Trials')

    ylim([0 100])
    yticks(0:20:100)
    ylabel('VAS')

end