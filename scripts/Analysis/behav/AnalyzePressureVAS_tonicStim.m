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

function AnalyzePressureVAS_tonicStim

close all; clear all

plotIndividual = false; % plot individual subjects' data
prepost = true; % compare pre vs. post ratings (sub 5->)

project.name = 'CPM-Pressure-01';
% project.phase = 'Pilot-02';
% project.phase = 'Pilot-04';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

if strcmp(project.phase,'Pilot-02')
    
    subjects = [6 7 10:17];
    block_order = {[1 0]; [1 0]; [1 0]; [1 0 0 1]; [1 0 1 0]; [1 0 0 1]; [0 1 0 1]; [1,0,1,0]; [0,1,1,0]; [1,0,0,1]}; % exp (2) or control (1) block
    rating_trials = [2 2 2 1 1 1 1 1 1 1];
    height = 800;
    rating_length = 12000;
    rating_duration = 200;
    
elseif strcmp(project.phase,'Pilot-04')
    
    if prepost
        prepost_order = [0 1];
        subjects = [5:7 10:16];
        height = 600;
    else
        subjects = [1:8 10:16]; %#ok<UNRCH> %[1 4 6 7 10];% only CPM responders, [1:8 10:11]; all subjects %[1 2 5 6]; subjects 3 and 4 had extremely high pain threshold
        block_order = {[0 1 1 0]; [1 0 0 1]; [1 0]; [0 1]; [1 1]; [1 1]; [1 1]; ... % [1 1] when changed to pre- and post-experiment experimental ratings only
            [1]; NaN; [1 1]; [1 1]; [1 1]; [1 1]; [1 1]; [1 1]; ...
            [1 1];};
        block_order = block_order(subjects);
        height = 800;
    end
    
    rating_length = 12000;
    rating_duration = 200;
    rating_trials = NaN;
    
elseif strcmp(project.phase,'Experiment-01')
   
    prepost_order = [1 1];
    subjects = [1:2 4:13 15:18 20:27 29:34 37:40 42:49];
    subjects_without_prerating = 2:15; % some participants had their pre-experiment rating accidentally overwritten by the post-experiment rating
    
    rating_length = 5000;
    rating_duration = 80;
    height = 1200;
    
end

rows = 7;%ceil(numel(subjects)/5);
cols = 7;
if plotIndividual; figure('Position',[10 10 1500 height]); end

for sub = 1:numel(subjects)
    
    clear ratings_blocks pressure
    
    subID = ['sub' sprintf('%03d',subjects(sub))];
    
    path.sub = fullfile(path.data,subID,'pain');
    
    if prepost
        blocks_sub = prepost_order;
        if strcmp(project.phase,'Experiment-01') && ismember(subjects(sub),subjects_without_prerating)
            blocks_sub = 1; % only one rating (post-experiment)
        end
    else
        blocks_sub = block_order{sub}; %#ok<UNRCH>
    end
    
    row_no = 1;
    
    for cond = 1:numel(blocks_sub)
        
        if strcmp(project.phase,'Pilot-02') && subjects(sub) < 11
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(cond) '.mat']);    
        else
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(cond) '_tonicstim.mat']);
        end

        data = load(path.datafile,'VAS');
        data = data.VAS;
        
        if strcmp(project.phase,'Pilot-02') && subjects(sub) < 11
            trial = rating_trials(sub); % last trial of each block
            rating = [data(1,trial).tonicStim.conRating];
        else
            rating = [data(cond).tonicStim.conRating];
        end
        
        if numel(rating) < rating_length
            ratingx = NaN(1,rating_length);
            ratingx(1:numel(rating)) = rating; 
            rating = ratingx;
        else
            rating = rating(1:rating_length); 
        end
        rating = rating(1:ceil(rating_length/rating_duration):end);
        
        ratings_blocks(row_no,:) = rating; %#ok<AGROW>
        
        row_no = row_no + 1;
        
    end
    
    exp_ratings = ratings_blocks(blocks_sub==1,:);
%     exp_ratings = exp_ratings(:);
    control_ratings = ratings_blocks(blocks_sub==0,:);
    if isempty(control_ratings) && strcmp(project.phase,'Experiment-01') && size(exp_ratings,1) > 1
        control_ratings = exp_ratings(1,:);
        exp_ratings = exp_ratings(2,:);
    else
        control_ratings = NaN(1,rating_duration);
    end
