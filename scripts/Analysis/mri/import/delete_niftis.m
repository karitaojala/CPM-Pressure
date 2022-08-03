clear all

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..','..');
path.nifti = fullfile(path.main,'data',project.name,project.phase,'mri','rawdata');

sub_folders = ls(path.nifti);
sub_folders = sub_folders(3:end,:);

series_names = {'epi-run1' 'epi-run2' 'epi-run3' 'epi-run4' 'epi-run5' 'epi-run6'};
series2take = size(series_names,2);

for sub = [17:34 38:44 46:47]
    
    subID = ['sub' sprintf('%03d',sub);];
    sub_ind = find(contains(cellstr(sub_folders),subID)==1);
    
    fprintf(['\nDeleting NIFTIs... ' sub_folders(sub_ind,:) '\n------------------------------------------------\n'])
    
    path.sub_nifti = fullfile(path.nifti,sub_folders(sub_ind,:)); % subject path
    
    for series = 1:series2take
        
        clear niftis
        path.series_nifti = fullfile(path.sub_nifti,series_names{series});
        
        if exist(path.series_nifti,'dir')
            
            niftis = spm_select('FPList',path.series_nifti,'^sub');
            fprintf(['Series ' num2str(series) '/' num2str(series2take) ': ' series_names{series} ' -- Files found: ' num2str(size(niftis,1)) '\n'])
            
            cd(path.series_nifti)
            
            for file = 1:size(niftis,1)
                delete(niftis(file,:))
            end
            
        end
        
    end
    
end