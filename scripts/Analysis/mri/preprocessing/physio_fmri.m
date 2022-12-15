function physio_fmri

spm_path    = 'C:\Data\Toolboxes\spm12';
PhysIO_path = 'C:\Data\Toolboxes\tapas';

addpath(spm_path, PhysIO_path)

base_dir    = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\';
physio_dir   = fullfile(base_dir,'physio');
motion_dir   = fullfile(base_dir,'mri','data');
%logdir      = fullfile(base_dir,'logs');

all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];

n_runs            = 6;
n_scans_all       = [56 232 232 232 232 56];
n_dummy           = 5;
n_scans           = n_scans_all-n_dummy;
run_first_trial   = [1 2 4 6 8 10];
TR                = 1.991;
buffer_time_end   = round(TR);
multiband_factor  = 3; % brain only

% Options
spinal              = false;
extract_physio_runs = false;
convert_physio2bids = false;
run_physio_batch    = false;
calc_manual_physio  = false;
add_button_presses  = false;
zscore_physio       = true;

if spinal % Spinal
    n_slices = 12;
    onset_slice = 1; % onset slice index, here 1 as it's the first spinal slice that is closest to the slice time correction reference slice
    % slices acquired descending
    time_slice_to_slice  = 0.0725; % 72.5 ms in spinal cord
    no_motion_reg  = 2;
    region = 'spinal';
    
else % Brain
    n_slices = 60/multiband_factor;
    onset_slice = n_slices; % last brain slice closest to the slice time correction reference slice (50 ms from last brain slice and first spinal)
    time_slice_to_slice  = 0.0575; % 57.5 ms in the brain, except that multiband factor 3 -> 3 slices acquired at each time
    no_motion_reg = 6;
    region = 'brain';
    
end

relative_start_acquisition = 0;

physregopts.samp_int = 0.01; % 10 ms equals 100Hz
physregopts.tol_s    = 5;    % taken times 10 = ms
physregopts.order_c  = 3;    % according to Harvey 2008 --> 3C4R1X
physregopts.order_r  = 4;
physregopts.order_cr = 1;
physregopts.h_size   = 300; %for breathing histogram

no_noise_reg = 18 + no_motion_reg;