%     control_ratings = control_ratings(:);
    if numel(blocks_sub) > 2 || (numel(blocks_sub)>1 && blocks_sub(1)==blocks_sub(2)) && ~strcmp(project.phase,'Experiment-01')% if more than 2 blocks (4 ratings: 2 control, 2 exp), only 1 block, or only exp ratings
        ratings_allsubs_mean_exp(sub,:) = nanmean(exp_ratings);
        ratings_allsubs_mean_control(sub,:) = nanmean(control_ratings);
    else
        ratings_allsubs_mean_exp(sub,:) = exp_ratings;
        ratings_allsubs_mean_control(sub,:) = control_ratings;
    end
    
%     ratings_allsubs{sub} = rating; %#ok<NASGU,AGROW>
%     pressure_allsubs{sub} = pressure; %#ok<NASGU,AGROW>
   
    if plotIndividual
        subplot(rows,cols,sub);
        plot(ratings_allsubs_mean_control(sub,:),'Color',[253, 216, 110]./255,'LineWidth',1.5);
        hold on
        plot(ratings_allsubs_mean_exp(sub,:),'Color',[239, 123, 5]./255,'LineWidth',1.5); 
        hold on
        ylim([0 100])
        set(gca,'yTick',0:20:100)
        ylabel('Pain rating (VAS)')
        xlabel('Time (s)')
        set(gca,'xTick',0:20:rating_duration)
        xlim([0 rating_duration])
        if sub == numel(subjects)
            if prepost
                legend({'Pre-experiment rating','Post-experiment rating'},'Location','southeast')
            else
                legend({'Control','Experimental'},'Location','southeast') %#ok<UNRCH>
            end
            legend('boxoff')
        end
        title(subID)
    end
    
end

for tp = 1:rating_duration
    
    % CON
    errorbar_con(:,tp) = nanstd(ratings_allsubs_mean_control(:,tp))/sqrt(numel(subjects));
    
    % EXP
    errorbar_exp(:,tp) = nanstd(ratings_allsubs_mean_exp(:,tp))/sqrt(numel(subjects));
    
end

%colors = [252, 192, 24; 58, 119, 242]./255; % con, exp
colors = [3, 186, 251; 0, 85, 254]./255; % blue shades

mean_control = nanmean(ratings_allsubs_mean_control);
mean_experimental = nanmean(ratings_allsubs_mean_exp);

% Take mean of VAS50-VAS70 period
ramp_up_end = 10;
ramp_down_start = rating_duration-10;
mean_allsubs_control = nanmean(ratings_allsubs_mean_control(:,ramp_up_end:ramp_down_start),2);
mean_allsubs_exp = nanmean(ratings_allsubs_mean_exp(:,ramp_up_end:ramp_down_start),2);

figure('Position',[10 10 900 400]);
hold on
p1 = plot(mean_control,'Color',colors(1,:),'LineWidth',2);
x = 1:rating_duration;
y = mean_control;
errorsem = errorbar_con;
hl = boundedline(x, y, errorsem, 'linewidth', 2, 'cmap', colors(1,:),'alpha');

clear x y errorsem
p2 = plot(mean_experimental,'Color',colors(2,:),'LineWidth',2);
x = 1:rating_duration;
y = mean_experimental;
errorsem = errorbar_exp;
hl = boundedline(x, y, errorsem, 'linewidth', 2, 'cmap', colors(2,:),'alpha');

hold on
ylim([0 100])
set(gca,'yTick',0:20:100,'FontSize',14)
ylabel('Conditioning stimulus pain rating','FontSize',14)
xlabel('Time (seconds)','FontSize',14)
set(gca,'xTick',0:10:rating_duration,'FontSize',14)
xlim([0 rating_duration])
if prepost
    legend([p1,p2],{'Pre-experiment rating','Post-experiment rating'},'Location','northeast','FontSize',14)
    legend('boxoff')
else
    legend({'Control','Experimental'},'Location','southeast') %#ok<UNRCH>
end
%legend([p1,p2],{'Control, non-painful','Experimental, painful'},'boxoff','Location','northeast')
title({'Pre/post-experiment conditioning stimulus ratings'})%;['fMRI study (N = ' num2str(numel(subjects)) ')']},'FontSize',14)

end