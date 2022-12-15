
roipath = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\Version_23Nov22\Fourier_phasic_tonic\PhasicStim-All';
roinames = {'Left_S1' 'Left_S2'};

betafolder_con = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\Version_23Nov22\Fourier_phasic_tonic\PhasicStim-CON';
betafolder_exp = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\Version_23Nov22\Fourier_phasic_tonic\PhasicStim-EXP';

betafile_con = fullfile(betafolder_con,sprintf('beta_0001.nii'));
betafile_exp = fullfile(betafolder_exp,sprintf('beta_0001.nii'));

figure

for roi = 1:2
    
    subplot(2,1,roi)
    roifile = fullfile(roipath,[roinames{roi} '.nii']);
    
    Y = spm_read_vols(spm_vol(roifile),1); % Y is 4D matrix of image data
    indx = find(Y>0);
    [x,y,z] = ind2sub(size(Y),indx);
    roicoords = [x y z]';

    meanbeta_con = mean(spm_get_data(betafile_con,roicoords),2);
    meanbeta_exp = mean(spm_get_data(betafile_exp,roicoords),2);

    bar([meanbeta_exp meanbeta_con],'LineWidth',1.5)
    hold on
    set(gca,'xticklabel',{'Tonic EXP' 'Tonic CON'})
    ylabel('Beta')
    title(['Phasic stimulus response - ' strrep(roinames{roi},'_',' ')])
    ylim([0 1])
    yticks([0:0.2:1])

end

firstlvlpath = fullfile('C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\sub001\1stlevel\Version_23Nov22\Fourier_phasic_tonic');
SPM_bf = load(fullfile(firstlvlpath,'SPM.mat'));
basisFunc = SPM_bf.SPM.xBF.bf;

figure
plot(basisFunc*meanbeta_exp,'LineWidth',1.5,'Color','r')
hold on
plot(basisFunc*meanbeta_con,'LineWidth',1.5,'Color','b')
legend('EXP','CON')


firstlvlpath = fullfile('C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\sub001\1stlevel\Version_23Nov22\Fourier_phasic_tonic');
SPM_bf = load(fullfile(firstlvlpath,'SPM.mat'));
basisFunc = SPM_bf.SPM.xBF.bf;

figure
plot(basisFunc*beta(1),'LineWidth',1.5,'Color','r')
hold on
plot(basisFunc*beta(2),'LineWidth',1.5,'Color','b')
legend('Tonic EXP','Tonic CON')
title(['Phasic stimulus response BF x beta'])

% voxelcoords = [39 -18 9]; % posterior insula
% voxelcoords = [36 7.5 10.5]; % anterior insula
voxelcoords = [46.5 -1.5 4.5]; % central operculum/S2

beta_con = spm_get_data(betafile_con,voxelcoords');
beta_exp = spm_get_data(betafile_exp,voxelcoords');
    
figure('Position',[500 500 300 300])
bar([beta(1) beta(2)],'LineWidth',1.5)
% bar([beta_exp beta_con],'LineWidth',1.5)
set(gca,'xticklabel',{'Tonic EXP' 'Tonic CON'})
title({'Phasic stimulus response'; ['voxel x = ' num2str(voxelcoords(1)) ', y = ' num2str(voxelcoords(2)) ', z = ' num2str(voxelcoords(3))]})
ylabel('Beta')