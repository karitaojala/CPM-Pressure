%function plot_Fourier_model(options,analysis_version,modelname,regressors)

analysis_version = '23Nov22';
basisF = 'Fourier';
modelname = [basisF '_phasic_tonic'];

sub = 1;

name = sprintf('sub%03d',sub);
disp(name);

firstlvlpath = fullfile(options.path.mridir,name,'1stlevel',['Version_' analysis_version],modelname);
SPM_bf = load(fullfile(firstlvlpath,'SPM.mat'));

FourierBasis = SPM_bf.SPM.xBF.bf;
% figure;subplot(2,1,1)
% plot(FourierBasis*beta(1:11),'LineWidth',2)
% title('Fourier set all - EXP')
% ylim([0 0.15])
% subplot(2,1,2)
% plot(FourierBasis*beta(12:22),'LineWidth',2)
% title('CON')
% ylim([0 0.15])
% sgtitle('Fourier set basis functions x betas')

clr = [147, 167, 244; 132, 150, 220; 106, 120, 176; 103, 117, 171; 88, 100, 146]/255;

figure;subplot(2,1,1)
plot(FourierBasis(:,1)*beta(1),'LineWidth',1.5,'Color','b')
hold on
plot(FourierBasis(:,2:3)*beta(2:3),'LineWidth',1.5,'Color',clr(1,:))
plot(FourierBasis(:,2:5)*beta(2:5),'LineWidth',1.5,'Color',clr(2,:))
plot(FourierBasis(:,2:7)*beta(2:7),'LineWidth',1.5,'Color',clr(3,:))
plot(FourierBasis(:,2:9)*beta(2:9),'LineWidth',1.5,'Color',clr(4,:))
plot(FourierBasis(:,2:11)*beta(2:11),'LineWidth',1.5,'Color',clr(5,:))
% legend('Hanning window + 1st order', ...
%     'Hanning window + 1st-2nd order', ...
%     'Hanning window + 1st-3rd order', ...
%     'Hanning window + 1st-4th order', ...
%     'Hanning window + 1st-5th order', ...
%     'Location','south')
title('EXP')
ylim([-0.02 0.2])
xlim([0 6000])

subplot(2,1,2)
plot(FourierBasis(:,1)*beta(12),'LineWidth',1.5,'Color','b')
hold on
plot(FourierBasis(:,2:3)*beta(13:14),'LineWidth',1.5,'Color',clr(1,:))
plot(FourierBasis(:,2:5)*beta(13:16),'LineWidth',1.5,'Color',clr(2,:))
plot(FourierBasis(:,2:7)*beta(13:18),'LineWidth',1.5,'Color',clr(3,:))
plot(FourierBasis(:,2:9)*beta(13:20),'LineWidth',1.5,'Color',clr(4,:))
plot(FourierBasis(:,2:11)*beta(13:22),'LineWidth',1.5,'Color',clr(5,:))
title('CON')
ylim([-0.02 0.2])
xlim([0 6000])

% legend('Hanning window + 1st order', ...
%     'Hanning window + 1st-2nd order', ...
%     'Hanning window + 1st-3rd order', ...
%     'Hanning window + 1st-4th order', ...
%     'Hanning window + 1st-5th order', ...
%     'Location','best')

sgtitle('Fourier set basis functions x betas')

%end