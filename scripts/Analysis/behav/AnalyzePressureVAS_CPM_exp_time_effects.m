close all; clear all

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

load(fullfile(path.code,'Experiment-01_ratings.mat'))

% ratings_allsubs = ratings_allsubs(1:40,:,:);
blocks_to_take = 0; % 0 all, 1 = first con vs. exp, 2 = last con vs. exp

ymax = 70;
ymin = 30;

subjects = [1:2 4:13 15:18 20:27 29:34 37:40 42:49];

no_subjects = size(ratings_allsubs,1);
no_blocks = size(ratings_allsubs,2);
no_stims_block = size(ratings_allsubs,3); 
no_stims_total = no_blocks*no_stims_block;
no_stims_cond = no_stims_block*2;

con_ratings = NaN(no_subjects,no_blocks,no_stims_block);
exp_ratings = NaN(no_subjects,no_blocks,no_stims_block);

for sub = 1:no_subjects
    
    for block = 1:no_blocks
        
        blockdata = squeeze(ratings_allsubs(sub,block,:))';
        condition = conditions_allsubs_perblock(sub,block);
        
        if condition == 1
            exp_ratings(sub,block,:) = ratings_allsubs(sub,block,:);
        else
            con_ratings(sub,block,:) = ratings_allsubs(sub,block,:);
        end
        
    end
end

colors = [253, 216, 110; 239, 123, 5]./255;

figure('Position',[50,50,1400,300]);

for block = 1:no_blocks
   
    subplot(1,4,block)
    clear plotdata
    plotdata = squeeze([nanmean(con_ratings(:,block,:),1) nanmean(exp_ratings(:,block,:),1)])';
    
    for cond = 1:2
        plot(plotdata(:,cond),'-o','Color',colors(cond,:),'MarkerFaceColor',colors(cond,:),'MarkerEdgeColor',colors(cond,:),'LineWidth',1.5)
        hold on
    end
    
    line([9.5 9.5],[ymin ymax],'LineStyle','--','Color',[133, 146, 158]./255,'LineWidth',1)
    hold on

    xlim([1 18])
    set(gca,'xTick',0:2:18,'FontSize',14)
    xlabel('Test stimulus index')
    
    ylim([ymin ymax])
    if block == 1
        ylabel('Test pain rating')
    else
        set(gca,'ytick',[])
    end
    title(['Block ' num2str(block)])
    if block == 4
        lgd = legend('Control','Experimental','Location','northwest');
        %lgd.NumColumns = 2;
        legend('boxoff')
    end
    
    sgtitle('Block-wise true data values','FontSize',14)
    
end