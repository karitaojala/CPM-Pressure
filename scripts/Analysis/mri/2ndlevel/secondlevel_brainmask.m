function secondlevel_brainmask(options)

%mask_name = [options.preproc.norm_prefix 'mask.nii'];
%masks = cell(length(subj), 1);

%secondlvlpath = fullfile(options.path.mridir,'2ndlevel',['Version_' analysis_version],modelname);

% sub_ind = 1;
% 
% for sub = subj
%     
%     name = sprintf('sub%03d',sub);
%     disp(name);
%     
%     firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
%     
%     maskfile = spm_select('FPList', firstlvlpath, mask_name);
%     assert(size(maskfile, 1) == 1);
%     masks{sub_ind} = maskfile;
%     
%     
%     sub_ind = sub_ind + 1;
%     
% end

secondlvlpath = fullfile(options.path.mridir,'2ndlevel','meanmasks');

mask1 = spm_select('ExtFPList', secondlvlpath, 'mean_wmean.nii');
mask2 = spm_select('ExtFPList', secondlvlpath, 'mean_wskull.nii');

matlabbatch{1}.spm.util.imcalc.input          = cellstr(char(mask1,mask2));
matlabbatch{1}.spm.util.imcalc.output         = options.stats.secondlvl.mask_name;
matlabbatch{1}.spm.util.imcalc.outdir         = {secondlvlpath};
% only take voxels where we have data from all subjects
% matlabbatch{1}.spm.util.imcalc.expression     = 'all(X)';
matlabbatch{1}.spm.util.imcalc.expression     = '(i1.*i2)>0.8';

% Smoothing with 2 mm
matlabbatch{2}.spm.spatial.smooth.data = {fullfile(secondlvlpath,options.stats.secondlvl.mask_name)};
matlabbatch{2}.spm.spatial.smooth.fwhm = [2 2 2];
matlabbatch{2}.spm.spatial.smooth.dtype = 0;
matlabbatch{2}.spm.spatial.smooth.im = 0;
matlabbatch{2}.spm.spatial.smooth.prefix = 's_';

% Final thresholding
matlabbatch{3}.spm.util.imcalc.input = {fullfile(secondlvlpath,['s_' options.stats.secondlvl.mask_name])};
matlabbatch{3}.spm.util.imcalc.output = options.stats.secondlvl.mask_name;
matlabbatch{3}.spm.util.imcalc.outdir = {secondlvlpath};
matlabbatch{3}.spm.util.imcalc.expression = 'i1>0';

%% Run matlabbatch
spm_jobman('run', matlabbatch);
clear matlabbatch

end