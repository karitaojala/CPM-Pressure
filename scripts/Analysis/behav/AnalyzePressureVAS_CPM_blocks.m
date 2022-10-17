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

function AnalyzePressureVAS_CPM_blocks

close all; clear all

plotIndividual = false; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Pilot-04';

path.code = pwd;
path.main = fullfile(path.code,'..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

if strcmp(project.phase,'Pilot-02')
    subjects = [1:2 4 6 7 10:17];
    block_order = {[0 1]; [0 1]; [0 1]; [1 0]; [1 0]; [1 0]; [1 0 0 1]; [1 0 1 0]; [1 0 0 1]; [0 1 0 1]; [1,0,1,0]; [0,1,1,0]; [1,0,0,1]}; % exp (2) or control (1) block
    % stim_cuff_subs = [1 1 NaN 1 1]; % 1 = tonic stim cuff 1 (left), phasic stim cuff 2 (right); 2 = phasic stim cuff 1, tonic stim cuff 2
    phasicStimPressure = [80 67 50 46 41 43 80 81 48 73 64 72 90];
elseif strcmp(project.phase,'Pilot-04')
    subjects = [1:2 6:8 10:16];%[1:8 10:16]; %[1 4 6 7 10];% only CPM responders, [1:8 10:11]; all subjects %[1 2 5 6]; subjects 3 and 4 had extremely high pain threshold
    block_order = {[0 1 1 0]; [1 0 0 1]; [1 0]; [0 1]; [1 0 1 0]; [0 0 1 1]; [0 1 0 1]; ...
        [1 0 0 1]; NaN; [0 1 0 1]; [1 0 0 1]; [1 1 0 0]; [1 0 1 0]; [1 1 0 0]; [1 1 0 0]; ...
        [0 1 0 1];};
    block_order = block_order(subjects);
%     phasicStimPressure = [];
end

rows = ceil(numel(subjects)/5);
cols = 5;
figure('Position',[10 10 1800 800]); 

datatable_long = NaN(numel(subjects)*4,4);
datatable_trial = NaN(numel(subjects)*4*2*9,5); % 4 blocks, 2 trials per block, 9 ratings per trial

sub_row_no = 1;
sub_row_no_trial = 1;

for sub = 1:numel(subjects)
    
    clear ratings_blocks pressure blocks blocktrials blockratings conditions
    
    subID = ['sub' sprintf('%03d',subjects(sub))];
    
    path.sub = fullfile(path.data,subID,'pain');
    
    blocks_sub = block_order{sub};
%     blocks = NaN(4,18);
%     conditions = NaN(4,18);
    
    row_no = 1;
    trial_counter = 0;
    stim_counter = 0;
    
    for block = 1:numel(blocks_sub)
        
        if strcmp(project.phase,'Pilot-02') && subjects(sub) < 11
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(block) '.mat']);
        else
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(block) '_phasicstim.mat']);
        end
        path.paramfile = fullfile(path.sub,['parameters_' subID '.mat']);

        data = load(path.datafile,'VAS');
        data = data.VAS;
        
%         param = load(path.paramfile,'P');
%         param = param.P;
        
        trials = size(data,1);
        if trials > 3; trials = trials(1:3,:); end % 4th trial (if exists) rating for tonic stimulus only (not phasic)
        stimuli = size(data,2);
        
        ratings = [];
        
        for trial = 1:trials
            
            for stim = 1:stimuli
                
                stim_counter = stim_counter + 1;
                
                ratings = [ratings data(trial,stim).phasicStim.finalRating]; %#ok<AGROW>
                blocktrials(stim_counter) = trial;
                
            end
            
        end
        
        trial_counter = trial_counter + trials;
        
        ratings_blocks(row_no,:) = ratings; %#ok<AGROW>
        blocks(block,1:numel(ratings)) = block;
        blockratings(block,1:numel(ratings)) = 1:numel(ratings);
        conditions(block,1:numel(ratings)) = blocks_sub(block);
        
        if strcmp(subID,'sub005') && row_no == 1
            ratings_blocks(row_no,stimuli+1:stimuli*2) = NaN;% accidentally overwrote first trial with second trial values
        end
        row_no = row_no + 1;
        
    end
    
%     pressure = ones(length(ratings),2)*phasicStimPressure(sub); %#ok<AGROW>
    
    ratings_allsubs{sub} = ratings; %#ok<NASGU,AGROW>
