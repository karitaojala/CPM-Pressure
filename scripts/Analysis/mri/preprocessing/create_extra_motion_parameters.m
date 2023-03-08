function create_extra_motion_parameters(motion_file,name,run_id,region)

% Load motion parameters
[fp,~,ext] = fileparts(motion_file);
if strcmp(ext,'.tsv')
    motionparam = importdata(motion_file);
    motionparam = motionparam.data;
else
    motionparam = load(motion_file);
end
nparam = size(motionparam,2);

motionfile_orig = fullfile(fp,['motion-' name '-epi-' run_id '-' region '-' num2str(nparam) 'param.txt']);
writematrix(motionparam,motionfile_orig,'Delimiter','tab');

% Derivatives of motion parameters (total 12 regressors)
motionparam_deriv = [zeros(1,nparam); diff(motionparam)];
% [~,motionparam_deriv] = gradient(motionparam);
% figure;plot(motionparam_deriv);
% figure;plot(motionparam_deriv2)

motionparam_with_deriv = [motionparam motionparam_deriv];
nparam2 = size(motionparam_with_deriv,2);
motionparam_with_deriv_zscored = zscore(motionparam_with_deriv);
% motionfile_deriv = fullfile(fp,[name '-' num2str(nparam2) 'param-gradient' ext]);
% motionfile_deriv = fullfile(fp,[name '-' num2str(nparam2) 'param.txt']);
% writematrix(motionparam_with_deriv_zscored,motionfile_deriv,'Delimiter','tab');

% Squares of motion parameters on top of derivatives (total 24 regressors)
motionparam_square = motionparam_with_deriv_zscored.^2;
motionparam_square_zscored = zscore(motionparam_square);
%figure;plot(motionparam_square);
motionparam_with_deriv_square = [motionparam_with_deriv_zscored motionparam_square_zscored];
nparam3 = size(motionparam_with_deriv_square,2);
% motionfile_24 = fullfile(fp,[name '-24param-gradient' ext]);
motionfile_square = fullfile(fp,['motion-' name '-epi-' run_id '-' region '-' num2str(nparam3) 'param.txt']);
% writematrix(motionparam_with_deriv_square,motionfile_square,'Delimiter','tab');

end