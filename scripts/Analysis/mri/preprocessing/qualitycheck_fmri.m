function qualitycheck_fmri
%%Quality check for fMRI data, spinal cord
% 1. SPM check registration for T2 and each EPI run

hostname = char(getHostName(java.net.InetAddress.getLocalHost));
switch hostname
    case 'isnb05cda5ba721' % work laptop
        base_dir          = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\';
        base_dir2          = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\sc_proc\';
        sct_path          = 'C:\Users\ojala\spinalcordtoolbox';
        spm_path          = 'C:\Data\Toolboxes\spm12';
    otherwise
        error('Only host isnb05cda5ba721 (Karita work laptop) accepted');
end

addpath(spm_path)
addpath(sct_path)

% all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];
all_subs     = [1 2 4:10 12:13 15:18 20:24 26:27 29:34 37:40 42:49]; % subs 11 and 25 not run
% all_subs2     = [1 2 4:7 12:13 15:18 24:27 29:30 37:39 42:44]; % if sc_proc data
%all_subs = setdiff(all_subs,all_subs2);
data1 = true;
data2 = false;

for sub = 1:numel(all_subs)
    
    clear images
    
    name        = sprintf('sub%0.3d',all_subs(sub));
    a           = dir([base_dir name filesep 'epi-run*']);
    epi_folders = cellstr(strvcat(a.name));
    
    t2_dir   = [base_dir name filesep 't2_spinalcord' filesep];
    t2_file  = [t2_dir sprintf('%s-t2_spinalcord.nii.gz',name)];

    fprintf(['Doing volunteer ' name '\n']);
    
    epi_files = {};
    epi_ind = 1;
    
    for epi = [1 6]
        
        % Find EPIs in both data folders
%         func_name = sprintf('%s-epi-run%d-spinal_moco.nii.gz',name,epi);
        
        fprintf(['EPI run ' num2str(epi) '\n']);

        func_name = 'spinal_warped_t2.nii.gz';
        
        full_epi_dir = [base_dir name filesep epi_folders{epi}];
        full_epi_dir2 = strrep(full_epi_dir,'mri\data','mri\sc_proc');
        
        epi_file = spm_select('ExtFPListRec',full_epi_dir,['^' func_name '$']);
        epi_file2 = spm_select('ExtFPListRec',full_epi_dir2,['^' func_name '$']);
        
%         epi_file = epi_file(1:end-2);
%         epi_file2 = strrep(epi_file,'mri\data','mri\sc_proc');
        
%         % Gunzip both files
%         if ~exist([epi_file '.gz'],'file')
%             gunzip(epi_file,full_epi_dir)
%         end
%         
%         if ~exist([epi_file2 '.gz'],'file')
%             gunzip(epi_file2,full_epi_dir2)
%         end
%         
%         epi_file = [epi_file(1:end-3) ',1'];
%         epi_file2 = [epi_file2(1:end-3) ',1'];
        
        if all_subs(sub) == 11 || all_subs(sub) == 25 || (~data1 && data2)
            images = char(t2_file, epi_file2);
        elseif (data1 && ~data2)
            images = char(t2_file, epi_file);
        else
            images = char(t2_file, epi_file, epi_file2);
        end
        
        epi_files{epi_ind} = epi_file;
        epi_ind = epi_ind + 1;
        % Compare T2, and the two EPIs from the two datasets
         %spm_check_registration(images)
        
    end
    
    % Compare T2 and EPIs of different runs
    images = char(t2_file, epi_files{:});
    spm_check_registration(images)
    
end

end