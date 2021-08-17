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

plotIndividual = true; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Pilot-02';

path.code = pwd;
path.main = fullfile(path.code,'..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

subjects = [6 7 10:17];
rating_trials = [2 2 2 1 1 1 1 1 1 1];
block_order = {[1 0]; [1 0]; [1 0]; [1 0 0 1]; [1 0 1 0]; [1 0 0 1]; [0 1 0 1]; [1,0,1,0]; [0,1,1,0]; [1,0,0,1]};% exp (2) or control (1) block
% phasicStimPressure = [80 67 50 46 41 43 80 81];

rows = 2;
cols = 5;
figure; 

for sub = 1:numel(subjects)
    
    clear ratings_blocks pressure
    
    subID = ['sub' sprintf('%03d',subjects(sub))];
    
    path.sub = fullfile(path.data,subID,'pain');
    
    blocks_sub = block_order{sub};
    
    row_no = 1;
    
    for cond = 1:numel(blocks_sub)
        
        if subjects(sub) < 11
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(cond) '.mat']);
        else
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(cond) '_tonicstim.mat']);
        end

        data = load(path.datafile,'VAS');
        data = data.VAS;
        
        trial = rating_trials(sub); % last trial of each block

        if subjects(sub) < 11
            rating = [data(1,trial).tonicStim.conRating];
        else
            rating = [data(cond).tonicStim.conRating];
        end
        if numel(rating) < 12000
            ratingx = NaN(1,12000);
            ratingx(1:numel(rating)) = rating; 
            rating = ratingx;
        else
            rating = rating(1:12000); 
        end
        rating = rating(1:(12000/200):end);
        
        ratings_blocks(row_no,:) = rating; %#ok<AGROW>
        
        row_no = row_no + 1;
        
    end
    
    exp_ratings = ratings_blocks(blocks_sub==1,:);
%     exp_ratings = exp_ratings(:);
    control_ratings = ratings_blocks(blocks_sub==0,:);
%     control_ratings = control_ratings(:);
    if numel(blocks_sub) > 2
        ratings_allsubs_mean_exp(sub,:) = mean(exp_ratings);
        ratings_allsubs_mean_control(sub,:) = mean(control_ratings);
    else
        ratings_allsubs_mean_exp(sub,:) = exp_ratings;
        ratings_allsubs_mean_control(sub,:) = control_ratings;
    end
    
%     ratings_allsubs{sub} = rating; %#ok<NASGU,AGROW>
%     pressure_allsubs{sub} = pressure; %#ok<NASGU,AGROW>
   
    if plotIndividual
        subplot(rows,cols,sub);
        plot(ratings_allsubs_mean_exp(sub,:),'Color',[239, 123, 5]./255,'LineWidth',1.5); 
        hold on
        plot(ratings_allsubs_mean_control(sub,:),'Color',[253, 216, 110]./255,'LineWidth',1.5);
        hold on
        ylim([0 100])
        set(gca,'yTick',0:20:100)
        ylabel('Pain rating (VAS)')
        xlabel('Time (s)')
        set(gca,'xTick',0:50:200)
        if sub == numel(subjects)
            legend({'Experimental','Control'})
            legend('boxoff')
        end
%         title(subID)
    end
    
end

end