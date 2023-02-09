clear all

addpath(genpath('C:\Data\CPM-Pressure\scripts\Analysis\mri'))
options = get_options();

for sub = 1:numel(options.subj.all_subs)
    
clear corrmat
    
name = sprintf('sub%03d',options.subj.all_subs(sub));
physiopathsub = fullfile(options.path.physiodir,name);

for run = options.acq.exp_runs
    clear corrmat_run
    physiofile = fullfile(physiopathsub, [name '-run' num2str(run) '-multiple_regressors-brain-HRVRVT_noiseROI_6comp_24motion-zscored.txt']);
    physio = load(physiofile);
    corrmat_run = corrcoef(physio(:,1:58));
    %figure;imagesc(tril(corrmat_run)); title([name ' ' sprintf('run%02d',run)]);colormap(gray);colorbar
    corrmat(run-1,:,:,:) = corrmat_run;
end

corrmat_all(sub,:,:,:) = squeeze(mean(corrmat,1));

end

corrmat_all_mean = squeeze(mean(corrmat_all,1));
figure;imagesc(tril(corrmat_all_mean))
% set(gca,'xticklabel',{'Transl x' 'Transl y' 'Transl z' 'Rot x' 'Rot y' 'Rot z'});
% set(gca,'yticklabel',{'Transl x' 'Transl y' 'Transl z' 'Rot x' 'Rot y' 'Rot z'});
colormap(gray)
caxis([-1 1])
colorbar