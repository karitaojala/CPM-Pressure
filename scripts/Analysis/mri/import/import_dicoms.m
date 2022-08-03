%function import_dicoms
clear all

addpath('C:\Data\Toolboxes\spm12')

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..','..');
path.dicom = fullfile(path.main,'data',project.name,project.phase,'mri','sourcedata');
path.nifti = fullfile(path.main,'data',project.name,project.phase,'mri','rawdata');

sub_folders = ls(path.dicom);
sub_folders = sub_folders(3:end,:);

series_names = {'field_map_mag' 'field_map_phase' 't1_corrected' 't1_uncorrected' 't2_spinalcord' ...
    'epi-run1' 'epi-run2' 'epi-run3' 'epi-run4' 'epi-run5' 'epi-run6'};
series2take = size(series_names,2);

for sub = 48:size(sub_folders,1)
    fprintf(['\nConverting DICOM to NIFTI... ' sub_folders(sub,:) '\n------------------------------------------------\n'])
    path.sub_dicom = fullfile(path.dicom,sub_folders(sub,:),'DICOM'); % subject path
    
    for series = 1:series2take
        
        path.series_dicom = fullfile(path.sub_dicom,series_names{series}); 
        path.series_nifti = fullfile(path.nifti,sub_folders(sub,:),series_names{series}); 
        
        if ~exist(path.series_nifti,'dir')
            mkdir(path.series_nifti)
        end
        
        if exist(path.series_dicom,'dir') && exist(path.series_nifti,'dir')
            dicoms = spm_select('FPList',path.series_dicom,'MR.*');
            fprintf(['Series ' num2str(series) '/' num2str(series2take) ': ' series_names{series} ' -- Files found: ' num2str(size(dicoms,1)) '\n'])
            
            matlabbatch{series}.spm.util.import.dicom.data = cellstr(dicoms);
            matlabbatch{series}.spm.util.import.dicom.root = 'flat';
            matlabbatch{series}.spm.util.import.dicom.outdir = {path.series_nifti};
            matlabbatch{series}.spm.util.import.dicom.protfilter = '.*';
            matlabbatch{series}.spm.util.import.dicom.convopts.format = 'nii';
            matlabbatch{series}.spm.util.import.dicom.convopts.meta = 0;
            matlabbatch{series}.spm.util.import.dicom.convopts.icedims = 0;
        end
        
    end
    
    spm_jobman('run',matlabbatch);
    clear matlabbatch
    
end