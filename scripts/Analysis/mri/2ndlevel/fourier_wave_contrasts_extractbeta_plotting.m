

SPM_tonicBF = load('C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\sub001\1stlevel\Version_19Dec22\Fourier_tonic_only\SPM.mat');
tonicFourier_des = SPM_tonicBF.SPM.xX.X;
tonicFourier_des_mtx = tonicFourier_des(1:227,1:11);

SPM_tonicPmod = load('C:\Data\CPM-Pressure\data\CPM-Pressure-01\Experiment-01\mri\data\sub001\1stlevel\Version_19Dec22\HRF_phasic_tonic_pmod\SPM.mat');
tonicPmod = SPM_tonicPmod.SPM.xX.X(1:227,2);

beta = pinv(tonicFourier_des_mtx)*tonicPmod;
figure
plot(tonicFourier_des_mtx*beta)
hold on
plot(tonicPmod)
legend('Fourier set * contrast weights','Tonic pmod')

tonicPmod_Fourier_beta = beta;
