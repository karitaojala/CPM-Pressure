function create_spinal_masks(options)

% Creating masks for ROI analysis in the spinal cord
% Dorsal horn + intermediate region, divided into left and right side
% SCT spinal level 5, 6, 7 corresponding to vertebral levels C4, C5, C6

secondlvlpath = fullfile(options.path.mridir,'2ndlevel','meanmasks');

mask_dhL = spm_select('ExtFPList', secondlvlpath, 'PAM50_atlas_dorsalhorn_left.nii');
% mask_izL = spm_select('ExtFPList', secondlvlpath, 'PAM50_atlas_intermzone_left.nii');

mask_dhR = spm_select('ExtFPList', secondlvlpath, 'PAM50_atlas_dorsalhorn_right.nii');
% mask_izR = spm_select('ExtFPList', secondlvlpath, 'PAM50_atlas_intermzone_right.nii');

% masks_region = {mask_dhL mask_dhR mask_izL mask_izR};
masks_region = {mask_dhL mask_dhR};

mask_spinal5 = spm_select('ExtFPList', secondlvlpath, 'spinal_level_05.nii');
mask_spinal6 = spm_select('ExtFPList', secondlvlpath, 'spinal_level_06.nii');
mask_spinal7 = spm_select('ExtFPList', secondlvlpath, 'spinal_level_07.nii');

masks_splvl = {mask_spinal5 mask_spinal6 mask_spinal7};

output_mask_name = {'mask-left-dorsalhorn-spinal_level_' 'mask-right-dorsalhorn-spinal_level_'};
% output_mask_name = {'dorsalhorn_left-spinal_level_' 'intermzone_left-spinal_level_' ...
%     'dorsalhorn_right-spinal_level_' 'intermzone_right-spinal_level_'};

n_batch = 1;

for splvl = 1:3
    
    for side = 1:2
        
        mask_splvl = masks_splvl{splvl};
        splvl_name = num2str(mask_splvl(end-6));
        mask_reg1 = masks_region{side};
%         mask_reg2 = masks_region{side+2};
        output_name = [output_mask_name{side} splvl_name '.nii'];
        
        % Intersection
% %         matlabbatch{n_batch}.spm.util.imcalc.input          = cellstr(char(mask_reg1,mask_reg2,mask_splvl));
%         matlabbatch{n_batch}.spm.util.imcalc.input          = cellstr(char(mask_reg1,mask_splvl));
%         matlabbatch{n_batch}.spm.util.imcalc.output         = output_name;
%         matlabbatch{n_batch}.spm.util.imcalc.outdir         = {secondlvlpath};
% %         matlabbatch{n_batch}.spm.util.imcalc.expression     = '((i1+i2).*(i3>0.01))>0';
%         matlabbatch{n_batch}.spm.util.imcalc.expression     = '(i1.*(i2>0.01))>0';
%         n_batch = n_batch + 1;
%         
%         % Smoothing with 1 mm
        matlabbatch{n_batch+1}.spm.spatial.smooth.data = {fullfile(secondlvlpath,output_name)};
        matlabbatch{n_batch+1}.spm.spatial.smooth.fwhm = [0.5 0.5 0.5];
        matlabbatch{n_batch+1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{n_batch+1}.spm.spatial.smooth.im = 0;
        matlabbatch{n_batch+1}.spm.spatial.smooth.prefix = 's_';
        n_batch = n_batch + 1;
        
        % Binarize to be sure
        matlabbatch{n_batch}.spm.util.imcalc.input          = cellstr(fullfile(secondlvlpath,['s_' output_name]));
        matlabbatch{n_batch}.spm.util.imcalc.output         = ['bin_s_' output_name '_05mm'];
        matlabbatch{n_batch}.spm.util.imcalc.outdir         = {secondlvlpath};
        matlabbatch{n_batch}.spm.util.imcalc.expression     = 'i1>0';
        n_batch = n_batch + 1;
        
    end
    
end

%% Run matlabbatch
spm_jobman('run', matlabbatch);
clear matlabbatch

end