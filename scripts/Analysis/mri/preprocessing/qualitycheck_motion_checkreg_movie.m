function qualitycheck_motion_checkreg_movie
%%Quality check for fMRI data, spinal cord
% 1. SPM check registration for T2 and each EPI run

hostname = char(getHostName(java.net.InetAddress.getLocalHost));
switch hostname
    case 'isnb05cda5ba721' % work laptop
        base_dir          = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\';
        base_dir2          = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\sc_proc\';
        l_string          = '';
        n_proc            = 2; % maximum processes on 2 cores
        sct_path          = 'C:\Users\ojala\spinalcordtoolbox';
        spm_path          = 'C:\Data\Toolboxes\spm12';
    otherwise
        error('Only host isnb05cda5ba721 (Karita work laptop) accepted');
end

addpath(spm_path)
addpath(sct_path)

% all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];
% all_subs     = [1 2 4:10 12:13 15:18 20:24 26:27 29:34 37:40 42:49]; % subs 11 and 25 not run
% all_subs2     = [1 2 4:7 12:13 15:18 24:27 29:30 37:39 42:44]; % if sc_proc data
% all_subs = setdiff(all_subs,all_subs2);
% data1 = true;
% data2 = false;

subs2check = 8;
epis2check = 2;

for sub = subs2check
    
    clear images
    
    name        = sprintf('sub%0.3d',sub);
    a           = dir([base_dir name filesep 'epi-run*']);
    epi_folders = cellstr(strvcat(a.name));
    
%     t2_dir   = [base_dir name filesep 't2_spinalcord' filesep];
%     t2_file  = [t2_dir sprintf('%s-t2_spinalcord.nii.gz',name)];

    fprintf(['Doing volunteer ' name '\n']);
    
    for epi = epis2check
        
        % Find EPIs in both data folders
%         func_name = sprintf('%s-epi-run%d-spinal_moco.nii.gz',name,epi);
        
        fprintf(['EPI run ' num2str(epi) '\n']);

        func_name = ['a' name '-epi-run' num2str(epi) '-spinal_moco.nii.gz'];
        
        full_epi_dir = [base_dir name filesep epi_folders{epi}];
        
        epi_file = spm_select('ExtFPListRec',full_epi_dir,['^' func_name '$']);
        
        epi_file = epi_file(1:end-2);
        
        % Gunzip file
        if ~exist([epi_file '.gz'],'file')
            gunzip(epi_file,full_epi_dir)
        end
        
        epi_files = spm_select('ExtFPListRec',full_epi_dir,['^' func_name(1:end-3) '$']);
        
        images = char(epi_files);
        
        % EPI volumes in checkreg
        spm_check_registration(images)
        
    end
    
end

end