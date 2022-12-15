function qualitycheck_motion_fmri
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

% Subject list and setting for which SCT preproc data to take
all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49]; % all 42 included subjects
% all_subs     = [1 2 4:10 12:13 15:18 20:27 29:34 37:40 42:49]; % subs 11 and 25 not run -> take 25 from sc_proc
% all_subs2     = [1 2 4:7 12:13 15:18 24:27 29:30 37:39 42:44]; % if sc_proc data
% all_subs = setdiff(all_subs,all_subs2);
% data1 = true; % Karita's preproc data with SCT native Windows
% data2 = false; % Christian's preproc data with SCT WSL

% Whether spinal or brain motion is retrieved
spinal = false; % otherwise brain
motion_dir_spinal = fullfile(base_dir,'..','motion','spinal');
motion_dir_brain = fullfile(base_dir,'..','motion','brain');

% Threshold for marking spikes
spikeTh = 2; % units (mm?)

for sub = 10:numel(all_subs)
    
    clear motion motion_x motion_y motion_z rotation_x rotation_y rotation_z
    
    name        = sprintf('sub%0.3d',all_subs(sub));
    a           = dir([base_dir name filesep 'epi-run*']);
    epi_folders = cellstr(strvcat(a.name));

    fprintf(['Doing volunteer ' name '\n']);
    
    clear fig
    fig = figure('Position',[10,10,800,500]);
    
    
    for run = 1:6
        
        fprintf(['EPI run ' num2str(run) '\n']);
        
        switch spinal
            case true % spinal
                motion_name = 'moco_params.tsv'; 
            case false % brain
                motion_name = ['rp_a' name '-epi-run' num2str(run) '-brain.txt']; 
        end
        
        if spinal && all_subs(sub) == 25
            full_epi_dir = [base_dir2 name filesep epi_folders{run}];
        else
            full_epi_dir = [base_dir name filesep epi_folders{run}];
        end
        
        motion_file = fullfile(full_epi_dir,motion_name);
        
        try
            motion = importdata(motion_file);
        catch
            warning('Importing motion data failed')
            continue
        end
        
        switch spinal
            case true
                
                motion_x = motion.data(:,1);
                motion_y = motion.data(:,2);
                
                diff_x = diff(motion_x);
                diff_y = diff(motion_y);
                
                spikes = abs(diff_x) > spikeTh | abs(diff_y) > spikeTh;
                spikes = double(spikes);
                
                motiondir = motion_dir_spinal;
                
                legendtext = {'X translation','Y translation'};
                
            case false % brain
                
                motion_x = motion(:,1);
                motion_y = motion(:,2);
                motion_z = motion(:,3);
                
                diff_x = diff(motion_x);
                diff_y = diff(motion_y);
                diff_z = diff(motion_z);
                
                rotation_x = motion(:,4); % task: add to plot
                rotation_y = motion(:,5);
                rotation_z = motion(:,6);
                
                spikes = abs(diff_x) > spikeTh | abs(diff_y) > spikeTh | abs(diff_z) > spikeTh;
                spikes = double(spikes);
                if sum(spikes) > 0; fprintf(['--' num2str(sum(spikes)) ' spike(s) larger than ' num2str(spikeTh) ' mm found.\n']); end
                    
                motiondir = motion_dir_brain;
                
                legendtext = {'X transl.','Y transl.', 'Z transl.','X rotat.','Y rotat.', 'Z rotat.'};
                
        end
        
        subplot(2,3,run)
        
        plot(motion_x)
        hold on
        plot(motion_y)
        if ~spinal
            plot(motion_z); 
            plot(rotation_x); 
            plot(rotation_y); 
            plot(rotation_z); 
        end
        
        % mark spikes
        if sum(spikes) > 0
            spikes(spikes == 0) = NaN;
            spikes(spikes == 1) = -3;
            plot(spikes,'x','MarkerSize',10,'MarkerEdgeColor','r','LineWidth',2)
        end
        
        title(['EPI run ' num2str(run)])
        xlabel('Volume (TR)')
        ylabel('Movement (mm)') % Confirm that unit mm
        ylim([-5 5])
        
        if run == 6 % legend only for last run subplot
            lgd = legend(legendtext,'Location','southeast','FontSize',6);
            if ~spinal; lgd.NumColumns = 2; end
        end
        
    end
    
    sgtitle(name)
    
    if exist('motiondir','var')
        if ~exist(motiondir,'dir'); mkdir(motiondir); end
        savefig(fig,fullfile(motiondir,[name '_motion.fig']))
        saveas(fig,fullfile(motiondir,[name '_motion.png']))
    end
    
    close all
    
end

end