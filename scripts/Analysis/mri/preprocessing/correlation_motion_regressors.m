addpath(genpath('C:\Data\CPM-Pressure\scripts\Analysis\mri'))
options = get_options();
addpath(options.path.spmdir)

analysis_version = '23Nov22';
basisF = 'Fourier';
modelname = [basisF '_phasic_tonic'];

brainmask = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\meanmasks\brainmask_secondlevel.nii';

Y = spm_read_vols(spm_vol(brainmask),1); % Y is 4D matrix of image data
indx = find(Y>0);
[x,y,z] = ind2sub(size(Y),indx);
coords = [x y z]';

con_list = 47:52;
con_names = {'x translation' 'y translation' 'z translation' ...
    'x rotation' 'y rotation' 'z rotation'};

for con = 1:numel(con_list)
    
    figure('Position',[500 500 1200 900]);
    sgtitle(['Motion regressor con images: ' con_names{con}])
    
    for sub = 1:numel(options.subj.all_subs)
        
        name = sprintf('sub%03d',options.subj.all_subs(sub));
        
        firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
        conimg = spm_read_vols(spm_vol(fullfile(firstlvlpath,['s_w_nlco_dartel_con_00' num2str(con_list(con)) '.nii'])),1); % con image 1st level
        
        conimg(conimg < 0.05 & conimg > -0.05) = 0;
        subplot(6,7,sub)
        image(conimg(:,:,60)); colormap(jet); hold on
        title(name)
        axis off
        %     physiopathsub = fullfile(options.path.physiodir,name);
        %
        %     for run = options.acq.exp_runs
        %         motionfile = fullfile(physiopathsub, [name '-run' num2str(run) '-motion_regressors-brain-zscored.txt']);
        %         motion = load(motionfile);
        %         corrmat(run-1,:,:,:) = corr(motion);
        %     end
        %
        %     corrmat_all(sub,:,:,:) = squeeze(mean(corrmat,1));
        %     corrmat_all_var(sub,:,:,:) = squeeze(std(corrmat,1));
        
        %figure;imagesc(squeeze(corrmat_all(sub,:,:,:)))
        
    end
    
end

corrmat_all_mean = squeeze(mean(corrmat_all,1));
figure;imagesc(corrmat_all_mean)
set(gca,'xticklabel',{'Transl x' 'Transl y' 'Transl z' 'Rot x' 'Rot y' 'Rot z'});
set(gca,'yticklabel',{'Transl x' 'Transl y' 'Transl z' 'Rot x' 'Rot y' 'Rot z'});
colormap(jet)
caxis([-1 1])
colorbar

corrmat_all_mean_var = squeeze(mean(corrmat_all_var,1));
figure;imagesc(corrmat_all_mean_var)
set(gca,'xticklabel',{'Transl x' 'Transl y' 'Transl z' 'Rot x' 'Rot y' 'Rot z'});
set(gca,'yticklabel',{'Transl x' 'Transl y' 'Transl z' 'Rot x' 'Rot y' 'Rot z'});
colormap(jet)
caxis([-1 1])
colorbar