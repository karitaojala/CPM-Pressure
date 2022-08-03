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

function AnalyzePressureVAS

close all; clear all

plotIndividual = true; % plot individual subjects' data

project.name = 'CPM-Pressure-01';
project.phase = 'Pilot-02';

path.code = pwd;
path.main = fullfile(path.code,'..');
path.data = fullfile(path.main,'data',project.name,project.phase,'logs');

subjects = 1:2;
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
    
    subID = ['sub' sprintf('%03d',subjects(sub))];
    
    path.sub = fullfile(path.data,subID,'pain');
    path.datafile =  fullfile(path.sub,[subID '_VAS_calibration.mat']);
    
    data = load(path.datafile,'VAS');
    data = data.VAS;
    
    ratings = [];
    pressure = [];
    
    for step = 1:3
        ratings = [ratings data(step).calibStep.finalRating]; %#ok<AGROW>
        pressure = [pressure data(step).calibStep.trialPressure]; %#ok<AGROW>
    end
    
    format long
    y = ratings';
    x = pressure';
    X = [ones(length(x),1) x];
    b = X\y;
    yCalc = X*b;
    
    if plotIndividual
       
        figure
        scatter(pressure,ratings,'filled'); %#ok<UNRCH>
        hold on
        plot(x,yCalc,'LineWidth',2)
        ylim([0 100])
        xlim([0 100])
        xticks(0:10:100)
        xticklabels(0:10:100)
        ylabel('VAS rating')
        xlabel('Pressure (kPa)')
        grid on
    
        title(['Pressure pain calibration - ' project.name ' / ' project.phase ' - ' subID])
        
    end
    
    ratings_allsubs{sub} = ratings; %#ok<NASGU,AGROW>
    pressure_allsubs{sub} = pressure; %#ok<NASGU,AGROW>
    
end

% % Averaged plot over subjects
% figure;
% 
% fitdata = pressure_allsubs\ratings_allsubs;
% 
% plot(mean(pressure_allsubs),mean(ratings_allsubs),'Color',colors(1:2,:),'LineWidth',2,'LineStyle','-', 'Marker', 'none');  %#ok<AGROW>
% hold on
% ylim([0 100])
% xlim([0 100])
% xticks(0:10:100)
% xticklabels(0:10:100)
% ylabel('VAS rating')
% xlabel('Pressure (kPa)')
% 
% title(['Pressure pain calibration - ' project.name ' / ' project.phase ' - average of N = ' num2str(numel(subjects))])


end