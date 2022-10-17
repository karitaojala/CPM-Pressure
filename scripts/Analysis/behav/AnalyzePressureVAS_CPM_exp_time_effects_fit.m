close all; clear all

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
    
    for block = 1:no_blocks
        
        blockdata = squeeze(ratings_allsubs(sub,block,:))';
        condition = conditions_allsubs_perblock(sub,block);
        
        if condition == 1
            exp_ratings(sub,block_ind) = ratings_allsubs(sub,block,:);
        else
            con_ratings(sub,block_ind) = ratings_allsubs(sub,block,:);
        end
        
        block_ind = block_ind+no_stims_block;
        
    end
end

%% Calculate error bars for each timepoint

for tp = 1:no_stims_total
    
    % CON
    con_subjects = sum(~isnan(con_ratings(:,tp)));
    errorbar_con(:,tp) = nanstd(con_ratings(:,tp))/sqrt(con_subjects);
    
    % EXP
    exp_subjects = sum(~isnan(exp_ratings(:,tp)));
    errorbar_exp(:,tp) = nanstd(exp_ratings(:,tp))/sqrt(exp_subjects);
    
end

%% Model fit
%load('Experiment-01_nlme2b-fit_blockfactor.mat')
load('Experiment-01_nlme-s1_fit.mat')

data = nlmefit;

con_ind = find(data.Condition == 'Con');
exp_ind = find(data.Condition == 'Exp');

%xmax = numel(con_ind);
xmax = no_stims_total;

% Sort block-wise
[~,con_sort_ind] = sort(data.StimulusCentered(con_ind),'ascend');
[~,exp_sort_ind] = sort(data.StimulusCentered(exp_ind),'ascend');

figure('Position',[50,50,1200,300]);

hold on

line([18.5 18.5],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
line([36.5 36.5],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
line([54.5 54.5],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)

%plot(nanmean(con_ratings),'o','Color',colors(1,:),'MarkerFaceColor',colors(1,:),'MarkerEdgeColor',colors(1,:),'LineStyle','none','MarkerSize',4)
errorbar(nanmean(con_ratings),errorbar_con,':o','Color',colors(1,:),'MarkerFaceColor',colors(1,:),'MarkerEdgeColor',colors(1,:),...
    'LineStyle','-','MarkerSize',5,'CapSize',0)
errorbar(nanmean(exp_ratings),errorbar_exp,':o','Color',colors(2,:),'MarkerFaceColor',colors(2,:),'MarkerEdgeColor',colors(2,:),...
    'LineStyle','-','MarkerSize',5,'CapSize',0)
        
data_upper_con = data.upper(con_ind(con_sort_ind));
data_fit_con = data.fit(con_ind(con_sort_ind)); 
data_lower_con = data.lower(con_ind(con_sort_ind));
data_se_con = data.se(con_ind(con_sort_ind));

%interp_upper_con = linspace(data_upper_con(1), data_upper_con(end),no_stims_total);
%interp_fit_con = linspace(data_fit_con(1), data_fit_con(end),no_stims_total);
%interp_lower_con = linspace(data_lower_con(1), data_lower_con(end),no_stims_total);


%plot(interp_upper_con,':','Color',colors(1,:),'LineWidth',1.5)
p_con = plot(data_fit_con,'-','Color',colors(1,:),'LineWidth',3);
%plot(interp_lower_con,':','Color',colors(1,:),'LineWidth',1.5)

data_upper_exp = data.upper(exp_ind(exp_sort_ind));
data_fit_exp = data.fit(exp_ind(exp_sort_ind)); 
data_lower_exp = data.lower(exp_ind(exp_sort_ind));
data_se_exp = data.se(exp_ind(exp_sort_ind));

%interp_upper_exp = linspace(data_upper_exp(1), data_upper_exp(end),no_stims_total);
%interp_fit_exp = linspace(data_fit_exp(1), data_fit_exp(end),no_stims_total);
%interp_lower_exp = linspace(data_lower_exp(1), data_lower_exp(end),no_stims_total);

x = 1:no_stims_total;
y = data_fit_con;
errorsem = data_se_con;
%errorsem(:,1) = interp_upper_con-interp_fit_con;%[interp_upper_con;interp_lower_con];
%errorsem(:,2) = abs(interp_lower_con-interp_fit_con);
hl = boundedline(x, y, errorsem, 'linewidth', 2, 'cmap', colors(1,:),'alpha');

clear errorsem y
y = data_fit_exp;
errorsem = data_se_exp;
%errorsem(:,1) = interp_upper_exp-interp_fit_exp;%[interp_upper_con;interp_lower_con];
%errorsem(:,2) = abs(interp_lower_exp-interp_fit_exp);
h2 = boundedline(x, y, errorsem, 'linewidth', 2, 'cmap', colors(2,:),'alpha');

%plot(interp_upper_exp,':','Color',colors(2,:),'LineWidth',1.5)
p_exp = plot(data_fit_exp,'-','Color',colors(2,:),'LineWidth',3);
%plot(interp_lower_exp,':','Color',colors(2,:),'LineWidth',1.5)

% line([5.5 5.5],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
% line([10.5 10.5],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
% line([15.5 15.5],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)

% line([1 1],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
% line([2.15 2.15],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
% line([2.85 2.85],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
% line([3.6 3.6],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)

xlim([1 xmax])
% set(gca,'xTick',[])
set(gca,'xTick',0:5:xmax, 'FontSize',14)

ylim([ymin ymax])
set(gca,'yTick',ymin:10:ymax, 'FontSize',14)
ylabel('Test stimulus pain rating', 'FontSize',14)

xlabel('Test stimulus index', 'FontSize',14)
%title(['Block ' num2str(block)])
lgd = legend([p_con,p_exp],{'Control','Experimental'},'FontSize',14);
%lgd.NumColumns = 2;
legend('boxoff')
title('Development of Conditioned Pain Modulation over the experiment','FontSize',14)