function qualitycheck_con_norm_checkreg
%%Quality check for fMRI data, spinal cord

base_dir          = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\';
spm_path          = 'C:\Data\Toolboxes\spm12';

addpath(spm_path)

all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];
% all_subs     = [1 2 4:10 12:13 15:18 20:24 26:27 29:34 37:40 42:49]; % subs 11 and 25 not run
% all_subs2     = [1 2 4:7 12:13 15:18 24:27 29:30 37:39 42:44]; % if sc_proc data
% all_subs = setdiff(all_subs,all_subs2);
% data1 = true;
% data2 = false;

subs2check = all_subs(10:end);
%images2check = 2;

im_dir = '1stlevel\Version_01Mar23-spinal\HRF_phasic_tonic_RETROICOR';

for sub = subs2check
    
    clear images
    
    name        = sprintf('sub%0.3d',sub);
    
    con_dir  = [base_dir name filesep im_dir filesep];
    con_file = [con_dir 's_w_con_0001.nii'];
    
    t2_dir   = [base_dir name filesep 't2_spinalcord' filesep];
    t2_file  = [t2_dir 't2_norm_cropped.nii'];

    fprintf(['Doing volunteer ' name '\n']);
    
    images = char({con_file t2_file});
    
    % EPI volumes in checkreg
    spm_check_registration(images)
    
end

end