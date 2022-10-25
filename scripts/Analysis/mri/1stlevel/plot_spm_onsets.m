
all_subs    = [1 2 4:13 15:18 20:27 29:34 37:40 42:49];

for sub = 5%all_subs
    
    clear SPM
    sub_id = sprintf('sub%03d',sub);
    %spmname = ['C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\' sub_id '\1stlevel\Version_13Oct22\Boxcar_painOnly_HRF_noPhysio\SPM.mat'];
    %load(spmname)

    figure;
    for run = 1:4
        %onsets = SPM.Sess(run).U.ons;
        
        spmname = ['C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\logs\' sub_id '\pain\' sub_id '-run' num2str(run+1) '-onsets.mat'];
        load(spmname)
        
        onsets = onsetsStim;
        onsets2 = onsetsVAS;
        onsets3 = onsetsTonic;
        subplot(2,2,run)
        hold on
        plot(onsets,ones(numel(onsets),1),'o','LineWidth',2,'Color','red');
        plot(onsets2,0.8*ones(numel(onsets2),1),'o','LineWidth',2,'Color','green');
        plot(onsets3,1.2*ones(numel(onsets3),1),'o','LineWidth',2,'Color','b');
        title(sprintf('Run %d',run))
        ylim([0 2])
    end
    sgtitle(sprintf('Sub%03d',sub))
    
    close all
    
end
    