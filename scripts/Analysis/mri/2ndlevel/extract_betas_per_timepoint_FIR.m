

% ROI coordinates
roifile = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\meanmasks\LeftS1_cluster.nii';
% roifile = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\meanmasks\LeftParietalOperculum_cluster.nii';
% roifile = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\meanmasks\LeftCentralOperculum_cluster.nii';

Y = spm_read_vols(spm_vol(roifile),1); % Y is 4D matrix of image data
indx = find(Y>0);
[x,y,z] = ind2sub(size(Y),indx);
XYZ = [x y z]';

% Extract betas from the ROI for this condition
% Save in a matrix of format [subject,condition,ROI]

% betafolder = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\Version_13Oct22\Boxcar_painOnly_FIR\FTest';
betafolder = 'C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\2ndlevel\Version_24Oct22\Boxcar_FIR\SanityCheck';

for tp = 1:10
    cond_bfile = fullfile(betafolder,sprintf('beta_00%02d.nii',tp));
    meanbetas(tp) = mean(spm_get_data(cond_bfile,XYZ),2);
end

figure;plot(meanbetas)
%ylim([0.002 0.022])
ylabel('Mean beta')
xlabel('TR')