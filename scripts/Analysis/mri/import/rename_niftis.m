clear all

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..','..');
path.nifti = fullfile(path.main,'data',project.name,project.phase,'mri','rawdata');

sub_folders = ls(path.nifti);
sub_folders = sub_folders(3:end,:);

series_names = {'field_map_mag' 'field_map_phase' 't1_corrected' 't1_uncorrected' 't2_spinalcord' ...
    'epi-run1' 'epi-run2' 'epi-run3' 'epi-run4' 'epi-run5' 'epi-run6'};
series2take = size(series_names,2);

for sub = [16, 17, 18, 19, 20, 22, 23, 24, 25, 26, 27, 29, 30, 32, 33, 34]%[1:13 15:18 20:27 29:size(sub_folders,1)]
    
    subID = sprintf('%03d',sub);
    sub_ind = find(contains(cellstr(sub_folders),subID)==1);
    
    fprintf(['\nRenaming NIFTIs... ' sub_folders(sub_ind,:) '\n------------------------------------------------\n'])
    path.sub_nifti = fullfile(path.nifti,sub_folders(sub_ind,:)); % subject path
    
    for series = 1:series2take
        
        clear niftis
        path.series_nifti = fullfile(path.sub_nifti,series_names{series});
        
        if exist(path.series_nifti,'dir')
            if contains(series_names{series},'epi')
                niftis = spm_select('FPList',path.series_nifti,'^sub');
                %niftis = spm_select('FPList',path.series_nifti,'^epi');
            else
                niftis = spm_select('FPList',path.series_nifti,'^.');
            end
            fprintf(['Series ' num2str(series) '/' num2str(series2take) ': ' series_names{series} ' -- Files found: ' num2str(size(niftis,1)) '\n'])
            
            cd(path.series_nifti)
            
            for file = 1:size(niftis,1)
                if matches(series_names{series},'field_map_mag')
                    
                    newfile = ['sub' subID '-' series_names{series} '_' num2str(file) '.nii'];
                    
                    if ~exist(newfile,'file')
                        movefile(niftis(file,:),['sub' subID '-' series_names{series} '_' num2str(file) '.nii'])
                    end
                    
                elseif contains(series_names{series},'epi')
                    % no need to rename epis, already correct name due to
                    % 3D->4D conversion
%                     [~,name,ext] = fileparts(niftis(file,:));
%                     
%                     newfile = ['sub' subID '-' strrep(name,' ','') strrep(ext,' ','')];
%                     
%                     if ~exist(newfile,'file')
%                         movefile(niftis(file,:),newfile)
%                     end
                    
                else
                    
                    newfile = ['sub' subID '-' series_names{series} '.nii'];
                    
                    if ~exist(newfile,'file')
                        movefile(niftis(file,:),['sub' subID '-' series_names{series} '.nii'])
                    end
                    
                end
            end
            
        end
        
    end
    
end