%     pressure_allsubs{sub} = pressure; %#ok<NASGU,AGROW>

    datatable_wide(sub,1) = sub;
    datatable_wide(sub,2:numel(blocks_sub)+1) = nanmean(ratings_blocks,2);
    
    datatable_long(sub_row_no:sub_row_no+numel(blocks_sub)-1,1) = sub;
    datatable_long(sub_row_no:sub_row_no+numel(blocks_sub)-1,2) = 1:numel(blocks_sub);
    datatable_long(sub_row_no:sub_row_no+numel(blocks_sub)-1,3) = blocks_sub';
    datatable_long(sub_row_no:sub_row_no+numel(blocks_sub)-1,4) = nanmean(ratings_blocks,2);
        
    sub_row_no = sub_row_no + 4;
    
    exp_ratings = ratings_blocks(blocks_sub==1,:);
    exp_ratings_block_mean(sub,:) = nanmean(exp_ratings,2);
    exp_ratings = reshape(exp_ratings',1,[]);
    control_ratings = ratings_blocks(blocks_sub==0,:);
    control_ratings_block_mean(sub,:) = nanmean(control_ratings,2);
    control_ratings = reshape(control_ratings',1,[]);
    
    ratings_allsubs_mean_exp(sub) = nanmean(exp_ratings);
    ratings_allsubs_mean_control(sub) = nanmean(control_ratings);
    
    if strcmp(subID,'sub005')
        trial_counter = trial_counter + 1;
        blocktrials = [blocktrials(1:9) repmat(2,[1 9]) blocktrials(10:end)];
    end
    all_trials = 1:trial_counter;
    all_ratings = 1:numel(ratings_blocks);
    all_trials = repmat(all_trials,numel(all_ratings)/numel(all_trials),1);
    all_trials = all_trials(:);
    
    ratings_blocks_x = reshape(ratings_blocks',1,[])';
    blocks = reshape(blocks',1,[])';
    blockratings = reshape(blockratings',1,[])';
    conditions = reshape(conditions',1,[])';
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,1) = sub;
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,2) = blocks;
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,3) = all_trials;
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,4) = blocktrials';
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,5) = all_ratings';
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,6) = blockratings;
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,7) = conditions;
    datatable_trial(sub_row_no_trial:sub_row_no_trial+numel(all_ratings)-1,8) = ratings_blocks_x;
    
    sub_row_no_trial = sub_row_no_trial + 4*2*9;
    
    block_ratings = numel(all_ratings)/numel(blocks_sub);
    
    subplot(rows,cols,sub);
    for bl = 1:numel(blocks_sub)
        bl_trials = (block_ratings*bl-block_ratings):(block_ratings*bl);
        if bl > 1
            startvalue = ratings_blocks(bl-1,end);
        else
            startvalue = NaN;
        end
        
        if blocks_sub(bl) == 1 % experimental blocks
            plot(bl_trials,[startvalue ratings_blocks(bl,:)],'Color',[239, 123, 5]./255,'LineWidth',1.5);
        elseif blocks_sub(bl) == 0 % control blocks
            plot(bl_trials,[startvalue ratings_blocks(bl,:)],'Color',[253, 216, 110]./255,'LineWidth',1.5);
        end
        hold on
        if bl ~= numel(blocks_sub)
            line([block_ratings*bl block_ratings*bl],[0 100],'Color','k')
            hold on
        end
    end
    ylim([0 100])
    set(gca,'yTick',0:20:100)
    ylabel('Phasic pain rating (VAS)')
    xlabel('Trials')
    set(gca,'xTick',0:10:numel(all_trials))
    xlim([1 numel(all_trials)])
    title(subID)
    
end

cpm_data = [ratings_allsubs_mean_control; ratings_allsubs_mean_exp]';

Control = ratings_allsubs_mean_control';
Experimental = ratings_allsubs_mean_exp';
SubjectID = subjects';
cpm_table = table(SubjectID,Control,Experimental);
datafile = fullfile(path.main,'data',project.name,project.phase,'cpm_data.csv');
% writetable(cpm_table,datafile)

datatable_long = datatable_long(~isnan(datatable_long(:,1)),:);
SubjectID = datatable_long(:,1);
Block = datatable_long(:,2);
Condition = datatable_long(:,3);
VAS = datatable_long(:,4);
cpm_table_long = table(SubjectID,Block,Condition,VAS);
datafile2 = fullfile(path.main,'data',project.name,project.phase,'cpm_data_long.csv');
writetable(cpm_table_long,datafile2)

datatable_trial = datatable_trial(~isnan(datatable_trial(:,1)),:);
datatable_trial = datatable_trial(~isnan(datatable_trial(:,8)),:);
SubjectID = datatable_trial(:,1);
Block = datatable_trial(:,2);
Trial = datatable_trial(:,3);
BlockTrial = datatable_trial(:,4);
Rating = datatable_trial(:,5);
BlockRating = datatable_trial(:,6);
Condition = datatable_trial(:,7);
VAS = datatable_trial(:,8);
cpm_table_trial = table(SubjectID,Block,Trial,BlockTrial,Rating,BlockRating,Condition,VAS);
datafile3 = fullfile(path.main,'data',project.name,project.phase,'cpm_data_trial.csv');
writetable(cpm_table_trial,datafile3)

% Calculate within-subject error bars
subavg = nanmean(cpm_data,2); % mean over conditions for each sub
grandavg = nanmean(subavg); % mean over subjects and conditions

newvalues = nan(size(cpm_data));

% normalization of subject values
for block = 1:2
    meanremoved = cpm_data(:,block)-subavg; % remove mean of conditions from each condition value for each sub
    newvalues(:,block) = meanremoved+repmat(grandavg,[numel(subjects) 1 1]); % add grand average over subjects to the values where individual sub average was removed
    bardata(:,block) = nanmean(newvalues(:,block));
end

tvalue = tinv(1-0.025, numel(subjects)-1);
newvar = (block/(block-1))*nanvar(newvalues);
errorbars = squeeze(tvalue*(sqrt(newvar)./sqrt(numel(subjects)))); % calculate error bars according to Cousineau (2005) with Morey (2008) fix
    
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

for block = 1:2
    scatter(jittered_xdata(:,block),cpm_data(:,block),'filled','MarkerEdgeColor','k','MarkerFaceColor',scattercolors(block,:));
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