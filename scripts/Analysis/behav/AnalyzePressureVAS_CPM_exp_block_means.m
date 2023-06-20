clear all

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

load(fullfile(path.code,'Experiment-01_ratings.mat'))

% ratings_allsubs = ratings_allsubs(1:40,:,:);
blocks_to_take = 0; % 0 all, 1 = first con vs. exp, 2 = last con vs. exp

ymax = 75;
ymin = 35;
colors = [252, 192, 24; 58, 119, 242]./255;
% 252, 192, 24 % darker yellow
% 253, 216, 110 % lighter yellow
% 239, 123, 5 % orange
% 58, 119, 242 % blue
subjects = [1:2 4:13 15:18 20:27 29:34 37:40 42:49];

ratings_allsubs = ratings_allsubs(1:end-1,:,:); % remove last subject, exluded
no_subjects = size(ratings_allsubs,1);
no_blocks = size(ratings_allsubs,2);
no_stims_block = size(ratings_allsubs,3); 
no_stims_total = no_blocks*no_stims_block;
no_stims_cond = no_stims_block*2;

con_ratings = NaN(no_subjects,no_stims_total);
exp_ratings = NaN(no_subjects,no_stims_total);

for sub = 1:no_subjects
    
    block_ind = 1:no_stims_block;
    
    expBlocks = 0;
    conBlocks = 0;
    
    for block = 1:no_blocks
        
        blockdata = squeeze(ratings_allsubs(sub,block,:))';
        condition = conditions_allsubs_perblock(sub,block);
        
        if condition == 1
            exp_ratings(sub,block_ind) = ratings_allsubs(sub,block,:);
            expBlocks = expBlocks + 1;
            if expBlocks == 1
                exp_rating_start(sub,:) = nanmean(ratings_allsubs(sub,block,1:5),3); % mean of first 5 trials of first exp block
            else
                exp_rating_end(sub,:) = nanmean(ratings_allsubs(sub,block,end-4:end),3); % mean of last 5 trials of last exp block
            end
        else
            con_ratings(sub,block_ind) = ratings_allsubs(sub,block,:);
            conBlocks = conBlocks + 1;
            if conBlocks == 1
                con_rating_start(sub,:) = nanmean(ratings_allsubs(sub,block,1:5),3);
            else
                con_rating_end(sub,:) = nanmean(ratings_allsubs(sub,block,end-4:end),3);
            end
        end
        
        block_ind = block_ind+no_stims_block;
        
    end
end

exp_rating_diff = exp_rating_end-exp_rating_start;
con_rating_diff = con_rating_end-con_rating_start;

Subject = subjects';
RatingDiffCON = con_rating_diff;
RatingDiffEXP = exp_rating_diff;

summarytablefile = fullfile(path.code,'Experiment-01_ratings_time_difference_table_wide.csv');
datatable1 = table(Subject,RatingDiffCON,RatingDiffEXP);
writetable(datatable1,summarytablefile);

block_ind = 1:no_stims_block;

for block = 1:no_blocks
    
    exp_block_means(:,block) = nanmean(exp_ratings(:,block_ind(1:end)),2);
    con_block_means(:,block) = nanmean(con_ratings(:,block_ind(1:end)),2);
    
    block_ind = block_ind+no_stims_block;
    
end

figure;
plot(nanmean(exp_block_means))
hold on
plot(nanmean(con_block_means))
ylim([40 60])