if extract_physio_runs
    
    for sub = all_subs
        
        name = sprintf('sub%03d',sub);
        disp(name);
        
        outdir = fullfile(physio_dir,name);
        if ~exist(outdir,'dir'); mkdir(outdir); end
        
        start_scan = n_dummy + 1;
        all_scans = [];
        
        for run = 1:n_runs
            
            if strcmp(name,'sub006') && run == 6
                n_scans_run = 52-n_dummy; % sub006 has less scans for run 6
            else
                n_scans_run = n_scans(run);
            end
            
            [start_scan,physio,behav] = get_physio(physio_dir,name,run,start_scan,n_scans_run,n_dummy,run_first_trial(run),buffer_time_end);
            
            start_scans_all(run) = start_scan;
            all_scans = [all_scans physio.scansPhysioStart'];
            
            save(fullfile(outdir,sprintf('sub%03d-run%d-physio.mat',sub,run)),'physio');
            save(fullfile(outdir,sprintf('sub%03d-run%d-behav.mat',sub,run)),'behav');
            
            if run < n_runs
                start_scan = start_scan + n_scans(run) + n_dummy;
            end
            
        end
        
        %check_scanner_runs(all_scans)
        
    end
    
end

if calc_manual_physio
    
    for sub = 1:numel(all_subs)
        
        fprintf('Manually calculating physiological noise regressors...\n')
        name = sprintf('sub%03d',all_subs(sub));
        disp(name);
        
        output_dir = fullfile(physio_dir,name);
        
        for run = 1:n_runs
        
            run_id = sprintf('run%d',run);
            fprintf([run_id '\n']);
            
            physio_file = fullfile(output_dir,sprintf('sub%03d-run%d-physio.mat',all_subs(sub),run));
            physio_reg_file = fullfile(output_dir,sprintf('sub%03d-run%d-physio-regressors.mat',all_subs(sub),run));
            physio_fig_file = fullfile(output_dir,sprintf('sub%03d-run%d-physio-fig',all_subs(sub),run));
            
            load(physio_file,'physio');
            
            [physio_reg,physio_fig] = calc_physio_regressors(physio,physregopts);
            
            save(physio_reg_file,'physio_reg');
            sgtitle([name ' ' run_id])
            savefig(physio_fig,physio_fig_file);
            saveas(physio_fig,[physio_fig_file '.png']);
            close all
            
        end
        
    end
    
end

if convert_physio2bids

    physio2bids(physio_dir,all_subs,n_runs);
    
end

if run_physio_batch
    
    for sub = 1:numel(all_subs)
        
        fprintf('Running PhysIO batch...\n')
        name = sprintf('sub%03d',all_subs(sub));
        disp(name);
        
        output_dir = fullfile(physio_dir,name);
        
        for run = 1:n_runs
        
            close all
            run_id = sprintf('run%d',run);
            disp(run_id);
            
            physio_file = fullfile(output_dir,[name '-' run_id '-physio-bids.tsv.gz']);
            
            if spinal
                motion_file = fullfile(motion_dir,name,['epi-' run_id],'moco_params.tsv');
            else
                motion_file = fullfile(motion_dir,name,['epi-' run_id],['rp_a' name '-epi-' run_id '-brain.txt']);
            end
            
            if strcmp(name,'sub006') && run == 6
                n_scans_run = 52-n_dummy; % sub006 has less scans for run 6
            else
                n_scans_run = n_scans(run);
            end
            
            matlabbatch = physio_batch(spinal,name,run_id,output_dir,physio_file,motion_file,no_motion_reg,relative_start_acquisition,n_scans_run,n_slices,onset_slice,time_slice_to_slice);
            spm_jobman('run',matlabbatch);
            
        end
        
        fprintf('... Done\n')
        fprintf('--------\n')
        
    end
    
end

if add_button_presses

    for sub = 1:numel(all_subs)
        
        fprintf('Adding button presses to noise regressors...\n')
        name = sprintf('sub%03d',all_subs(sub));
        disp(name);
        
        output_dir = fullfile(physio_dir,name);
        
        for run = 1:n_runs
        
            run_id = sprintf('run%d',run);
            fprintf([run_id '\n']);
            
            behav_file = fullfile(output_dir,sprintf('sub%03d-run%d-behav.mat',all_subs(sub),run));
            behavdata = load(behav_file);
            
            physio_file = fullfile(output_dir,sprintf('sub%03d-run%d-multiple_regressors-%s.txt',all_subs(sub),run,region));
            physiodata = load(physio_file);

            bpPerScan = behavdata.behav.buttonPresses;
            
        end
        
    end
    
end

if zscore_physio
    
    for sub = 1:numel(all_subs)
        
        fprintf('Z-scoring noise regressors...\n')
        name = sprintf('sub%03d',all_subs(sub));
        disp(name);
        
        output_dir = fullfile(physio_dir,name);
        
        for run = 1:n_runs
        
            run_id = sprintf('run%d',run);
            fprintf([run_id '\n']);
            
            % Physio + motion regressors
            physio_file = fullfile(output_dir,sprintf('sub%03d-run%d-multiple_regressors-%s.txt',all_subs(sub),run,region));
            physiodata = load(physio_file);
            physiodata_temp = physiodata(:,1:no_noise_reg); % take only real physio regressors, not motion volume exclusion regressors
            %physiodata_temp_z = reshape(zscore(physiodata_temp(:)), size(physiodata_temp));
            physiodata_temp_z = zscore(physiodata_temp);
            physiodata_z = physiodata;
            physiodata_z(:,1:no_noise_reg) = physiodata_temp_z;
            
            physiofile_new = fullfile(output_dir,sprintf('sub%03d-run%d-multiple_regressors-%s-zscored.txt',all_subs(sub),run,region));
            writematrix(physiodata_z,physiofile_new,'Delimiter','tab');
            
            % Motion regressors only
            if spinal
                motion_file = fullfile(motion_dir,name,['epi-' run_id],'moco_params.tsv');
            else
                motion_file = fullfile(motion_dir,name,['epi-' run_id],['rp_a' name '-epi-' run_id '-brain.txt']);
            end
            motiondata = load(motion_file);
            %motiondata_z = reshape(zscore(motiondata(:)), size(motiondata));
            motiondata_z = zscore(motiondata);
            
            motionfile_new = fullfile(output_dir,sprintf('sub%03d-run%d-motion_regressors-%s-zscored.txt',all_subs(sub),run,region));
            writematrix(motiondata_z,motionfile_new,'Delimiter','tab');
            
        end
        
    end
        
end

end

function check_scanner_runs(all_scans)
%Check scanner pulses over runs

figure;

for pulse = 1:numel(all_scans)
    line([all_scans(pulse) all_scans(pulse)],[0 1],'Color',[128 128 128]./255)
    hold on
end

end