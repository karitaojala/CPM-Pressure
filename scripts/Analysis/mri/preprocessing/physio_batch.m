function matlabbatch = physio_batch(spinal,sub_id,run_id,output_dir,physio_file,motion_file,no_motion_reg,relative_start_acquisition,no_scans_run,n_slices,onset_slice,time_slice_to_slice)

% Physio regressors run-wise
% Then need to also split physio signals into runs (6 files)
% OR create physio regressors across runs but then split regressors later
% into runs for GLM?

matlabbatch{1}.spm.tools.physio.save_dir = {output_dir};

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
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Ndummies = 0;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nscans = no_scans_run;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.onset_slice = onset_slice;
%matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.time_slice_to_slice = time_slice_to_slice;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nprep = 0;
matlabbatch{1}.spm.tools.physio.scan_timing.sync.scan_timing_log = struct([]);

matlabbatch{1}.spm.tools.physio.preproc.cardiac.modality = 'PPU';
matlabbatch{1}.spm.tools.physio.preproc.respiratory.filter.passband = [0.05 2];
matlabbatch{1}.spm.tools.physio.preproc.respiratory.despike = true;

if spinal; output_suffix = 'spinal'; else; output_suffix = 'brain'; end
matlabbatch{1}.spm.tools.physio.model.output_multiple_regressors = [sub_id '-' run_id '-multiple_regressors-' output_suffix '.txt'];
matlabbatch{1}.spm.tools.physio.model.output_physio = [sub_id '-' run_id '-physio-' output_suffix '.mat'];

matlabbatch{1}.spm.tools.physio.model.orthogonalise = 'none';
matlabbatch{1}.spm.tools.physio.model.censor_unreliable_recording_intervals = false;

matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.c = 3;
matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.r = 4;
matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.cr = 1;
% matlabbatch{1}.spm.tools.physio.model.rvt.yes.method = 'hilbert';
% matlabbatch{1}.spm.tools.physio.model.rvt.yes.delays = 0;
% matlabbatch{1}.spm.tools.physio.model.hrv.yes.delays = 0;
% matlabbatch{1}.spm.tools.physio.model.noise_rois.no = struct([]);

matlabbatch{1}.spm.tools.physio.model.movement.yes.file_realignment_parameters = {motion_file}; % Realignment motion regressors file
matlabbatch{1}.spm.tools.physio.model.movement.yes.order = no_motion_reg; % Number of motion regressors
matlabbatch{1}.spm.tools.physio.model.movement.yes.censoring_method = 'MAXVAL';
matlabbatch{1}.spm.tools.physio.model.movement.yes.censoring_threshold = 2; % mm for translation, degrees for rotation

matlabbatch{1}.spm.tools.physio.model.other.no = struct([]);

matlabbatch{1}.spm.tools.physio.verbose.level = 2;
matlabbatch{1}.spm.tools.physio.verbose.fig_output_file = [sub_id '-' run_id '-physio.jpeg'];
matlabbatch{1}.spm.tools.physio.verbose.use_tabs = false;

end
