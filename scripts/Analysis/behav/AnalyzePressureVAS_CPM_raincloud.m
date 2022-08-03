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

function AnalyzePressureVAS_CPM

close all; clear all

plotIndividual = false; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Pilot-02';

path.code = pwd;
path.main = fullfile(path.code,'..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

subjects = [1:2 4 6 7 10:17];
block_order = {[0 1]; [0 1]; [0 1]; [1 0]; [1 0]; [1 0]; [1 0 0 1]; [1 0 1 0]; [1 0 0 1]; [0 1 0 1]; [1,0,1,0]; [0,1,1,0]; [1,0,0,1]}; % exp (2) or control (1) block
% stim_cuff_subs = [1 1 NaN 1 1]; % 1 = tonic stim cuff 1 (left), phasic stim cuff 2 (right); 2 = phasic stim cuff 1, tonic stim cuff 2
phasicStimPressure = [80 67 50 46 41 43 80 81 48 73 64 72 90];
% totalTrials = 14;
% calibTrials = {1:4; 5:7; 8:14};
% samplingRate = 0.005; % 200 Hz
% samplingRate_to_10 = 0.1/samplingRate;
% colors = [45, 0, 179; 89, 0, 179; 134, 0, 179; 179, 0, 179; 179, 0, 134; 179, 0, 89; 179, 0, 45]/255; % 7 different colors for different pressure levels
% colors = [0, 51, 153; 0, 102, 255; 153, 102, 255; 204, 0, 204; 255, 51, 153; 255, 102, 0; 204, 51, 0]/255;
% colors = [0, 0, 153; 0, 0, 255; 102, 102, 255; ...
%     204, 0, 255; ...
%     255, 102, 163; 255, 0, 102; 153, 0, 61]/255;

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
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(cond) '_phasicstim.mat']);
        end

        data = load(path.datafile,'VAS');
        data = data.VAS;
        
        trials = size(data,1);
        if trials > 3; trials = trials(1:3,:); end % 4th trial (if exists) rating for tonic stimulus only (not phasic)
        stimuli = size(data,2);
        
        ratings = [];
        
        for trial = 1:trials
            
            for stim = 1:stimuli
                
                ratings = [ratings data(trial,stim).phasicStim.finalRating]; %#ok<AGROW>
                
            end
            
        end
        
        ratings_blocks(row_no,:) = ratings; %#ok<AGROW>
        
        row_no = row_no + 1;
        
    end
    
    pressure = ones(length(ratings),2)*phasicStimPressure(sub); 
    
    ratings_allsubs{sub} = ratings; %#ok<NASGU,AGROW>
    pressure_allsubs{sub} = pressure; %#ok<NASGU,AGROW>

    exp_ratings = ratings_blocks(blocks_sub==1,:);
    exp_ratings = exp_ratings(:);
    control_ratings = ratings_blocks(blocks_sub==0,:);
    control_ratings = control_ratings(:);
    
    ratings_allsubs_mean_exp(sub) = mean(exp_ratings);
    ratings_allsubs_mean_control(sub) = mean(control_ratings);
    
end

cpm_data = {ratings_allsubs_mean_control; ratings_allsubs_mean_exp}';

%cpm_data = [ratings_allsubs_mean_control; ratings_allsubs_mean_exp]';
%cpm_data = {cpm_data};

clr_control = [253, 216, 110]./255;
clr_exp = [239, 123, 5]./255;

plot_top_to_bottom = 1;

h = rm_raincloud(cpm_data, [clr_control; clr_exp], plot_top_to_bottom);
        
xlim([0 100])
set(gca,'xTick',0:20:100)
xlabel('Test stimulus pain rating (VAS)','FontSize',14)
% set(gca,'xTickLabel', {'Control','Experimental'},'FontSize',14)
% box off
title('Average CPM effect','FontSize',14)

end