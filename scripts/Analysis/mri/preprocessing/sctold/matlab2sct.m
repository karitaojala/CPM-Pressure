
function matlab2sct

% define the drive as in linux
base_dir = fullfile(cd,'..','..','..','..','data','CPM-Pressure-01','Experiment-01','mri','rawdata');

sct_gen  = 'bash -ic ';

cmd_qform         = '"sct_image -i %s -set-qform-to-sform"';
cmd_mean          = '"sct_maths -i %s -mean t -o %s"';
cmd_deep_seg_t2   = '"sct_deepseg_sc -i %s -o %s -c %s -qc %s"';
cmd_straighten_t2 = '"sct_straighten_spinalcord -i %s -s %s -o %s -ofolder %s"';

cmd_label      = '"sct_label_vertebrae -i %s -s %s -c %s -ofolder %s -qc %s"';
cmd_register   = '"sct_register_to_template -i %s -s %s -ldisc %s -c %s -ofolder %s -qc %s"';
cmd_multimodal = '"sct_register_multimodal -i %s -d %s -identity 1 -ofolder %s -qc %s"';

cmd_coregister = '"sct_register_multimodal -i %s -d %s -param step=1,type=im,algo=syn,metric=MI,iter=5,slicewise=0 -o %s -owarp %s -owarpinv %s -ofolder %s -qc %s"';
% MI seems a bit better than CC

cmd_mask           = '"sct_create_mask -i %s -p centerline,%s -size 35mm -f cylinder -o %s"';
cmd_moco           = '"sct_fmri_moco -i %s -m %s -qc-seg %s -ofolder %s -qc %s"';
cmd_norm_epi       = '"sct_register_multimodal -i %s -d %s -dseg %s -param step=1,type=im,algo=syn,metric=CC,iter=5,slicewise=0 -initwarp %s -initwarpinv %s -o %s -owarp %s -owarpinv %s -ofolder %s -qc %s"';
cmd_warp_epi       = '"sct_apply_transfo -i %s -d %s -w %s -o %s"';
cmd_deep_seg_epi   = '"sct_deepseg_sc -i %s -o %s -c %s -qc %s -centerline svm -kernel 2d"';

cmd_straighten_epi = '"sct_straighten_spinalcord -i %s -s %s -o %s -ofolder %s"';

epi_template        = '~/spinalcordtoolbox/data/PAM50/template/PAM50_t2s.nii.gz';
% epi_template        = 'PAM50_t2s.nii.gz';
t2_template         = '~/spinalcordtoolbox/data/PAM50/template/PAM50_t2.nii.gz';
t2s_template        = '~/spinalcordtoolbox/data/PAM50/template/PAM50_t2s.nii.gz';
warped_epi_template = '~/spinalcordtoolbox/data/PAM50/template/PAM50_t2s_reg.nii.gz';
        
sub_folders = ls(base_dir);
sub_folders = sub_folders(3:end,:);

