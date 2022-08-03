%function get_dicoms
clear all

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..','..');
path.dicom = fullfile(path.main,'data',project.name,project.phase,'mri','sourcedata');

sub_folders = ls(path.dicom);
sub_folders = sub_folders(3:end,:);

series_names = {'field_map_mag' 'field_map_phase' 't1_corrected' 't1_uncorrected' 't2_spinalcord' ...
    'epi-run1' 'epi-run2' 'epi-run3' 'epi-run4' 'epi-run5' 'epi-run6'};

% load subject specific series numbers
path.seriesfile = fullfile(path.dicom,'..');
series_data = readtable(fullfile(path.seriesfile,'subjects_scanseries.xlsx')); % load scan series numbers for all participants

for sub = 48:size(sub_folders,1)
    fprintf(['\nProcessing... ' sub_folders(sub,:) '\n---------------------------------\n'])
    path.sub = fullfile(path.dicom,sub_folders(sub,:)); % subject path
    series_folders = ls(path.sub);
    if any(ismember(series_folders,'.dcminfo.stu','rows')) || any(ismember(series_folders,'.dcminfo','rows'))
        series_folders = series_folders(4:end,:); %  if .dcminfo in the folder
    else
        series_folders = series_folders(3:end,:); % if no .dcminfo file
    end
    
    series_no = table2array(series_data(sub,2:end));
    if any(isnan(series_no))
        series2take = series_folders(series_no(~isnan(series_no)),:);
    else
        series2take = series_folders(series_no,:); % find the series to take for this participant
    end
    series2take_ind = find(~isnan(series_no));
    
    if ~exist(fullfile(path.sub,'DICOM'),'dir'); mkdir(fullfile(path.sub,'DICOM')); end % make new DICOM folder
    
    for series = series2take_ind
        path.series = fullfile(path.sub,'DICOM',series_names{series}); % new path for the series
        if ~exist(path.series,'dir')
            mkdir(path.series); % make new folder
            origpath = fullfile(path.sub,series2take(series,:));
            cd(origpath)
            copyfile('MR*',path.series) % move DICOM files to new folder
            seriesfolder = dir(path.series);
            no_files = size(seriesfolder,1)-2; % number of files in the folder
            fprintf(['Series ' num2str(series) '/' num2str(size(series2take,1)) ': ' series_names{series} ' -- Files found: ' num2str(no_files) '\n'])
        end
    end
    
    cd(path.sub)
    rmdir('1.3*','s'); % remove remaining original folders
    
end

%end