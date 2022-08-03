
function sct_fmri_T2(base_dir, name)

templ_dir = 'C:\Users\ojala\spinalcordtoolbox\data\PAM50\template\'; %requires native windows install

% sct_gen   = 'bash -ic ';
sct_gen   = '';

cparam_1 = '-param step=1,type=seg,algo=affine,metric=MeanSquares,smooth=10'; % just affine, just segments ... 10mm makes it more robust
                                                                              % initially had 1st step as affine, but when incr smooth to 20 it zoomed the cord
                                                                              % finally simple 2dof as first step with large smoothness gets the segments over each other
                                                                              
cparam_2 = '-param step=1,type=seg,algo=translation,metric=MeanSquares,smooth=20:step=2,type=seg,algo=affine,metric=MeanSquares:step=3,type=im,algo=syn,metric=MI,iter=5'; % had to add step 1 with 10mm smoothing to get non-overlapping segs to come together

%cmd_slicetime      = '"slicetimer -i %s -o %s "'; % to be completed


cmd_qform          = '"sct_image -i %s -set-qform-to-sform"';
cmd_mean           = '"sct_maths -i %s -mean t -o %s"';
cmd_deep_seg_t2    = '"sct_deepseg_sc -i %s -o %s -c %s -kernel 3d -qc %s"';
%cmd_deep_seg_t2    = '"sct_deepseg_sc -i %s -o %s -c %s -qc %s"'; % older 2d version which did not work well for some subjects
cmd_centerline_t2  = '"sct_get_centerline -i %s -c %s -method fitseg -o %s -qc %s"';
cmd_multimodal     = '"sct_register_multimodal -i %s -d %s -identity 1 -ofolder %s -qc %s"';
cmd_mask           = '"sct_create_mask -i %s -p centerline,%s -size 35mm -f cylinder -o %s"';
cmd_moco           = '"sct_fmri_moco -i %s -m %s -qc-seg %s -ofolder %s -qc %s"';
cmd_label          = '"sct_label_vertebrae -i %s -s %s -c %s -ofolder %s -qc %s"';
cmd_register       = '"sct_register_to_template -i %s -s %s -ldisc %s -c %s -ofolder %s -qc %s"';

cmd_moco           = '"sct_fmri_moco -i %s -m %s -qc-seg %s -ofolder %s -qc %s"';

cmd_coregister_t2_epi  = ['"sct_register_multimodal -i %s -iseg %s -d %s -dseg %s ' cparam_1 ' -o %s -ofolder %s -qc %s"']; % coarse just to create a mask
cmd_coregister         = ['"sct_register_multimodal -i %s -iseg %s -d %s -dseg %s ' cparam_2 ' -o %s -owarp %s -owarpinv %s -ofolder %s -qc %s"'];

cmd_deep_seg_epi_2d   = '"sct_deepseg_sc -i %s -o %s -c %s -qc %s -centerline svm -kernel 2d"';

cmd_apply_transform   = '"sct_apply_transfo -i %s -d %s -o %s -w %s"';

epi_mask_file       = 'spinal_mask.nii.gz';
epi_mean_file       = 'spinal_mean.nii.gz';
epi_mean_seg_file   = 'spinal_mean_seg.nii.gz';
epi_mean_reg_file   = 'spinal_mean_reg.nii.gz';
epi_moco_mean_seg_file  = 'spinal_moco_mean_seg.nii.gz';
epi_moco_mean_norm_file = 'spinal_moco_mean_norm.nii.gz';

epi_warp2t2          = 'warp_epi2t2.nii.gz';
epi_warp2t2_inv      = 'warp_t22epi.nii.gz';

epi_warped2t2        = 'spinal_warped_t2.nii.gz';

t2_seg_file          = 't2_seg.nii.gz';
t2_seg_center_file   = 't2_seg_center.nii.gz';

t2_template_win         = 'PAM50_t2.nii.gz';
t2_template_win_levels  = 'PAM50_levels.nii.gz';
t2_template_win_gm      = 'PAM50_gm.nii.gz';
t2_template_win_cord    = 'PAM50_cord.nii.gz';
t2_reg_coarse_file      = 't2_reg_coarse.nii.gz';
t2_reg_coarse_seg_file  = 't2_reg_coarse_seg.nii.gz';

t2_label_d_file         = 't2_seg_labeled_discs.nii.gz';

t2_warp2template        = 'warp_anat2template.nii.gz';
t2_warp2template_inv    = 'warp_template2anat.nii.gz';

t2_mod               = 't2';
epi_mod              = 't2s';

% if nargin < 2
% base_dir = 'c:\Users\buechel\Data\cpm\mri\data\';
% name     = 'sub045';
% end
%% start with house keeping

a    = dir([base_dir name filesep 'epi-run*']);

epi_dirs = cellstr([strvcat(a.folder) repmat(filesep,numel(a),1) strvcat(a.name) repmat(filesep,numel(a),1)]);
t2_dir   = [base_dir name filesep 't2_spinalcord' filesep];
t2_file  = sprintf('%s-t2_spinalcord.nii.gz',name);

% cd(t2_dir)

%%now do T2 related stuff
% fix qform mismatch
qc_dir   = [t2_dir 'qc'];
command = sprintf([sct_gen cmd_qform],p2wsl([t2_dir t2_file]));
run(command);

% Segment t2
command = sprintf([sct_gen cmd_deep_seg_t2],p2wsl([t2_dir t2_file]),p2wsl([t2_dir t2_seg_file]),t2_mod,p2wsl(qc_dir));
run(command);
% let's have a look
% spm_check_registration(strvcat([t2_dir t2_file],[t2_dir t2_seg_file]));input('press return to continue');

