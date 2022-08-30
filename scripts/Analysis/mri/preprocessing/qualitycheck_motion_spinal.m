function qualitycheck_motion_spinal
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

% all_subs     = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];
all_subs     = [1 2 4:10 12:13 15:18 20:27 29:34 37:40 42:49]; % subs 11 and 25 not run -> take 25 from sc_proc
% all_subs2     = [1 2 4:7 12:13 15:18 24:27 29:30 37:39 42:44]; % if sc_proc data
% all_subs = setdiff(all_subs,all_subs2);
% data1 = true;
% data2 = false;

for sub = 1:numel(all_subs)
    
    clear images
    
    name        = sprintf('sub%0.3d',all_subs(sub));
    a           = dir([base_dir name filesep 'epi-run*']);
    epi_folders = cellstr(strvcat(a.name));

    fprintf(['Doing volunteer ' name '\n']);
    
    clear fig
    fig = figure('Position',[10,10,800,500]);
    
    for run = 1:6
        
        fprintf(['EPI run ' num2str(run) '\n']);

        motion_name = 'moco_params.tsv';
        
        if all_subs(sub) == 25
            full_epi_dir = [base_dir2 name filesep epi_folders{run}];
        else
            full_epi_dir = [base_dir name filesep epi_folders{run}];
        end
        
        motion_file = fullfile(full_epi_dir,motion_name);
        
        motion = importdata(motion_file);
        
        motion_x = motion.data(:,1);
        motion_y = motion.data(:,2);
        
        diff_x = diff(motion_x);
        diff_y = diff(motion_y);
        
        spikes = abs(diff_x) > 1 | abs(diff_y) > 1;
        
        subplot(2,3,run)
        
        plot(motion_x)
        hold on
        plot(motion_y)
        
        % mark spikes
        if sum(spikes) > 0
            spikes = double(spikes);
            spikes(spikes == 0) = NaN;
            spikes(spikes == 1) = -2.5;
            plot(spikes,'x','MarkerSize',10,'MarkerEdgeColor','r','LineWidth',2)
        end
        
        title(['EPI run ' num2str(run)])
        xlabel('Volume (TR)')
        ylabel('Movement') % Unit ????
        ylim([-3 3])
        
        if run == 6
            legend('X direction','Y direction')
        end
        
    end
    
    sgtitle(name)
    
    motiondir = fullfile(base_dir,'..','motion');
    if ~exist(motiondir,'dir'); mkdir(motiondir); end
    savefig(fig,fullfile(motiondir,[name '_motion.fig']))
    saveas(fig,fullfile(motiondir,[name '_motion.png']))
    
    close all
    
end

end