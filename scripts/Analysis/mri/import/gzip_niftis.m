clear all

addpath('C:\Data\Toolboxes\spm12')

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..','..');
path.nifti = fullfile(path.main,'data',project.name,project.phase,'mri','rawdata');

all_subs = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];
sub_folders = ls(path.nifti);
sub_folders = sub_folders(3:end,:);

series_names = {'field_map_mag' 'field_map_phase' 't1_corrected' 't1_uncorrected' 't2_spinalcord' ...
    'epi-run1' 'epi-run2' 'epi-run3' 'epi-run4' 'epi-run5' 'epi-run6'};
series2take = size(series_names,2);

for sub = all_subs
    
    subID = ['sub' sprintf('%03d',sub);];
    sub_ind = find(contains(cellstr(sub_folders),subID)==1);
    
    fprintf(['\nGzipping NIFTIs... ' sub_folders(sub_ind,:) '\n------------------------------------------------\n'])
    
    path.sub_nifti = fullfile(path.nifti,sub_folders(sub_ind,:)); % subject path
    
    for series = 1:series2take
        
        path.series_nifti = fullfile(path.sub_nifti,series_names{series});
        
        if exist(path.series_nifti,'dir')
            niftis = spm_select('FPList',path.series_nifti,'sub.*\.nii$');
            fprintf(['Series ' num2str(series) '/' num2str(series2take) ': ' series_names{series} ' -- Files found: ' num2str(size(niftis,1)) '\n'])
            
            for file = 1:size(niftis,1)
                [~,name,ext] = fileparts(strrep(niftis(file,:),' ',''));
                gzippedfile = fullfile(path.series_nifti,[name '.nii.gz']);
                if ~exist(gzippedfile,'file')
                    gzip(strrep(niftis(file,:),' ',''))
                end
            end
            
        end
        
    end
    
end