% Find centerline in segmented t2
command = sprintf([sct_gen cmd_centerline_t2],p2wsl([t2_dir t2_seg_file]),t2_mod,p2wsl([t2_dir t2_seg_center_file]),p2wsl(qc_dir));
run(command);

% Label vertebrae in T2
command = sprintf([sct_gen cmd_label],p2wsl([t2_dir t2_file]),p2wsl([t2_dir t2_seg_file]),t2_mod,p2wsl(t2_dir),p2wsl(qc_dir));
run(command);

% Register T2 to template
command = sprintf([sct_gen cmd_register],p2wsl([t2_dir t2_file]),p2wsl([t2_dir t2_seg_file]),p2wsl([t2_dir t2_label_d_file]),t2_mod,p2wsl(t2_dir),p2wsl(qc_dir));
run(command);

% WSL : 238s ; native Windows 263s

for ep=1:numel(epi_dirs)
%for ep=3
    qc_dir   = [epi_dirs{ep} 'qc'];
    epi_file  = sprintf('a%s-epi-run%s-spinal.nii.gz',name,num2str(ep));
    
    epi_moco_mean_file  = sprintf('a%s-epi-run%s-spinal_moco_mean.nii.gz',name,num2str(ep));
    
    copyfile([t2_dir t2_file],epi_dirs{ep});
    copyfile([t2_dir t2_seg_file],epi_dirs{ep});
    
    % create mean epi
    command = sprintf([sct_gen cmd_mean],p2wsl([epi_dirs{ep} epi_file]),p2wsl([epi_dirs{ep} epi_mean_file]));
    run(command);
    
    %segment mean EPI
    command = sprintf([sct_gen cmd_deep_seg_epi_2d],p2wsl([epi_dirs{ep} epi_mean_file]),p2wsl([epi_dirs{ep} epi_mean_seg_file]),epi_mod,p2wsl(qc_dir));
    run(command);
    
    % Coarse register T2 to EPI for mask
    command = sprintf([sct_gen cmd_coregister_t2_epi],p2wsl([epi_dirs{ep} t2_file]),p2wsl([epi_dirs{ep} t2_seg_file]),p2wsl([epi_dirs{ep} epi_mean_file]),p2wsl([epi_dirs{ep} epi_mean_seg_file]),p2wsl([epi_dirs{ep} t2_reg_coarse_file]),p2wsl(epi_dirs{ep}),p2wsl(qc_dir));
    run(command);
    
    % now segment it to get a good centerline
    command = sprintf([sct_gen cmd_deep_seg_t2],p2wsl([epi_dirs{ep} t2_reg_coarse_file]),p2wsl([epi_dirs{ep} t2_reg_coarse_seg_file]),t2_mod,p2wsl(qc_dir));
    run(command);
    
    % and create a mask
    command = sprintf([sct_gen cmd_mask],p2wsl([epi_dirs{ep} epi_file]),p2wsl([epi_dirs{ep} t2_reg_coarse_seg_file]),p2wsl([epi_dirs{ep} epi_mask_file]));
    run(command);
    
    %run moco
    command = sprintf([sct_gen cmd_moco],p2wsl([epi_dirs{ep} epi_file]),p2wsl([epi_dirs{ep} epi_mask_file]),p2wsl([epi_dirs{ep} epi_mean_seg_file]),p2wsl(epi_dirs{ep}),p2wsl(qc_dir));
    run(command);
    
    %segment mean moco EPI --> this should be better than the segmented mean
    command = sprintf([sct_gen cmd_deep_seg_epi_2d],p2wsl([epi_dirs{ep} epi_moco_mean_file]),p2wsl([epi_dirs{ep} epi_moco_mean_seg_file]),epi_mod,p2wsl(qc_dir));
    run(command);
    
    % Precise Coregister mean to T2
    command = sprintf([sct_gen cmd_coregister],p2wsl([epi_dirs{ep} epi_moco_mean_file]),p2wsl([epi_dirs{ep} epi_moco_mean_seg_file]),p2wsl([t2_dir t2_file]),p2wsl([t2_dir t2_seg_file]),p2wsl([epi_dirs{ep} epi_warped2t2]),p2wsl([epi_dirs{ep} epi_warp2t2_inv]),p2wsl([epi_dirs{ep} epi_warp2t2]),p2wsl(epi_dirs{ep}),p2wsl(qc_dir));
    run(command);
    %spm_check_registration(strvcat([epi_dirs{ep} epi_moco_mean_file],[epi_dirs{ep} epi_moco_mean_seg_file],[t2_dir t2_file],[t2_dir t2_seg_file],[epi_dirs{ep}  epi_warped2t2]));
    
    warp_combined = [p2wsl([epi_dirs{ep} epi_warp2t2_inv]) ' ' p2wsl([t2_dir t2_warp2template])];
    
    command = sprintf([sct_gen cmd_apply_transform],p2wsl([epi_dirs{ep} epi_moco_mean_file]),p2wsl([templ_dir t2_template_win]),p2wsl([epi_dirs{ep} epi_moco_mean_norm_file]),warp_combined);
    run(command);
    %spm_check_registration(strvcat([epi_dirs{ep} epi_moco_mean_file],[epi_dirs{ep} epi_moco_mean_norm_file],[t2_dir t2_file],[templ_dir t2_template_win],[templ_dir t2_template_win_cord]));
    
end


function out = p2wsl(in)
% out = strrep(in, 'c:', '/mnt/c');
% out = strrep(out, 'd:', '/mnt/d');
% out = strrep(out,'\','/');
out = in; %bypass for win

function [stat, log] = run(command)
command(1)   = [];
command(end) = []; %get rid of " needed for WSL bash

fprintf('Running: %s \n',command)
[stat, log] = system(command,'-echo');
if stat ~= 0
    error(log);
end

