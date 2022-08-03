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

function AnalyzePressureVAS_CPM_exp_effect

close all; clear all

plotIndividual = false; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

subjects = [1:2 4:13 15:18 20:27 29:34 37:40 42:50]; % sub 3, 36 excluded due to behavioral reasons, rest dropouts during scanning
blocks = 4;
trials = 2;
stimuli = 9;

ratings_all = [];
conditions_all = [];
trials_all = [];
blocks_all = [];

for sub = 1:numel(subjects)
    
    clear ratings_blocks pressure
    
    subID = ['sub' sprintf('%03d',subjects(sub))];
    
    path.sub = fullfile(path.data,subID,'pain');
    
    path.paramfile = fullfile(path.sub,['parameters_' subID '.mat']);
    param = load(path.paramfile,'P');
    param = param.P;
    
    phasicStimPressures(sub,:) = param.pain.CPM.experimentPressure.phasicStim;
    if phasicStimPressures(sub,:) >= 100; phasicStimPressures(sub,:) = 99; end % actually 99 kPa maximum output
    tonicStimPressures_Peak(sub,:) = param.pain.CPM.experimentPressure.tonicStimPeak;
    tonicStimPressures_Trough(sub,:) = param.pain.CPM.experimentPressure.tonicStimTrough;
    
    blocks_sub = param.pain.CPM.tonicStim.condition;
    control_blocks_sub = find(blocks_sub == 0);
    exp_blocks_sub = find(blocks_sub == 1);
    
    row_no = 1;
    
    for block = 1:blocks
        
        path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(block) '_phasicstim.mat']);
        
        data = load(path.datafile,'VAS');
        data = data.VAS;
        
        ratings = [];
        
        for trial = 1:trials
            
            for stim = 1:stimuli
                
                try
                    trial_rating = data(trial,stim).phasicStim.finalRating;
                    response = data(trial,stim).phasicStim.response;
                catch
                    trial_rating = NaN; % some trials in 1-2 participants error and lost
                    response = NaN;
                end
                
                if trial_rating == 0 && response == 0; trial_rating = NaN; end % replace missed ratings with NaN
                ratings = [ratings trial_rating]; %#ok<AGROW>
                
                trials_all = [trials_all trial];
                blocks_all = [blocks_all block];
                
            end
            
        end
          
        ratings_blocks(row_no,:) = ratings; %#ok<AGROW>
        conditions = blocks_sub(block)*ones(size(ratings));
        conditions_blocks(row_no,:) = conditions; %#ok<AGROW>
        conditions_allsubs_perblock(sub,block) = blocks_sub(block); %#ok<AGROW>
        
        ratings_all = [ratings_all ratings];
        conditions_all = [conditions_all conditions];
        row_no = row_no + 1;
    end
    
    ratings_allsubs(sub,:,:) = ratings_blocks;
    conditions_allsubs(sub,:,:) = conditions_blocks;
    
end

% ratings_allsubs_b1 = squeeze(ratings_allsubs(:,1,:));
% ratings_allsubs_b2 = squeeze(ratings_allsubs(:,2,:));
% ratings_allsubs_b3 = squeeze(ratings_allsubs(:,3,:));
% ratings_allsubs_b4 = squeeze(ratings_allsubs(:,4,:));

save('Experiment-01_ratings.mat','ratings_allsubs','conditions_allsubs','conditions_allsubs_perblock','phasicStimPressures');

no_stimuli = 72;
stimuli_per_trial = 9;
stimuli_per_block = 18;
no_trials = 4*2;

Subject = repmat(subjects,[no_stimuli 1]);
Subject = Subject(:);
Stimulus = repmat(1:no_stimuli,[length(subjects) 1])';
Stimulus = Stimulus(:);
Trial = trials_all';
Block = blocks_all';
Condition = conditions_all';
PainRating = ratings_all';

summarytablefile = fullfile(path.code,'Experiment-01_ratings_table_long.csv');
datatable1 = table(Subject,Stimulus,Trial,Block,Condition,PainRating);
writetable(datatable1,summarytablefile);
    
end