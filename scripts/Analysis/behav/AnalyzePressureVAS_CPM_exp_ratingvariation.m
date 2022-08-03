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

function AnalyzePressureVAS_CPM_exp_ratingvariation

close all; clear all

plotIndividual = false; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

subjects = [1:2 4:13 15:18 20:27 29:34 37:40 42:50];
blocks = 4;
trials = 2;
stimuli = 9;

rows = 7;%ceil(numel(subjects)/3);
cols = 7;%ceil(numel(subjects)/4); 

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
    
    row_no = 1;
    
    for block = control_blocks_sub
        
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
                
            end
            
        end
        
        ratings_blocks(row_no,:) = ratings; %#ok<AGROW>
        
        row_no = row_no + 1;
    end
    
    ratings_allsubs(sub,:,:) = ratings_blocks;
    
end

ratings_allsubs_b1 = squeeze(ratings_allsubs(:,1,:));
ratings_allsubs_b2 = squeeze(ratings_allsubs(:,2,:));
% ratings_allsubs_b3 = squeeze(ratings_allsubs(:,3,:));
% ratings_allsubs_b4 = squeeze(ratings_allsubs(:,4,:));

ratings_allsubs_b1_mean = nanmean(ratings_allsubs_b1,2);
ratings_allsubs_b2_mean = nanmean(ratings_allsubs_b2,2);
save('Experiment-01_controlratings.mat','ratings_allsubs_b1_mean','ratings_allsubs_b2_mean','phasicStimPressures');

% Averaged plot over subjects
figure('Position',[10 10 1800 1200]);

for sub = 1:numel(subjects)
    
    phasicStimPressure = phasicStimPressures(sub);
    
    subID = ['sub' sprintf('%02d',subjects(sub))];
    subplot(rows,cols,sub)
    
    sub_ratings_b1 = squeeze(ratings_allsubs(sub,1,:));
%     sub_ratings_b1 = squeeze(sub_ratings_b1(~isnan(sub_ratings_b1)));
    mean_b1(sub,1) = nanmean(sub_ratings_b1);

    sub_ratings_b2 = squeeze(ratings_allsubs(sub,2,:));
    mean_b2(sub,1) = nanmean(sub_ratings_b2);
%     sub_ratings_b2 = squeeze(sub_ratings_b2(~isnan(sub_ratings_b2)));
    
%     sub_ratings_b3 = squeeze(ratings_allsubs(sub,3,:));
% %     sub_ratings_b3 = squeeze(sub_ratings_b3(~isnan(sub_ratings_b3)));
%     
%     sub_ratings_b4 = squeeze(ratings_allsubs(sub,4,:));
% %     sub_ratings_b4 = squeeze(sub_ratings_b4(~isnan(sub_ratings_b4)));
    
%     plotdata = [sub_ratings_b1; sub_ratings_b2; sub_ratings_b3; sub_ratings_b4];

%     plotdata = [sub_ratings_b1; sub_ratings_b2];
    plotdata = [sub_ratings_b1 sub_ratings_b2];
     
    labels_b1 = repmat({'Block 1'},size(sub_ratings_b1,1),size(sub_ratings_b1,2));
    labels_b2 = repmat({'Block 2'},size(sub_ratings_b2,1),size(sub_ratings_b2,2));
%     labels_b3 = repmat({'Block 3'},size(sub_ratings_b3,1),size(sub_ratings_b3,2));
%     labels_b4 = repmat({'Block 4'},size(sub_ratings_b4,1),size(sub_ratings_b4,2));
    
%     labeldata = [labels_b1; labels_b2; labels_b3; labels_b4];

%     labeldata = [labels_b1; labels_b2;];
    for cond = 1:2
        labeldata = cond*ones(size(plotdata(:,cond)));
        scatter(plotdata(:,cond),labeldata,'filled')
        hold on
    end
%     boxplot(plotdata, labeldata, 'Orientation','horizontal', 'FactorDirection','list')
%     title([subID ': phasic stimulus ' num2str(phasicStimPressure) ' kPa'])
    title(subID)
    
    ylim([0 3])
    set(gca, 'YDir','reverse')
    ax = gca;   %or as appropriate
    yticklabels = get(ax, 'YTickLabel');
    yticklabels{1} = '';   %needs to exist but make it empty
    yticklabels{2} = 'Block 1';
    yticklabels{3} = 'Block 2';
    yticklabels{end} = '';
    set(ax, 'YTickLabel', yticklabels);

    xlim([0 100])
    xticks(0:20:100)
    xlabel('VAS')
        
end

end