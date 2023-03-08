clear all

addpath('C:\Data\Toolboxes\spm12')

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..','..');
path.nifti = fullfile(path.main,'data',project.name,project.phase,'mri','data');

all_subs = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];
sub_folders = ls(path.nifti);
sub_folders = sub_folders(3:end,:);

folder_names = {'epi-run1' 'epi-run2' 'epi-run3' 'epi-run4' 'epi-run5' 'epi-run6'};
runs2take = size(folder_names,2);

for sub = all_subs
    
    subID = ['sub' sprintf('%03d',sub);];
    sub_ind = find(contains(cellstr(sub_folders),subID)==1);
    
    fprintf(['\nGzipping NIFTIs... ' sub_folders(sub_ind,:) '\n------------------------------------------------\n'])
    
    path.sub_nifti = fullfile(path.nifti,strrep(sub_folders(sub_ind,:),' ','')); % subject path
    
    for run = 1:runs2take
        
        path.series_nifti = fullfile(path.sub_nifti,folder_names{run});
        
        epi_file = fullfile(path.series_nifti,sprintf('a%s-%s-spinal_moco.nii',subID,folder_names{run}));
        spinal_mask_file = fullfile(path.series_nifti,'spinal_mask.nii');
        
        if exist(path.series_nifti,'dir')
            fprintf(['EPI run ' num2str(run) '/' num2str(runs2take) ': ' folder_names{run} '\n'])
            
            % Cannot gunzip spinal files -> leads to error and the
            % file disappearing!!!
%             if ~exist(epi_file,'file') && exist([epi_file '.gz'],'file')
%                 gunzip([epi_file '.gz.'])
%             end
            
%             if ~exist(spinal_mask_file,'file') && exist([spinal_mask_file '.gz'],'file')
%                 gunzip([spinal_mask_file '.gz.'])
%             end
            
        end
        
    end
    
end