for sub = 1

    sub_folder = sub_folders(1,:);
    subID = sub_folder(1:6);
    
    qc_dir   = fullfile(base_dir,sub_folder,'qualitycontrol');
    if ~exist(qc_dir,'dir')
        mkdir(qc_dir)
    end

    for run = 1:6
        
        epi_folder          = fullfile(base_dir,sub_folder,['epi-run' num2str(run)]);
        epi_name            = [subID '-epi-run' num2str(run) '-4D-spinal'];
        epi_file            = [epi_name '.nii.gz'];
        epi_mask_file       = [epi_name '-mask.nii.gz'];
        epi_mean_file       = [epi_name '-mean.nii.gz'];
        epi_moco_mean_file  = [epi_name '-moco_mean.nii.gz'];
        epi_moco_mean_seg_file  = [epi_name '-moco_mean_seg.nii.gz'];
        epi_moco_mean_norm_file = [epi_name '-moco_mean_norm.nii.gz'];
        
        epi_mean_reg_file    = [epi_name '-mean_reg.nii.gz'];
        epi_warp2templ       = [epi_name '-warp_epi2template.nii.gz'];
        epi_warp2templ_inv   = [epi_name '-warp_template2epi.nii.gz'];
        
        epi_warp2t2          = [epi_name '-warp_epi2t2.nii.gz'];
        epi_warp2t2_inv      = [epi_name '-warp_t22epi.nii.gz'];
        epi_warped2t2        = [epi_name '-warped_t2.nii.gz'];
        epi_straight         = 'epi_straight.nii.gz';
        epi_mod              = 't2s';
        
        t1_file         = [subID '-t1_corrected.nii.gz'];
        t1_seg_file     = [subID '-t1_seg.nii.gz'];
        t1_mod          = 't1';
        
        t2_folder       = fullfile(base_dir,sub_folder,'t2_spinalcord');
        t2_file         = [subID '-t2_spinalcord.nii.gz'];
        t2_seg_file     = [subID '-t2_seg.nii.gz'];
        t2_seg_reg_file = [subID '-t2_seg_reg.nii.gz'];
        t2_label_d_file = [subID '-t2_seg_labeled_discs.nii.gz'];
        t2_straight     = [subID '-t2_straight.nii.gz'];
        t2_warp2templ       = [subID '-warp_anat2template.nii.gz'];
        t2_warp2templ_inv   = [subID '-warp_template2anat.nii.gz'];
        t2_mod              = 't2';
        
        
        %% fix qform mismatch
        command = sprintf([sct_gen cmd_qform],p2wsl([t2_folder t2_file]));
        run(command);
        %command = sprintf([sct_gen cmd_qform],p2wsl([base_dir t1_file]));
        %run(command);
        
        %% find SC in T2 image
        command = sprintf([sct_gen cmd_deep_seg_t2],p2wsl([t2_folder t2_file]),p2wsl([t2_folder t2_seg_file]),t2_mod,p2wsl(qc_dir));
        run(command);
        % let's have a look
        spm_check_registration(strvcat([t2_folder t2_file],[t2_folder t2_seg_file]));input('press return to continue');
        
        %% straighten T2 image
        %cmd_straighten = '"sct_straighten_spinalcord -i %s -s %s -o %s -ofolder %s"';
        command = sprintf([sct_gen cmd_straighten_t2],p2wsl([t2_folder t2_file]),p2wsl([t2_folder t2_seg_file]),p2wsl([t2_folder t2_straight]),p2wsl(qc_dir));
        run(command);
        % let's have a look
        spm_check_registration(strvcat([t2_folder t2_file],[t2_folder t2_straight]));input('press return to continue');
        
        %% Label vertebrae in T2
        command = sprintf([sct_gen cmd_label],p2wsl([t2_folder t2_file]),p2wsl([t2_folder t2_seg_file]),t2_mod,p2wsl(t2_folder),p2wsl(qc_dir));
        run(command);
        
        %% register T2 to template
        command = sprintf([sct_gen cmd_register],p2wsl([t2_folder t2_file]),p2wsl([t2_folder t2_seg_file]),p2wsl([t2_folder t2_label_d_file]),t2_mod,p2wsl(t2_folder),p2wsl(qc_dir));
        run(command);
        
        %% epi stuff
        
        %% create mean epi
        command = sprintf([sct_gen cmd_mean],p2wsl([epi_folder epi_file]),p2wsl([epi_folder epi_mean_file]));
        run(command);
        
        %% Coarse register epi to T2
        command = sprintf([sct_gen cmd_multimodal],p2wsl([t2_file t2_seg_file]),p2wsl([epi_folder epi_mean_file]),p2wsl(epi_folder),p2wsl(qc_dir));
        run(command);
        % let's have a look
        spm_check_registration(strvcat([t2_folder t2_file],[epi_folder epi_mean_reg_file]));input('press return to continue');
        
        %% create mask
        command = sprintf([sct_gen cmd_mask],p2wsl([epi_folder epi_file]),p2wsl([t2_folder t2_seg_reg_file]),p2wsl([epi_folder epi_mask_file]));
        run(command);
        
        %% motion correction
        command = sprintf([sct_gen cmd_moco],p2wsl([epi_folder epi_file]),p2wsl([epi_folder epi_mask_file]),p2wsl([t2_folder t2_seg_reg_file]),p2wsl(epi_folder),p2wsl(qc_dir));
        run(command);
        
        %% Precise Coregister mean to T2
        % command = sprintf([sct_gen cmd_coregister],p2wsl([base_dir epi_moco_mean_file]),p2wsl([base_dir t2_file]),p2wsl([base_dir epi_warped2t2]),p2wsl([base_dir epi_warp2t2_inv]),p2wsl([base_dir epi_warp2t2]),p2wsl(base_dir),p2wsl(qc_dir));
        %run(command);
        %spm_check_registration(strvcat([base_dir epi_moco_mean_file],[base_dir epi_warped2t2],[base_dir t2_file]));input('press return to continue');
        
        %% find SC in epi image
        % command = sprintf([sct_gen cmd_deep_seg_epi],p2wsl([base_dir epi_moco_mean_file]),p2wsl([base_dir epi_moco_mean_seg_file]),epi_mod,p2wsl(qc_dir));
        % run(command);
        % let's have a look
        % spm_check_registration(strvcat([base_dir epi_moco_mean_file],[base_dir epi_moco_mean_seg_file]));input('press return to continue');
        
        %% Label vertebrae in EPI $$$
        %command = sprintf([sct_gen cmd_label],p2wsl([base_dir epi_moco_mean_file]),p2wsl([base_dir epi_moco_mean_seg_file]),t2_mod,p2wsl(base_dir),p2wsl(qc_dir));
        %run(command);
        
        %% straighten EPI image
        % command = sprintf([sct_gen cmd_straighten_epi],p2wsl([base_dir epi_moco_mean_file]),p2wsl([base_dir epi_moco_mean_seg_file]),p2wsl([base_dir epi_straight]),p2wsl(qc_dir));
        % run(command);
        % let's have a look
        % spm_check_registration(strvcat([base_dir epi_moco_mean_file],[base_dir epi_moco_mean_seg_file],[base_dir epi_straight]));input('press return to continue');
        
        %% epi to template normalisation
        % command = sprintf([sct_gen cmd_norm_epi],p2wsl([base_dir epi_template]),p2wsl([base_dir epi_moco_mean_file]),p2wsl([base_dir t2_seg_reg_file]),p2wsl([base_dir t2_warp2templ_inv]),p2wsl([base_dir t2_warp2templ]),p2wsl([base_dir warped_epi_template]),p2wsl([base_dir epi_warp2templ_inv]),p2wsl([base_dir epi_warp2templ]),p2wsl(base_dir),p2wsl(qc_dir));
        % run(command);
        % spm_check_registration(strvcat([base_dir epi_moco_mean_file],[base_dir warped_epi_template],[base_dir t2_file]));input('press return to continue');
        
        %% warp mean epi to template
        % command = sprintf([sct_gen cmd_warp_epi],p2wsl([base_dir epi_moco_mean_file]),p2wsl([base_dir t2s_template]),p2wsl([base_dir epi_warp2templ]),p2wsl([base_dir epi_moco_mean_norm_file]));
        % run(command);
        % spm_check_registration(strvcat([base_dir epi_moco_mean_file],[base_dir epi_moco_mean_norm_file],[base_dir t2s_template]));input('press return to continue');
        
    end
    
end


function out = p2wsl(in)
out = strrep(in, 'c:', '/mnt/c');
out = strrep(out,'\','/');

function [stat, log] = run(command)
fprintf('Running: %s \n',command)
[stat, log] = system(command,'-echo');
if stat ~= 0
    error(log);
end

