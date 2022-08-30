clear all

addpath('C:\Data\Toolboxes\spm12')

project.name = 'CPM-Pressure-01';
project.phase = 'Experiment-01';

path.code = pwd;
path.main = fullfile(path.code,'..','..','..','..');
path.nifti = fullfile(path.main,'data',project.name,project.phase,'mri','rawdata');

sub_folders = ls(path.nifti);
sub_folders = sub_folders(3:end,:);

epi_folders = {'epi-run1' 'epi-run2' 'epi-run3' 'epi-run4' 'epi-run5' 'epi-run6'};
series2take = size(epi_folders,2);


for sub = 48:50
    
    subID = ['sub' sprintf('%03d',sub);];
    sub_ind = find(contains(cellstr(sub_folders),subID)==1);
    
    fprintf(['\nConverting 3D to 4D... ' sub_folders(sub_ind,:) '\n------------------------------------------------\n'])
    
    path.sub_nifti = fullfile(path.nifti,sub_folders(sub_ind,:)); % subject path
    
    for series = 1:series2take
        
        path.series_nifti = fullfile(path.sub_nifti,epi_folders{series});
        
        if exist(path.series_nifti,'dir')
            
            niftis = spm_select('FPList',path.series_nifti,'fPRISMA*');
            niftis_brain = niftis(2:2:end,:);
            niftis_spinal = niftis(1:2:end,:);
            
            % discard first 5 dummy scans
            niftis_brain = niftis_brain(6:end,:);
            niftis_spinal = niftis_spinal(6:end,:);
            
            % subject 37 has too many volumes for Run 6, leave the rest out
            if sub == 37
                niftis_brain = niftis_brain(1:51,:);
                niftis_spinal = niftis_spinal(1:51,:);
            end
            
            fprintf(['EPI run ' num2str(series) '/' num2str(series2take) ': ' epi_folders{series} ' -- Files found BRAIN: ' num2str(size(niftis_brain,1)) '\n'])
            fprintf(['EPI run ' num2str(series) '/' num2str(series2take) ': ' epi_folders{series} ' -- Files found SPINAL: ' num2str(size(niftis_spinal,1)) '\n'])
            
            matlabbatch{1}.spm.util.cat.vols = cellstr(niftis_brain);
            matlabbatch{1}.spm.util.cat.name = [subID '-epi-run' num2str(series) '-brain.nii'];
            matlabbatch{1}.spm.util.cat.dtype = 4;
            matlabbatch{1}.spm.util.cat.RT = 1.991;
            
            matlabbatch{2}.spm.util.cat.vols = cellstr(niftis_spinal);
            matlabbatch{2}.spm.util.cat.name = [subID '-epi-run' num2str(series) '-spinal.nii'];
            matlabbatch{2}.spm.util.cat.dtype = 4;
            matlabbatch{2}.spm.util.cat.RT = 1.991;
            
            spm_jobman('run',matlabbatch);
            clear matlabbatch
            
        end
        
    end
    
end