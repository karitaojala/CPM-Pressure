function matlabbatch = physio_batch(spinal,physio_name,sub_id,run_id,output_dir,physio_file,motion_file,no_motion_reg,relative_start_acquisition,no_scans_run,n_slices,onset_slice,time_slice_to_slice)

version_name = erase(physio_name,'-');
output_dir_version = fullfile(output_dir,version_name);
if ~exist(output_dir_version,'dir'); mkdir(output_dir_version); end

% Physio regressors run-wise

matlabbatch{1}.spm.tools.physio.save_dir = {output_dir_version};

matlabbatch{1}.spm.tools.physio.log_files.vendor = 'BIDS';
matlabbatch{1}.spm.tools.physio.log_files.cardiac = {physio_file};
matlabbatch{1}.spm.tools.physio.log_files.respiration = {''};
matlabbatch{1}.spm.tools.physio.log_files.scan_timing = {''};
matlabbatch{1}.spm.tools.physio.log_files.sampling_interval = [];
matlabbatch{1}.spm.tools.physio.log_files.relative_start_acquisition = relative_start_acquisition;
matlabbatch{1}.spm.tools.physio.log_files.align_scan = 'first';

matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nslices = n_slices;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.NslicesPerBeat = [];
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.TR = 1.991;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Ndummies = 0; % dummies already removed
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nscans = no_scans_run;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.onset_slice = onset_slice;
%matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.time_slice_to_slice = time_slice_to_slice;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nprep = 0;
matlabbatch{1}.spm.tools.physio.scan_timing.sync.scan_timing_log = struct([]);

matlabbatch{1}.spm.tools.physio.preproc.cardiac.modality = 'PPU';
matlabbatch{1}.spm.tools.physio.preproc.respiratory.filter.passband = [0.05 2];
matlabbatch{1}.spm.tools.physio.preproc.respiratory.despike = true;

if spinal; brain_or_spinal = 'spinal'; else; brain_or_spinal = 'brain'; end
matlabbatch{1}.spm.tools.physio.model.output_multiple_regressors = [sub_id '-' run_id '-multiple_regressors-' brain_or_spinal '-' version_name '.txt'];
matlabbatch{1}.spm.tools.physio.model.output_physio = [sub_id '-' run_id '-physio-' brain_or_spinal '-' version_name '.mat'];
% matlabbatch{1}.spm.tools.physio.model.output_physio = [sub_id '-' run_id '-physio-' output_suffix '.mat'];

matlabbatch{1}.spm.tools.physio.model.orthogonalise = 'none'; % done later manually
matlabbatch{1}.spm.tools.physio.model.censor_unreliable_recording_intervals = false;

matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.c = 3;
matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.r = 4;
matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.cr = 1;
% matlabbatch{1}.spm.tools.physio.model.retroicor.no = struct([]);
% matlabbatch{1}.spm.tools.physio.model.rvt.yes.method = 'hilbert';
% matlabbatch{1}.spm.tools.physio.model.rvt.yes.delays = 0;
% matlabbatch{1}.spm.tools.physio.model.hrv.yes.delays = 0;
% matlabbatch{1}.spm.tools.physio.model.rvt.yes.delays = [-5, 5, 10, 15];
% matlabbatch{1}.spm.tools.physio.model.hrv.yes.delays = [-5, 5, 10, 15];
matlabbatch{1}.spm.tools.physio.model.rvt.no = struct([]);
matlabbatch{1}.spm.tools.physio.model.hrv.no = struct([]);
% matlabbatch{1}.spm.tools.physio.model.noise_rois.no = struct([]);
fmri_file = fullfile(output_dir,'..','..','mri','data',sub_id,['epi-' run_id],['ra' sub_id '-epi-' run_id '-brain.nii']);
roi_file_wm = fullfile(output_dir,'..','..','mri','data',sub_id,'t1_corrected','noiseROI',['inv_nlin_c2' sub_id '-t1_corrected.nii']);
roi_file_csf = fullfile(output_dir,'..','..','mri','data',sub_id,'t1_corrected','noiseROI',['inv_nlin_c3' sub_id '-t1_corrected.nii']);
roi_file_wm_x_csf = fullfile(output_dir,'..','..','mri','data',sub_id,'t1_corrected','noiseROI',['inv_nlin_c2xc3' sub_id '-t1_corrected.nii']);
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.fmri_files = {fmri_file};
% matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.roi_files = {roi_file_wm roi_file_csf}';
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.roi_files = {roi_file_wm roi_file_csf roi_file_wm_x_csf}';
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.force_coregister = 'No';
% matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.thresholds = 0.7; % for WM or CSF
% matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.n_voxel_crop = 1; % for WM or CSF
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.thresholds = [0.7 0.5 0.05]; % for WM x CSF boundary
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.n_voxel_crop = [1 1 0]; % for WM x CSF boundary
matlabbatch{1}.spm.tools.physio.model.noise_rois.yes.n_components = 6;

matlabbatch{1}.spm.tools.physio.model.movement.yes.file_realignment_parameters = {motion_file}; % Realignment motion regressors file
matlabbatch{1}.spm.tools.physio.model.movement.yes.order = no_motion_reg; % Number of motion regressors
matlabbatch{1}.spm.tools.physio.model.movement.yes.censoring_method = 'MAXVAL';
matlabbatch{1}.spm.tools.physio.model.movement.yes.censoring_threshold = 2; % mm for translation, degrees for rotation

matlabbatch{1}.spm.tools.physio.model.other.no = struct([]);

matlabbatch{1}.spm.tools.physio.verbose.level = 0;
matlabbatch{1}.spm.tools.physio.verbose.fig_output_file = '';%[sub_id '-' run_id '-physio-' brain_or_spinal '-' version_name '.jpeg'];
matlabbatch{1}.spm.tools.physio.verbose.use_tabs = false;

end
