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
    subjects = [1:8 10:14]; %[1 4 6 7 10];% only CPM responders, [1:8 10:11]; all subjects %[1 2 5 6]; subjects 3 and 4 had extremely high pain threshold
    block_order = {[0 1 1 0]; [1 0 0 1]; [1 0]; [0 1]; [1 0 1 0]; [0 0 1 1]; [0 1 0 1]; [1 0 0 1]; [0 1 0 1]; [1 0 0 1]; [1 1 0 0]; [1 0 1 0]; [1 1 0 0]};
%     phasicStimPressure = [];
end
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
        
        if strcmp(project.phase,'Pilot-02') && subjects(sub) < 11
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(cond) '.mat']);
        else
            path.datafile =  fullfile(path.sub,[subID '_VAS_rating_block' num2str(cond) '_phasicstim.mat']);
        end
        path.paramfile = fullfile(path.sub,['parameters_' subID '.mat']);

        data = load(path.datafile,'VAS');
        data = data.VAS;
        
        param = load(path.paramfile,'P');
        param = param.P;
        
        phasicStimPressure(sub) = param.pain.CPM.experimentPressure.phasicStim;
        
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
        
        if strcmp(subID,'sub005') && row_no == 1
            ratings_blocks(row_no,stimuli+1:stimuli*2) = NaN;% accidentally overwrote first trial with second trial values
        end
        row_no = row_no + 1;
        
    end
    
    pressure = ones(length(ratings),2)*phasicStimPressure(sub); %#ok<AGROW>
    
%     format long
%     y = ratings';
%     x = pressure';
%     X = [ones(length(x),1) x];
%     b = X\y;
%     yCalc = X*b;
    

%     if plotIndividual
%         
%         figure %#ok<UNRCH>
%         bar(mean(ratings_blocks,2),'LineWidth',1); 
%         hold on
%         
%         xdata = repmat([1 2],size(ratings_blocks,2),1);
%         jitter_amount = 0.05;
%         jittered_xdata = xdata + (rand(size(xdata))-0.5)*(2*jitter_amount);
%         jittered_xdata = jittered_xdata';
%         
%         for cond = 1:2
%             scatter(jittered_xdata(cond,:),ratings_blocks(cond,:),'filled','MarkerEdgeColor','k');
%         end
%         
%         ylim([0 100])
%         ylabel('VAS pain rating')
%         set(gca,'xTickLabel', {'Control','Experimental'})
%         
% %         legend('Control','Experimental')
%         title(['Conditioned pain modulation - / ' project.phase ' - ' subID])
%         
%     end
    
    ratings_allsubs{sub} = ratings; %#ok<NASGU,AGROW>
    pressure_allsubs{sub} = pressure; %#ok<NASGU,AGROW>

    exp_ratings = ratings_blocks(blocks_sub==1,:);
    exp_ratings_block_mean(sub,:) = nanmean(exp_ratings,2);
    exp_ratings = exp_ratings(:);
    control_ratings = ratings_blocks(blocks_sub==0,:);
    control_ratings_block_mean(sub,:) = nanmean(control_ratings,2);
    control_ratings = control_ratings(:);
    
    ratings_allsubs_mean_exp(sub) = nanmean(exp_ratings);
    ratings_allsubs_mean_control(sub) = nanmean(control_ratings);
    
end

cpm_data = [ratings_allsubs_mean_control; ratings_allsubs_mean_exp]';

Control = ratings_allsubs_mean_control';
Experimental = ratings_allsubs_mean_exp';
SubjectID = subjects';
cpm_table = table(SubjectID,Control,Experimental);
datafile = fullfile(path.main,'data',project.name,project.phase,'cpm_data.csv');
% writetable(cpm_table,datafile)

% Calculate within-subject error bars
subavg = nanmean(cpm_data,2); % mean over conditions for each sub
grandavg = nanmean(subavg); % mean over subjects and conditions

newvalues = nan(size(cpm_data));

% normalization of subject values
for cond = 1:2
    meanremoved = cpm_data(:,cond)-subavg; % remove mean of conditions from each condition value for each sub
    newvalues(:,cond) = meanremoved+repmat(grandavg,[numel(subjects) 1 1]); % add grand average over subjects to the values where individual sub average was removed
    bardata(:,cond) = nanmean(newvalues(:,cond));
end

tvalue = tinv(1-0.025, numel(subjects)-1);
newvar = (cond/(cond-1))*nanvar(newvalues);
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

for cond = 1:2
    scatter(jittered_xdata(:,cond),cpm_data(:,cond),'filled','MarkerEdgeColor','k','MarkerFaceColor',scattercolors(cond,:));
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